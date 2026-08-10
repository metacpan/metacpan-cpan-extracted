#!/usr/bin/env perl

require 5.010;
use warnings FATAL => 'all';
use Scalar::Util 'looks_like_number';
use Stats::LikeR;
use Test::Exception; # dies_ok
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

# Gemini helped to write some of the tests
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

# ----------------------------------------------------------------------
# Tests
# ----------------------------------------------------------------------

# Collect chisq_test's warnings rather than letting them reach the harness;
# several sections below are about the warning itself.
sub warnings_from (&) {
	my ($code) = @_;
	my @w;
	{
		local $SIG{__WARN__} = sub { push @w, $_[0] };
		$code->();
	}
	return @w;
}

dies_ok { chisq_test() } 'Croaks with no arguments';
dies_ok { chisq_test(123) } 'Croaks with non-reference (scalar)';
dies_ok { chisq_test(\"string") } 'Croaks with scalar reference';
dies_ok { chisq_test([]) } 'Croaks with empty array reference';
dies_ok { chisq_test({}) } 'Croaks with empty hash reference';
dies_ok { chisq_test([undef, undef]) } 'Croaks with undefined values in array ref';
dies_ok { chisq_test({ A => undef }) } 'Croaks with undefined keys in hash ref';
dies_ok { chisq_test(undef) } 'Croaks with undefined arg';
# ======================================================================
# 1D Array Test
# R Code: 
#   chisq.test(c(10, 20, 30))
# R Output:
#   Chi-squared test for given probabilities
#   data:  c(10, 20, 30)
#   X-squared = 10, df = 2, p-value = 0.006738
# ======================================================================
my $data = [10, 20, 30];
my $res = chisq_test($data);
is(ref($res), 'HASH', 'Returns a hashref');
is($res->{'data.name'}, 'Perl ArrayRef', 'Correct data.name');
is($res->{method}, 'Chi-squared test for given probabilities', 'Correct method detected');

# Expected: (10-20)^2/20 + (20-20)^2/20 + (30-20)^2/20 = 10
is_approx($res->{statistic}{'X-squared'}, 10.0, 'Calculates correct X-squared statistic', 1e-13);
is_approx($res->{parameter}{df}, 2, 'Calculates correct degrees of freedom', 1e-13);
is_approx( $res->{'p.value'}, 0.00673794699908547, 'chisq_test: p-value with 1D array', 1e-13);
ok(looks_like_number($res->{'p.value'}), 'p.value is a number');

is(ref($res->{expected}), 'ARRAY', 'Expected frequencies is an array ref');
is_approx($res->{expected}[0], 20.0, 'Expected frequency [0] is correct');

# ======================================================================
# 2D Array Test (2x2 Matrix)
# R Code: 
#   chisq.test(rbind(c(10, 15), c(20, 5)))
# R Output:
#   Pearson's Chi-squared test with Yates' continuity correction
#   data:  rbind(c(10, 15), c(20, 5))
#   X-squared = 6.75, df = 1, p-value = 0.009375
# ======================================================================
$data = [[10, 15], [20, 5]];
$res = chisq_test($data);
is($res->{method}, "Pearson's Chi-squared test with Yates' continuity correction", 'Yates correction triggered for 2x2');

# R calculation equivalent for [[10, 15], [20, 5]] yields X-squared = 6.75
is_approx($res->{statistic}{'X-squared'}, 6.75, 'Calculates correct X-squared statistic with Yates', 1e-13);
is_approx($res->{parameter}{df}, 1, 'Calculates correct degrees of freedom', 1e-13);
is_approx($res->{'p.value'}, 0.00937476845943488, 'chisq_test: 2x2 p-value', 1e-13);
# ======================================================================
# 2D Array Test (> 3x2 Matrix)
# R Code: 
#   chisq.test(rbind(c(10, 10, 20), c(20, 20, 20)))
# R Output:
#   Pearson's Chi-squared test
#   data:  rbind(c(10, 10, 20), c(20, 20, 20))
#   X-squared = 2.5, df = 2, p-value = 0.2865
# ======================================================================
$data = [[10, 10, 20], [20, 20, 20]];
$res = chisq_test($data);
    
is($res->{method}, "Pearson's Chi-squared test", 'Standard Pearson applied (no Yates)');
is_approx($res->{parameter}{df}, 2, 'Calculates correct degrees of freedom', 1e-13);
is_approx($res->{'p.value'}, 0.249352208777296, 'chisq_test: 3x2 matrix, p-value correct', 1e-13);
# ======================================================================
# 1D Hash Test
# R Code: 
#   chisq.test(c(A=10, B=20, C=30))
# R Output:
#   Chi-squared test for given probabilities
#   data:  c(A = 10, B = 20, C = 30)
#   X-squared = 10, df = 2, p-value = 0.006738
# ======================================================================
$data = { A => 10, B => 20, C => 30 };
$res = chisq_test($data);

is($res->{'data.name'}, 'Perl HashRef', 'Correct data.name');
is_approx($res->{statistic}{'X-squared'}, 10.0, 'Calculates correct X-squared from Hash keys', 1e-13);
is_approx($res->{parameter}{df}, 2, 'Calculates correct degrees of freedom', 1e-13);

is(ref($res->{expected}), 'HASH', 'Expected frequencies is a hash ref');
is_approx($res->{expected}{A}, 20.0, 'Expected frequency for key A is correct', 1e-13);
is_approx($res->{'p.value'}, 0.00673794699908547, 'chisq_test: p-value for 1D hash', 1e-13);
#
# 2D Hash Test
# R Code: 
#   chisq.test(rbind(Group1=c(Success=10, Failure=15), Group2=c(Success=20, Failure=5)))
# R Output:
#   Pearson's Chi-squared test with Yates' continuity correction
#   data:  rbind(...)
#   X-squared = 6.75, df = 1, p-value = 0.009375
#
$data = {
	Group1 => { Success => 10, Failure => 15 },
	Group2 => { Success => 20, Failure => 5 }
};
$res = chisq_test($data);

is($res->{method}, "Pearson's Chi-squared test with Yates' continuity correction", 'Yates correction triggered for 2x2 HoH');
is_approx($res->{statistic}{'X-squared'}, 6.75, 'Calculates correct X-squared from 2D Hash');
is_approx($res->{parameter}{df}, 1, 'Calculates correct degrees of freedom', 1e-13);
is_approx($res->{'p.value'}, 0.00937476845943488, 'chisq_test: 2x2 p-value', 1e-13);
#
# Memory Leak Validations
#
# It's crucial that the XS matrices, nested SVs, and Av/Hv structures are freed.
no_leaks_ok {
	eval { chisq_test([]) }; # Expected failure
} 'No leaks on early exception (Empty Array)' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	$data = [10, 20, 30, 40];
	chisq_test($data);
} 'No leaks with successful 1D Array processing' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	$data = [[10, 15], [20, 5]];
	chisq_test($data);
} 'No leaks with successful 2D Array processing' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	$data = { a => 10, b => 20, c => 30 };
	chisq_test($data);
} 'No leaks with successful 1D Hash processing' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	$data = {
		row1 => { col1 => 10, col2 => 15 },
		row2 => { col1 => 20, col2 => 5 }
	};
	chisq_test($data);
} 'No leaks with successful 2D Hash processing' unless $INC{'Devel/Cover.pm'};

# ======================================================================
# Input validation.  R's chisq.test() refuses to coerce: every entry must be
# a nonnegative finite number and at least one of them must be positive.
# ======================================================================
throws_ok { chisq_test([10, -5, 30]) } qr/nonnegative and finite/,
	'Croaks on a negative count';
throws_ok { chisq_test([[10, -5], [30, 1]]) } qr/nonnegative and finite/,
	'Croaks on a negative count in a 2D array';
throws_ok { chisq_test({ A => 10, B => -5 }) } qr/nonnegative and finite/,
	'Croaks on a negative count in a hash';
throws_ok { chisq_test([10, 9**9**9, 30]) } qr/nonnegative and finite/,
	'Croaks on an infinite count';
throws_ok { chisq_test(['a', 'b', 'c']) } qr/is not a number/,
	'Croaks on a non-numeric entry';
throws_ok { chisq_test([10, undef, 30]) } qr/is undef/,
	'Croaks on an undefined entry';
throws_ok { chisq_test([0, 0, 0]) } qr/at least one entry of 'x' must be positive/,
	'Croaks when everything is zero';
throws_ok { chisq_test([5]) } qr/'x' must at least have 2 elements/,
	'Croaks on a single element';
throws_ok { chisq_test([[5]]) } qr/'x' must at least have 2 elements/,
	'Croaks on a 1x1 table';
throws_ok { chisq_test({ A => 5 }) } qr/'x' must at least have 2 elements/,
	'Croaks on a single-key hash';
throws_ok { chisq_test([[1, 2, 3], [4, 5]]) } qr/same number of columns/,
	'Croaks on a ragged 2D array';

# A hole in a sparse array is not the same as a stored undef: av_fetch()
# returns NULL for it, which must not be dereferenced.
{
	my @flat = (10, 20, 30);
	delete $flat[1];
	throws_ok { chisq_test(\@flat) } qr/element \[1\] is undef/,
		'Croaks on a hole in a sparse 1D array';
	my @row = (10, 20, 30);
	delete $row[1];
	throws_ok { chisq_test([\@row, [4, 5, 6]]) } qr/cell \[0\]\[1\] is undef/,
		'Croaks on a hole in a sparse table row';
	my @p = (0.2, 0.3, 0.5);
	delete $p[1];
	throws_ok { chisq_test([10, 20, 30], p => \@p) } qr/p\[1\] is undef/,
		'Croaks on a hole in a sparse p';
}
throws_ok { chisq_test([[1, 2], 3]) } qr/row 2 is not an array reference/,
	'Croaks when a row is not an array ref';
throws_ok { chisq_test({ a => { x => 1, y => 2 }, b => 3 }) } qr/is not a hash reference/,
	'Croaks when a hash row is not a hash ref';
throws_ok { chisq_test({ a => { x => 1, y => 2 }, b => { x => 3 } }) }
	qr/same 2 column key\(s\)/, 'Croaks when a hash row is missing a column';
throws_ok { chisq_test({ a => { x => 1, y => 2 }, b => { x => 3, z => 4 } }) }
	qr/has no column/, 'Croaks when a hash row has a different column key';
# Hash rows and columns are read in sorted key order, so which row a
# malformed hash is blamed on does not depend on Perl's hash randomization.
{
	my %msg;
	for (1 .. 50) {
		my %h = (alpha => { x => 1, y => 2 }, beta => { x => 3 }, gamma => { x => 1, y => 1 });
		eval { chisq_test(\%h) };
		my $e = $@;
		$e =~ s/ at .*//s;
		$msg{$e}++;
	}
	is(scalar keys %msg, 1, 'The croak from a malformed hash is the same every time');
	like((keys %msg)[0], qr/row 'beta' has 1/, '... and names the offending row');
}

throws_ok { chisq_test([10, 20, 30], 'correct') } qr/odd number of named arguments/,
	'Croaks on an odd number of named arguments';
throws_ok { chisq_test([10, 20, 30], banana => 1) } qr/unknown argument 'banana'/,
	'Croaks on an unknown named argument';

# ======================================================================
# correct => 0 turns off Yates' continuity correction, as in R.
# ======================================================================
{
	my $res = chisq_test([[10, 15], [20, 5]], correct => 0);
	is($res->{method}, "Pearson's Chi-squared test", 'correct => 0 drops Yates');
	is_approx($res->{statistic}{'X-squared'}, 8.3333333333333339,
		'correct => 0 gives the uncorrected statistic', 1e-12);
	is(chisq_test([[10, 15], [20, 5]], correct => 1)->{method},
		"Pearson's Chi-squared test with Yates' continuity correction",
		'correct => 1 is the default');
	# a correction of exactly 0 is reported as a plain Pearson test, as R does
	is(chisq_test([[10, 20], [20, 40]])->{method}, "Pearson's Chi-squared test",
		'A zero correction is not called a correction');
}

# ======================================================================
# p => ... runs the goodness-of-fit test against given probabilities, which
# is what the method string has always claimed.
# ======================================================================
{
	my $res = chisq_test([10, 20, 30], p => [0.2, 0.3, 0.5]);
	is($res->{method}, 'Chi-squared test for given probabilities', 'p => gives a GOF test');
	is_approx($res->{statistic}{'X-squared'}, 0.55555555555555558, 'p => statistic', 1e-13);
	is_deeply($res->{expected}, [12, 18, 30], 'p => expected frequencies');

	# unnormalised weights need rescale.p, exactly as in R
	throws_ok { chisq_test([10, 20, 30], p => [2, 3, 5]) }
		qr/probabilities must sum to 1/, 'Croaks when p does not sum to 1';
	my $r2 = chisq_test([10, 20, 30], p => [2, 3, 5], 'rescale.p' => 1);
	is_approx($r2->{statistic}{'X-squared'}, 0.55555555555555558, 'rescale.p rescales', 1e-13);
	is_approx(chisq_test([10, 20, 30], p => [2, 3, 5], rescale_p => 1)
			->{statistic}{'X-squared'},
		0.55555555555555558, 'rescale_p is an alias', 1e-13);

	throws_ok { chisq_test([10, 20, 30], p => [0.5, 0.5]) }
		qr/same number of elements/, 'Croaks when p is the wrong length';
	throws_ok { chisq_test([10, 20, 30], p => [-0.5, 1.0, 0.5]) }
		qr/probabilities must be non-negative/, 'Croaks on a negative probability';
	throws_ok { chisq_test([10, 20, 30], p => [0, 0, 0], 'rescale.p' => 1) }
		qr/positive value to be rescaled/, 'Croaks when p sums to zero';
	throws_ok { chisq_test([[10, 15], [20, 5]], p => [0.25, 0.25, 0.25, 0.25]) }
		qr/goodness-of-fit test only/, 'Croaks when p is given for a contingency table';
	throws_ok { chisq_test([10, 20, 30], p => 0.5) }
		qr/'p' must be an array reference or a hash reference/, 'Croaks when p is not a reference';

	# a hash of counts takes a hash of probabilities, so the caller never has
	# to guess the order the keys came back in
	my $h = chisq_test({ A => 10, B => 20, C => 30 }, p => { A => 0.2, B => 0.3, C => 0.5 });
	is_approx($h->{statistic}{'X-squared'}, 0.55555555555555558, 'keyed p statistic', 1e-13);
	is_deeply($h->{expected}, { A => 12, B => 18, C => 30 }, 'keyed p expected frequencies');
	throws_ok { chisq_test({ A => 10, B => 20 }, p => [0.5, 0.5]) }
		qr/must be a hash reference keyed like 'x'/, 'Croaks on an array p for a hash x';
	throws_ok { chisq_test([10, 20], p => { A => 0.5, B => 0.5 }) }
		qr/must be an array reference when 'x' is an array reference/,
		'Croaks on a hash p for an array x';
	throws_ok { chisq_test({ A => 10, B => 20 }, p => { A => 0.5, Z => 0.5 }) }
		qr/'p' has no entry for/, 'Croaks when keyed p is missing a key';
}

# ======================================================================
# A 1 x k or k x 1 table is a goodness-of-fit test, as in R, not a
# contingency table with df 0.
# ======================================================================
{
	for my $case ([[10, 20, 30]], [[10], [20], [30]]) {
		my $res = chisq_test($case);
		is($res->{method}, 'Chi-squared test for given probabilities',
			'Single-row/column table collapses to a GOF test');
		is($res->{parameter}{df}, 2, '... with df = k - 1, not 0');
		is_approx($res->{statistic}{'X-squared'}, 10, '... and the GOF statistic', 1e-13);
	}
	is_deeply(chisq_test([[10, 20, 30]])->{expected}, [[20, 20, 20]],
		'... while expected keeps the shape it was given');
}

# ======================================================================
# R warns when any expected count falls below 5.
# ======================================================================
{
	my @w = warnings_from { chisq_test([[3, 1], [1, 3]]) };
	is(scalar @w, 1, 'One warning for a table with small expected counts');
	like($w[0], qr/Chi-squared approximation may be incorrect/,
		'... which is the message R gives');
	is(scalar(warnings_from { chisq_test([[100, 150], [200, 50]]) }), 0,
		'No warning when every expected count is at least 5');
	is(scalar(warnings_from { chisq_test([10, 20, 30]) }), 0,
		'No warning for a comfortable goodness-of-fit test');
}

# ======================================================================
# Leak checks for the paths added above
# ======================================================================
no_leaks_ok {
	eval { chisq_test([[1, 2, 3], [4, 5]]) };  # croak from mid-parse
} 'No leaks when a ragged array croaks' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	eval { chisq_test({ a => { x => 1, y => 2 }, b => { x => 3 } }) };
} 'No leaks when a hash row croaks' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	eval { chisq_test([10, 20, 30], p => [0.5, 0.5]) };
} 'No leaks when p validation croaks' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	chisq_test([10, 20, 30], p => [0.2, 0.3, 0.5]);
} 'No leaks with given probabilities' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	chisq_test({ A => 10, B => 20, C => 30 }, p => { A => 0.2, B => 0.3, C => 0.5 });
} 'No leaks with keyed probabilities' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	chisq_test([[10, 15], [20, 5]], correct => 0);
} 'No leaks with correct => 0' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	chisq_test([[10, 20, 30]]);
} 'No leaks when a 1 x k table collapses' unless $INC{'Devel/Cover.pm'};

done_testing();
