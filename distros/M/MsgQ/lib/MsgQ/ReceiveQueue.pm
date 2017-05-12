package MsgQ::ReceiveQueue;


require 5.6.1;
use IO::Socket;
use strict;
use warnings;

use vars qw($VERSION $sock $new_sock $DEBUG $record_time $REPORT_DIR $ERROR %CONFIG 
	    $handles $yesterdays_date_string $micro
	    $receiveq);

$VERSION = '1.01';

$DEBUG = 1; #to turn debugging on set $DEBUG = 1;

sub new 
{
        my ($class) = @_;

	my $collector = 
	{
		"DEBUG" => 0, #0 is off , 1 is on
		"CONFIG_FILE" => './ReceiveQueue.conf', #0 is off , 1 is on
	};

	bless $collector, $class;
	return $collector;
}

#################################################
#  Accessor Methods 
#################################################
sub debug
{
	my $collector = shift;
	my $debug = shift;		
	if($debug)
	{
		$collector->{'DEBUG'} = $debug;		
	}

	return $collector->{'DEBUG'};

}
sub config_file
{
	my $collector = shift;
	my $path = shift;		
	if($path)
	{
		$collector->{'CONFIG_FILE'} = $path;		
	}

	return $collector->{'CONFIG_FILE'};

}


#################################################
#  Member Functions 
#################################################

sub start_queue
{
my $collector = shift;
my $config_file = shift;


for(0 .. 40)
{
	print "\n";
}
print "Receive Queue is running...\n\n\n\n";
				
#parse the configuration file
$config_file = $collector->config_file() if !$config_file;
parse_config_file($config_file);

#set the report directory and create it if it doesn't exist
$REPORT_DIR = $CONFIG{DATA}{MESSAGE_FILES};


#this is where the errors are being logged
$ERROR = "$REPORT_DIR/ReceiveQueue_Error_Log.txt";

use File::Path;
$REPORT_DIR = "$REPORT_DIR/Message_Files";
if(!-d $REPORT_DIR)
{
	mkpath $REPORT_DIR;
}






#######################################################################################
#######################################################################################
#start the main server that will be writing all the data to file

#######################################################################################

use Sys::Hostname;
my $receiveq = hostname();
$sock = new IO::Socket::INET (  LocalHost => $receiveq,
				LocalPort => $CONFIG{SERVER}{RECEIVE_QUEUE_PORT},
				Proto 	  => 'tcp',
				Listen    => 5000, 
				Reuse     => 1
			     );

die "Socket could not get created. Reason: $!" unless $sock;

#add main socket to readables list
use IO::Select;
$handles = new IO::Select($sock);


while(1)
{


	
	
		#check the readable handles
		foreach my $filehandle ($handles->can_read(1))
		{
	
			if($filehandle == $sock)
			{
				$new_sock = $sock->accept();
				$handles->add($new_sock);
	
			}
			else
			{
	
	
				
				if($_ = <$filehandle>)
				{
	
					#only print to file if this is a complete record...the only instance where
					#we would not get a complete record is if the data mover dies and the remaining
					#data in the socket buffer gets read by the receive queue and there is no following newline.
					if(/\n/)
					{
						print_to_file($_);
				
						#send back the acknowledgment to the data server that the data was written to file.
						syswrite($filehandle,"ACK",3);
					}	
				
				}
				else
				{
					#remove the socket from the readables list if the other end has diconnected
					$handles->remove($filehandle);
				}
	
			}
		}




}


}#end start queue



# This sub will parse the config.txt file and place the values in a hash.
sub parse_config_file()
{
	my $config_file = shift;
	undef %CONFIG; #reset the hash
	my $section;

	# Parse the config.txt file and get the parameter values
	open (FILE_, "$config_file") || die log_error("could not open file $config_file $!");
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


}

sub log_error
{
	my $error = shift;

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
	$micro++;
	$micro = 0 if $micro > 999;
	$micro = sprintf("%06d",$micro);
	my $error_time = "$year$mon$mday $hours:$min:$sec.$micro $receiveq";

	open E , ">> $ERROR" or die "could not open error log $ERROR $!";
	print E "$error_time $receiveq\t$error\n";
	close E;
	
}


#this subroutine takes care of the output to a temporary file if no socket connection is possible
sub print_to_file
{
		my $record = shift;
		my $filename;

		#if the message is a error message then print to the error log and return
		if($record =~ /^#/)
		{
			log_error($record);
			return;
		}

		#set the report file
		$filename = get_filename($record);


		#if there is a flag which indicates that we must check for a duplicate value
		#then we must check whether the file already has this record in it and if so then do not write to file again
		if($record =~ /^CHECK_FOR_DUPLICATE/)
		{
			$record =~ s/CHECK_FOR_DUPLICATE\t//;	

			$filename = get_filename($record);
			my ($key) = split(/\t/,$record);


		#if the text file does not exist yet then we can assume that no duplication has been done and skip over this block.
		if(-e "$REPORT_DIR/$filename.txt")
		{
				open FILE, "$REPORT_DIR/$filename.txt" or log_error( "could not open file $REPORT_DIR/$filename.txt $!");
				while(<FILE>)
				{

					#if the unique key from the record matches a record already in the file then return and
					#do not print the record to file again.
					if(/$key/)
					{
						close FILE;
						return 0;
					}
				}
			
				close FILE;
			}
		}


		#generate a date string that will be in the same format as the date coming in from 
		#the dataservers.	
		my ($sec,$min,$hours,$mday,$mon,$year) = localtime;
		$year -= 100 if($year >= 100);
		$mon += 1;
		$year += 2000;
		$mon = sprintf("%02d",$mon);
		$mday = sprintf("%02d",$mday);

		my $todays_date_string;
		if($CONFIG{MESSAGE}{STORAGE} eq 'D')
		{
			$todays_date_string = "$year$mon$mday";
		}
		elsif($CONFIG{MESSAGE}{STORAGE} eq 'H')
		{
			$todays_date_string = "$year$mon$mday$hours";

		}
		elsif($CONFIG{MESSAGE}{STORAGE} eq 'MIN')
		{
			$todays_date_string = "$year$mon$mday$hours$min";
		}
		elsif($CONFIG{MESSAGE}{STORAGE} eq 'SEC')
		{
			$todays_date_string = "$year$mon$mday$hours$min$sec";
		}
		elsif($CONFIG{MESSAGE}{STORAGE} eq 'M')
		{
			$todays_date_string = "$year$mon";
		}
		elsif($CONFIG{MESSAGE}{STORAGE} eq 'U')
		{
			$todays_date_string = $filename;
		}
	
		#If the data coming in to the receive queue is for a previous day, which could happen
		#had the receive queue been turned off for a day and data was allowed
		#to collect on the data servers, then we want to make sure
		#we write the data to the correct file that contains a matching time stamp.
		if(($filename < $todays_date_string) && ($CONFIG{MESSAGE}{STORAGE} ne 'U'))
		{
			open OLD_FILE, ">> $REPORT_DIR/$filename.txt" or log_error( "could not open file $REPORT_DIR/$filename.txt $!");

			#print any records to file
			print $record if $DEBUG == 1;
			print OLD_FILE $record;
	
			close OLD_FILE;
	
		}
		else
		{
	
			#if the file is closed or if the date has changed then close the previous file and open a new one in append mode.
			if(($todays_date_string > $yesterdays_date_string) || ($CONFIG{MESSAGE}{STORAGE} eq 'U'))
			{
				close PRINT_TO_FILE;
				open PRINT_TO_FILE, ">> $REPORT_DIR/$todays_date_string.txt" or log_error( "could not open file $REPORT_DIR/$todays_date_string.txt $!");
				PRINT_TO_FILE->autoflush(1);


				$yesterdays_date_string = $todays_date_string;
			}	
		
			#print any records to file
			print PRINT_TO_FILE "$record";
			print "TO FILE:  $record"  if $DEBUG == 1;

		}





}
sub get_filename
{
		my $record = shift;
		my $filename;

		if($CONFIG{MESSAGE}{STORAGE} eq 'D')
		{
			$filename = substr($record,0,8);
		}
		elsif($CONFIG{MESSAGE}{STORAGE} eq 'H')
		{
			$filename = substr($record,0,11);
			print $filename,"\n";

		}
		elsif($CONFIG{MESSAGE}{STORAGE} eq 'MIN')
		{
			$filename = substr($record,0,14);
		}
		elsif($CONFIG{MESSAGE}{STORAGE} eq 'SEC')
		{
			$filename = substr($record,0,17);
		}
		elsif($CONFIG{MESSAGE}{STORAGE} eq 'M')
		{
			$filename = substr($record,0,6);
		}
		elsif($CONFIG{MESSAGE}{STORAGE} eq 'U')
		{
			($filename) = split("\t",$record);
		}
		$filename =~ s/(\s|\.|\:)//g;
			
		return $filename;

}

1;
