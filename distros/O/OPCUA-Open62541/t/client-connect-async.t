use strict;
use warnings;
use OPCUA::Open62541 ':all';
use POSIX qw(sigaction SIGALRM);

use Net::EmptyPort qw(empty_port);
use Scalar::Util qw(looks_like_number);
use Test::More tests => 27;
use Test::NoWarnings;
use Test::LeakTrace;

# initialize the server

my $s = OPCUA::Open62541::Server->new();
ok($s, "server");

my $sc = $s->getConfig();
ok($s, "config server");

my $port = empty_port();
my $r = $sc->setMinimal($port, "");
is($r, STATUSCODE_GOOD, "minimal server config");

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

my @testdesc = (
    ['client', 'client creation'],
    ['config', 'config creation'],
    ['config_default', 'set default config'],
    ['connect_async', 'call to connect_async'],
    ['iterate', 'calls to run_iterate'],
    ['state_session', 'client state SESSION after connect'],
    ['cb_client', 'client in callback'],
    ['cb_data', 'data in callback'],
    ['cb_after', 'callback called after connect'],
    ['cb_afterreq', 'reqID in callback called after connect'],
    ['cb_afterresp', 'response in callback called after connect'],
    ['disconnect', 'client disconnected'],
    ['state_disconnected', 'client state DISCONNECTED after disconnect'],
);
my %testok = map { $_ => 0 } map { $_->[0] } @testdesc;

no_leaks_ok {
    my $c;
    my $data = ['foo'];
    {
	$c = OPCUA::Open62541::Client->new();
	$testok{client} = 1 if $c;

	my $cc = $c->getConfig();
	$testok{config} = 1 if $cc;

	$r = $cc->setDefault();
	$testok{config_default} = 1 if $r == STATUSCODE_GOOD;

	$r = $c->connect_async(
	    "opc.tcp://localhost:$port",
	    sub {
		my ($c, $d, $i, $r) = @_;
		$testok{cb_client} = 1 if $c->getState == CLIENTSTATE_SESSION;
		$testok{cb_data} = 1 if $d->[0] eq 'foo';
		push(@$data, 'bar', $i, $r);
	    },
	    $data
	);
	$testok{connect_async} = 1 if $r == STATUSCODE_GOOD;

	my $maxloop = 1000;
	my $failed_iterate = 0;
	while($c->getState != CLIENTSTATE_SESSION && $maxloop-- > 0) {
	    $r = $c->run_iterate(0);
	    $failed_iterate = 1 if $r != STATUSCODE_GOOD;
	}
	$testok{iterate} = 1 if not $failed_iterate and $maxloop > 0;

	$testok{state_session} = 1 if $c->getState == CLIENTSTATE_SESSION;
	$testok{cb_after} = 1 if $data->[1] eq "bar";
	$testok{cb_afterreq} = 1 if looks_like_number $data->[2];
	$testok{cb_afterresp} = 1 if $data->[3] == STATUSCODE_GOOD;

	$r = $c->disconnect();
	$testok{disconnect} = 1 if $r == STATUSCODE_GOOD;
	$testok{state_disconnected} = 1
	    if $c->getState == CLIENTSTATE_DISCONNECTED;
    }
} "leak connect_async callback/data";

ok($testok{$_->[0]}, $_->[1]) for (@testdesc);

waitpid $pid, 0;

is($?, 0, "server finished");

my $c = OPCUA::Open62541::Client->new();
ok($c, "client new");

my $cc = $c->getConfig();
ok($cc, "client config");

$r = $cc->setDefault();
is($r, STATUSCODE_GOOD, "client config default");

eval { $c->connect_async("opc.tcp://localhost:$port", "", undef) };
ok($@, "callback not a reference");
like($@, qr/callback is not a CODE reference/, "callback not a reference error");

eval { $c->connect_async("opc.tcp://localhost:$port", [], undef) };
ok($@, "callback not a code reference");
like($@, qr/callback is not a CODE reference/,
    "callback not a code reference error");

# the connection itself gets established in run_iterate. so this call should
# also succeed if no server is running
$r = $c->connect_async("opc.tcp://localhost:$port", undef, undef);
is($r, STATUSCODE_GOOD, "connect_async no callback");
