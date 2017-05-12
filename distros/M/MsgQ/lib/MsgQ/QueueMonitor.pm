package MsgQ::QueueMonitor;


require 5.6.1;
use strict;
use warnings;
use IO::Socket;

use vars qw($VERSION $DEBUG $con %CONFIG %STATUS);

$VERSION = '1.01';

$DEBUG=0;#set the debug on or off 0 is off and 1 is on;


sub new 
{
        my ($class) = @_;

	my $mover = 
	{
		"DEBUG" => 0, #0 is off , 1 is on
		"CONFIG_FILE" => './QueueMonitor.conf', #0 is off , 1 is on
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

sub get_status
{

my $mover = shift;
my $config_file = shift;


#parse the configuration file
$config_file = $mover->config_file() if !$config_file;
parse_config_file($config_file);

#save the config file path for later use if necessary.				
$mover->config_file($config_file) if $config_file;

foreach my $queue (keys %CONFIG)
{
	my $host = $CONFIG{$queue}{SEND_QUEUE_HOST};
	my $port = $CONFIG{$queue}{SEND_QUEUE_PORT};

	open_socket(\$con,$host,$port);		
	if ($con)
	{
		if ((exists $CONFIG{$queue}{SEND_QUEUE_REC_SEP})  && (exists $CONFIG{$queue}{SEND_QUEUE_LENGTH}))
		{
			print "Both record separator and message length are defined\n";
			exit;
		}
		elsif (exists $CONFIG{$queue}{SEND_QUEUE_REC_SEP})
		{
			print $con "STATUS\n" ;
		}
		elsif(exists $CONFIG{$queue}{SEND_QUEUE_LENGTH})
		{
			my $mess;
			for (2 .. $CONFIG{$queue}{SEND_QUEUE_LENGTH})
			{
				$mess .= "\0";
			}
			$mess .= pack "c", length("STATUS");
			$mess .= "STATUS";
			print $con $mess;
		}
		else
		{
			print "No record separator or message length defined\n";
			exit;
		}

		my $status = <$con>;
		($STATUS{$queue}{FILES},$STATUS{$queue}{SENT_TODAY},$STATUS{$queue}{SENT_LAST_HOUR},$STATUS{$queue}{CONNECTS}) = split(/\|/,$status);
		close $con;
		undef $con;
	}
	else
	{
		$STATUS{$queue} = undef;
	}

}

return %STATUS;


}

# This sub will parse the config.txt file and place the values in a hash.
sub parse_config_file()
{
	my $config_file = shift;
	undef %CONFIG; #reset the hash
	my $section;

	# Parse the config.txt file and get the parameter values
	open (FILE_, "$config_file") || die ("could not open file $config_file $!");
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

 
sub open_socket
{
		my $r_socket = shift;
		my $host = shift;
		my $port = shift;

		my $ping = `ping -n 1 -w 100 $host`;
		if($ping !~ /request\s+timed\s+out/i)
		{
	
			$$r_socket = new IO::Socket::INET (  
				   PeerAddr => $host,
				   PeerPort => $port,
	  			   Proto    => 'tcp',
				   Type     => SOCK_STREAM,
				   Timeout  => 5
		
	   	     			);
			if($$r_socket)
			{
				print "Opened a new Server Connection: $$r_socket\n" if $DEBUG == 1;
				$$r_socket->autoflush(1);
			

			}
		}

		

	
}

1;
