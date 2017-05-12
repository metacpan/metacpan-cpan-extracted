#!/usr/bin/perl
use POE;
use POE::Component::Logger;
use POE::Component::MessageQueue;
use POE::Component::MessageQueue::Storage::Default;
use POE::Component::MessageQueue::Storage::Memory;
use POE::Component::MessageQueue::Storage::BigMemory;
use POE::Component::MessageQueue::Storage::DBI;
use POE::Component::MessageQueue::Storage::Throttled;
use Getopt::Long;
use Devel::StackTrace;
use IO::File;
use Carp;
use POSIX qw(setsid strftime);
use strict;

my $DATA_DIR = '/var/lib/perl_mq';
my $CONF_DIR = '/etc/perl_mq';
my $CONF_LOG = "$CONF_DIR/log.conf";

my $port     = 61613;
my $hostname = undef;
my $timeout  = 4;
my $granularity;
my $throttle_max = 2;
my $pump_frequency;
my $background = 0;
my $debug_shell = 0;
my $pidfile;
my $show_version = 0;
my $show_usage   = 0;
my $statistics   = 0;
my $uuids = 1;
my $stat_interval = 10;
my $front_store = 'memory';
my $front_max;
my $storage = 'default';
my $crash_cmd = undef;
my $dbi_dsn = undef;
my $dbi_username = undef;
my $dbi_password = undef;
my $mq_id = '';

GetOptions(
	"port|p=i"         => \$port,
	"hostname|h=s"     => \$hostname,
	"timeout|i=i"      => \$timeout,
	"granularity=i"    => \$granularity,
	"storage=s"        => \$storage,
	"front-store|f=s"  => \$front_store,
	"front-max=s"      => \$front_max,
	"throttle|T=i"     => \$throttle_max,
	"pump-freq|Q=i"    => \$pump_frequency,
	"data-dir=s"       => \$DATA_DIR,
	"log-conf=s"       => \$CONF_LOG,
	"stats!"           => \$statistics,
	"uuids!"           => \$uuids,
	"dbi-dsn=s"        => \$dbi_dsn,
	"dbi-username=s"   => \$dbi_username,
	"dbi-password=s"   => \$dbi_password,
	"mq-id=s"          => \$mq_id,
	"stats-interval=i" => \$stat_interval,
	"background|b"     => \$background,
	"debug-shell"      => \$debug_shell,
	"pidfile|p=s"      => \$pidfile,
	"crash-cmd=s"      => \$crash_cmd,
	"version|v"        => \$show_version,
	"help|h"           => \$show_usage,
) or usage(1);

# byte kilo mega giga tera peta exa zetta yotta
my @size_units = qw(b k m g t p e z y);
my $size_pattern = '((?:\d*\.)?\d+)(['.join('',@size_units).']?)$';
my $size_regex = qr/$size_pattern/i;
sub parse_size
{
	my $string = shift;
	if ($string =~ $size_regex)
	{
		my ($number, $unit) = ($1, lc($2));
		return $number unless $unit;
		for(my $i = 0; $i < @size_units; $i++)
		{
			if ($unit eq $size_units[$i])
			{
				return $number * (1024**$i);	
			}
		}
	}
	die "Unable to parse size: $string";
}

sub version
{
	print "POE::Component::MessageQueue version $POE::Component::MessageQueue::VERSION\n";
	print "Copyright 2007-2011 David Snopek (http://www.hackyourlife.org)\n";
	print "Copyright 2007, 2008 Paul Driver <frodwith\@gmail.com>\n";
	print "Copyright 2007 Daisuke Maki <daisuke\@endeworks.jp>\n";
}

sub usage
{
	my $exit_level = shift;
	my $X = ' ' x (length $0);
    print <<"ENDUSAGE";
$0 [--port|-p <num>]               [--hostname|-h <host>]
$X [--storage <str>]
$X [--front-store <str>]           [--front-max <size>] 
$X [--granularity <seconds>]       [--nouuids]
$X [--timeout|-i <seconds>]        [--throttle|-T <count>]
$X [--dbi-dsn <str>]               [--mq-id <str>]
$X [--dbi-username <str>]          [--dbi-password <str>]
$X [--pump-freq|-Q <seconds>]
$X [--data-dir <path_to_dir>]      [--log-conf <path_to_file>]
$X [--stats-interval|-i <seconds>] [--stats]
$X [--pidfile|-p <path_to_file>]   [--background|-b]
$X [--crash-cmd <path_to_script>]
$X [--debug-shell] [--version|-v]  [--help|-h]

SERVER OPTIONS:
  --port     -p <num>     The port number to listen on (Default: 61613)
  --hostname -h <host>    The hostname of the interface to listen on 
                          (Default: localhost)

STORAGE OPTIONS:
  --storage <str>         Specify which overall storage engine to use.  This
                          affects what other options are value.  (can be
                          default or dbi)
  --front-store -f <str>  Specify which in-memory storage engine to use for
                          the front-store (can be memory or bigmemory).
  --front-max <size>      How much message body the front-store should cache.
                          This size is specified in "human-readable" format
                          as per the -h option of ls, du, etc. (ex. 2.5M)
  --timeout -i <secs>     The number of seconds to keep messages in the 
                          front-store (Default: 4)
  --pump-freq -Q <secs>   How often (in seconds) to automatically pump each
                          queue.  Set to zero to disable this timer entirely
                          (Default: 0)
  --granularity <secs>    How often (in seconds) Complex should check for
                          messages that have passed the timeout.  
  --[no]uuids             Use (or do not use) UUIDs instead of incrementing
                          integers for message IDs.  (Default: uuids)
  --throttle -T <count>   The number of messages that can be stored at once 
                          before throttling (Default: 2)
  --data-dir <path>       The path to the directory to store data 
                          (Default: /var/lib/perl_mq)
  --log-conf <path>       The path to the log configuration file 
                          (Default: /etc/perl_mq/log.conf)

  --dbi-dsn <str>         The database DSN when using --storage dbi
  --dbi-username <str>    The database username when using --storage dbi
  --dbi-password <str>    The database password when using --storage dbi
  --mq-id <str>           A string uniquely identifying this MQ when more
                          than one MQ use the DBI database for storage

STATISTICS OPTIONS:
  --stats                 If specified the, statistics information will be 
                          written to \$DATA_DIR/stats.yml
  --stats-interval <secs> Specifies the number of seconds to wait before 
                          dumping statistics (Default: 10)

DAEMON OPTIONS:
  --background -b         If specified the script will daemonize and run in the
                          background
  --pidfile    -p <path>  The path to a file to store the PID of the process

  --crash-cmd  <path>     The path to a script to call when crashing.
                          A stacktrace will be printed to the script's STDIN.
                          (ex. 'mail root\@localhost')

OTHER OPTIONS:
  --debug-shell           Run with POE::Component::DebugShell
  --version    -v         Show the current version.
  --help       -h         Show this usage message

ENDUSAGE
	
	exit($exit_level) if (defined $exit_level);
}

if ( $show_version )
{
	version;
	exit 0;
}

if ( $show_usage )
{
	version;
	print "\n";
	usage(0);
}

if ( not -d $DATA_DIR )
{
	mkdir $DATA_DIR;

	if ( not -d $DATA_DIR )
	{
		die "Unable to create the data dir: $DATA_DIR";
	}
}

if ( $background )
{   
	# the simplest daemonize, ever.
	defined(fork() && exit 0) or "Can't fork: $!";
	setsid or die "Can't start a new session: $!";
	open STDIN,  '/dev/null' or die "Can't redirect STDIN from /dev/null: $!";
	open STDOUT, '>/dev/null' or die "Can't redirect STDOUT to /dev/null: $!";
	open STDERR, '>/dev/null' or die "Can't redirect STDERR to /dev/null: $!";
}

if ( $pidfile )
{
	my $fd = IO::File->new(">$pidfile")
		|| die "Unable to open pidfile: $pidfile: $!";
	$fd->write("$$");
	$fd->close();
}

my $logger_alias;
if ( -e $CONF_LOG )
{
	$logger_alias = 'mq_logger';

	# we create a logger, because a production message queue would
	# really need one.
	POE::Component::Logger->spawn(
		ConfigFile => $CONF_LOG,
		Alias      => $logger_alias
	);
}
else
{
	print STDERR "LOGGER: Unable to find configuration: $CONF_LOG\n";
	print STDERR "LOGGER: Will send all messages to STDERR\n";
}

if ($storage eq 'default') {
	if ($front_store eq 'memory') 
	{
		$front_store = POE::Component::MessageQueue::Storage::Memory->new();
	}
	elsif ($front_store eq 'bigmemory')
	{
		$front_store = POE::Component::MessageQueue::Storage::BigMemory->new();
	}
	else
	{
		die "Unknown front-store specified: $front_store";
	}

	$storage = POE::Component::MessageQueue::Storage::Default->new(
		data_dir     => $DATA_DIR,
		timeout      => $timeout,
		throttle_max => $throttle_max,
		front        => $front_store,
		front_max    => $front_max ? parse_size($front_max) : undef,
		granularity  => $granularity,
	);
}
else {
	if ($storage eq 'dbi')
	{
		$storage = POE::Component::MessageQueue::Storage::DBI->new(
			dsn      => $dbi_dsn,
			username => $dbi_username,
			password => $dbi_password,
			mq_id    => $mq_id,
		);
	}
	else
	{
		die "Unknown storage specified: $storage";
	}

	if ($throttle_max > 0) {
		$storage = POE::Component::MessageQueue::Storage::Throttled->new(
			back         => $storage,
			throttle_max => $throttle_max
		);
	}
}

my $idgen;
if ($uuids) 
{
	use POE::Component::MessageQueue::IDGenerator::UUID;
	$idgen = POE::Component::MessageQueue::IDGenerator::UUID->new();
}
else
{
	use POE::Component::MessageQueue::IDGenerator::SimpleInt;
	$idgen = POE::Component::MessageQueue::IDGenerator::SimpleInt->new(
		filename => "$DATA_DIR/last_id.mq",
	);
}

my %args = (
	port     => $port,
	hostname => $hostname,

	storage => $storage,

	pump_frequency => $pump_frequency,
	idgen => $idgen,
	logger_alias => $logger_alias,
);

if ($statistics) {
	require POE::Component::MessageQueue::Statistics;
	require POE::Component::MessageQueue::Statistics::Publish::YAML;
	my $stat = POE::Component::MessageQueue::Statistics->new();
	my $publish = POE::Component::MessageQueue::Statistics::Publish::YAML->spawn(
		statistics => $stat,
		output => "$DATA_DIR/stats.yml",
		interval => $stat_interval,
	);
	$args{observers} = [ $stat ];
}
my $mq = POE::Component::MessageQueue->new(%args);

# install the debug shell if requested
if ( $debug_shell )
{
	require POE::Component::DebugShell;
	POE::Component::DebugShell->spawn();
}

# install a die handler so we can catch crashes and log them
$SIG{__DIE__} = sub {
	my $trace = Devel::StackTrace->new()->as_string();
	my $banner = sprintf("\n%s\n", '=' x 30);
	my $diemsg = sprintf("$banner MQ Crashed: %s $banner\n$trace", 
		strftime('%Y-%m-%d %H:%M:%S', localtime(time())));

	# Print it first, cause don't know if the other stuff is gonna work.
	print STDERR $diemsg;

	# This will probably work, but we should say so if it doesn't.
	my $fn = "$DATA_DIR/crashed.log";
	if(open DIEFILE, ">>", $fn)
	{
		print DIEFILE $diemsg;
		close DIEFILE;	
	}
	else
	{
		print STDERR "Couldn't open crashlog '$fn': $!\n";
	}

	# Only bother if one was specified.
	if ($crash_cmd)
	{
		if (open DIEPIPE, '|-', $crash_cmd)
		{
			print DIEPIPE $diemsg;
			close DIEPIPE;	
		}
		else
		{
			print STDERR "Couldn't send crashlog to $crash_cmd: $!\n";
		}
	}
};

POE::Kernel->run();
exit;

