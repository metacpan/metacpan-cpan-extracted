use strict;
use warnings;
use Test::More tests => 26;
use constant EPS => 1e-2;

BEGIN { use_ok('Statistics::Zed') };

my $zed = Statistics::Zed->new(tails => 2,);
my $val;

# Cache data by add() only - by-passing load():
eval {$zed->add(observed => [6, 6], expected => [2.5, 2.5], variance => [8, 8]);};
ok(!$@, 'Failed to add data');

# successfully loaded all three arrays by add()?
$val = $zed->ndata();
ok( $val == 3, 'Failed to access updated data for observed count');

# check the actual values were succesfully loaded by add():
$val = $zed->access(label => 'observed');
ok( ($val->[0] + $val->[1]) == 12, 'Failed to access updated data for observed count');

$val = $zed->access(label => 'expected');
ok( ($val->[0] + $val->[1]) == 5, 'Failed to access updated data for expected count');

$val = $zed->access(label => 'variance');
ok( ($val->[0] + $val->[1]) == 16, 'Failed to access updated data for variance count');

# Initialise data by load()
$zed->unload();
eval {$zed->load(observed => [6], expected => [2.5], variance => [8]);};
ok(!$@, 'Failed to load data');

# successfully loaded all three arrays by load()?
$val = $zed->ndata();
ok( $val == 3, 'Failed to access updated data for observed count');

$val = $zed->access(label => 'observed');
ok($val->[0] == 6, 'Failed to access data');

# Add on top of what was loaded:
eval {$zed->add(observed => [6], expected => [2.5], variance => [8]);};
ok(!$@, 'Failed to update data');

$val = $zed->access(label => 'observed');
ok( ($val->[0] + $val->[1]) == 12, 'Failed to access updated data for observed count');

$val = $zed->access(label => 'expected');
ok( ($val->[0] + $val->[1]) == 5, 'Failed to access updated data for expected count');

$val = $zed->access(label => 'variance');
ok( ($val->[0] + $val->[1]) == 16, 'Failed to access updated data for variance count');

# Check these cached data produce the required stats:
my %ref = (
	z_value => 1.75,
    z_value_cc => 1.625,
    p_value => 0.080118,
	p_value_cc => 0.10416,
    obsdev  => (12 - 5 ),
    obsdev_cc  => (12 - 5.5),
    stdev   => sqrt(16),
);
my %res = ();

eval { ($res{'z_value'}, $res{'p_value'}, $res{'obsdev'}, $res{'stdev'}) = $zed->zscore();}; # should be default ccorr => 0
ok(!$@, $@);

foreach (qw/z_value p_value obsdev stdev/) {
    ok(defined $res{$_} );
    ok(equal($res{$_}, $ref{$_}), "Failed zscore() $_ return value with no cccorr by default:  $res{$_} != $ref{$_}");
}

# Check obsdev() method:
eval { $res{'obsdev'} = $zed->obsdev();};  # should be default ccorr => 0
ok(!$@, $@);
ok(equal($res{'obsdev'}, $ref{'obsdev'}), "Failed obsdev() with no ccorr by default:  $res{'obsdev'} != $ref{'obsdev'}");

# - now with continuity correction:
$res{'obsdev'} = $zed->obsdev(ccorr => 1);
ok(equal($res{'obsdev'}, $ref{'obsdev_cc'}), "Failed obsdev() with ccorr => 1:  $res{'obsdev'} != $ref{'obsdev_cc'}");

# - now specifying no continuity correction:
$res{'obsdev'} = $zed->obsdev(ccorr => 0);
ok(equal($res{'obsdev'}, $ref{'obsdev'}), "Failed obsdev() with ccorr => 0:  $res{'obsdev'} != $ref{'obsdev'}");

sub equal {
    return 0 if ! defined $_[0] || ! defined $_[1];
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}