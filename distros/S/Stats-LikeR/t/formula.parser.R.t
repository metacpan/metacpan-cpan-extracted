require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;
use Stats::LikeR;
use Time::HiRes ();

# Regression tests for the formula parser (0.3428).
#
# Provenance: every number below is R 4.6.1's own output for the call named
# beside it (lm(), glm(family = poisson), coef(), summary(fit)$r.squared,
# fitted(), residuals()), printed with options(digits = 17).  The generator is
# t/formula.parser.R.R; run `Rscript t/formula.parser.R.R` to reproduce them.
# No R test suite covers these formulas, so the data are small and made up.
# The croak cases have R's behavior in the comment: R's terms() or
# model.frame() stops with a syntax error or "object 'q' not found".
#
# Tolerance: relative 1e-9.  The worst disagreement seen on the double build is
# 3e-15; the headroom covers long double and quadmath, whose rounding differs
# in the last digits.

my %d = (
	y   => [1.5, 2.25, 3.75, 3.0, 5.5, 4.25, 7.0, 6.5, 8.25, 9.0],
	x   => [1 .. 10],
	z   => [0.5, 0.25, 1.0, 0.75, 1.5, 1.25, 2.0, 1.75, 2.5, 2.25],
	u   => [map { 2 * $_ } 1 .. 10],
	a   => [qw(p q p q p q p q p q)],
	cnt => [1, 2, 2, 4, 3, 6, 5, 9, 8, 12],
);
my $TOL = 1e-9;

sub near {
	my ($got, $want, $name) = @_;
	my $scale = abs($want) > 1 ? abs($want) : 1;
	ok(defined $got && abs($got - $want) <= $TOL * $scale, $name)
		or diag("got " . ($got // 'undef') . ", want $want");
}

sub check_coef {
	my ($fit, $want, $name) = @_;
	is_deeply([sort keys %{ $fit->{coefficients} }], [sort keys %$want], "$name: coefficient names");
	near($fit->{coefficients}{$_}, $want->{$_}, "$name: $_") for sort keys %$want;
}

# 3: offset() anywhere a term may stand, and in lm().
my @lm = (
	['y~x+offset(z)', { Intercept => 0.55000000000000027, x => 0.57727272727272727 },
		2.5636363636363635, 0.9147053819542903, 1.6272727272727268, -0.12727272727272668],
	['y~x+offset(u/2)', { Intercept => 0.63333333333333341, x => -0.18787878787878787 },
		4.4878787878787874, 0.3935298935298937, 1.4454545454545451, 0.054545454545454952],
	['y~x+offset(-z)', { Intercept => 0.71666666666666734, x => 1.0469696969696969 },
		7.6242424242424232, 0.92224623698905039, 1.2636363636363641, 0.23636363636363583],
	['y~x+offset(u+z)', { Intercept => 0.54999999999999971, x => -1.4227272727272726 },
		2.5636363636363622, 0.98488031928261943, 1.6272727272727261, -0.12727272727272615],
	['y~x+offset(u-z)', { Intercept => 0.71666666666666679, x => -0.95303030303030312 },
		7.624242424242424, 0.90764790764790759, 1.263636363636363, 0.236363636363637],
	['y~x+offset(z)+offset(u/2)', { Intercept => 0.54999999999999971, x => -0.42272727272727267 },
		2.563636363636363, 0.85186644341573925, 1.627272727272727, -0.1272727272727269],
	['y~x*offset(z)', { Intercept => 0.55000000000000027, x => 0.57727272727272727 },
		2.5636363636363635, 0.9147053819542903, 1.6272727272727268, -0.12727272727272668],
	['y~x-offset(z)', { Intercept => 0.55000000000000027, x => 0.57727272727272727 },
		2.5636363636363635, 0.9147053819542903, 1.6272727272727268, -0.12727272727272668],
	['y~a+offset(z)-1', { ap => 3.7000000000000002, aq => 3.7499999999999996 },
		30.049999999999997, 0.82199185486856718, 4.1999999999999993, -2.6999999999999993],
);
for my $c (@lm) {
	my ($f, $coef, $rss, $r2, $fit1, $res1) = @$c;
	my $r = lm(formula => $f, data => \%d);
	check_coef($r, $coef, "lm $f");
	near($r->{rss}, $rss, "lm $f: rss");
	near($r->{r_squared}, $r2, "lm $f: r.squared");
	near($r->{fitted_values}{1}, $fit1, "lm $f: fitted, offset included");
	near($r->{residuals}{1}, $res1, "lm $f: residual");
	is($r->{df_residual}, 10 - scalar(keys %$coef), "lm $f: df");
}

my @glm = (
	['cnt~x+offset(z)*a', { Intercept => -0.18832300881830696, x => -0.031922264875208349, aq => 0.83399084717524807 }],
	['cnt~x-offset(z)',   { Intercept => 0.027134350833246265, x => 0.00014736126235270167 }],
	['cnt~x+offset(u/2)', { Intercept => 0.17141256185750897, x => -0.76958522801152129 }],
	['cnt~x+offset(-z)',  { Intercept => 0.24456620202115265, x => 0.46238410049705581 }],
);
for my $c (@glm) {
	check_coef(glm(formula => $c->[0], data => \%d, family => 'poisson'), $c->[1], "glm $c->[0]");
}

# 1: '.' leaves out every variable the response mentions.
my %dot = (y => $d{y}, x => $d{x}, z => $d{z});
my @dot = (
	['log(y)~.',   { Intercept => 0.44918656137576113, x => 0.088482449033065041, z => 0.40401311427005066 }],
	['I(y+x)~.',   { Intercept => 0.90000000000000102, z => 7.0545454545454547 }],
	['log(y)~.-x', { Intercept => 0.47868071105344945, z => 0.73649261972762836 }],
	['y~.',        { Intercept => 0.45937499999999892, x => 0.32187500000000008, z => 2.0875000000000004 }],
);
check_coef(lm(formula => $_->[0], data => \%dot), $_->[1], "lm $_->[0]") for @dot;

# 2: the last intercept marker wins.
my %with = (Intercept => 0.63333333333333297, x => 0.81212121212121213);
my %without = (x => 0.90259740259740262);
check_coef(lm(formula => $_, data => \%d), \%with, "lm $_") for 'y~x-1+1', 'y~0+x+1', 'y~x+0+1';
check_coef(lm(formula => $_, data => \%d), \%without, "lm $_") for 'y~x+1-1', 'y~1+x-1', 'y~x-1+0';
check_coef(lm(formula => 'y~0+1', data => \%d), { Intercept => 5.0999999999999996 }, 'lm y~0+1');

# 4: a long sum is linear in its terms.  The columns are copies of x, so all
# but the first are aliased (R reports NA for them).
{
	my $k = 8000;
	my %w = (y => $d{y});
	$w{"v$_"} = $d{x} for 1 .. $k;
	my $f = 'y~' . join('+', map { "v$_" } 1 .. $k);
	my $t0 = [Time::HiRes::gettimeofday];
	my $r;
	lives_ok { $r = lm(formula => $f, data => \%w) } "a sum of $k terms parses";
	is($r->{rank}, 2, 'the long sum: rank 2') if $r;
	# Generous bound: this whole test file runs in about a second; a quadratic parse (and 0.3427 outright) did not finish.
	cmp_ok(Time::HiRes::tv_interval($t0), '<', 120, 'the long sum is not quadratic');
}

# 5: a long run of unary signs does not overflow the stack; R reads `y ~ -x`
# as the intercept alone.
{
	my $r;
	lives_ok { $r = lm(formula => 'y~' . ('-' x 100000) . 'x', data => \%d) } '100000 unary minus signs';
	is_deeply([keys %{ $r->{coefficients} }], ['Intercept'], 'and leave the intercept alone') if $r;
	lives_ok { lm(formula => 'y~x' . ('+-' x 50000) . 'z', data => \%d) } '+-+-... runs';
}

# 6: malformed input.  R: syntax errors for all of these but the last three,
# "object 'q' not found" for the mistyped names.
for my $f ('y~x+', 'y~x+z+', 'y~+', 'y~x-', 'y~1+', 'y~0+') {
	throws_ok { lm(formula => $f, data => \%d) } qr/^lm: the formula has an operator with no operand/, "'$f' has an operator with no operand";
}
for my $f ('y~x z', 'y ~ x z', 'y~(x) z') {
	throws_ok { lm(formula => $f, data => \%d) } qr/^lm: syntax error in the formula/, "'$f' is a syntax error";
}
throws_ok { lm(formula => 'y~x,z', data => \%d) } qr/^lm: cannot read the formula near ',z'/, "'y~x,z' is refused";
for my $e ('I(x>0)', 'I(x==0)', 'I(a=="a")', 'I(x&z)', 'I(x%%2)', 'I(!x)') {
	throws_ok { lm(formula => "y~$e", data => \%d) } qr/^lm: cannot evaluate term/, "$e is not evaluated";
}
throws_ok { lm(formula => 'y~q', data => \%d) } qr/^lm: object 'q' not found/, 'a mistyped predictor is named';
throws_ok { lm(formula => 'y~x+log(q)', data => \%d) } qr/^lm: object 'q' not found/, 'a mistyped column in a call is named';
throws_ok { lm(formula => 'q~x', data => \%d) } qr/^lm: object 'q' not found/, 'a mistyped response is named';
throws_ok { glm(formula => 'cnt~x+offset(q)', data => \%d, family => 'poisson') } qr/^glm: object 'q' not found/, 'a mistyped offset column is named';
throws_ok { lm(formula => 'y~x+offset()', data => \%d) } qr/offset\(\) is empty/, 'an empty offset() is refused';

done_testing;
