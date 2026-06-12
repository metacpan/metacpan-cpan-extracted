#!/usr/bin/env perl

require 5.010;
use warnings FATAL => 'all';
use feature 'say';
use File::Temp;
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

done_testing();
