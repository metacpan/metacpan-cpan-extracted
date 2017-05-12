use Test::More tests => 11;
use constant EPS     => 1e-3;

use Statistics::ANOVA::KW;
my $kw = Statistics::ANOVA::KW->new();

my ($h_value, $f_value, $p_value, %data, %ref_vals) = ();

# three-level test from Sarantakos (1993), pp. 402-403
%data = (
    1 => [ 13, 4, 8, 34, 31, 28, 16, 10 ],
    2 => [ 23, 11, 14, 30, 33, 19, 12, 21 ],
    3 => [ 26, 15, 17, 9, 24, 20, 18, 6],
);

%ref_vals = (
    h_value => 0.6350, # Sarantakos gives wrong value of .634
    f_value => 0.298, # unpublished
    p_by_f => 0.7453,
);

# pre-load data:
eval { $kw->load( \%data ); };
ok( !$@, $@ );

eval { $h_value = $kw->h_value(correct_ties => 1); };
ok( !$@, $@ );
ok( about_equal($h_value, $ref_vals{'h_value'}), "Kruskall-Wallis:h_value: $h_value != $ref_vals{'h_value'}" );
#diag("h = $h_value");

eval { ($f_value) = $kw->fprob_test(correct_ties => 1); };
ok( !$@, $@ );
ok( about_equal($f_value, $ref_vals{'f_value'}), "Kruskall-Wallis:f_value: $f_value != $ref_vals{'f_value'}" );

eval { $p_value = $kw->fprob_test(correct_ties => 1); };
ok( !$@, $@ );
ok( about_equal($p_value, $ref_vals{'p_by_f'}), "Kruskall-Wallis:p_value by f_value: $f_value != $ref_vals{'p_by_f'}" );

#my $str = $kw->chiprob_str(correct_ties => 1);
#diag("chi: $str");
#$str = $kw->fprob_str(correct_ties => 1);
#diag("f: $str");

# test levels 1 and 2 only:
%ref_vals = ( # SPSS values
    h_value => 0.3970588235294118,
);
eval { $h_value = $kw->h_value(lab => [1, 2], correct_ties => 1); };
ok( !$@, $@ );
ok( about_equal($h_value, $ref_vals{'h_value'}), "Kruskall-Wallis:h_value: $h_value != $ref_vals{'h_value'}" );
#diag("h = $h_value");

# test levels 2 and 3 only:
%ref_vals = ( # SPSS values
    h_value => 0.5404411764705883,
);
eval { $h_value = $kw->h_value(lab => [2, 3], correct_ties => 1); };
ok( !$@, $@ );
ok( about_equal($h_value, $ref_vals{'h_value'}), "Kruskall-Wallis:h_value: $h_value != $ref_vals{'h_value'}" );
#diag("h = $h_value");

sub about_equal {
    return 0 if ! defined $_[0] || ! defined $_[1];
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}
1;
