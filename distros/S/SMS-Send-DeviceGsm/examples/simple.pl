use strict;
use SMS::Send;
use Getopt::Long;

my $message;
my $number;
my $port;

GetOptions( "port=s" => \$port, "number=s" => \$number, "message=s" => \$message );

die "You must specify --port and --number\n" unless $number and $port;

unless ( $message ) {
  print "Type your message [use EOF to finish]: ";
  while (<STDIN>) {
	chomp;
	$message = join ' ', $message, $_;
  }
  die "No message specified\n" unless $message;
}

my $sender = SMS::Send->new( 'DeviceGsm', _port => $port );

$sender->send_sms( text => $message, to => $number );
