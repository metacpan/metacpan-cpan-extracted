use strict;
use warnings;
use OPCUA::Open62541 ':all';
use POSIX qw(sigaction SIGALRM);

use Net::EmptyPort qw(empty_port);
use Test::More tests => 12;
use Test::NoWarnings;
use Test::Warn;

my $s = OPCUA::Open62541::Server->new();
ok($s, "server");

my $sc = $s->getConfig();
ok($s, "config server");

my $port = empty_port();
my $r = $sc->setMinimal($port, "");
is($r, STATUSCODE_GOOD, "minimal server config");

my $c = OPCUA::Open62541::Client->new();
ok($c, "client");

my $cc = $c->getConfig();
ok($c, "config client");

$r = $cc->setDefault();
is($r, STATUSCODE_GOOD, "default client config");

my $pid = fork // die "Unable to fork: $!\n";

if ( !$pid ) {
    my $running = 1;
    sub handler {
	$running = 0;
    }

    # Perl signal handler only works between perl statements.
    # Use the real signal handler to interrupt the OPC UA server.
    # This is not signal safe, best effort is good enough for a test.
    my $sigact = POSIX::SigAction->new(\&handler)
	or die "could not create POSIX::SigAction";
    sigaction(SIGALRM, $sigact)
	or die "sigaction failed: $!";
    alarm(1)
	// die "alarm failed: $!";

    # run server and stop after one second
    $s->run($running);

    POSIX::_exit 0;
}

$r = $c->connect("opc.tcp://localhost:$port");
is($r, STATUSCODE_GOOD, "client connected");

is($c->getState, CLIENTSTATE_SESSION, "client state connected");

$r = $c->disconnect();
is($r, STATUSCODE_GOOD, "client disconnected");

is($c->getState, CLIENTSTATE_DISCONNECTED, "client state disconnected");

waitpid $pid, 0;

is($?, 0, "server finished");
