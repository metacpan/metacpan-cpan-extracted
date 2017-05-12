use strict;
use warnings;
use Test::More tests => 5;
use constant EPS     => 1e-2;

use Statistics::ANOVA;
my $aov = Statistics::ANOVA->new();

# Example from http://www.itl.nist.gov/div898/handbook/prc/section4/prc433.htm#Example

my @g1 = ( 6.9, 5.4, 5.8, 4.6, 4.0 );
my @g2 = ( 8.3, 6.8, 7.8, 9.2, 6.5 );
my @g3 = ( 8.0, 10.5, 8.1, 6.9, 9.3 );

eval {
    $aov->load_data(
        {
            g1 => \@g1,
            g2 => \@g2,
            g3 => \@g3,
        }
    );
};

my %indep_nist = (
    ss_b => 27.897,
    ss_w => 17.452,
    ss_tot => 45.349, 
    ms_b => 18.949,
    ms_w => 1.454,
    f_value => 9.590,
);

#$aov->anova( independent => 1, parametric => 1, ordinal => 0 );

my ($ss_b, $ss_w, $ss_tot) = ();

$ss_b = $aov->ss_b(independent => 1, ordinal => 0);
ok(
    about_equal( $ss_b, $indep_nist{'ss_b'} ),
    "Independent measures ss_b wanted $ss_b != $indep_nist{'ss_b'}"
);
#diag("indep ss_b = $ss_b");

$ss_w = $aov->ss_w(independent => 1);
ok(
    about_equal( $ss_w, $indep_nist{'ss_w'} ),
    "Independent measures ss_w wanted $ss_w != $indep_nist{'ss_w'}"
);
#diag("indep ss_w = $ss_w");

$ss_tot = $aov->ss_total(independent => 1, ordinal => 0);
ok(
    about_equal( $ss_tot, $indep_nist{'ss_tot'} ),
    "Independent measures ss_tot wanted $ss_tot != $indep_nist{'ss_tot'}"
);
#diag("indep ss_tot = $ss_tot");

# Example from Maxwell & Delaney (1990), p. 89ff.
$aov->load_data(
        {
            g1 => [6, 5, 4, 7, 7, 5, 5, 7, 7, 7],
            g2 => [5, 4, 4, 3, 4, 3, 4, 4, 4, 5],
            g3 => [3, 3, 4, 4, 4, 3, 1, 2, 2, 4],
        }
    );

my %ref_vals = (
    ss_w => 26.00,
    ss_b => 46.67,
    df_w => 27,
    df_b => 2,
    f_value => 24.23,
);
#$aov->anova(independent => 1, parametric => 1, ordinal => 0);

$ss_b = $aov->ss_b(independent => 1, ordinal => 0);
ok(
    about_equal( $ss_b, $ref_vals{'ss_b'} ),
    "Independent measures ss_b wanted $ss_b != $ref_vals{'ss_b'}"
);
#diag("indep ss_b = $ss_b");

$ss_w = $aov->ss_w(independent => 1);
ok(
    about_equal( $ss_w, $ref_vals{'ss_w'} ),
    "Independent measures ss_w wanted $ss_w != $ref_vals{'ss_w'}"
);
#diag("fval = $aov->{'_stat'}->{'f_value'}");
#diag("df_w = $aov->{'_stat'}->{'df_w'}");

#my $df_w = $aov->{'_stat'}->{'df_w'};
#my $df_b = $aov->{'_stat'}->{'df_b'};
#diag("df b = $df_b, w = $df_w");

#my $f_mod = ($ss_b / $df_b) / ($ss_w / $df_w);
#diag("f_mod = $f_mod");

#require Statistics::ANOVA::EffectSize;
#my $es = Statistics::ANOVA::EffectSize->new();
#my $data = $aov->get_hoa_by_lab_numonly_indep();
#my $omg = $es->omega_sq_partial_by_ss(ss_b => $ss_b, ss_w => $ss_w, df_b => $df_b, df_w => $df_w );

#diag("omg = $omg");

    
sub about_equal {
    return 0 if !defined $_[0] || !defined $_[1];
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}
1;
