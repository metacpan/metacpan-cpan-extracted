package MsgQ::SendQueue;


require 5.6.1;
use strict;
use warnings;
use IO::Socket;

use vars qw($VERSION $sock $new_sock $DEBUG $record_time $server_con 
	    $record_separator %CONFIG $MESSAGE_TYPE
            $REPORT_FILE $REPORT_DIR $ERROR $TEMP $last_connect_attempt 
	    $receiveq_handle $filehandle  
	    $sendq $micro $f_micro $message_length $messages_sent_today
	    $messages_sent_last_hour $socket_connects_today);

$VERSION = '1.01';

$DEBUG=1;#set the debug on or off 0 is off and 1 is on;


sub new 
{
        my ($class) = @_;

	my $mover = 
	{
		"DEBUG" => 0, #0 is off , 1 is on
		"CONFIG_FILE" => './SendQueue.conf', #0 is off , 1 is on
	};

	bless $mover, $class;
	return $mover;
}

#################################################
#  Accessor Methods 
#################################################
sub debug
{
	my $mover = shift;
	my $debug = shift;		
	if($debug)
	{
		$mover->{'DEBUG'} = $debug;		
	}

	return $mover->{'DEBUG'};

}
sub config_file
{
	my $mover = shift;
	my $path = shift;		
	if($path)
	{
		$mover->{'CONFIG_FILE'} = $path;		
	}

	return $mover->{'CONFIG_FILE'};

}


#################################################
#  Member Functions
#################################################

sub start_queue
{

my $mover = shift;
my $config_file = shift;

$last_connect_attempt = 0;


#get the hostname of this machine for later use
use Sys::Hostname;
$sendq = hostname();

for(0 .. 40)
{
	print "\n";
}
print "Send Queue is running...\n\n\n\n";


#parse the configuration file
$config_file = $mover->config_file() if !$config_file;
parse_config_file($config_file);

#save the config file path for later use if necessary.				
$mover->config_file($config_file) if $config_file;

#set the report directory and create it if it doesn't exist
$REPORT_DIR = "$CONFIG{DATA}{FILES}/$CONFIG{QUEUE}{QUEUE}";

#this is where the errors are being logged
$ERROR = "$REPORT_DIR/$CONFIG{QUEUE}{QUEUE}_error_log.txt";

#temp directory is where any temporary files are stored during a file transmit to the receive queue
use File::Path;
$TEMP = "$REPORT_DIR/tmp";
if(!-d $TEMP)
{
	mkpath $TEMP or log_error("$sendq: could not make dir $TEMP $!");
}

$REPORT_DIR = "$REPORT_DIR/Message_Files";
if(!-d $REPORT_DIR)
{
	mkpath $REPORT_DIR or log_error("$sendq: could not make dir $TEMP $!");
}



#setup the record separator in case there are escaped characters
if(exists $CONFIG{MESSAGE}{REC_SEP})
{
	$CONFIG{MESSAGE}{REC_SEP} =~ s/\\n/\n/g;
	$CONFIG{MESSAGE}{REC_SEP} =~ s/\\r/\r/g;
	$CONFIG{MESSAGE}{REC_SEP} =~ s/\\t/\t/g;
	$CONFIG{MESSAGE}{REC_SEP} =~ s/\\f/\f/g;
	$CONFIG{MESSAGE}{REC_SEP} =~ s/\\b/\b/g;
	$CONFIG{MESSAGE}{REC_SEP} =~ s/\\a/\a/g;
	$CONFIG{MESSAGE}{REC_SEP} =~ s/\\e/\e/g;
	$CONFIG{MESSAGE}{REC_SEP} =~ s/\\u/\u/g;
	$CONFIG{MESSAGE}{REC_SEP} =~ s/\\l/\l/g;
	$CONFIG{MESSAGE}{REC_SEP} =~ s/\\U/\U/g;
	$CONFIG{MESSAGE}{REC_SEP} =~ s/\\L/\L/g;
	$CONFIG{MESSAGE}{REC_SEP} =~ s/\\Q/\Q/g;
	$CONFIG{MESSAGE}{REC_SEP} =~ s/\\E/\E/g;
}


#fork the process that will be looking for incoming files and sending them out to the
#receive queue.
my $pid = fork();
if($pid == 0)#this is the child
{

	undef $server_con;

	while(1)
	{
	
		if(!defined $server_con)
		{

			open_socket(\$server_con);
			if (($DEBUG == 1) && ($server_con))
			{  
				print "opened con $server_con\n";		
			}
			elsif(($DEBUG == 1) && (!$server_con))
			{  
				print "didn't open con\n";		
			}
		}

		if(defined $server_con)
		{

			send_file_to_server(\$server_con);

		}		

		sleep 1;
	}

	print "Exiting file transmission thread\n" if $DEBUG == 1;
	exit;
}

#open the main socket.
$sock = new IO::Socket::INET (  LocalHost => $sendq,
				LocalPort => $CONFIG{SERVER}{SEND_QUEUE_PORT},
				Proto 	  => 'tcp',
				Listen    => 5, 
				Reuse     => 1
			     );

die log_error("$sendq: Socket could not get created. Reason: $!") unless $sock;

#add main socket to readables list
use IO::Select;
my $handles = new IO::Select($sock);


#set the first report file that will be used.
my ($sec,$min,$hours,$mday,$mon,$year) = localtime;
$year -= 100 if($year >= 100);
$mon += 1;
$year = sprintf("%02d",$year);
$mon = sprintf("%02d",$mon);
$mday = sprintf("%02d",$mday);
$hours = sprintf("%02d",$hours);
$min = sprintf("%02d",$min);
$sec = sprintf("%02d",$sec);
$REPORT_FILE = "$REPORT_DIR/$year$mon$mday$hours$min$sec.txt";

#calculate in bytes the MAX_FILE_SIZE
$CONFIG{DATA}{MAX_FILE_SIZE} *= 1000;

while(1)
{


	#check the readable handles
	HANDLE: foreach $filehandle ($handles->can_read(1))
	{



		if($filehandle == $sock)
		{
			$new_sock = $sock->accept();
			$handles->add($new_sock);

		}
		else
		{
			
			$record_time = record_key(1);

			if($MESSAGE_TYPE eq 'HEADER')
			{
				#find the bytes that contain the message length at the beggining of the message
				$message_length = '';
				my $var;
				while(length $message_length < $CONFIG{MESSAGE}{LENGTH})
				{
					if(sysread $filehandle,$var, 1)
					{
						$message_length .= $var;
					}
					else
					{
						#remove the socket from the readables list once the reading has finished and the socket has disconnected
						$handles->remove($filehandle);
						next HANDLE;
	
					}
				}
				print "message length is $message_length\n" if $DEBUG == 1;
				$message_length = unpack "N", $message_length;
				print "message length is $message_length\n" if $DEBUG == 1;
	
				#read in the message
				my $mess;
				undef $_;
				my $remaining_message = $message_length;
				while($remaining_message > 0)
				{
					
					if(sysread $filehandle,$mess, $remaining_message)
					{
						$_ .= $mess;
						$remaining_message -= length($mess);
						print "$mess\n" if $DEBUG == 1;
					}
					else
					{
						#remove the socket from the readables list once the reading has finished and the socket has disconnected
						$handles->remove($filehandle);
						next HANDLE;
					}
				}


			}
			else
			{
				my $sep = $CONFIG{MESSAGE}{REC_SEP};
				my $orig_sep = $/;

				$/ = $sep;
				$_ = <$filehandle>;

				if(!$_ || !/$sep/)
				{
					#remove the socket from the readables list if the reading has finished and the socket has disconnected
					$handles->remove($filehandle);
					next HANDLE;
				}
				
				chomp;
				$/ = $orig_sep;
			}

			#if this is a status request from the monitor then acknowledge it
			if(/^STATUS$/)#currently not being used
			{

				#count the number of files in the message files folder
				opendir DIR, "$REPORT_DIR" or die log_error("$sendq: could not open dir $REPORT_DIR $!");
				my @files = grep !/^\./, readdir DIR;
				closedir DIR;
				my $file_count = $#files + 1;
				$messages_sent_today = 0;
				$messages_sent_last_hour = 0;
				$socket_connects_today = 0;
				print $filehandle "$file_count|$messages_sent_today|$messages_sent_last_hour|$socket_connects_today\n";
			
				$handles->remove($filehandle);
				close $filehandle;
				undef $filehandle;

			}
			else  #send data to the receive queue
			{

	
					
				#open a connection to the receiving server...if no connection is possible then
				#print to the local file for the time being until the receiving server is available
				#again.
				if(!$server_con)
				{
					open_socket(\$server_con);
				}
	

				#send to the receiving server...if no send is possible then
				#print to the local file for the time being until the receiving server is available
				#again.
				if(defined $server_con)
				{
					#print "Entering files less than zero and Server Connection is: $server_con\n" if $DEBUG == 1;

					my $temp_record = "$record_time\t$_\n";
					if(syswrite $server_con, $temp_record,length($temp_record))
					{
						print "TO SOCKET:  $temp_record"  if $DEBUG == 1;
						
						#get the acknowledgement
						get_ack();
					}
					else
					{
						shutdown $server_con,2;
						undef $server_con;

						print_to_file($_);
					}
				}
				#if there is no connection open then just keep printing to file
				else
				{
					#print "Entering no connection and just print to file. Connection is: $server_con\n" if $DEBUG == 1;

					print_to_file($_);
				}

	
			}


				

	
		}




	}


}



close ($sock);

}#end start send queue

# This sub will parse the config.txt file and place the values in a hash.
sub parse_config_file()
{
	my $config_file = shift;
	undef %CONFIG; #reset the hash
	my $section;

	# Parse the config.txt file and get the parameter values
	open (FILE_, "$config_file") || die log_error("$sendq: could not open file $config_file $!");
	while(<FILE_>)
	{

		chomp; #get rid of the newline before creating the hash elemets otherwise we will get confused when dealing with the hash later
		s/#.*//;
		s/^\s+//;#get rid of whitespace first
		s/\s+$//;#get rid of whitespace first
		if(length($_) == 0)#if this line is blank then skip it
		{
			next;
		}


		if(/\[/ && /\]/)#if this is part of another section then start creating new hash elements
		{
			s/\[|\]//g;#replace the brackets with empty space
			$section = $_;
			next;
		}
			

		#Do normal key/value pairs
		my ($key,$value) = split(/\s*=\s*/);
		$CONFIG{$section}{$key} = $value;

	}
	close(FILE_);


	#Do some checking on config parameters
	if((exists $CONFIG{MESSAGE}{LENGTH}) && (exists $CONFIG{MESSAGE}{REC_SEP} ))
	{
		print "You have both the REC_SEP and MESSAGE LENGTH defined, in the configuration file...\n" if $DEBUG == 1;
		exit;
	}
	elsif((exists $CONFIG{MESSAGE}{LENGTH}) && (!exists $CONFIG{MESSAGE}{REC_SEP} ))
	{
		$MESSAGE_TYPE = 'HEADER';
	}
	elsif((exists $CONFIG{MESSAGE}{REC_SEP}) && (!exists $CONFIG{MESSAGE}{LENGTH}))
	{
		$MESSAGE_TYPE = 'REC_SEP'; 
	}
	else
	{
		print "You have neither the REC_SEP nor MESSAGE LENGTH defined, in the configuration file...\n" if $DEBUG == 1;
		exit;
	}


}




sub log_error
{
	my $error = shift;


	open E , ">> $ERROR" or die "could not open error log $ERROR $!";
	$record_time = record_key(2) if !defined $record_time;
	print E "$record_time\t$error\n";
	close E;
	
}
 
sub open_socket
{
	my $r_socket = shift;

	my $duration = time() - $last_connect_attempt;
	if($duration > $CONFIG{SERVER}{SOCKET_RECONNECT_INTERVAL})
	{
		$last_connect_attempt = time();

		my $ping = `ping -n 1 -w 100 $CONFIG{SERVER}{RECEIVE_QUEUE_HOST}`;
		if($ping !~ /request\s+timed\s+out/i)
		{
	
			$$r_socket = new IO::Socket::INET (  
				   PeerAddr => $CONFIG{SERVER}{RECEIVE_QUEUE_HOST},
				   PeerPort => $CONFIG{SERVER}{RECEIVE_QUEUE_PORT},
	  			   Proto    => 'tcp',
				   Type     => SOCK_STREAM,
				   Timeout  => 5
		
	   	     			);
			if($$r_socket)
			{
				print "Opened a new Server Connection: $$r_socket\n" if $DEBUG == 1;
				$$r_socket->autoflush(1);

				$receiveq_handle = new IO::Select();
				$receiveq_handle->add($$r_socket);
				
				$socket_connects_today++;

			}
			else
			{
				log_error("$sendq: Could not open connection with receive queue: $CONFIG{SERVER}{RECEIVE_QUEUE_HOST}");
			}	
		}

		
	}

	
}

#this function will get the acknowledgement sent back from the receive queue that the data sent was written to file.
sub get_ack
{


	#here we will wait up to two seconds for the ACK.  If it doesn't show up then we carry
	#on as though we've lost the connection to the receive queue and we susequently remove the filehandles
	#from the readables list as well as close the server connection.
	my @handles = $receiveq_handle->can_read(2);
	#print "handles are @handles\n";

	my $ack;
	if($#handles >= 0)#there should be only one handle.
	{
		#get the acknowledement
		sysread ($server_con, $ack, 3);
		if($ack eq 'ACK')
		{
			print "Got acknowledgment: $ack\n" if $DEBUG == 1;
			return (0);
		}
		#if we don't get the ack then close the socket so that we don't keep writing to it until the socket buffer fills up
		#we also want to rollback the previous transaction...
		else
		{
			print "Didn't get correct acknowledgment: $ack...rolling back transaction\n" if $DEBUG == 1;

		}
	}
	#if we don't get the ack then close the socket so that we don't keep writing to it until the socket buffer fills up
	#we also want to rollback the previous transaction...
	else
	{
		print "Didn't get acknowledgment: $ack...closing the socket $server_con\n" if $DEBUG == 1;
		print "num handles is $#handles\n" if $DEBUG == 1;

		$receiveq_handle->remove($server_con);
		close $server_con;
		shutdown $server_con,2;
		undef $server_con;


	}

	return -1;
}

sub send_file_to_server
{
	my $r_socket = shift;

	#find out if there are any files in the report dir on the local drive that
	#have data that needs sending over to the receive queue. 
	opendir DIR, "$REPORT_DIR" or die log_error("$sendq: could not open dir $REPORT_DIR $!");
	my @files = grep !/^\./, readdir DIR;
	closedir DIR;
					
	if($#files < 0)
	{
		#clear out any files in the temp dir if they exist.  This would be very rare...
		opendir DIR, "$TEMP" or die log_error("$sendq: could not open dir $TEMP $!");
		my @t_files = grep !/^\./, readdir DIR;
		closedir DIR;
		
		foreach my $file (@t_files)
		{
			unlink "$TEMP/$file";
		}
		return;
	}
	#if there is only one file left to send then sleep just in case the main thread is still
	#writing to this file.
        elsif($#files == 0)
	{
		#we sleep here (SOCKET_RECONNECT_INTERVAL) to avoid reading and deleteing the file
		#before the main thread has reconnected to the controller.  This would
		#happen only under very rare cicumstances but it could happen.
		my $sleep = $CONFIG{SERVER}{SOCKET_RECONNECT_INTERVAL} + 5;
		sleep $sleep;
	}
	
	my $file = $files[0];
        
	#Find out if there are any data files in existence. A temp file would only exists if the data server had crashed during a previous transmittal of a file.  In such
	#a case we would then have to determine what data had been previously sent and what data had not been sent and then
	#proceed to send over the data that was not previously sent over.
	opendir DIR, "$TEMP" or die log_error("$sendq: could not open dir $TEMP $!");
	my @temp_files = grep !/^\./, readdir DIR;
	closedir DIR;

	my $NUM_PREVIOUS_TRANSMIT = 0;#how many records were previously transmitted.
	if($#temp_files >= 0)#if true then we must determine if the file currently being transmitted matches one of the temp files
	{
		FILES: for my $i (0 .. $#temp_files)
		{
			#if the file is a match then count the number of entries that were previously transmitted
			if($file eq $temp_files[$i])
			{
				open TEMP_FILE, "$TEMP/$file";
				while(<TEMP_FILE>)
				{
					$NUM_PREVIOUS_TRANSMIT++;
				}
				close TEMP_FILE;

				last FILES;
				
			}
		}
	}



	my $ended_loop_early = 'FALSE';	
	my $line;
	my $check_data = 'TRUE';#we must check the first line of each file for possible duplication

	open DATA_FILE, "$REPORT_DIR/$file" or die log_error("$sendq: could not open $REPORT_DIR/$file $!");
	DATA: while(<DATA_FILE>)
	{
		$line++;
		my $trans = 1;

		#get rid of any transactions that were previously transmitted.
		next DATA if $line <=  $NUM_PREVIOUS_TRANSMIT;

		#get next record
		chomp $_;
		$_ .= "\n";#make sure there is a newline at the end of each line


		#create a copy that we can manipulate as we please
		my $new_record = $_;

		#add a record key to each record in the file if necessary 
		#as would be the case if we were transmitting a file that was manually
		#placed in the send folder.  We can not simply add a record key to the beginning
		#of the message because we will end up sending a duplicate record if the send queue
		#dies and is restarted during the sending of the file.
		if (!/^(\d){8}\s\d\d\:\d\d\:\d\d\.\d\d\d\d\d\d\s\w+\s\w+/)
		{
			open TMP, "> $TEMP/temp.txt" or die log_error("$sendq: could not open $TEMP/temp.txt $!");
			do
			{
				$new_record = $_;
				$new_record = join("\t",record_key(2),$new_record);
				print TMP $new_record;
			}while(<DATA_FILE>);
			close TMP;
			close DATA_FILE;

			#now we copy the temp file to the send folder with a different name
			#The different name is important and ensures that we don't step on our toes
			#if the system crashes during this whole process - otherwise we can't guarantee delivery.
			use File::Copy;
			move ("$TEMP/temp.txt", "$REPORT_DIR/$file") or die log_error("could not move file $TEMP/temp.txt $!");
			return;
		}

		#add the CHECK_FOR_DUPLICATE flag to the beginning of the line if this is the first line
		#being sent over because each first line could have already been written by the receive queue to file.
		if($check_data eq 'TRUE')
		{
			$new_record = "CHECK_FOR_DUPLICATE\t$new_record";
			$check_data = 'FALSE';
		}

	
		if(syswrite ($$r_socket, $new_record,length($new_record)))
		{
			print "TO SOCKET:  $new_record" if $DEBUG == 1;

			#get the acknowledgement
			if (get_ack() != 0)
			{
				$ended_loop_early = 'TRUE';
				last DATA;
			}
			else
			{
				if($trans == 1)#open the temp file on the first successful transmission
				{
					#open a temparary file in the c:/temp directory that has the same filename as the file being transmitted
					#so that we can print all the data that has been successfully transmitted.  That way if the data server
					#goes down during the file transmit we can then go back when the data server starts up again and then
					#only continue transmitting the data that was not previously sent
					open OUT, ">> $TEMP/$file" or die log_error("$sendq: could not open $TEMP/$file $!");
					OUT->autoflush(1);
					$trans++;
				}

				#keep track of data that has been transmitted in case the send queue goes down during the transmit
				print OUT $_;
			}
		}
		#we still keep printing to file in the event that the socket should go
		#down during the writing of this old data to the receive queue.  That
		#way when the socket is available we still have the old data
		else
		{
			shutdown $$r_socket,2;
			undef $$r_socket;

			#we have to exit the loop here
			#otherwise the next iteration will fail as a write to an
			#undefined socket takes place
			$ended_loop_early = 'TRUE';
			last DATA;
											
		}
	}
	close DATA_FILE;
	close OUT;

	#only unlink the file and the temp if all the data was transmitted successfully
	if($ended_loop_early eq 'FALSE')
	{
		unlink "$REPORT_DIR/$file" or die "could not unlink $REPORT_DIR/$file";
		unlink "$TEMP/$file" or die "could not unlink $TEMP/$file";
	}


}

#this subroutine takes care of the output to a temporary file if no socket connection is possible
sub print_to_file
{
	my $record = shift;
	chomp $record;
		
	if(-s $REPORT_FILE >= $CONFIG{DATA}{MAX_FILE_SIZE})
	{
		#set the report file for the day
		my ($sec,$min,$hours,$mday,$mon,$year) = localtime;
		$year -= 100 if($year >= 100);
		$mon += 1;
		$year = sprintf("%02d",$year);
		$mon = sprintf("%02d",$mon);
		$mday = sprintf("%02d",$mday);
		$hours = sprintf("%02d",$hours);
		$min = sprintf("%02d",$min);
		$sec = sprintf("%02d",$sec);

		$REPORT_FILE = "$REPORT_DIR/$year$mon$mday$hours$min$sec.txt";

	}

	open PRINT_TO_FILE, ">> $REPORT_FILE" or die log_error("$sendq: could not open file $REPORT_FILE $!");
	print PRINT_TO_FILE $record_time,"\t$record\n";
	close PRINT_TO_FILE;#close the previous file

	print "TO FILE:  $record\n"  if $DEBUG == 1;

}

sub record_key
{
	my $range = shift;

	#get the time that this record came in at
	my ($sec,$min,$hours,$mday,$mon,$year) = localtime;
	$year -= 100 if($year >= 100);
	$mon += 1;
	$year += 2000;
	$mon = sprintf("%02d",$mon);
	$mday = sprintf("%02d",$mday);
	$hours = sprintf("%02d",$hours);
	$min = sprintf("%02d",$min);
	$sec = sprintf("%02d",$sec);


	#add a flag to the end of the timing that will give the timing a greater uniqueness.
	my $key;
	if($range == 1)
	{
		$micro++;
		$micro = 0 if $micro > 499;
		$micro = sprintf("%06d",$micro);
		$key = "$year$mon$mday $hours:$min:$sec.$micro $sendq $CONFIG{QUEUE}{QUEUE} ";
	}
	else
	{
		$f_micro++;
		$f_micro = 500 if (($f_micro < 500) || ($f_micro > 999));
		$f_micro = sprintf("%06d",$f_micro);
		$key = "$year$mon$mday $hours:$min:$sec.$f_micro $sendq $CONFIG{QUEUE}{QUEUE} ";
	}
	return $key;

}

1;
