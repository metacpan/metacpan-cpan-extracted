#line 1
# $Id$
package Test::Data::Scalar;
use strict;

use base qw(Exporter);
use vars qw(@EXPORT $VERSION);

@EXPORT = qw(
	blessed_ok defined_ok dualvar_ok greater_than length_ok
	less_than maxlength_ok minlength_ok number_ok
	readonly_ok ref_ok ref_type_ok strong_ok tainted_ok
	untainted_ok weak_ok undef_ok number_between_ok
	string_between_ok
	);

$VERSION = '1.22';

use Scalar::Util;
use Test::Builder;

my $Test = Test::Builder->new();

#line 44

sub blessed_ok ($;$)
	{
	my $ref  = ref $_[0];
	my $ok   = Scalar::Util::blessed($_[0]);
	my $name = $_[1] || 'Scalar is blessed';

	$Test->diag("Expected a blessed value, but didn't get it\n\t" .
		qq|Reference type is "$ref"\n| ) unless $ok;

	$Test->ok( $ok, $name );
	}

#line 62

sub defined_ok ($;$)
	{
	my $ok   = defined $_[0];
	my $name = $_[1] || 'Scalar is defined';

	$Test->diag("Expected a defined value, got an undefined one\n", $name )
		unless $ok;

	$Test->ok( $ok, $name );
	}

#line 79

sub undef_ok ($;$)
	{
	my $name = $_[1] || 'Scalar is undefined';

	if( @_ > 0 )
		{
		my $ok   = not defined $_[0];

		$Test->diag("Expected an undefined value, got a defined one\n")
			unless $ok;

		$Test->ok( $ok, $name );
		}
	else
		{
		$Test->diag("Expected an undefined value, but got no arguments\n");

		$Test->ok( 0, $name );
		}
	}

#line 119

#line 125

sub greater_than ($$;$)
	{
	my $value = shift;
	my $bound = shift;
	my $name  = shift || 'Scalar is greater than bound';

	my $ok = $value > $bound;

	$Test->diag("Number is less than the bound.\n\t" .
		"Expected a number greater than [$bound]\n\t" .
		"Got [$value]\n") unless $ok;

	$Test->ok( $ok, $name );
	}

#line 146

sub length_ok ($$;$)
	{
	my $string = shift;
	my $length = shift;
	my $name   = shift || 'Scalar has right length';

	my $actual = length $string;
	my $ok = $length == $actual;

	$Test->diag("Length of value not within bounds\n\t" .
		"Expected length=[$length]\n\t" .
		"Got [$actual]\n") unless $ok;

	$Test->ok( $ok, $name );
	}

#line 168

sub less_than ($$;$)
	{
	my $value = shift;
	my $bound = shift;
	my $name  = shift || 'Scalar is less than bound';

	my $ok = $value < $bound;

	$Test->diag("Number is greater than the bound.\n\t" .
		"Expected a number less than [$bound]\n\t" .
		"Got [$value]\n") unless $ok;

	$Test->ok( $ok, $name );
	}

#line 189

sub maxlength_ok($$;$)
	{
	my $string = shift;
	my $length = shift;
	my $name   = shift || 'Scalar length is less than bound';

	my $actual = length $string;
	my $ok = $actual <= $length;

	$Test->diag("Length of value longer than expected\n\t" .
		"Expected max=[$length]\n\tGot [$actual]\n") unless $ok;

	$Test->ok( $ok, $name );
	}

#line 210

sub minlength_ok($$;$)
	{
	my $string = shift;
	my $length = shift;
	my $name   = shift || 'Scalar length is greater than bound';

	my $actual = length $string;
	my $ok = $actual >= $length;

	$Test->diag("Length of value shorter than expected\n\t" .
		"Expected min=[$length]\n\tGot [$actual]\n") unless $ok;

	$Test->ok( $ok, $name );
	}

#line 235

sub number_ok($;$)
	{
	my $number = shift;
	my $name   = shift || 'Scalar is a number';

	$number =~ /\D/ ? $Test->ok( 0, $name ) : $Test->ok( 1, $name );
	}

#line 254

sub number_between_ok($$$;$)
	{
	my $number = shift;
	my $lower  = shift;
	my $upper  = shift;
	my $name   = shift || 'Scalar is in numerical range';

	unless( defined $lower and defined $upper )
		{
		$Test->diag("You need to define LOWER and UPPER bounds " .
			"to use number_between_ok" );
		$Test->ok( 0, $name );
		}
	elsif( $upper < $lower )
		{
		$Test->diag(
			"Upper bound [$upper] is lower than lower bound [$lower]" );
		$Test->ok( 0, $name );
		}
	elsif( $number >= $lower and $number <= $upper )
		{
		$Test->ok( 1, $name );
		}
	else
		{
		$Test->diag( "Number [$number] was not within bounds\n",
			"\tExpected lower bound [$lower]\n",
			"\tExpected upper bound [$upper]\n" );
		$Test->ok( 0, $name );
		}
	}

#line 293

sub string_between_ok($$$;$)
	{
	my $string = shift;
	my $lower  = shift;
	my $upper  = shift;
	my $name   = shift || 'Scalar is in string range';

	unless( defined $lower and defined $upper )
		{
		$Test->diag("You need to define LOWER and UPPER bounds " .
			"to use string_between_ok" );
		$Test->ok( 0, $name );
		}
	elsif( $upper lt $lower )
		{
		$Test->diag(
			"Upper bound [$upper] is lower than lower bound [$lower]" );
		$Test->ok( 0, $name );
		}
	elsif( $string ge $lower and $string le $upper )
		{
		$Test->ok( 1, $name );
		}
	else
		{
		$Test->diag( "String [$string] was not within bounds\n",
			"\tExpected lower bound [$lower]\n",
			"\tExpected upper bound [$upper]\n" );
		$Test->ok( 0, $name );
		}

	}

#line 332

sub readonly_ok($;$)
	{
	my $ok   = not Scalar::Util::readonly( $_[0] );
	my $name = $_[1] || 'Scalar is read-only';

	$Test->diag("Expected readonly reference, got writeable one\n")
		unless $ok;

	$Test->ok( $ok, $name );
	}

#line 349

sub ref_ok($;$)
	{
	my $ok   = ref $_[0];
	my $name = $_[1] || 'Scalar is a reference';

	$Test->diag("Expected reference, didn't get it\n")
		unless $ok;

	$Test->ok( $ok, $name );
	}

#line 366

sub ref_type_ok($$;$)
	{
	my $ref1 = ref $_[0];
	my $ref2 = ref $_[1];
	my $ok = $ref1 eq $ref2;
	my $name = $_[2] || 'Scalar is right reference type';

	$Test->diag("Expected references to match\n\tGot $ref1\n\t" .
		"Expected $ref2\n")	unless $ok;

	ref $_[0] eq ref $_[1] ? $Test->ok( 1, $name ) : $Test->ok( 0, $name );
	}

#line 385

sub strong_ok($;$)
	{
	my $ok   = not Scalar::Util::isweak( $_[0] );
	my $name = $_[1] || 'Scalar is not a weak reference';

	$Test->diag("Expected strong reference, got weak one\n")
		unless $ok;

	$Test->ok( $ok, $name );
	}

#line 406

sub tainted_ok($;$)
	{
	my $ok   = Scalar::Util::tainted( $_[0] );
	my $name = $_[1] || 'Scalar is tainted';

	$Test->diag("Expected tainted data, got untainted data\n")
		unless $ok;

	$Test->ok( $ok, $name );
	}

#line 423

sub untainted_ok($;$)
	{
	my $ok = not Scalar::Util::tainted( $_[0] );
	my $name = $_[1] || 'Scalar is not tainted';

	$Test->diag("Expected untainted data, got tainted data\n")
		unless $ok;

	$Test->ok( $ok, $name );
	}

#line 440

sub weak_ok($;$)
	{
	my $ok = Scalar::Util::isweak( $_[0] );
	my $name = $_[1] || 'Scalar is a weak reference';

	$Test->diag("Expected weak reference, got stronge one\n")
		unless $ok;

	$Test->ok( $ok, $name );
	}

#line 488


"The quick brown fox jumped over the lazy dog";
