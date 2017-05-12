use strict;
use warnings;
use Test::More tests => 4;
use constant EPS => 1e-2;

BEGIN {  };

use Statistics::Zed; 
my $zed = Statistics::Zed->new();
my $val;

$zed->load(observed => [6, 6], expected => [2.5, 2.5], variance => [8, 8]);

# Check these cached data produce the required stats:
my %ref = (
    p_value_2t => 0.080118,
    p_value_1t => 0.080118 * .5,
);
my %res = ();

# should use ccorr => 1 set in new() above:
($res{'z_value'}, $res{'p_value_2t'}, $res{'obsdev'}) = $zed->zscore();

# just want to check that tails is the default of 2:
ok(equal($res{'p_value_2t'}, $ref{p_value_2t}), "Failed zscore() p_value using default tails value of 2:  $res{'p_value_2t'} != $ref{p_value_2t}");

# specify tails => 1 - should take precedence over value set in new():
($res{'z_value'}, $res{'p_value_1t'}, $res{'obsdev'}, $res{'stdev'}) = $zed->zscore(tails => 1);
ok(equal($res{'p_value_1t'}, $ref{p_value_1t}), "Failed zscore() p_value using arg value of 1:  $res{'p_value_1t'} != $ref{p_value_1t}");

# read the current value - should return default of 2
$val = $zed->tails();
ok(equal($val, 2), "Failed tails() read of default value:  $val != 2");

# explicitly reset the default:
$zed->tails(value => 1);
$val = $zed->tails();
ok(equal($val, 1), "Failed tails() re-set of value:  $val != 1");

sub equal {
    return 0 if ! defined $_[0] || ! defined $_[1];
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}