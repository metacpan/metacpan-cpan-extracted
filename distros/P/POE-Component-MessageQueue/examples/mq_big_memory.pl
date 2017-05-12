
use POE;
use POE::Component::MessageQueue;
use POE::Component::MessageQueue::Storage::BigMemory;
use POE::Component::MessageQueue::Logger;
use Getopt::Long;
use Carp;
use strict;

$SIG{__DIE__} = sub {
    Carp::confess(@_);
};

#use POE::Component::DebugShell;
#POE::Component::DebugShell->spawn();

# Force some logger output without using the real logger.
$POE::Component::MessageQueue::Logger::LEVEL = 0;

my $port     = 61613;
my $hostname = undef;

GetOptions(
	"port|p=i"     => \$port,
	"hostname|h=s" => \$hostname
);

POE::Component::MessageQueue->new({
	port     => $port,
	hostname => $hostname,

	storage => POE::Component::MessageQueue::Storage::BigMemory->new(),
	pump_frequency => 1
});

POE::Kernel->run();
exit;

