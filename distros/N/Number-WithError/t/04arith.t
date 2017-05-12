#!/usr/bin/perl -w

# Tests for Number::WithError

use strict;
use lib ();
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		$FindBin::Bin = $FindBin::Bin; # Avoid a warning
		chdir catdir( $FindBin::Bin, updir() );
		lib->import(
			catdir('blib', 'lib'),
			'lib',
			);
	}
}


#####################################################################

use Number::WithError ':all';
use Params::Util qw/_INSTANCE/;
BEGIN {
	require Test::LectroTest;
   	if (defined $ENV{PERL_TEST_ATTEMPTS}) {
		Test::LectroTest->import(
			trials => $ENV{PERL_TEST_ATTEMPTS}+0,
			regressions => catdir('t', 'regression.txt')
		);
	}
	else {
		Test::LectroTest->import(
			trials => 100,
			regressions => catdir('t', 'regression.txt')
		);
	}
}

sub Error () {
	Frequency(
		[40, Float],
		[40, List(Float, 'length' => 2)],
		[10, List(Float, 'length' => 1)],
		[10, Unit(undef) ],
	)
}

sub WithError () {
	Concat(
		Float,
		List(
			Error,
			'length' => [0, 20]
		)
	)
}

sub WithErrorSmall () {
	Concat(
		Float(range=>[0..20]),
		List(
			Error,
			'length' => [0, 10]
		)
	)
}

sub max {
	my $max = $_[0];
	for (@_) {
		$max = $_ if $_ > $max;
	}
	return $max;
}

sub min {
	my $min = $_[0];
	for (@_) {
		$min = $_ if $_ < $min;
	}
	return $min;
}

use constant EPS => 1e-8;
use constant EPS_UNSTABLE => 1e-6;
my $IsUnstable = 0;

sub numeq ($$) {
	return undef if not defined $_[0] or not defined $_[1];
	if ($IsUnstable) {
		return abs($_[0]-$_[1]) < abs(EPS_UNSTABLE * min($_[0], $_[1])) + EPS;
	}
	return abs($_[0]-$_[1]) < EPS;
}

sub undef_or_eq ($$) {
	if (not defined $_[0]) {
		if (not defined $_[1]) {
			return 1;
		}
		else {
			return undef;
		}
	}
	elsif (not defined $_[1]) {
		return undef;
	}

	if ($IsUnstable) {
		return abs($_[0]-$_[1]) < abs(EPS_UNSTABLE * min($_[0], $_[1])) + EPS;
	}
	return abs($_[0]-$_[1]) < EPS;
}

sub diag {
	print "# " . join('', @_) . "\n";
}

sub test_err_calc {
	my $sub = shift;
	my $res = shift;
	my $o1 = shift;
	my $o2 = shift;

	if (not @{$res->{errors}} == max(scalar(@{$o1->{errors}}), scalar(@{$o2->{errors}}))) {
		diag(
			"Number of errors in result is ",
			scalar(@{$res->{errors}}),
			" but the expected number of errors is ",
		   	max( scalar(@{$o1->{errors}}), scalar(@{$o2->{errors}}) )
		);
		return undef;
	}
	
	foreach my $no (0..$#{$res->{errors}}) {
		my $e1 = $o1->{errors}[$no];
		my $e2 = $o2->{errors}[$no];
		my $eres = $res->{errors}[$no];
		
		if (ref($e1) eq 'ARRAY') {
			return undef if not ref($eres) eq 'ARRAY' and @{$e1}!=1;
			if (ref($e2) eq 'ARRAY') {
				for (0..1) {
					my $cmperr = $sub->($e1->[$_]||0, $e2->[$_]||0, $o1->{num}, $o2->{num});
					if (not numeq( $cmperr||0, $eres->[$_]||0 )) {
						diag(
							"Error number $no (both are arys) is in the result: ",
							$eres->[$_]||0, " The expected result is: ", $cmperr||0
						);
						return undef;
					}
				}
			}
			else {
				for (0..1) {
					my $cmperr = $sub->($e1->[$_]||0, $e2||0, $o1->{num}, $o2->{num});
					if (not numeq( $cmperr||0, $eres->[$_]||0 )) {
						diag(
							"Error number $no (err1 is ary) is in the result: ",
							$eres->[$_]||0, " The expected result is: ", $cmperr||0
						);
						return undef;
					}
				}
			}
		}
		elsif (ref($e2) eq 'ARRAY') {
			return undef if not ref($eres) eq 'ARRAY' and @{$e2} != 1;
			for (0..1) {
				my $cmperr = $sub->($e1||0, $e2->[$_]||0, $o1->{num}, $o2->{num});
				if (not numeq( $cmperr||0, $eres->[$_]||0 )) {
					diag(
						"Error number $no (err2 is ary) is in the result: ",
						$eres->[$_]||0, " The expected result is: ", $cmperr||0
					);
					return undef;
				}
			}
		}
		else {
			my $cmperr =  $sub->($e1||0, $e2||0, $o1->{num}, $o2->{num});
			if ( not numeq( $cmperr||0, $eres||0 ) ) {
				diag("Error number $no is in the result: ", $eres||0, " The expected result is: ", $cmperr||0);
				return undef;
			}
		}
	}
	return 1;
}

my $Operator;

# add
$Operator = 'addition';
Property {
	##[ x <- WithError, y <- WithError ]##
	$IsUnstable = 0;
	my ($o1, $o2) = map {witherror(@$_)} ($x, $y);
	return undef if grep {not defined} ($o1, $o2);

	my $res = $o1->add($o2);
	my $num = $o1->{num} + $o2->{num};
	# parms: err1||0, err2||0, n1, n2
	my $err_calc = sub { sqrt($_[0]**2 + $_[1]**2) };

	return undef if not defined $res;
	return undef if not _INSTANCE($res, 'Number::WithError');

	if ( not numeq($res->{num}, $num) ) {
		diag("Result of $Operator is $res->{num}. Should be $num.");
	   	return undef;
	}

	test_err_calc($err_calc, $res, $o1, $o2) or return undef;
	1
}, name => "add() method" ;

Property {
	##[ x <- WithError, y <- WithError ]##
	$IsUnstable = 0;
	my ($o1, $o2) = map {witherror(@$_)} ($x, $y);
	return undef if grep {not defined} ($o1, $o2);

	my $res = $o1 + $o2;
	my $num = $o1->{num} + $o2->{num};
	# parms: err1||0, err2||0, n1, n2
	my $err_calc = sub { sqrt($_[0]**2 + $_[1]**2) };

	return undef if not defined $res;
	return undef if not _INSTANCE($res, 'Number::WithError');

	if ( not numeq($res->{num}, $num) ) {
		diag("Result of $Operator is $res->{num}. Should be $num.");
	   	return undef;
	}

	test_err_calc($err_calc, $res, $o1, $o2) or return undef;
	1
}, name => "overload: +" ;

Property {
	##[ x <- WithError, y <- Float ]##
	$IsUnstable = 0;
	my ($o1, $o2) = map {witherror(ref($_)eq'ARRAY' ? @$_ : $_)} ($x, $y);
	return undef if grep {not defined} ($o1, $o2);

	my $res = $y + $o1;
	my $num = $y + $o1->{num};
	# parms: err1||0, err2||0, n1, n2
	my $err_calc = sub { sqrt($_[0]**2 + $_[1]**2) };
	
	return undef if not defined $res;
	return undef if not _INSTANCE($res, 'Number::WithError');

	if ( not numeq($res->{num}, $num) ) {
		diag("Result of $Operator is $res->{num}. Should be $num.");
	   	return undef;
	}

	test_err_calc($err_calc, $res, $o2, $o1) or return undef;
	1
}, name => "overload: +, number" ;



# subtract
$Operator = 'subtraction';
Property {
	##[ x <- WithError, y <- WithError ]##
	$IsUnstable = 0;
	my ($o1, $o2) = map {witherror(@$_)} ($x, $y);
	return undef if grep {not defined} ($o1, $o2);

	my $res = $o1->subtract($o2);
	my $num = $o1->{num} - $o2->{num};
	# parms: err1||0, err2||0, n1, n2
	my $err_calc = sub { sqrt($_[0]**2 + $_[1]**2) };

	return undef if not defined $res;
	return undef if not _INSTANCE($res, 'Number::WithError');

	if ( not numeq($res->{num}, $num) ) {
		diag("Result of $Operator is $res->{num}. Should be $num.");
	   	return undef;
	}

	test_err_calc($err_calc, $res, $o1, $o2) or return undef;
	1
}, name => "subtract() method" ;

Property {
	##[ x <- WithError, y <- WithError ]##
	$IsUnstable = 0;
	my ($o1, $o2) = map {witherror(@$_)} ($x, $y);
	return undef if grep {not defined} ($o1, $o2);

	my $res = $o1 - $o2;
	my $num = $o1->{num} - $o2->{num};
	# parms: err1||0, err2||0, n1, n2
	my $err_calc = sub { sqrt($_[0]**2 + $_[1]**2) };

	return undef if not defined $res;
	return undef if not _INSTANCE($res, 'Number::WithError');

	if ( not numeq($res->{num}, $num) ) {
		diag("Result of $Operator is $res->{num}. Should be $num.");
	   	return undef;
	}

	test_err_calc($err_calc, $res, $o1, $o2) or return undef;
	1
}, name => "overload: -" ;

Property {
	##[ x <- WithError, y <- Float ]##
	$IsUnstable = 0;
	my ($o1, $o2) = map {witherror(ref($_)eq'ARRAY' ? @$_ : $_)} ($x, $y);
	return undef if grep {not defined} ($o1, $o2);

	my $res = $y - $o1;
	my $num = $y - $o1->{num};
	# parms: err1||0, err2||0, n1, n2
	my $err_calc = sub { sqrt($_[0]**2 + $_[1]**2) };
	
	return undef if not defined $res;
	return undef if not _INSTANCE($res, 'Number::WithError');

	if ( not numeq($res->{num}, $num) ) {
		diag("Result of $Operator is $res->{num}. Should be $num.");
	   	return undef;
	}

	test_err_calc($err_calc, $res, $o2, $o1) or return undef;
	1
}, name => "overload: -, number" ;




# multiply
$Operator = 'multiplication';
Property {
	##[ x <- WithError, y <- WithError ]##
	$IsUnstable = 0;
	my ($o1, $o2) = map {witherror(@$_)} ($x, $y);
	return undef if grep {not defined} ($o1, $o2);

	my $res = $o1->multiply($o2);
	my $num = $o1->{num} * $o2->{num};
	# parms: err1||0, err2||0, n1, n2
	my $err_calc = sub { sqrt(($_[0]*$_[3])**2 + ($_[2]*$_[1])**2) };

	return undef if not defined $res;
	return undef if not _INSTANCE($res, 'Number::WithError');

	if ( not numeq($res->{num}, $num) ) {
		diag("Result of $Operator is $res->{num}. Should be $num.");
	   	return undef;
	}

	test_err_calc($err_calc, $res, $o1, $o2) or return undef;
	1
}, name => "multiply() method" ;

Property {
	##[ x <- WithError, y <- WithError ]##
	$IsUnstable = 0;
	my ($o1, $o2) = map {witherror(@$_)} ($x, $y);
	return undef if grep {not defined} ($o1, $o2);

	my $res = $o1 * $o2;
	my $num = $o1->{num} * $o2->{num};
	# parms: err1||0, err2||0, n1, n2
	my $err_calc = sub { sqrt(($_[0]*$_[3])**2 + ($_[2]*$_[1])**2) };
	
	return undef if not defined $res;
	return undef if not _INSTANCE($res, 'Number::WithError');

	if ( not numeq($res->{num}, $num) ) {
		diag("Result of $Operator is $res->{num}. Should be $num.");
	   	return undef;
	}

	test_err_calc($err_calc, $res, $o1, $o2) or return undef;
	1
}, name => "overload: *" ;

Property {
	##[ x <- WithError, y <- Float ]##
	$IsUnstable = 0;
	my ($o1, $o2) = map {witherror(ref($_)eq'ARRAY' ? @$_ : $_)} ($x, $y);
	return undef if grep {not defined} ($o1, $o2);

	my $res = $y * $o1;
	my $num = $y * $o1->{num};
	# parms: err1||0, err2||0, n1, n2
	my $err_calc = sub { sqrt(($_[0]*$_[3])**2 + ($_[2]*$_[1])**2) };
	
	return undef if not defined $res;
	return undef if not _INSTANCE($res, 'Number::WithError');

	if ( not numeq($res->{num}, $num) ) {
		diag("Result of $Operator is $res->{num}. Should be $num.");
	   	return undef;
	}

	test_err_calc($err_calc, $res, $o2, $o1) or return undef;
	1
}, name => "overload: *, number" ;




# divide
$Operator = 'division';
Property {
	##[ x <- WithError, y <- WithError ]##
	$IsUnstable = 0;
	my ($o1, $o2) = map {witherror(@$_)} ($x, $y);
	return undef if grep {not defined} ($o1, $o2);

	my $res = $o1->divide($o2);
	my $num = $o1->{num} / $o2->{num};
	# parms: err1||0, err2||0, n1, n2
	my $err_calc = sub { sqrt(($_[0]/$_[3])**2 + ($_[2]*$_[1]/$_[3]**2)**2) };

	return undef if not defined $res;
	return undef if not _INSTANCE($res, 'Number::WithError');

	if ( not numeq($res->{num}, $num) ) {
		diag("Result of $Operator is $res->{num}. Should be $num.");
	   	return undef;
	}

	test_err_calc($err_calc, $res, $o1, $o2) or return undef;
	1
}, name => "divide() method" ;

Property {
	##[ x <- WithError, y <- WithError ]##
	$IsUnstable = 0;
	my ($o1, $o2) = map {witherror(@$_)} ($x, $y);
	return undef if grep {not defined} ($o1, $o2);

	my $res = $o1 / $o2;
	my $num = $o1->{num} / $o2->{num};
	# parms: err1||0, err2||0, n1, n2
	my $err_calc = sub { sqrt(($_[0]/$_[3])**2 + ($_[2]*$_[1]/$_[3]**2)**2) };
	
	return undef if not defined $res;
	return undef if not _INSTANCE($res, 'Number::WithError');

	if ( not numeq($res->{num}, $num) ) {
		diag("Result of $Operator is $res->{num}. Should be $num.");
	   	return undef;
	}

	test_err_calc($err_calc, $res, $o1, $o2) or return undef;
	1
}, name => "overload: /" ;

Property {
	##[ x <- WithError, y <- Float ]##
	$IsUnstable = 0;
	my ($o1, $o2) = map {witherror(ref($_)eq'ARRAY' ? @$_ : $_)} ($x, $y);
	return undef if grep {not defined} ($o1, $o2);

	my $res = $y / $o1;
	my $num = $y / $o1->{num};
	# parms: err1||0, err2||0, n1, n2
	my $err_calc = sub { sqrt( $_[0]**2/$_[3]**2 + $_[2]**2*$_[1]**2/$_[3]**4 ) };

	return undef if not defined $res;
	return undef if not _INSTANCE($res, 'Number::WithError');

	if ( not numeq($res->{num}, $num) ) {
		diag("Result of $Operator is $res->{num}. Should be $num.");
	   	return undef;
	}

	test_err_calc($err_calc, $res, $o2, $o1) or return undef;
	1
}, name => "overload: /, number" ;




# exponentiate
$Operator = 'exponentiation';
Property {
	##[ x <- WithErrorSmall, y <- WithErrorSmall ]##
	$IsUnstable = 1;
	my ($o1, $o2) = map {witherror(@$_)} ($x, $y);
	return undef if grep {not defined} ($o1, $o2);
	
	$tcon->retry if $y->[0] > 10 or $x->[0] > 50 or $y->[0] < 0;
	
	my $res = $o1->exponentiate($o2);
	my $num = $o1->{num} ** $o2->{num};
	# parms: err1||0, err2||0, n1, n2
	my $err_calc = sub { sqrt( ($_[3]*$_[2]**($_[3]-1)*$_[0])**2 + (log($_[2])*$_[2]**$_[3]*$_[1])**2 ) };

	if ($o1->{num} < 0) {
		return 1 if not defined $res;
		return undef;
	}
	return undef if not defined $res;
	return undef if not _INSTANCE($res, 'Number::WithError');

	if ( not numeq($res->{num}, $num) ) {
		diag("Result of $Operator is $res->{num}. Should be $num.");
	   	return undef;
	}

	test_err_calc($err_calc, $res, $o1, $o2) or return undef;
	1
}, name => "exponentiate() method" ;

Property {
	##[ x <- WithErrorSmall, y <- WithErrorSmall ]##
	$IsUnstable = 1;
	my ($o1, $o2) = map {witherror(@$_)} ($x, $y);
	return undef if grep {not defined} ($o1, $o2);
	
	$tcon->retry if $y->[0] > 10 or $x->[0] > 50 or $y->[0] < 0;

	my $res = $o1 ** $o2;
	my $num = $o1->{num} ** $o2->{num};
	# parms: err1||0, err2||0, n1, n2
	my $err_calc = sub { sqrt( ($_[3]*$_[2]**($_[3]-1)*$_[0])**2 + (log($_[2])*$_[2]**$_[3]*$_[1])**2 ) };
	
	if ($o1->{num} < 0) {
		return 1 if not defined $res;
		return undef;
	}
	return undef if not defined $res;
	return undef if not _INSTANCE($res, 'Number::WithError');

	if ( not numeq($res->{num}, $num) ) {
		diag("Result of $Operator is $res->{num}. Should be $num.");
	   	return undef;
	}

	test_err_calc($err_calc, $res, $o1, $o2) or return undef;
	1
}, name => "overload: **" ;

Property {
	##[ x <- WithErrorSmall, y <- Float(range => [0,10]) ]##
	$IsUnstable = 1;
	my ($o1, $o2) = map {witherror(ref($_)eq'ARRAY' ? @$_ : $_)} ($x, $y);
	return undef if grep {not defined} ($o1, $o2);
	
	$tcon->retry if $y > 10 or $x->[0] > 50 or $y < 0;

	my $res = $y ** $o1;
	my $num = $y ** $o1->{num};
	# parms: err1||0, err2||0, n1, n2
	my $err_calc = sub { sqrt( ($_[3]*$_[2]**($_[3]-1)*$_[0])**2 + (log($_[2])*$_[2]**$_[3]*$_[1])**2 ) };

	if ($y < 0) {
		return 1 if not defined $res;
		return undef;
	}
	return undef if not defined $res;
	return undef if not _INSTANCE($res, 'Number::WithError');

	if ( not numeq($res->{num}, $num) ) {
		diag("Result of $Operator is $res->{num}. Should be $num.");
	   	return undef;
	}

	test_err_calc($err_calc, $res, $o2, $o1) or return undef;
	1
}, name => "overload: **, number" ;


















1;

