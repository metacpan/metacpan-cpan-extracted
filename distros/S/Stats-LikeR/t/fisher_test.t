#!/usr/bin/perl
require 5.010;
use strict;
use warnings;
use Test::More;

# Stats::LikeR::fisher_test returns a hashref:
#   { p_value, estimate => { "odds ratio" => OR }, conf_int => [lo, hi],
#     alternative, method, conf_level }
#
# All expected values below were produced by R's stats::fisher.test().
# CI bounds match R to the precision R prints, because the XS solver replicates
# R's uniroot/zeroin (Brent-Dekker) with tol = .Machine$double.eps^0.25.

use Stats::LikeR 'fisher_test';

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
eval { fisher_test([[3,1,9],[1,3]]) };         ok($@, "C5 non-2x2 row croaks");
eval { fisher_test([[3,1],[1,3]], alternative => "sideways") };
ok($@, "C5 bad alternative croaks");
eval { fisher_test([[3,1],[1,3]], conf_level => 1.5) };
ok($@, "C5 conf_level out of range croaks");

done_testing();
