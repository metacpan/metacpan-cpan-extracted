
use POE;
use POE::Component::Logger;
use POE::Component::MessageQueue;
use POE::Component::MessageQueue::Storage::Default;
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

my $DATA_DIR = '/tmp/perl_mq';

my $port     = 61613;
my $hostname = undef;
my $timeout  = 4;
my $throttle_max = 2;

GetOptions(
	"port|p=i"     => \$port,
	"hostname|h=s" => \$hostname,
	"timeout|i=i"  => \$timeout,
	"throttle|T=i" => \$throttle_max,
);

# we create a logger, because a production message queue would
# really need one.
#POE::Component::Logger->spawn(
#	ConfigFile => 'log.conf',
#	Alias      => 'mq_logger'
#);

POE::Component::MessageQueue->new({
	port     => $port,
	hostname => $hostname,

	# configure to use a logger
	#logger_alias => 'mq_logger',

	storage => POE::Component::MessageQueue::Storage::Default->new({
		data_dir     => $DATA_DIR,
		timeout      => $timeout,
		throttle_max => $throttle_max
	})
});

POE::Kernel->run();
exit;

