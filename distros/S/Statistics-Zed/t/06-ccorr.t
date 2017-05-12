use strict;
use warnings;
use Test::More tests => 14;
use constant EPS => 1e-2;

BEGIN {  };

use Statistics::Zed; 
my $zed = Statistics::Zed->new(tails => 2, ccorr => 1);
my $val;

$zed->load(observed => [6, 6], expected => [2.5, 2.5], variance => [8, 8]);

# Check these cached data produce the required stats:
my %ref = (
	z_value => 1.75,
    z_value_cc => 1.625,
    p_value => 0.080118,
	p_value_cc => 0.10416,
    obsdev  => (12 - 5 ),
    obsdev_cc  => (12 - 5.5),
);
my %res = ();

# that the default ccorr value of 0 set in new() has been tested in loaded_data.t

# should now use ccorr => 1 set in new() above:
($res{'z_value_cc'}, $res{'p_value_cc'}, $res{'obsdev_cc'}) = $zed->zscore();

foreach (qw/z_value_cc p_value_cc obsdev_cc/) {
    ok(defined $res{$_} );
    ok(equal($res{$_}, $ref{$_}), "Failed zscore() $_ return value cccorr => 1 set in new():  $res{$_} != $ref{$_}");
}

# specify ccorr => 0 - should take precedence over value set in new():
($res{'z_value'}, $res{'p_value'}, $res{'obsdev'}, $res{'stdev'}) = $zed->zscore(ccorr => 0);

foreach (qw/z_value p_value obsdev/) {
    ok(defined $res{$_} );
    ok(equal($res{$_}, $ref{$_}), "Failed zscore() $_ return value cccorr => 0 set in args:  $res{$_} != $ref{$_}");
}

# read the current value:
$val = $zed->ccorr();
ok(equal($val, 1), "Failed ccorr() read of value set in new():  $val != 1");

# explicitly reset the default:
$zed->ccorr(value => 0);
$val = $zed->ccorr();
ok(equal($val, 0), "Failed ccorr() re-set of value set in new():  $val != 0");

sub equal {
    return 0 if ! defined $_[0] || ! defined $_[1];
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}