use strict;
use warnings;
use Test::More tests => 3;
use constant EPS => 1e-2;

BEGIN { use_ok('Statistics::ANOVA::JT') };

my $aov = Statistics::ANOVA::JT->new();

# Example from wikipedia article on JT that uses other method for calc:

my @g1 = (10, 12, 14, 16);
my @g2 = (12, 18, 20, 22);
my @g3 = (20, 25, 27, 30);

eval {$aov->load_data({1 => \@g1, 2 => \@g2, 3 => \@g3});};
ok(!$@, $@);

my %ref_vals = (
    z_value => 2.939,
);

my $val;

my ($z, $p) = $aov->zprob_test();
ok( about_equal($z, $ref_vals{'z_value'}), "probtest z-value: $z != $ref_vals{'z_value'}" );

sub about_equal {
    return 0 if ! defined $_[0] || ! defined $_[1];
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}
1;