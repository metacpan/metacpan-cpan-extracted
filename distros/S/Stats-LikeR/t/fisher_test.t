#!/usr/bin/perl
require 5.010;
use strict;
use warnings;
use Test::More;
use Test::LeakTrace 'no_leaks_ok';
use Stats::LikeR 'fisher_test';

# Stats::LikeR::fisher_test returns a hashref:
#   { p_value, estimate => { "odds ratio" => OR }, conf_int => [lo, hi],
#     alternative, method, conf_level }
#
# All expected values below were produced by R's stats::fisher.test().
# CI bounds match R to the precision R prints, because the XS solver replicates
# R's uniroot/zeroin (Brent-Dekker) with tol = .Machine$double.eps^0.25.


# Relative-tolerance compare that also handles 0 and +Inf.
sub close_to {
    my ($got, $exp, $name, $rel) = @_;
    $rel //= 1e-4;
    if ($exp == 9**9**9) {       # +Inf expected
        return ok($got == 9**9**9, $name);
    }
    if ($exp == 0) {
        return ok(abs($got) < 1e-9, $name);
    }
    my $err = abs($got - $exp) / abs($exp);
    ok($err < $rel, $name)
        or diag("got=$got expected=$exp rel_err=$err");
}

my $INF = 9**9**9;

# Case 1: matrix(c(3,1,1,3)) -> a=3 b=1 c=1 d=3  (the classic tea-tasting 2x2)
{
    my $r = fisher_test([[3,1],[1,3]]);
    close_to($r->{p_value},               0.4857143, 'C1 two.sided p-value');
    close_to($r->{estimate}{"odds ratio"},6.408309,  'C1 conditional MLE odds ratio');
    close_to($r->{conf_int}[0],           0.2117329, "C1 CI lower");
    close_to($r->{conf_int}[1],           621.9338,  "C1 CI upper", 1e-3);
}
{
    my $r = fisher_test([[3,1],[1,3]], alternative => "greater");
    close_to($r->{p_value},     0.2428571, "C1 greater p-value");
    close_to($r->{conf_int}[0], 0.3135693, "C1 greater CI lower");
    is($r->{conf_int}[1], $INF,            "C1 greater CI upper is Inf");
}

# Case 2: Convictions matrix(c(2,10,15,3),2) -> a=2 b=15 c=10 d=3
# Note: sample OR = (2*3)/(15*10) = 0.04, but R's conditional MLE = 0.0469.
{
    my $r = fisher_test([[2,15],[10,3]]);
    close_to($r->{p_value},                0.0005367241, "C2 two.sided p-value");
    close_to($r->{estimate}{"odds ratio"}, 0.04693661,   "C2 conditional MLE odds ratio");
    close_to($r->{conf_int}[0],            0.003325464,  "C2 CI lower", 1e-3);
    close_to($r->{conf_int}[1],            0.363182271,  "C2 CI upper", 1e-3);

    # Guard against regressing to the sample OR / Woolf interval.
    ok(abs($r->{estimate}{"odds ratio"} - 0.04) > 1e-3,
       "C2 odds ratio is the conditional MLE, NOT the sample OR (0.04)");
}
{
    my $r = fisher_test([[2,15],[10,3]], alternative => 'less');
    close_to($r->{p_value},     0.0004651809, 'C2 less p-value');
    is($r->{conf_int}[0], 0,                   'C2 less CI lower is 0');
    close_to($r->{conf_int}[1], 0.2849601,     'C2 less CI upper');
}

# Case 3: edge cases — boundary cells give OR 0 / Inf, not NaN.
{
    my $r = fisher_test([[0,5],[5,0]]);   # observed at lower boundary
    is($r->{estimate}{"odds ratio"}, 0, 'C3 zero corner => OR 0');
    is($r->{conf_int}[0], 0,            'C3 CI lower 0');
}
{
    my $r = fisher_test([[5,0],[0,5]]);   # observed at upper boundary
    is($r->{estimate}{"odds ratio"}, $INF, "C3 full corner => OR Inf");
    is($r->{conf_int}[1], $INF,            "C3 CI upper Inf");
}

# Case 4: hash input must give the same answer as the equivalent array.
# Keys are sorted lexically into rows/columns: r1<r2, and within a row c1<c2.
my $arr  = fisher_test([[3,1],[1,3]]);
my $hash = fisher_test({
  r1 => { c1 => 3, c2 => 1 },
  r2 => { c1 => 1, c2 => 3 },
});
close_to($hash->{p_value},               $arr->{p_value},               "C4 hash p-value matches array");
close_to($hash->{estimate}{"odds ratio"},$arr->{estimate}{"odds ratio"},"C4 hash OR matches array");
close_to($hash->{conf_int}[0],           $arr->{conf_int}[0],           "C4 hash CI lower matches array");
close_to($hash->{conf_int}[1],           $arr->{conf_int}[1],           "C4 hash CI upper matches array", 1e-3);

# Case 5: input validation should croak, not silently coerce to 0.
eval { fisher_test([[3,1],[1,-3]]) };          ok($@, "C5 negative cell croaks");
eval { fisher_test([[3,1,9],[1,3]]) };         ok($@, "C5 ragged rows croak");
eval { fisher_test([[3,1],[1,3]], alternative => "sideways") };
ok($@, "C5 bad alternative croaks");
eval { fisher_test([[3,1],[1,3]], conf_level => 1.5) };
ok($@, "C5 conf_level out of range croaks");

# ---------------------------------------------------------------------------
# R x C tables (added 2026-07-16). fisher_test now accepts any table >= 2x2.
# For non-2x2 the two-sided p-value is computed by exact enumeration over the
# fixed row/column margins; no odds ratio or CI is defined. Expected p-values
# come from R's stats::fisher.test().
# ---------------------------------------------------------------------------

# Case 6: p-values for assorted shapes match R to full precision.
close_to(fisher_test([[5,3,2],[1,4,6],[7,2,1]])->{p_value}, 0.05408923883,  "C6 3x3 p-value", 1e-6);
close_to(fisher_test([[1,9,11],[11,3,9]])->{p_value},       0.002505556763, "C6 2x3 p-value", 1e-6);
close_to(fisher_test([[8,2],[1,5],[3,3]])->{p_value},       0.05179186139,  "C6 3x2 p-value", 1e-6);
close_to(fisher_test([[2,0,1,3],[1,4,0,2],[0,1,5,1]])->{p_value}, 0.01611374522, "C6 3x4 p-value", 1e-6);
close_to(fisher_test([[0,5,3],[6,1,2],[2,4,0]])->{p_value},  0.01159739195,  "C6 3x3-with-zeros p-value", 1e-6);
# A uniform table is exactly the most likely outcome, so p == 1.
close_to(fisher_test([[10,10,10],[10,10,10],[10,10,10]])->{p_value}, 1, "C6 uniform 3x3 p-value == 1", 1e-9);

# Case 7: shape of the R x C result hash.
{
    my $r = fisher_test([[5,3,2],[1,4,6],[7,2,1]]);
    is($r->{method},      "Fisher's Exact Test for Count Data", "C7 method string");
    is($r->{alternative}, "two.sided",                          "C7 alternative is two.sided");
    is($r->{conf_level},  0.95,                                 "C7 default conf_level echoed");
    ok(!exists $r->{estimate}, "C7 no odds-ratio estimate for R x C");
    ok(!exists $r->{conf_int}, "C7 no confidence interval for R x C");
    # p is a valid probability
    ok($r->{p_value} > 0 && $r->{p_value} <= 1, "C7 p_value in (0,1]");
}

# Case 8: 'alternative' is ignored for R x C (only two-sided is defined), but a
# custom conf_level is still echoed back unchanged.
{
    my $base = fisher_test([[5,3,2],[1,4,6],[7,2,1]]);
    for my $alt (qw(greater less two.sided)) {
        my $r = fisher_test([[5,3,2],[1,4,6],[7,2,1]], alternative => $alt);
        is($r->{alternative}, "two.sided", "C8 alternative=>$alt forced to two.sided");
        close_to($r->{p_value}, $base->{p_value}, "C8 alternative=>$alt gives same p", 1e-9);
    }
    my $r = fisher_test([[5,3,2],[1,4,6],[7,2,1]], conf_level => 0.9);
    is($r->{conf_level}, 0.9, "C8 custom conf_level echoed for R x C");
}

# Case 9: hash-of-hashes R x C. Rows sort a<b<c, columns sort x<y<z, so an
# equivalent array must match regardless of insertion / hash-randomization order.
{
    my $arr  = fisher_test([[4,1,2],[0,3,5],[6,2,1]]);
    my $hash = fisher_test({
        b => { z => 5, x => 0, y => 3 },   # deliberately unsorted insertion order
        c => { y => 2, z => 1, x => 6 },
        a => { x => 4, z => 2, y => 1 },
    });
    close_to($hash->{p_value}, 0.03248463501, "C9 hash p-value matches R", 1e-6);
    close_to($hash->{p_value}, $arr->{p_value}, "C9 hash p-value matches equivalent array", 1e-9);
    ok(!exists $hash->{estimate}, "C9 hash R x C has no estimate");
}

# Case 10: R x C input validation.
eval { fisher_test([[1,2,3],[4,5]]) };          ok($@, "C10 ragged array rows croak");
eval { fisher_test([[1,2,3]]) };                ok($@, "C10 single row croaks");
eval { fisher_test([[1],[2]]) };                ok($@, "C10 single column croaks");
eval { fisher_test([[0,0,0],[0,0,0],[0,0,0]]) };ok($@, "C10 all-zeros R x C croaks");
eval { fisher_test([[1,2,-3],[4,5,6],[7,8,9]]) };ok($@, "C10 negative cell in R x C croaks");
# hash with a row exposing a different column key set
eval {
    fisher_test({
        a => { x => 1, y => 2, z => 3 },
        b => { x => 4, y => 5, w => 6 },   # 'w' instead of 'z'
        c => { x => 7, y => 8, z => 9 },
    });
};
ok($@, "C10 hash with mismatched column keys croaks");
# hash with an inner row of the wrong column count
eval {
    fisher_test({
        a => { x => 1, y => 2, z => 3 },
        b => { x => 4, y => 5 },           # only 2 columns
    });
};
ok($@, "C10 hash with inconsistent column count croaks");
# outer hash with fewer than 2 keys
eval { fisher_test({ a => { x => 1, y => 2 } }) };
ok($@, "C10 single-key outer hash croaks");

# Case 11: no SV leaks. Covers both the 2x2 exact path and the R x C
# enumeration path, for array and hash input. The croak paths are exercised
# too (inside eval), since those unwind after the XS has already done its own
# Newx allocations and must Safefree them before longjmp-ing out.
if ($INC{'Devel/Cover.pm'}) { done_testing(); exit 0 }
no_leaks_ok { fisher_test([[3,1],[1,3]]) }                    "C11 2x2 array no leak";
no_leaks_ok { fisher_test([[2,15],[10,3]], alternative => 'less') } "C11 2x2 array (less) no leak";
no_leaks_ok { fisher_test({ r1 => { c1 => 3, c2 => 1 },
                            r2 => { c1 => 1, c2 => 3 } }) }  "C11 2x2 hash no leak";
no_leaks_ok { fisher_test([[5,3,2],[1,4,6],[7,2,1]]) }       "C11 3x3 array no leak";
no_leaks_ok { fisher_test([[2,0,1,3],[1,4,0,2],[0,1,5,1]]) } "C11 3x4 array no leak";
no_leaks_ok { fisher_test({ a => { x => 4, 'y' => 1, z => 2 },
                            b => { x => 0, 'y' => 3, z => 5 },
                            c => { x => 6, 'y' => 2, z => 1 } }) } "C11 3x3 hash no leak";
no_leaks_ok { eval { fisher_test([[1,2,3],[4,5]]) } }        "C11 ragged-array croak no leak";
no_leaks_ok { eval { fisher_test([[1,2,-3],[4,5,6],[7,8,9]]) } } "C11 negative-cell croak no leak";
no_leaks_ok { eval { fisher_test({ a => { x => 1, 'y' => 2, z => 3 },
                                   b => { x => 4, 'y' => 5, w => 6 },
                                   c => { x => 7, 'y' => 8, z => 9 } }) } }
    "C11 hash mismatched-keys croak no leak";
no_leaks_ok { eval { fisher_test({ a => { x => 1, 'y' => 2, z => 3 },
                                   b => { x => 4, 'y' => 5 } }) } }
    "C11 hash bad-column-count croak no leak";

done_testing();
