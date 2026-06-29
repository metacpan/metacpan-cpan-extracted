#!/usr/bin/env perl
require 5.010;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::Exception; # dies_ok
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

# predict() on the training predictors must reproduce the stored fitted.values
sub predict_matches_fit {
	my ($model, $newdata, $test_name, $epsilon) = @_;
	$epsilon = 1e-7 if not defined $epsilon;
	my $pred = predict($model, $newdata);
	my $fit  = $model->{'fitted.values'};
	my $ok = 1;
	foreach my $k (sort keys %$fit) {
		if (not defined $pred->{$k} or abs($pred->{$k} - $fit->{$k}) > $epsilon) {
			$ok = 0;
			diag("row $k: pred=" . (defined $pred->{$k} ? $pred->{$k} : 'undef') . " fit=$fit->{$k}");
		}
	}
	ok($ok, $test_name);
}

#--------
# models fitted via aov
#--------
my %oneway = (y => [1, 2, 3, 4, 5, 6, 7, 8, 9], g => [qw(A A A B B B C C C)]);
my %reg    = (y => [1, 3, 5],                    x => [0, 1, 2]);
my %twoway = (
	A => [qw(a1 a1 a1 a1 a2 a2 a2 a2)],
	B => [qw(b1 b1 b2 b2 b1 b1 b2 b2)],
	y => [10, 10, 12, 12, 20, 20, 30, 30],
);
# factor x continuous: g1: y = 1 + 2x ; g2: y = 3 + 5x
my %fxc = (
	g => [qw(g1 g1 g1 g2 g2 g2)],
	x => [0, 1, 2, 0, 1, 2],
	y => [1, 3, 5, 3, 8, 13],
);
# continuous x continuous: y = 1 + 2x + 3z + 4xz
my %cxc = (
	x => [0, 1, 0, 1, 2, 1],
	z => [0, 0, 1, 1, 1, 2],
	y => [1, 3, 4, 10, 16, 17],
);

my $m_oneway = aov(\%oneway, 'y~g');
my $m_reg    = aov(\%reg,    'y~x');
my $m_two    = aov(\%twoway, 'y~A*B');
my $m_fxc    = aov(\%fxc,    'y~g*x');
my $m_cxc    = aov(\%cxc,    'y~x*z');

#--------
# round-trips: predict(training) == fitted.values
#--------
predict_matches_fit($m_oneway, \%oneway, 'round-trip: one-way factor');
predict_matches_fit($m_reg,    \%reg,    'round-trip: simple regression');
predict_matches_fit($m_two,    \%twoway, 'round-trip: factor x factor interaction', 1e-6);
predict_matches_fit($m_fxc,    \%fxc,    'round-trip: factor x continuous interaction', 1e-6);
predict_matches_fit($m_cxc,    \%cxc,    'round-trip: continuous x continuous interaction', 1e-6);

#--------
# explicit predicted values
#--------
{
	my $p = predict($m_oneway, { g => [qw(A B C)] });
	is_approx($p->{1}, 2, 'one-way predict A');
	is_approx($p->{2}, 5, 'one-way predict B');
	is_approx($p->{3}, 8, 'one-way predict C');
}
{
	my $p = predict($m_reg, { x => [0, 1, 2, 3] });
	is_approx($p->{1}, 1, 'reg predict x=0');
	is_approx($p->{4}, 7, 'reg predict x=3 (extrapolation)');
}
{
	my $p = predict($m_two, { A => [qw(a1 a2)], B => [qw(b1 b2)] });
	is_approx($p->{1}, 10, 'two-way predict a1,b1', 1e-6);
	is_approx($p->{2}, 30, 'two-way predict a2,b2', 1e-6);
}
{
	my $p = predict($m_two, { A => ['a2'], B => ['b1'] });
	is_approx($p->{1}, 20, 'two-way predict a2,b1 (cross cell)', 1e-6);
}
{
	my $p = predict($m_fxc, { g => [qw(g2 g1)], x => [1, 2] });
	is_approx($p->{1}, 8, 'fxc predict g2,x=1', 1e-6); # 3 + 5*1
	is_approx($p->{2}, 5, 'fxc predict g1,x=2', 1e-6); # 1 + 2*2
}
{
	my $p = predict($m_cxc, { x => [2], z => [1] });
	is_approx($p->{1}, 16, 'cxc predict x=2,z=1', 1e-6); # 1+4+3+8
}

#--------
# newdata shapes all agree (HoA / AoH / HoH / flat single row)
#--------
{
	my $hoa  = predict($m_reg, { x => [0, 2] });
	my $aoh  = predict($m_reg, [ { x => 0 }, { x => 2 } ]);
	my $hoh  = predict($m_reg, { a => { x => 0 }, b => { x => 2 } });
	my $flat = predict($m_reg, { x => 0 });

	is_approx($hoa->{1},  1, 'HoA row 1');
	is_approx($hoa->{2},  5, 'HoA row 2');
	is_approx($aoh->{1},  1, 'AoH row 1');
	is_approx($aoh->{2},  5, 'AoH row 2');
	is_approx($hoh->{a},  1, 'HoH row a');
	is_approx($hoh->{b},  5, 'HoH row b');
	is_approx($flat->{1}, 1, 'flat single row');
}

#--------
# no newdata -> stored fitted.values returned
#--------
{
	my $p = predict($m_reg);
	my $f = $m_reg->{'fitted.values'};
	is_approx($p->{$_}, $f->{$_}, "no-newdata returns fitted.values [$_]") for sort keys %$f;
}

#--------
# binomial family: link vs response (hand-built model)
#--------
{
	my $glm = { family => 'binomial', coefficients => { Intercept => 0, x => 1 } };

	my $link = predict($glm, { x => [0, 2] }, type => 'link');
	is_approx($link->{1}, 0, 'binomial link x=0');
	is_approx($link->{2}, 2, 'binomial link x=2');

	my $resp = predict($glm, { x => [0, 2] }, type => 'response');
	is_approx($resp->{1}, 0.5,               'binomial response x=0');
	is_approx($resp->{2}, 1 / (1 + exp(-2)), 'binomial response x=2 (logistic)');
}

# gaussian: link and response coincide
{
	my $l = predict($m_reg, { x => [1] }, type => 'link');
	my $r = predict($m_reg, { x => [1] }, type => 'response');
	is_approx($l->{1}, 3, 'gaussian link = eta');
	is_approx($r->{1}, 3, 'gaussian response = eta (identity link)');
}

#--------
# error handling
#--------
throws_ok { predict(5, { x => [1] }) } qr/model must be/, 'non-hashref model croaks';
throws_ok { predict({}, { x => [1] }) } qr/coefficients/, 'model without coefficients croaks';
throws_ok { predict($m_reg, 5) } qr/newdata must be/, 'scalar newdata croaks';
throws_ok { predict($m_reg, { z => [1] }) } qr/missing column 'x'/, 'missing continuous column croaks';
throws_ok { predict($m_oneway, { x => [1] }) } qr/missing factor column 'g'/, 'missing factor column croaks';
throws_ok { predict($m_oneway, { g => ['Z'] }) } qr/unseen level/, 'unseen factor level croaks';
throws_ok { predict($m_reg, { x => [1] }, foo => 1) } qr/unknown argument/, 'unknown option croaks';
throws_ok { predict($m_reg, { x => [1] }, 'type') } qr/name => value pairs/, 'odd option list croaks';
throws_ok { predict($m_reg, { x => [1] }, type => 'bogus') } qr/type must be/, 'bad type value croaks';
throws_ok { predict($m_fxc, { g => ['g1'] }) } qr/missing column 'x'/, 'interaction missing continuous column croaks';

#--------
# leak checks
#--------
no_leaks_ok {
	eval { predict($m_oneway, { g => [qw(A B C)] }) }
} 'predict factor: no leaks' unless $INC{'Devel/Cover.pm'};
no_leaks_ok {
	eval { predict($m_two, \%twoway) }
} 'predict fxf interaction: no leaks' unless $INC{'Devel/Cover.pm'};
no_leaks_ok {
	eval { predict($m_fxc, \%fxc) }
} 'predict fxc interaction: no leaks' unless $INC{'Devel/Cover.pm'};
no_leaks_ok {
	eval { predict($m_oneway, { g => ['Z'] }) }
} 'predict croak path: no leaks' unless $INC{'Devel/Cover.pm'};

done_testing();
