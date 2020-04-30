use strict;
use warnings;
use OPCUA::Open62541 'STATUSCODE_GOOD';
use POSIX qw(sigaction SIGALRM);

use OPCUA::Open62541::Test::Server;
use Test::More tests => OPCUA::Open62541::Test::Server::planning_nofork() + 8;
use Test::LeakTrace;
use Test::NoWarnings;

my $server = OPCUA::Open62541::Test::Server->new();
$server->start();

# reset running after 1 second in signal handler
my $running = 1;
sub handler {
    $running = 0;
}
# Perl signal handler only works between perl statements.
# Use the real signal handler to interrupt the OPC UA server.
# This is not signal safe, best effort is good enough for a test.
ok(my $sigact = POSIX::SigAction->new(\&handler), "sigact");
ok(sigaction(SIGALRM, $sigact), "sigaction") or diag "sigaction failed: $!";
ok(defined(alarm(1)), "alarm") or diag "alarm failed: $!";

# run server and stop after one second
is($server->{server}->run($running), STATUSCODE_GOOD, "run");
# server run should only return after the handler was called
is($running, 0, "running");

ok($server->{log}->loggrep(qr/TCP network layer listening on /),
    "server loggrep listening");

no_leaks_ok { $server->{server}->run($running) } "run leak";

# the running variable should not be magical anymore
# unclear how to test that, but a simple store should work
$running = 2;
