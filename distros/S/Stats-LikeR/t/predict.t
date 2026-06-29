#!/usr/bin/env perl
require 5.010;
use warnings FATAL => 'all';
use feature 'say';
use File::Temp;
use Scalar::Util 'looks_like_number';
use Stats::LikeR;
use Test::Exception; # die_ok
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
		diag("		   got: $got\n	  expected: $expected; diff = $diff");
		return 0;
	}
}

# a small titanic-like frame reused by the factor tests
my $titanic = {
	age		 => [22,38,26,35,54,2,27,14,4,58,20,39,55,31,45,9,28,40,33,60],
	class	 => [qw(3rd 1st 3rd 1st 1st 3rd 2nd 2nd 3rd 1st 3rd 2nd 1st 3rd 2nd 3rd 2nd 1st 3rd 1st)],
	gender	 => [qw(male female female female male male male female female female male male female male female male male male female male)],
	survived => [	0,	  1,	 1,		1,	  0,   0,	0,	  1,	 1,		1,	  0,   0,	 1,	   0,	 1,	  0,   0,	1,	  0,   1 ],
};

#--------
# round-trip: predicting on the training data reproduces fitted.values (lm)
#--------
{
	my $data = { x => [1, 2, 3, 4], 'y' => [3, 5, 7, 9] };   # y = 1 + 2x exactly
	my $fit	 = lm(formula => 'y ~ x', data => $data);
	my $pred = predict($fit, $data);
	my $fv	 = $fit->{'fitted.values'};
	is(scalar keys %$pred, scalar keys %$fv, 'lm round-trip: one prediction per fitted value');
	is_approx($pred->{$_}, $fv->{$_}, "lm round-trip row $_") for sort keys %$fv;
}

#--------
# prediction on new data (exact line: intercept 1, slope 2)
#--------
{
	my $fit = lm(formula => 'y ~ x', data => { x => [1, 2, 3, 4], 'y' => [3, 5, 7, 9] });
	my $p	= predict($fit, { x => [10, 0] });
	is_approx($p->{1}, 21, 'new data: 1 + 2*10');
	is_approx($p->{2}, 1,  'new data: 1 + 2*0 = intercept');
}

#--------
# a flat single-row hash (scalar values) is one observation
#--------
{
	my $fit = lm(formula => 'y ~ x', data => { x => [1, 2, 3, 4], 'y' => [3, 5, 7, 9] });
	my $p	= predict($fit, { 'x' => 10 });
	is_approx($p->{1}, 21, 'flat hash: scalar values mean a single row');
}

#--------
# interactions and I() round-trip exactly through evaluate_term
#--------
{
	my $data = { x => [1, 2, 3, 4, 5], z => [2, 1, 4, 3, 5], 'y' => [5, 9, 8, 7, 3] };
	my $fit	 = lm(formula => 'y ~ x * z', data => $data);	  # x, z, x:z
	my $pred = predict($fit, $data);
	my $fv	 = $fit->{'fitted.values'};
	is_approx($pred->{$_}, $fv->{$_}, "interaction round-trip row $_") for sort keys %$fv;

	my $fit2  = lm(formula => 'y ~ x + I(x^2)', data => $data);
	my $pred2 = predict($fit2, $data);
	my $fv2	  = $fit2->{'fitted.values'};
	is_approx($pred2->{$_}, $fv2->{$_}, "I(x^2) round-trip row $_") for sort keys %$fv2;
}

#--------
# an aliased (collinear) term is dropped, and the round-trip still holds
#--------
{
	my $data = { x => [1, 2, 3, 4], x2 => [1, 2, 3, 4], 'y' => [2, 4, 6, 8] };
	my $fit	 = lm(formula => 'y ~ x + x2', data => $data);	  # x2 == x -> one aliased (NaN)
	my $aliased = grep { looks_like_number($_) && $_ != $_ } values %{ $fit->{coefficients} };
	ok($aliased >= 1, 'collinear fit produced an aliased (NaN) coefficient');
	my $pred = predict($fit, $data);
	my $fv	 = $fit->{'fitted.values'};
	is_approx($pred->{$_}, $fv->{$_}, "aliased-skip round-trip row $_") for sort keys %$fv;
}

#--------
# glm binomial: response reproduces fitted.values; response = logistic(link)
#--------
{
	my $data = { success => [0, 0, 1, 1], predictor => [0.1, 0.2, 0.9, 0.8] };
	my $fit	 = glm(formula => 'success ~ predictor', data => $data, family => 'binomial');
	ok($fit->{converged}, 'logistic fit converged');
	my $resp = predict($fit, $data);					   # type=response (default)
	my $link = predict($fit, $data, type => 'link');
	my $fv	 = $fit->{'fitted.values'};					   # mu
	for my $k (sort keys %$fv) {
		is_approx($resp->{$k}, $fv->{$k}, "glm response round-trip row $k");
		is_approx($resp->{$k}, 1 / (1 + exp(-$link->{$k})), "glm response = logistic(link) row $k");
	}
}

#--------
# factors: raw categorical columns are expanded from xlevels
#--------
{
	my $fit = glm(formula => 'survived ~ age + class + gender', data => $titanic, family => 'binomial');

	# raw class/gender (not pre-expanded dummies) now predict a real probability
	my $p = predict($fit, { age => [90], class => ['3rd'], gender => ['male'] });
	ok($p->{1} == $p->{1}, 'raw factor columns -> finite prediction (not NaN)');
	ok($p->{1} >= 0 && $p->{1} <= 1, 'factor prediction is a probability');

	# a flat single-row hash with raw factor values agrees with the 1-row HoA
	my $flat = predict($fit, { age => 90, class => '3rd', gender => 'male' });
	is_approx($flat->{1}, $p->{1}, 'flat hash matches the 1-row HoA for factors');

	# reference levels (first sorted: class '1st', gender 'female') predict fine
	ok(defined predict($fit, { age => 30, class => '1st', gender => 'female' })->{1},
		'reference factor levels predict without dying');

	# round-trip with factors reproduces fitted.values
	my $pred = predict($fit, $titanic);
	my $fv	 = $fit->{'fitted.values'};
	my $ok = 1;
	$ok = 0 for grep { abs($pred->{$_} - $fv->{$_}) > 1e-7 } keys %$fv;
	ok($ok, 'glm factor round-trip reproduces fitted.values');
}

#--------
# clean deaths: unseen factor level, missing factor column, missing column
#--------
{
	my $fit = glm(formula => 'survived ~ age + class + gender', data => $titanic, family => 'binomial');
	throws_ok { predict($fit, { age => 30, class => '4th', gender => 'male' }) }
		qr/unseen level '4th'/, 'an unseen factor level dies';
	throws_ok { predict($fit, { age => 30, gender => 'male' }) }
		qr/missing factor column 'class'/, 'a missing factor column dies';
	throws_ok { predict($fit, { class => '3rd', gender => 'male' }) }
		qr/missing column 'age'/, 'a missing continuous column dies';
}

#--------
# a missing value (column present, undef) still yields a NaN prediction
#--------
{
	my $model = { coefficients => { Intercept => 0, w => 1 } };
	my $p = predict($model, { w => [undef] });	 # column 'w' present, value missing
	ok($p->{1} != $p->{1}, 'a missing value -> NaN prediction');
}

#--------
# no newdata returns the model's fitted values
#--------
{
	my $fit = lm(formula => 'y ~ x', data => { x => [1, 2, 3], y => [2, 4, 6] });
	is_deeply(predict($fit), $fit->{'fitted.values'}, 'no newdata -> fitted.values');
}

#--------
# AoH and HoH input round-trip
#--------
{
	my $aoh = [ { x => 1, y => 3 }, { x => 2, y => 5 }, { x => 3, y => 7 } ];
	my $fit = lm(formula => 'y ~ x', data => $aoh);
	my $p	= predict($fit, $aoh);
	my $fv	= $fit->{'fitted.values'};
	is_approx($p->{$_}, $fv->{$_}, "AoH round-trip row $_") for sort keys %$fv;

	my $hoh = { a => { x => 1, y => 3 }, b => { x => 2, y => 5 }, c => { x => 3, y => 7 } };
	my $fitH = lm(formula => 'y ~ x', data => $hoh);
	my $pH	 = predict($fitH, $hoh);
	my $fvH	 = $fitH->{'fitted.values'};
	is_approx($pH->{$_}, $fvH->{$_}, "HoH round-trip row $_") for sort keys %$fvH;
}

#--------
# errors
#--------
throws_ok { predict('scalar', { x => [1] }) } qr/must be a fitted/,
	'a non-hashref model dies';
throws_ok { predict({ coefficients => {} }, { x => [1] }, type => 'bogus') } qr/type must be/,
	'an invalid type dies';
throws_ok { predict({}, { x => [1] }) } qr/no 'coefficients'/,
	'a model without coefficients dies';
throws_ok { predict({ coefficients => { x => 1 } }, 'scalar') } qr/HoA|AoH|flat/,
	'non-ref newdata dies';
lives_ok { predict(lm(formula => 'y ~ x', data => { x => [1,2,3], y => [1,2,3] })) }
	'a well-formed call lives';

#--------
# memory
#--------
my $LEAK_FIT = lm(formula => 'y ~ x', data => { x => [1,2,3,4], y => [3,5,7,9] });
my $LEAK_GLM = glm(formula => 'survived ~ age + class + gender', data => $titanic, family => 'binomial');
no_leaks_ok {
	my $p = predict($LEAK_FIT, { x => [10, 20] });
} 'predict: no memory leaks on a normal prediction' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	my $p = predict($LEAK_GLM, { age => 90, class => '3rd', gender => 'male' });
} 'predict: no memory leaks expanding factors (flat hash)' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	my $p = predict($LEAK_FIT);
} 'predict: no memory leaks returning fitted.values' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	eval { predict({}, { x => [1] }) };
} 'predict: no memory leaks on a die path' unless $INC{'Devel/Cover.pm'};

done_testing;
