#!/usr/bin/env perl

require 5.010;
use warnings FATAL => 'all';
use Scalar::Util 'looks_like_number';
use Stats::LikeR;
use Test::Exception; # dies_ok / throws_ok
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

# Custom helper for floating-point comparisons
sub is_approx {
	my ($got, $expected, $test_name, $epsilon) = @_;
	$epsilon = 1e-7 if not defined $epsilon;
	my $current_sub = ( split( /::/, ( caller(0) )[3] ) )[-1];
	my $i = 0;
	foreach my $arg ($got, $expected, $test_name) {
		next if defined $arg;
		die "\$arg[$i] (see subroutine signature for name) isn't defined in $current_sub";
		$i++;
	}
	my $diff = abs($got - $expected);
	if ($diff <= $epsilon) {
		pass("$test_name: within $epsilon");
		return 1;
	} else {
		fail($test_name);
		diag("         got: $got\n    expected: $expected; diff = $diff");
		return 0;
	}
}

my $NAN = 'inf' - 'inf';

#--------
# standard normal CDF: reference values (R pnorm)
#--------
is_approx( pnorm(0),     0.5,                  'pnorm(0) = 1/2');
is_approx( pnorm(1),     0.8413447460685429,   'pnorm(1)');
is_approx( pnorm(-1),    0.15865525393145705,  'pnorm(-1)');
is_approx( pnorm(2),     0.9772498680518208,   'pnorm(2)');
is_approx( pnorm(-2),    0.022750131948179195, 'pnorm(-2)');
is_approx( pnorm(1.96),  0.9750021048517795,   'pnorm(1.96)');
is_approx( pnorm(3),     0.9986501019683699,   'pnorm(3)');
is_approx( pnorm(-3),    0.0013498980316300946,'pnorm(-3)');
is_approx( pnorm(0.5),   0.6914624612740131,   'pnorm(0.5)');
# quantile round-trips
is_approx( pnorm(1.6448536269514722), 0.95, 'pnorm(qnorm(0.95))');
is_approx( pnorm(1.2815515594465625), 0.90, 'pnorm(qnorm(0.90))');

#--------
# range and monotonicity
#--------
ok( looks_like_number(pnorm(1.96)), 'pnorm returns a number');
my @grid = map { $_ / 2 } (-8 .. 8);
my $mono = 1;
my $inrange = 1;
my $prev;
for my $x (@grid) {
	my $p = pnorm($x);
	$inrange = 0 unless $p >= 0 && $p <= 1;
	$mono = 0 if defined $prev && $p < $prev;
	$prev = $p;
}
ok( $inrange, 'pnorm stays within [0, 1] across the grid');
ok( $mono,    'pnorm is non-decreasing across the grid');

#--------
# symmetry: pnorm(-x) == 1 - pnorm(x)
#--------
for my $x (0.3, 1, 1.96, 4) {
	is_approx( pnorm(-$x), 1 - pnorm($x), "symmetry: pnorm(-$x) == 1 - pnorm($x)");
}

#--------
# lower.tail = 0  (upper tail)
#--------
is_approx( pnorm(1.96, lower => 0), 0.024997895148220428, 'lower=>0: upper tail value');
is_approx( pnorm(1.96, lower => 0), 1 - pnorm(1.96),      'lower=>0 == 1 - lower tail');
is_approx( pnorm(1.96, lower => 0), pnorm(-1.96),         'lower=>0 == pnorm(-x)');
is_approx( pnorm(2, 'lower.tail' => 0), pnorm(2, lower => 0),
	"'lower.tail' alias matches 'lower'");

#--------
# log.p
#--------
is_approx( pnorm(1.96, log => 1), log(pnorm(1.96)),  'log=>1 == log(lower tail)');
is_approx( pnorm(-1,   log => 1), log(pnorm(-1)),    'log=>1 for a left-tail value');
is_approx( pnorm(6,    log => 1), log(pnorm(6)),     'log=>1 for a right value');
is_approx( pnorm(2, 'log.p' => 1), pnorm(2, log => 1),
	"'log.p' alias matches 'log'");
# deep left tail: underflows to 0 without log, finite with log
is_approx( pnorm(-40, log => 1), -804.6084420, 'log=>1 deep tail stays finite', 1e-4);
ok( pnorm(-40) == 0,             'without log the deep tail underflows to 0');
ok( pnorm(-40, log => 1) < -800, 'with log the deep tail is a large negative number');

#--------
# lower.tail = 0 combined with log.p
#--------
is_approx( pnorm(6, lower => 0, log => 1), log(pnorm(6, lower => 0)),
	'lower=>0, log=>1 == log(upper tail)');
is_approx( pnorm(6, lower => 0, log => 1), -20.736768949974707,
	'lower=>0, log=>1 deep right-tail value');

#--------
# mean / sd  (standardization)
#--------
is_approx( pnorm(2, mean => 1, sd => 0.5), pnorm(2),
	'pnorm(2, mean=>1, sd=>0.5) == pnorm(2)  [z = 2]');
is_approx( pnorm(7, mean => 3, sd => 2), pnorm(2),
	'pnorm(x, mean, sd) standardizes to (x-mean)/sd');
is_approx( pnorm(3, mean => 3), 0.5, 'pnorm at the mean is 1/2');

#--------
# sd == 0  degenerates to a step at the mean (H(x - mean))
#--------
is_approx( pnorm( 5, sd => 0), 1, 'sd=>0: x > mean -> 1');
is_approx( pnorm(-5, sd => 0), 0, 'sd=>0: x < mean -> 0');
is_approx( pnorm( 0, sd => 0), 1, 'sd=>0: x == mean -> 1');

#--------
# infinities
#--------
is_approx( pnorm('inf'),  1, 'pnorm(+Inf) = 1');
is_approx( pnorm('-inf'), 0, 'pnorm(-Inf) = 0');

#--------
# NaN propagation
#--------
{
	my $r = pnorm($NAN);
	ok( $r != $r, 'pnorm(NaN) is NaN' );          # NaN is the only value != itself
	my $rm = pnorm(1, mean => $NAN);
	ok( $rm != $rm, 'pnorm(x, mean=>NaN) is NaN' );
}

#--------
# sd < 0  warns and yields NaN (does not die under FATAL warnings)
#--------
{
	my (@w, $res);
	{
		local $SIG{__WARN__} = sub { push @w, $_[0] };
		$res = pnorm(1, sd => -1);
	}
	ok( scalar(@w) >= 1, 'sd<0 emits a warning' );
	like( $w[0], qr/non-negative/, 'sd<0 warning mentions non-negative' ) if @w;
	ok( $res != $res, 'sd<0 returns NaN' );
}

#--------
# array-reference input: elementwise, same length, undef -> NaN
#--------
{
	my @x = (-1.96, 0, 1.96, 3, -3);
	my $got = pnorm(\@x);
	is( ref($got), 'ARRAY', 'arrayref in -> arrayref out' );
	is( scalar(@$got), scalar(@x), 'arrayref out has the same length' );
	my $ok = 1;
	for my $i (0 .. $#x) {
		$ok = 0 if abs($got->[$i] - pnorm($x[$i])) > 1e-12;
	}
	ok( $ok, 'arrayref elements match the scalar calls' );

	my $wlog = pnorm([1, 2, 3], log => 1);
	is_approx( $wlog->[1], pnorm(2, log => 1), 'arrayref honours named args (log)' );

	is_approx( scalar(@{ pnorm([]) }), 0, 'empty arrayref -> empty arrayref' );
}

#--------
# usage / argument errors
#--------
throws_ok { pnorm() }                    qr/Usage: pnorm/,           'pnorm: no args croaks';
throws_ok { pnorm(1, 'mean') }           qr/even number of key-value/,'pnorm: dangling named arg croaks';
throws_ok { pnorm(1, foo => 2) }         qr/unknown argument 'foo'/, 'pnorm: unknown named arg croaks';

#--------
# no memory leaks  (hoist real calls out of the closure first)
#--------
pnorm(1.96);
pnorm(1.96, lower => 0, log => 1);
pnorm([-1.96, 0, 1.96]);
pnorm(5, sd => 0);
no_leaks_ok {
	eval {
		my $s  = pnorm(1.96);
		my $u  = pnorm(1.96, lower => 0);
		my $l  = pnorm(-40, log => 1);
		my $ms = pnorm(7, mean => 3, sd => 2);
		my $a  = pnorm([-1.96, 0, 1.96, 3]);
		my $z  = pnorm(0, sd => 0);
	}
} 'pnorm(): no memory leaks' unless $INC{'Devel/Cover.pm'};

done_testing;
