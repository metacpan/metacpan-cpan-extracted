use strict;
use warnings;
use OPCUA::Open62541 ':all';
use POSIX qw(sigaction SIGALRM);

use Test::More tests => 9;
use Test::NoWarnings;

my $s = OPCUA::Open62541::Server->new();
ok($s, "server");

my $c = $s->getConfig();
ok($s, "config");

my $d = $c->setDefault();
is($d, STATUSCODE_GOOD, "default");

# reset running after 1 second in signal handler
my $running = 1;
sub handler {
    $running = 0;
}
# Perl signal handler only works between perl statements.
# Use the real signal handler to interrupt the OPC UA server.
# This is not signal safe, best effort is good enough for a test.
my $sigact = POSIX::SigAction->new(\&handler);
ok($sigact, "sigact");
my $sa = sigaction(SIGALRM, $sigact);
ok($sa, "sigaction $!");
my $al = alarm(1);
ok(defined($al), "alarm $!");

# run server and stop after one second
my $r = $s->run($running);
is($r, STATUSCODE_GOOD, "run");
# server run should only return after the handler was called
is($running, 0, "running");

# the running variable should not be magical anymore
# unclear how to test that, but a simple store should work
$running = 2;
