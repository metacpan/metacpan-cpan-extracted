use strict;
use warnings;
use OPCUA::Open62541 ':all';

use Test::More tests => 4;
use Test::LeakTrace;

# preallocate integer variables for test result
my ($sok, $cok, $dok) = (0, 0, 0);
# show how memory for client and its config are expected to be allocated
no_leaks_ok {
    # keep global client config longer than the client
    my $cg;
    {
	# create client object
	my $s = OPCUA::Open62541::Client->new();
	$sok = 1 if $s;

	# the config object directly uses data from the client
	# creating a config increases the client reference count
	my $c = $s->getConfig();
	$cok = 1 if $c;
	# copy of the config has no effect on the UA data structues
	$cg = $c;
	# the client goes out of scope, but it is reference by the config
    }
    # both config and its client have valid memory
    my $d = $cg->setDefault();
    $dok = 1 if $d eq STATUSCODE_GOOD;
    # config goes out of scope, it derefeneces the client
    # the client is destroyed
    # the config is destroyed
} "leak client config default";
# Test::More inside Test::LeakTrace would create false positives
ok($sok, "client new");
ok($cok, "config get");
ok($dok, "default set");
