use strict;
use warnings;
use Test::More tests => 5;

use Statistics::Zed 0.10;
my $zed = Statistics::Zed->new();
my $ret;

# Check that string() returns correctly:

# by direct data:
eval { $ret = $zed->string(observed => 12,
    expected => 5,
    variance => 16,
    precision_p => 5,
    ccorr => 1
);};
ok(!$@, $@);
ok(equal($ret, "Z = 1.625, 2p = 0.10416"), "string:  '$ret' != 'Z = 1.625, 2p = 0.10416'");

# by pre-loading:
eval {$zed->add(observed => [12], expected => [5], variance => [16]);};
ok(!$@, 'Failed to load data');
eval { $ret = $zed->string(ccorr => 1, tails => 2, precision_p => 5,);};
ok(!$@, $@);
ok(equal($ret, "Z = 1.625, 2p = 0.10416"), "string:  '$ret' != 'Z = 1.625, 2p = 0.10416'");

sub equal {
    return 0 if ! defined $_[0] || ! defined $_[1];
    return 1 if $_[0] eq $_[1];
    return 0;
}
1;