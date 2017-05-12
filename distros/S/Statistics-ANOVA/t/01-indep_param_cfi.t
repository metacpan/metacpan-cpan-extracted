use strict;
use warnings;
use Test::More tests => 10;
use constant EPS     => 1e-1;

BEGIN { use_ok('Statistics::ANOVA') }

my $aov = Statistics::ANOVA->new();
isa_ok( $aov, 'Statistics::ANOVA' );

# Masson & Loftus (2003) Table 1
my @incg = ( 784, 853, 622, 954, 634, 751, 918, 894 );
my @cong = ( 632, 702, 598, 873, 600, 729, 877, 801 );
my @neut = ( 651, 689, 606, 855, 595, 740, 893, 822 );

eval { $aov->load_data( { incg => \@incg, cong => \@cong, neut => \@neut } ); };
ok( !$@, $@ );

my %ref_vals_indep = (
    f_val => 1.00,
    ms_b  => 13991.8,
    ms_w  => 14054.7,
    itv   => 87.166
);

my %ref_vals_rmdep = (
    f_val => 13.08,
    ms_b  => 13991.8,
    ms_w  => 1069.4,
    itv   => 24.798
);

# as Between-Ss design:

eval { $aov->anova( independent => 1, parametric => 1 ); };
ok( !$@, $@ );

ok(
    about_equal( $aov->{'_stat'}->{'ms_w'}, $ref_vals_indep{'ms_w'} ),
    "F-test indep: $aov->{'_stat'}->{'ms_w'} = $ref_vals_indep{'ms_w'}"
);

my $itv;

eval {
    $itv = $aov->confidence( independent => 1, name => 'incg', limits => 0 );
};
ok( !$@, $@ );

ok( about_equal( $itv, $ref_vals_indep{'itv'} ),
    "95% confidence interval: $itv = $ref_vals_indep{'itv'}" );

# as Repeated measures:

eval { $aov->anova( independent => 0, parametric => 1 ); };
ok( !$@, $@ );

eval {
    $itv = $aov->confidence( independent => 0, name => 'incg', limits => 0 );
};
ok( !$@, $@ );

ok( about_equal( $itv, $ref_vals_rmdep{'itv'} ),
    "95% confidence interval: $itv = $ref_vals_rmdep{'itv'}" );

sub about_equal {
    return 0 if !defined $_[0] || !defined $_[1];
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}
1;
