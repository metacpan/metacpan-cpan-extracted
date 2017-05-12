use strict;
use warnings;
use Net::IMP::Remote::Server;
use Net::IMP::Remote::Connection;
use Net::IMP::Debug qw($DEBUG $DEBUG_RX debug);
use Net::IMP::Cascade;
use AnyEvent;
use IO::Socket::INET;
use IO::Socket::UNIX;
use Getopt::Long qw(:config posix_default bundling);

sub usage {
    print STDERR "ERROR: @_\n" if @_;
    print STDERR <<USAGE;

Server for IMP plugins.
Listens on given address(es) for access from data provider and filters given
traffic according to configured modules.

Usage: $0 [-M|--module plugin]+ [options] listen-addr(s)
Options:
  -h|--help             this usage
  -d|--debug [rx]       enable debugging (for package matching rx only)
  -M|--module mod=args  use IMP module
  -I|--impl type        type of serializer for RPC 
    
USAGE
    exit(1);
}


my $INETCLASS = 'IO::Socket::INET';
BEGIN {
    for(qw(IO::Socket::IP IO::Socket::INET6)) {
	eval "require $_" or next;
	$INETCLASS = $_;
	last;
    }
}

my (@debug_pkg,@mod,$impl);
GetOptions(
    'h|help'     => sub { usage() },
    'd|debug:s'  => sub {
	$DEBUG = 1;
	push @debug_pkg,$_[1] if $_[1];
    },
    'M|module=s' => \@mod,
    'I|impl=s'   => \$impl,
);
my @listen = @ARGV;

if (@debug_pkg) {
    # glob2rx
    s{(\*)|(\?)|([^*?]+)}{ $1 ? '.*': $2 ? '.': "\Q$3" }esg for (@debug_pkg);
    $DEBUG_RX = join('|',@debug_pkg);
}

@mod or usage('no IMP modules defined');
@listen or usage('no listen addresses defined');

my @factory;
for my $mod (@mod) {
    my ($class,$args) = $mod =~m{^([a-z][\w:]*)(?:=(.*))?$}i
	or die "invalid module $mod";
    eval "require $class" or die "cannot load $class: $@";
    my %args = defined $args ? $class->str2cfg($args) : ();
    if ( my @err = $class->validate_cfg(%args)) {
	die "wrong args for $class: @err";
    } 
    push @factory, $class->new_factory(%args);
}

my $factory = 
    @factory == 1 ? $factory[0] :
    Net::IMP::Cascade->new_factory( parts => \@factory );

my @lwatch;
my %rpc; # active connections
for my $addr (@listen) {
    my $srv;
    if ( $addr =~m{/} ) {
	unlink($addr);
	$srv = IO::Socket::UNIX->new(
	    Local => $addr,
	    Listen => 100,
	    Type => SOCK_STREAM,
	) or die "failed to listen on unix socket $addr: $!";
	debug("listen on unix $addr");
    } else {
	$srv = $INETCLASS->new(
	    LocalAddr => $addr,
	    Listen => 100,
	    Reuse => 1,
	) or die "failed to listen on inet socket $addr: $!";
	debug("listen on inet $addr");
    }

    push @lwatch, AnyEvent->io( fh => $srv, poll => 'r', cb => sub {
	my $cl = $srv->accept or return;
	debug("new connection");
	$cl->blocking(0);
	my $conn = Net::IMP::Remote::Connection->new($cl,1, 
	    impl => $impl, 
	    eventlib => my::Event->new 
	);
	my $key;
	$conn->onClose( sub { 
	    shift; # self
	    delete $rpc{$key};
	    warn("[$key] error: @_") if @_;
	});
	my $rpc = Net::IMP::Remote::Server->new($conn,$factory);
	$rpc{$key = "$rpc"} = $rpc;
    });
}
AnyEvent->condvar->recv;


	

package my::Event;
use Net::IMP::Debug;
sub new {  bless {},shift }
{
    my %watchr;
    sub onread {
	my ($self,$fh,$cb) = @_;
	defined( my $fn = fileno($fh)) or die "invalid filehandle";
	if ( $cb ) {
	    debug(( $watchr{$fn} ? "update":"add" )." read-watcher $fn");
	    $watchr{$fn} = AnyEvent->io( 
		fh => $fh, 
		cb => $cb, 
		poll => 'r' 
	    );
	} elsif ( $watchr{$fn} ) {
	    debug("remove read-watcher $fn");
	    undef $watchr{$fn};
	}
    }
}

{
    my %watchw;
    sub onwrite {
	my ($self,$fh,$cb) = @_;
	defined( my $fn = fileno($fh)) or die "invalid filehandle";
	if ( $cb ) {
	    debug(( $watchw{$fn} ? "update":"add" )." write-watcher $fn");
	    $watchw{$fn} = AnyEvent->io( 
		fh => $fh, 
		cb => $cb, 
		poll => 'w' 
	    );
	} elsif ( $watchw{$fn} ) {
	    debug("remove write-watcher $fn");
	    undef $watchw{$fn};
	}
    }
}

sub now { return AnyEvent->now }
sub timer {
    my ($self,$after,$cb,$interval) = @_;
    return AnyEvent->timer( 
	after => $after, 
	cb => $cb,
	$interval ? ( interval => $interval ):()
    );
}


