use Test::More tests => 7;
use constant EPS => 1e-2;

# Calculate expected, variance and z_value not from a given sequence but
# from given frequencies

BEGIN {
    use_ok( 'Statistics::Sequences::Runs' ) || print "Bail out!\n";
}

my $runs = Statistics::Sequences::Runs->new();

my %refdat = (
    reiter => { # sample from reiter1.com
        data => [qw/m m w w m w m m w w m w m w m w m m w m m w m w m/],
        observed => 19,
        expected => 13.32,
        stdev => 2.41,
        variance => 2.41**2,
        z_value => 2.15,
        p_value => 1 - .984,
    },
);

my $val;

# calculate stats by given number of freq - and observed:
$runs->unload();
$val = $runs->expected(freqs => [14, 11]);
ok(equal($val, $refdat{'reiter'}->{'expected'}), "expected  $val != $refdat{'reiter'}->{'expected'}");

$val = $runs->variance(freqs => [14, 11]);
ok(equal($val, $refdat{'reiter'}->{'variance'}), "variance  $val != $refdat{'reiter'}->{'variance'}");

$val = $runs->z_value(ccorr => 1, freqs => [14, 11], observed => 19);
ok(equal($val, $refdat{'reiter'}->{'z_value'}), "z_value  $val != $refdat{'reiter'}->{'z_value'}");

$val = $runs->ztest_ok(freqs => [21, 21]); # base on zilch data
ok(equal($val, 1), "ztest_ok  $val != 1");

$val = $runs->ztest_ok(freqs => [20, 21]); # base on zilch data - should "just" pass
ok(equal($val, 1), "ztest_ok  $val != 1");

$val = $runs->ztest_ok(freqs => [20, 20]); # base on zilch data - and fail the test
ok(equal($val, 0), "ztest_ok  $val != 0");


sub equal {
    return 0 if ! defined $_[0] || ! defined $_[1];
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}
1;