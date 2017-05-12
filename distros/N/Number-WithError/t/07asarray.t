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

use Test::More tests => 64;


#####################################################################

use Number::WithError qw/:all/;

my @test_args = (
	{
		name => 'integer',
		args => [qw(5)],
		obj  => { num => '5', errors => [] },
	},
	{
		name => 'decimal',
		args => [qw(0.1)],
		obj  => { num => '0.1', errors => [] },
	},
	{
		name => 'scientific',
		args => [qw(0.001e-15)],
		obj  => { num => '0.001e-15', errors => [] },
	},
	{
		name => 'scientific with error',
		args => [qw(155e2 12)],
		obj  => { num => '155e2', errors => [12] },
	},
	{
		name => 'integer with 3 errors',
		args => [qw(5 0 3 1.2)],
		obj  => { num => '5', errors => [0, 3, 1.2] },
	},
	{
		name => 'decimal with 4 errors',
		args => [qw(0.1 0.1 0.1 0.1 0.1)],
		obj  => { num => '0.1', errors => [0.1, 0.1, 0.1, 0.1] },
	},
	{
		name => 'scientific with 3 errors incl unbalanced',
		args => [qw(3.4e5 2), [0.3, 0.5], 2],
		obj  => { num => '3.4e5', errors => [2, [0.3,0.5], 2] },
	},
	{
		name => 'decimal with undef error and 1 error',
		args => [qw(.4), undef, 0.1],
		obj  => { num => '0.4', errors => [undef, 0.1] },
	},
	{
		name => 'string with 1 error',
		args => ['2.0e-3 +/- 0.1e-3'],
		obj  => { num => '2.0e-3', errors => [0.1e-3] },
	},
	{
		name => 'string with 1 error (2)',
		args => ['2.0e-3+/-0.1e-3'],
		obj  => { num => '2.0e-3', errors => [0.1e-3] },
	},
	{
		name => 'string with 1 error (3)',
		args => ['2.0e-3+ /-0.1e-3'],
		obj  => { num => '2.0e-3', errors => [0.1e-3] },
	},
	{
		name => 'string with 1 error (4)',
		args => ['2.0e-3+/- 0.1e-3'],
		obj  => { num => '2.0e-3', errors => [0.1e-3] },
	},
	{
		name => 'string with 2 errors',
		args => ['2.0e-3 +/-0.1e-3+/--0.3e+1'],
		obj  => { num => '2.0e-3', errors => [0.1e-3, 0.3e+1] },
	},
	{
		name => 'string with 2 errors incl unbalanced',
		args => ['2.0e-3 +/- 0.1e-3 +0.15e-3 -0.01e-3'],
		obj  => { num => '2.0e-3', errors => [0.1e-3, [0.15e-3, 0.01e-3]]},
	},
	{
		name => 'string with 2 errors incl unbalanced (2)',
		args => ['2.0e-3 +/- 0.1e-3 -0.15e-3+0.01e-3'],
		obj  => { num => '2.0e-3', errors => [0.1e-3, [0.01e-3, 0.15e-3]]},
	},
	{
		name => 'string with 2 errors incl unbalanced (3)',
		args => ['2.0e-3+/-0.1e-3+0.15e-3-0.01e-3'],
		obj  => { num => '2.0e-3', errors => [0.1e-3, [0.15e-3, 0.01e-3]]},
	},
);

use Math::BigFloat;

foreach my $t (@test_args) {
	my $obj = $t->{obj};
	my $o = witherror($obj->{num}, @{$obj->{errors}});
	isa_ok($o, 'Number::WithError');
	my $ary = [$o->as_array];
	ok(@$ary == 1+@{$o->{errors}});
	my $o2 = witherror(@$ary);
	ok($o == $o2);
	ok($o eq $o2);
}

1;

