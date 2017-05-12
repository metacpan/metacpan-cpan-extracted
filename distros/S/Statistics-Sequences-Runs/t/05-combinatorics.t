use Test::More tests => 20;
use constant EPS => 1e-3;
use Array::Compare;

BEGIN {
    use_ok( 'Statistics::Sequences::Runs' ) || print "Bail out!\n";
}

my $runs = Statistics::Sequences::Runs->new();
my $val;

my %ref = (
    swed_1943_1 => {
        observed => 5,
        expected => 9,
        z_value => -2.29,
        p_value => .010973, # based on deviation ratio with ccorr & tails = 1
        p_exact => .0183512,  # SW 1943 p. 71 Table 1
        freqs => [5, 20],
        data => [qw/H H H H H H H H H H D H D D D D H H H H H H H H H/],
    },
    swed_1943_2 => {
        observed => 15,
        freqs => [20, 20],
        p_exact => .0379982, # SW 1943 p. 82 Table 1
        p_value => .039036, # based on deviation ratio with ccorr & tails = 1
    },
    swed_1943_3 => {
        data => [qw/E O E E O E E E O E E E O E O E/],
        observed => 11,
        expected => 7.88,
        freqs => [5, 11],
        p_exact => .0576923, # SW 1943 p. 82 Table 1
    },
);

my ($u, $num, @frq, @data) = ();

@data = (0, 0, 0, 0, 0, 1, 1, 1, 1, 1);
$runs->load(\@data);
$u = $runs->observed();
@frq = $runs->bi_frequency(data => \@data);
$num = Statistics::Sequences::Runs::_pmf_num($u, @frq);
ok(equal($num, 2) , "pmf internals: _pmf_num observed $num != 2"); # per S&E p. 66

# the same but by public method:
$num = $runs->m_seq_k();
ok(equal($num, 2) , "pmf numerator: observed $num != 2"); # per S&E p. 66

$num = $runs->pmf();
ok(equal($num, 1/126) , "pmf internals: pmf observed $num != " . 1/126); # per S&E p. 66

@data = (0, 0, 0, 0, 1, 1, 1, 1, 1, 0);
$runs->load(\@data);
$u = $runs->observed();
@frq = $runs->bi_frequency(data => \@data);
$num = Statistics::Sequences::Runs::_pmf_num($u, @frq);
ok(equal($num, 8) , "pmf internals: _pmf_num observed $num != 8"); # per S&E p. 66

$num = Statistics::Sequences::Runs::_pmf_denom(@frq);
ok(equal($num, 252) , "pmf internals: _pmf_denom observed $num != 252"); # per S&E p. 66

$num = $runs->n_max_seq();
ok(equal($num, 252) , "pmf denominator: observed $num != 252"); # per S&E p. 66

$num = $runs->pmf();
ok(equal($num, 8/252) , "pmf internals: pmf observed $num != " . 8/252); # per S&E p. 66

# test that observed value is less than expectation:
$runs->load(swed => $ref{'swed_1943_1'}->{'data'});
$val = $runs->p_value(exact => 1, tails => 1, ccorr => 1); # this should be below .05, according to Siegal, 1956, Table F;
ok(equal($val, $ref{'swed_1943_1'}->{'p_exact'}) , "exact p_value observed $val != $ref{'swed_1943_1'}->{'p_exact'}");

$num = $runs->cdf(observed => 5, freqs => [5, 20]); # S&E p. 67
ok(equal($num, .0183512) , "cdf: observed $num != .0183512");

$num = $runs->cdf(observed => 15, freqs => [20, 20]); # S&E p. 67
ok(equal($num, .038) , "cdf: observed $num != .038");

$num = $runs->cdfi(observed => 11, freqs => [5, 11]); # S&E p. 68
ok(equal($num, .0576923) , "cdf: observed $num != .0576923");

$num = $runs->cdf(observed => 4, freqs => [8, 8]); # S&E p. 69
ok(equal($num, .0088578) , "cdf: observed $num != .0088578");

$val = $runs->p_value(freqs => $ref{'swed_1943_2'}->{'freqs'}, observed => $ref{'swed_1943_2'}->{'observed'}, exact => 1, tails => 1, ccorr => 1); # this should be below .05, according to Siegal, 1956, Table F;
ok( equal($val, $ref{'swed_1943_2'}->{'p_exact'}) , "exact p_value observed $val != $ref{'swed_1943_2'}->{'p_exact'}");

# test that observed value is greater than expectation:
$val = $runs->p_value(freqs => [5, 11], observed => 11, exact => 1, precision_p => 7);
ok( equal($val, $ref{'swed_1943_3'}->{'p_exact'}) , "exact p_value observed $val != $ref{'swed_1943_3'}->{'p_exact'}");

# this sequence is close to expectation:
my @test2 = (qw/1 0 0 0 1 0 0 0 0 0 1 1 1 0 0 0 0 1 0 1 1 0 0 0 1 0 0 1 1 0 1 1 0 0 1 1 0 1 0 0 0 1 0 0 0 0 0 1 0 0 1 1 0 0 0 0 1 1 0 0 1 0 0 0 0 1 0 0 0 0 0 0 0 0 0 1 0 0 0 0 1 0 0 1 1 0 0 0 0 1 0 0 0 0 1 0 1 0 0 1/);

my $p_norm_2 = 0.9963;
my $p_norm_1 = 0.49816;
my $p_exact = 0.51118;

$runs->load(\@test2);

#diag("\nOne-tailed");
$val = $runs->p_value(exact => 0, tails => 1);
ok(equal($val, $p_norm_1), "Wrong 1-tailed norm p_value: <$val> not <$p_norm_1>");

$val = $runs->p_value(exact => 1, tails => 1);
ok(equal($val, $p_exact), "Wrong 1-tailed exact p_value: <$val> not <$p_exact>");
# and this s/be same as cdfi:
$val = $runs->cdfi();
ok(equal($val, $p_exact), "Wrong 1-tailed exact p_value by cdfi: <$val> not <$p_exact>");

#diag("\n2-tailed");
$val = $runs->p_value(exact => 0, tails => 2);
ok(equal($val, $p_norm_2), "Wrong 2-tailed norm p_value: <$val> not <$p_norm_2>");

$val = $runs->p_value(exact => 1, tails => 2); # tails should have no effect
ok(equal($val, $p_exact), "Wrong 1-tailed exact p_value: <$val> not <$p_exact>");

sub equal {
    return 0 if ! defined $_[0] || ! defined $_[1];
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}
1;