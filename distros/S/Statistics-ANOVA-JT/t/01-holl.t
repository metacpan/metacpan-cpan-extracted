use strict;
use warnings;
use Test::More tests => 12;
use constant EPS => 1e-2;

BEGIN { use_ok('Statistics::ANOVA::JT') };

my $aov = Statistics::ANOVA::JT->new();

# Example from Hollander & Wolfe (1999) p. 205ff.

my @g1 = (40, 35, 38, 43, 44, 41);
my @g2 = (38, 40, 47, 44, 40, 42);
my @g3 = (48, 40, 45, 43, 46, 44);



my %ref_vals = (
	j_value => 79,
    j_exp => 54,
    j_var => 150.29,
    z_value => 2.04,
    p_value => 2*.0207,
);

my $val;

# test as unloaded:
eval {$val = $aov->expected(data => {1 => \@g1, 2 => \@g2, 3 => \@g3});};
ok(!$@, $@);
ok( about_equal($val, $ref_vals{'j_exp'}), "expected value: $val != $ref_vals{'j_exp'}" );

eval {$aov->load_data({1 => \@g1, 2 => \@g2, 3 => \@g3});};
ok(!$@, $@);

# test as loaded:
eval {$val = $aov->expected();};
ok(!$@, $@);
ok( about_equal($val, $ref_vals{'j_exp'}), "expected value: $val != $ref_vals{'j_exp'}" );

eval {$val = $aov->variance();};
ok(!$@, $@);
ok( about_equal($val, $ref_vals{'j_var'}), "variance value: $val != $ref_vals{'j_var'}" );

eval {$val = $aov->observed();};
ok(!$@, $@);
ok( about_equal($val, $ref_vals{'j_value'}), "observed value: $val != $ref_vals{'j_value'}" );

my ($z, $p) = $aov->zprob_test(data =>  {1 => \@g1, 2 => \@g2, 3 => \@g3});
ok( about_equal($z, $ref_vals{'z_value'}), "zprob_test z-value: $z != $ref_vals{'z_value'}" );
ok( about_equal($p, $ref_vals{'p_value'}), "zprob_test p-value: $z != $ref_vals{'p_value'}" );

sub about_equal {
    return 0 if ! defined $_[0] || ! defined $_[1];
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}
1;