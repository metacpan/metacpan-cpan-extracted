use strict;
use warnings;
use Test::More tests => 15;
use constant EPS => 1e-5;

use Statistics::Zed 0.10;
my $zed = Statistics::Zed->new();
my $ret;

# Check that p_value() returns accurate values for variety of zscores & calling procs:

eval { $ret = $zed->p_value(value => 0, tails => 2);};
ok(!$@, $@);
ok(equal($ret, 1), "p_value  $ret != 1");

eval { $ret = $zed->p_value(value => 0, tails => 1);};
ok(!$@, $@);
ok(equal($ret, .5), "p_value  $ret != .5");

## tested vals are those returned by Statistics::Distributions uprob()

eval { $ret = $zed->p_value(value => 2.27688383542067, tails => 2);};
ok(!$@, $@);
ok(equal($ret, 0.022794), "p_value  $ret != 0.022794");

eval { $ret = $zed->p_value(value => 2.27688383542067, tails => 1);};
ok(!$@, $@);
ok(equal($ret, 0.011397), "p_value  $ret != 0.011397");

eval { $ret = $zed->p_value(value => -0.154432121011117, tails => 2);};
ok(!$@, $@);
ok(equal($ret, 0.87726), "p_value  $ret != 0.87726");

# direct calculation:
eval { $ret = $zed->p_value(observed => 12,
    expected => 5,
    variance => 16,
    precision_p => 5,
    ccorr => 1, tails => 2);};
ok(!$@, $@);
ok(equal($ret, 0.10416), "p_value  $ret != 0.10416");

# by pre-loading:
eval {$zed->add(observed => [12], expected => [5], variance => [16]);};
ok(!$@, 'Failed to load data');
eval { $ret = $zed->p_value(ccorr => 1, tails => 2);};
ok(!$@, $@);
ok(equal($ret, 0.10416), "p_value  $ret != 0.10416");

sub equal {
    return 0 if ! defined $_[0] || ! defined $_[1];
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}
1;