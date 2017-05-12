use strict;
use warnings;
use Test::More tests => 8;
use constant EPS     => 1e-2;

BEGIN { use_ok('Statistics::ANOVA') }

my $aov = Statistics::ANOVA->new();
isa_ok( $aov, 'Statistics::ANOVA' );

# Example 1: Maxwell & Delaney (1990), pp. 555ff.
my @y1 = ( 2, 4, 6, 8, 10, 3, 6, 9 );
my @y2 = ( 3, 7, 8, 9, 13, 4, 9, 11 );
my @y3 = ( 5, 9, 8, 8, 15, 9, 8, 10 );

eval { $aov->load_data( { y1 => \@y1, y2 => \@y2, y3 => \@y3 } ); };
ok( !$@, $@ );

my %ref_vals = (    # PASW output
    ms_w => 1.667,
    t_12 => -6.110,
    t_23 => -1.323,
);

eval { $aov->anova( independent => 0, parametric => 1 ); };
ok( !$@, $@ );

ok(
    about_equal( $aov->{'_stat'}->{'ms_w'}, $ref_vals{'ms_w'} ),
    "F-test pair comparison: $aov->{'_stat'}->{'ms_w'} = $ref_vals{'ms_w'}"
);

my $pair_dat;
eval {
    $pair_dat = $aov->compare(
        independent => 0,
        parametric  => 1,
        ordinal     => 0,
        adjust_p    => 0,
        adjust_e    => 2,
        use_t       => 0
    );
};
ok( !$@, $@ );

ok(
    about_equal( $pair_dat->{"y1,y2"}->{'t_value'}, $ref_vals{'t_12'} ),
"t-test pair comparison y1,y2: $pair_dat->{'y1,y2'}->{'t_value'} = $ref_vals{'t_12'}"
);

ok(
    about_equal( $pair_dat->{"y2,y3"}->{'t_value'}, $ref_vals{'t_23'} ),
"t-test pair comparison: y2,y3: $pair_dat->{'y2,y3'}->{'t_value'} = $ref_vals{'t_23'}"
);

sub about_equal {
    return 0 if !defined $_[0] || !defined $_[1];
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}
1;
