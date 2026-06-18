#!/usr/bin/env perl
# Regression tests for the bugs fixed in lm:
#   * HoH input validated only the first row, then blindly dereferenced the
#     rest -- a non-hashref row must now die cleanly
#   * the 0-degrees-of-freedom path (which also leaked the row-name strings)
#     must croak
#   * the formula was copied into a fixed 512-byte buffer and the `.`-expansion
#     into a fixed 2048-byte buffer; long formulas were silently truncated.
#     They must no longer truncate.
#   * a clean fit still produces the right coefficients
require 5.010;
use warnings FATAL => 'all';
use Scalar::Util 'looks_like_number';
use Stats::LikeR;
use Test::Exception;
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

# A perfectly linear relationship y = 2x + 1, so the fit is exact and easy to
# assert: intercept 1, slope 2, R^2 = 1.
my %line = (x => [1, 2, 3, 4], 'y' => [3, 5, 7, 9]);

# BUG: only the first HoH row was validated; a later non-hashref row used to be
# dereferenced blindly. Every row must now be checked.
{
	my $bad_hoh = {
		r1 => { x => 1, 'y' => 3 },
		r2 => 5,                       # not a hashref
		r3 => { x => 3, 'y' => 7 },
	};
	throws_ok { lm(formula => 'y ~ x', data => $bad_hoh) } qr/HashRef/,
		'HoH with a non-hashref row dies (every row validated)';
}

#
# BUG: the 0-df path (parameters >= observations) used to leak the committed
# row-name strings. It must croak.
#
{
	# 2 observations, 3 parameters (Intercept + x + z)
	my %tiny = (x => [1, 2], z => [3, 4], y => [5, 6]);
	throws_ok { lm(formula => 'y ~ x + z', data => \%tiny) } qr/0 degrees of freedom/,
		'parameters >= observations croaks (0 df)';
}

#
# BUG: fixed-size formula buffer (512) truncated long formulas, so a long
# column name was clipped and then "not found", collapsing the fit. A long
# name must now round-trip intact.
#
{
	my $long = 'x' x 600;              # far longer than the old 512-byte buffer
	my %data = ($long => [1, 2, 3, 4], y => [2, 4, 6, 8]);   # y = 2 * long
	my $res;
	lives_ok { $res = lm(formula => "y ~ $long", data => \%data) }
		'long column name does not truncate / collapse the model';
	ok exists $res->{coefficients}{$long}, 'long-named term survived in coefficients';
	is_approx $res->{coefficients}{$long}, 2.0, 'long-named coefficient is correct', 1e-6;
	is_approx $res->{'r.squared'}, 1.0, 'perfect fit on the long-named predictor', 1e-9;
}

# ---------------------------------------------------------------------------
# BUG: the `.`-expansion buffer (2048) silently dropped expanded terms. With
# many predictors, every one must still appear in the model.
# ---------------------------------------------------------------------------
{
	my $ncol = 50;                     # 50 long names overflow the old 2048 buffer
	my $nrow = 60;                     # rows > params, so no 0-df croak
	my %data;
	my @cols;
	for my $c (1 .. $ncol) {
		my $name = sprintf('predictor_with_a_long_name_%03d', $c);   # ~30 chars
		push @cols, $name;
		$data{$name} = [ map { ($_ + 1) * $c + ($_ % 5) } 0 .. $nrow - 1 ];
	}
	$data{y} = [ map { $_ + 1 } 0 .. $nrow - 1 ];
	my $rhs = join ' + ', @cols;
	my $res;
	lives_ok { $res = lm(formula => "y ~ $rhs", data => \%data) }
		'many long predictor names do not overflow the expansion buffer';
	is scalar(@{ $res->{terms} }), $ncol + 1,
		"all $ncol predictors plus the intercept are present (no truncation)";
}

# ---------------------------------------------------------------------------
# A clean fit still produces the documented results.
# ---------------------------------------------------------------------------
{
	my $res = lm(formula => 'y ~ x', data => \%line);
	is ref($res), 'HASH', 'lm returns a hash ref';
	is_approx $res->{coefficients}{Intercept}, 1.0, 'intercept', 1e-9;
	is_approx $res->{coefficients}{x},         2.0, 'slope',     1e-9;
	is_approx $res->{'r.squared'},             1.0, 'R^2 = 1 for an exact line', 1e-9;
}

# ---------------------------------------------------------------------------
# Leak guards (SV-level; see the oneway_test note about C-buffer leaks).
# ---------------------------------------------------------------------------
{
	no_leaks_ok { lm(formula => 'y ~ x', data => \%line) } 'no SV leak on a successful fit' unless $INC{'Devel/Cover.pm'};
	no_leaks_ok { eval { lm(formula => 'y ~ x + z', data => {x=>[1,2],z=>[3,4],'y'=>[5,6]}) } }
		'no SV leak on the 0-df croak path' unless $INC{'Devel/Cover.pm'};
}

done_testing;
