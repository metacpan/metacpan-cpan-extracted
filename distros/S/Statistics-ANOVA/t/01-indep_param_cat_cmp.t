use strict;
use warnings;
use Test::More tests => 11;
use constant EPS     => 1e-2;

BEGIN { use_ok('Statistics::ANOVA') }

my $aov = Statistics::ANOVA->new();
isa_ok( $aov, 'Statistics::ANOVA' );

# Example 1: Maxwell & Delaney (), pp. 134-5.
my @h1 = ( 84, 95, 93, 104 );
my @h2 = ( 81, 84, 92, 101, 80, 108 );
my @h3 = ( 98, 95, 86, 87, 94 );
my @h4 = ( 91, 78, 85, 80, 81 );

eval { $aov->load_data( { h1 => \@h1, h2 => \@h2, h3 => \@h3, h4 => \@h4 } ); };
ok( !$@, $@ );

my %ref_vals = (
    f_12       => .32,
    f_12_adj_e => .23,
    ms_w       => 67.375,
    t_12       => 0.448,
);

eval { $aov->anova( independent => 1, parametric => 1 ); };
ok( !$@, $@ );
ok(
    about_equal( $aov->{'_stat'}->{'ms_w'}, $ref_vals{'ms_w'} ),
"F-test pair comparison: h1,h2: $aov->{'_stat'}->{'ms_w'} = $ref_vals{'ms_w'}"
);

my $pair_dat;
eval {
    $pair_dat = $aov->compare(
        independent => 1,
        parametric  => 1,
        ordinal     => 0,
        adjust_p    => 0,
        adjust_e    => 2,
        use_t       => 0
    );
};
ok( !$@, $@ );

ok(
    about_equal( $pair_dat->{"h1,h2"}->{'t_value'}, $ref_vals{'f_12_adj_e'} ),
"F-test pair comparison (variance-adjusted denom.): g1,g2: $pair_dat->{'h1,h2'}->{'t_value'} = $ref_vals{'f_12_adj_e'}"
);

eval {
    $pair_dat = $aov->compare(
        independent => 1,
        parametric  => 1,
        ordinal     => 0,
        adjust_p    => 0,
        adjust_e    => 0,
        use_t       => 0
    );
};
ok( !$@, $@ );

ok(
    about_equal( $pair_dat->{"h1,h2"}->{'t_value'}, $ref_vals{'f_12'} ),
"F-test pair comparison (unadjusted denom.): g1,g2: $pair_dat->{'h1,h2'}->{'t_value'} = $ref_vals{'f_12'}"
);

# test the legacy offer of t-stat comparison:
eval {
    $pair_dat = $aov->compare(
        independent => 1,
        parametric  => 1,
        ordinal     => 0,
        use_t       => 1
    );
};
ok( !$@, $@ );

ok(
    about_equal( $pair_dat->{"h1,h2"}->{'t_value'}, $ref_vals{'t_12'} ),
"t-test pair comparison: h1,h2: $pair_dat->{'h1,h2'}->{'t_value'} = $ref_vals{'t_12'}"
);

sub about_equal {
    return 0 if !defined $_[0] || !defined $_[1];
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}
