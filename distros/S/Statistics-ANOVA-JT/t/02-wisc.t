use strict;
use warnings;
use Test::More tests => 9;
use constant EPS => 1e-2;

BEGIN { use_ok('Statistics::ANOVA::JT') };

my $aov = Statistics::ANOVA::JT->new();

# Example from mcardle.wisc.edu:

my @g1 = (16, 8, 6);
my @g2 = (27, 16, 15);
my @g3 = (31, 29, 18, 42);

eval {$aov->load_data({1 => \@g1, 2 => \@g2, 3 => \@g3});};
ok(!$@, $@);

my %ref_vals = (
	j_value => 30.5,
   j_exp => 16.5,
   j_var => 27.25,
    z_value => 2.69,
);

my $val;

eval {$val = $aov->observed();};
ok(!$@, $@);
ok( about_equal($val, $ref_vals{'j_value'}), "observed value: $val != $ref_vals{'j_value'}" );

eval {$val = $aov->expected();};
ok(!$@, $@);
ok( about_equal($val, $ref_vals{'j_exp'}), "expected value: $val != $ref_vals{'j_exp'}" );

eval {$val = $aov->variance(correct_ties => 0);};
ok(!$@, $@);
ok( about_equal($val, $ref_vals{'j_var'}), "variance value: $val != $ref_vals{'j_var'}" );

my ($z, $p) = $aov->zprob_test(correct_ties => 0, tails => 1);
ok( about_equal($z, $ref_vals{'z_value'}), "probtest z-value: $z != $ref_vals{'z_value'}" );

sub about_equal {
    return 0 if ! defined $_[0] || ! defined $_[1];
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}
1;