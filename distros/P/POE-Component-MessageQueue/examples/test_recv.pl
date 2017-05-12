
use Net::Stomp;
use Getopt::Long;
use strict;

my $MAX_THREADS  = 100;
my $MONKEY_COUNT = 10000;
my $USERNAME     = 'system';
my $PASSWORD     = 'manager';

my $port     = 61613;
my $hostname = "localhost";
my $ack_type = "client";

GetOptions(
	"port|p=i"     => \$port,
	"hostname|h=s" => \$hostname,
	"ack-type=s"   => \$ack_type
);

my $stomp = Net::Stomp->new({
	hostname => $hostname,
	port     => $port
});
$stomp->connect({ login => $USERNAME, passcode => $PASSWORD });
$stomp->subscribe({
	'destination'           => '/queue/monkey_bin',
	'ack'                   => $ack_type,
	'activemq.prefetchSize' => 1 
});
while (1)
{
	my $frame = $stomp->receive_frame;
	print $frame->body . "\n";
	if ( $ack_type eq 'client' )
	{
		$stomp->ack({ frame => $frame });
	}
}
$stomp->disconnect();

