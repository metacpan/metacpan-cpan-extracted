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


# sqrt
Property {
	##[ x <- WithError ]##
	$Operator = 'sqrt';
	$IsUnstable = 0;
	my ($o1) = map {witherror(@$_)} ($x);
	return undef if grep {not defined} ($o1);

	my $res = $o1->sqrt();
	
	if ($o1->{num} < 0) {
		return 1 if not defined $res;
		return undef;
	}
	
	my $num = sqrt($o1->{num});
	# parms: err1||0, err2||0, n1, n2
	my $err_calc = sub { sqrt( ( $_[0]/(2*sqrt$_[2]) )**2 ) };

	return undef if not defined $res;
	return undef if not _INSTANCE($res, 'Number::WithError');

	if ( not numeq($res->{num}, $num) ) {
		diag("Result of $Operator is $res->{num}. Should be $num.");
	   	return undef;
	}

	test_err_calc($err_calc, $res, $o1, witherror(0)) or return undef;
	1
}, name => "sqrt() method" ;

Property {
	##[ x <- WithError ]##
	$Operator = 'sqrt';
	$IsUnstable = 0;
	my ($o1) = map {witherror(@$_)} ($x);
	return undef if grep {not defined} ($o1);

	my $res = sqrt($o1);
	
	if ($o1->{num} < 0) {
		return 1 if not defined $res;
		return undef;
	}
	
	my $num = sqrt($o1->{num});
	# parms: err1||0, err2||0, n1, n2
	my $err_calc = sub { sqrt( ( $_[0]/(2*sqrt$_[2]) )**2 ) };

	return undef if not defined $res;
	return undef if not _INSTANCE($res, 'Number::WithError');

	if ( not numeq($res->{num}, $num) ) {
		diag("Result of $Operator is $res->{num}. Should be $num.");
	   	return undef;
	}

	test_err_calc($err_calc, $res, $o1, witherror(0)) or return undef;
	1
}, name => "overload: sqrt" ;




# log
Property {
	##[ x <- WithError ]##
	$Operator = 'log';
	$IsUnstable = 1;
	my ($o1) = map {witherror(@$_)} ($x);
	return undef if grep {not defined} ($o1);

	my $res = $o1->log();
	
	if ($o1->{num} < 0) {
		return 1 if not defined $res;
		return undef;
	}
	
	my $num = log($o1->{num});
	# parms: err1||0, err2||0, n1, n2
	my $err_calc = sub { sqrt( ( $_[0]/$_[2] )**2 ) };

	return undef if not defined $res;
	return undef if not _INSTANCE($res, 'Number::WithError');

	if ( not numeq($res->{num}, $num) ) {
		diag("Result of $Operator is $res->{num}. Should be $num.");
	   	return undef;
	}

	test_err_calc($err_calc, $res, $o1, witherror(0)) or return undef;
	1
}, name => "log() method" ;

Property {
	##[ x <- WithError ]##
	$Operator = 'log';
	$IsUnstable = 1;
	my ($o1) = map {witherror(@$_)} ($x);
	return undef if grep {not defined} ($o1);

	my $res = log($o1);
	
	if ($o1->{num} < 0) {
		return 1 if not defined $res;
		return undef;
	}
	
	my $num = log($o1->{num});
	# parms: err1||0, err2||0, n1, n2
	my $err_calc = sub { sqrt( ( $_[0]/$_[2] )**2 ) };

	return undef if not defined $res;
	return undef if not _INSTANCE($res, 'Number::WithError');

	if ( not numeq($res->{num}, $num) ) {
		diag("Result of $Operator is $res->{num}. Should be $num.");
	   	return undef;
	}

	test_err_calc($err_calc, $res, $o1, witherror(0)) or return undef;
	1
}, name => "overload: log" ;








# sin
Property {
	##[ x <- WithError ]##
	$Operator = 'sin';
	$IsUnstable = 0;
	my ($o1) = map {witherror(@$_)} ($x);
	return undef if grep {not defined} ($o1);

	my $res = $o1->sin();
	my $num = sin($o1->{num});
	# parms: err1||0, err2||0, n1, n2
	my $err_calc = sub { sqrt( ( $_[0]*cos($_[2]) )**2 ) };

	return undef if not defined $res;
	return undef if not _INSTANCE($res, 'Number::WithError');

	if ( not numeq($res->{num}, $num) ) {
		diag("Result of $Operator is $res->{num}. Should be $num.");
	   	return undef;
	}

	test_err_calc($err_calc, $res, $o1, witherror(0)) or return undef;
	1
}, name => "sin() method" ;

Property {
	##[ x <- WithError ]##
	$Operator = 'sin';
	$IsUnstable = 0;
	my ($o1) = map {witherror(@$_)} ($x);
	return undef if grep {not defined} ($o1);

	my $res = sin($o1);
	my $num = sin($o1->{num});
	# parms: err1||0, err2||0, n1, n2
	my $err_calc = sub { sqrt( ( $_[0]*cos($_[2]) )**2 ) };

	return undef if not defined $res;
	return undef if not _INSTANCE($res, 'Number::WithError');

	if ( not numeq($res->{num}, $num) ) {
		diag("Result of $Operator is $res->{num}. Should be $num.");
	   	return undef;
	}

	test_err_calc($err_calc, $res, $o1, witherror(0)) or return undef;
	1
}, name => "overload: sin" ;




# cos
Property {
	##[ x <- WithError ]##
	$Operator = 'cos';
	$IsUnstable = 0;
	my ($o1) = map {witherror(@$_)} ($x);
	return undef if grep {not defined} ($o1);

	my $res = $o1->cos();
	my $num = cos($o1->{num});
	# parms: err1||0, err2||0, n1, n2
	my $err_calc = sub { sqrt( ( $_[0]*sin($_[2]) )**2 ) };

	return undef if not defined $res;
	return undef if not _INSTANCE($res, 'Number::WithError');

	if ( not numeq($res->{num}, $num) ) {
		diag("Result of $Operator is $res->{num}. Should be $num.");
	   	return undef;
	}

	test_err_calc($err_calc, $res, $o1, witherror(0)) or return undef;
	1
}, name => "cos() method" ;

Property {
	##[ x <- WithError ]##
	$Operator = 'cos';
	$IsUnstable = 0;
	my ($o1) = map {witherror(@$_)} ($x);
	return undef if grep {not defined} ($o1);

	my $res = cos($o1);
	my $num = cos($o1->{num});
	# parms: err1||0, err2||0, n1, n2
	my $err_calc = sub { sqrt( ( $_[0]*sin($_[2]) )**2 ) };

	return undef if not defined $res;
	return undef if not _INSTANCE($res, 'Number::WithError');

	if ( not numeq($res->{num}, $num) ) {
		diag("Result of $Operator is $res->{num}. Should be $num.");
	   	return undef;
	}

	test_err_calc($err_calc, $res, $o1, witherror(0)) or return undef;
	1
}, name => "overload: cos" ;





# tan
Property {
	##[ x <- WithError ]##
	$Operator = 'tan';
	$IsUnstable = 1;
	my ($o1) = map {witherror(@$_)} ($x);
	return undef if grep {not defined} ($o1);

	$tcon->retry() if cos($o1->{num}) == 0;
	
	my $res = $o1->tan();
	my $num = sin($o1->{num}) / cos($o1->{num});
	# parms: err1||0, err2||0, n1, n2
	my $err_calc = sub { sqrt( ( $_[0]/cos($_[2])**2 )**2 ) };

	return undef if not defined $res;
	return undef if not _INSTANCE($res, 'Number::WithError');

	if ( not numeq($res->{num}, $num) ) {
		diag("Result of $Operator is $res->{num}. Should be $num.");
	   	return undef;
	}

	test_err_calc($err_calc, $res, $o1, witherror(0)) or return undef;
	1
}, name => "tan() method" ;






# abs
Property {
	##[ x <- WithError ]##
	$Operator = 'abs';
	$IsUnstable = 0;
	my ($o1) = map {witherror(@$_)} ($x);
	return undef if grep {not defined} ($o1);

	my $res = $o1->abs();
	my $num = abs($o1->{num});
	# parms: err1||0, err2||0, n1, n2
	my $err_calc = sub { $_[0] };

	return undef if not defined $res;
	return undef if not _INSTANCE($res, 'Number::WithError');

	if ( not numeq($res->{num}, $num) ) {
		diag("Result of $Operator is $res->{num}. Should be $num.");
	   	return undef;
	}

	test_err_calc($err_calc, $res, $o1, witherror(0)) or return undef;
	1
}, name => "abs() method" ;

Property {
	##[ x <- WithError ]##
	$Operator = 'abs';
	$IsUnstable = 0;
	my ($o1) = map {witherror(@$_)} ($x);
	return undef if grep {not defined} ($o1);

	my $res = abs($o1);
	my $num = abs($o1->{num});
	# parms: err1||0, err2||0, n1, n2
	my $err_calc = sub { $_[0] };

	return undef if not defined $res;
	return undef if not _INSTANCE($res, 'Number::WithError');

	if ( not numeq($res->{num}, $num) ) {
		diag("Result of $Operator is $res->{num}. Should be $num.");
	   	return undef;
	}

	test_err_calc($err_calc, $res, $o1, witherror(0)) or return undef;
	1
}, name => "overload: abs" ;



























1;
