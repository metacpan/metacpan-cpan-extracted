use Test::More tests => 6;
use constant EPS     => 1e-3;

use Statistics::ANOVA::KW;
my $kw = Statistics::ANOVA::KW->new();

my ($h_value, $f_value, $p_value, %data, %ref_vals) = ();

# 2-level test based on Siegal p.122 data for Mann-Whitney test:
%data = (
    1 => [13, 12, 12, 10, 10, 10, 10, 9, 8, 8, 7, 7, 7, 7, 7, 6],
    2 => [17, 16, 15, 15, 15, 14, 14, 14, 13, 13, 13, 12, 12, 12, 12, 11, 11, 10, 10, 10, 8, 8, 6]
);

%ref_vals = ( # from SPSS for Kruskall-Wallis test:
    h_value => 11.90908806814377,
    p_value => 0.00005586074028901287,
    mean_rank_1 => 12.500,
    mean_rank_2 => 25.217391304347824,
);

eval { $kw->load( \%data ); };
ok( !$@, $@ );

eval { $h_value = $kw->h_value(correct_ties => 0); };
ok( !$@, $@ );
ok( about_equal($h_value, $ref_vals{'h_value'}), "Kruskall-Wallis:h_value: $h_value != $ref_vals{'h_value'}" );

eval { $p_value = $kw->chiprob_test(correct_ties => 0); };
ok( !$@, $@ );
ok( about_equal($p_value, $ref_vals{'p_value'}), "Kruskall-Wallis:p_value by h: $p_value != $ref_vals{'p_value'}" );

# show that KW is same as square of Mann-Whitney stat for 2 levels:
my $mann_whitney_z = -3.450954660401057; # from SPSS, not 3.43 from Siegal
my $mann_whitney_chi = $mann_whitney_z**2;
ok( about_equal($h_value, $mann_whitney_chi), "Kruskall-Wallis:h_value by MW-z: $h_value != $mann_whitney_chi" );

sub about_equal {
    return 0 if ! defined $_[0] || ! defined $_[1];
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}
1;
