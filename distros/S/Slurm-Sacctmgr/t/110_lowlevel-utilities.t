#!/usr/bin/env perl 
#
# Before `make install' is performed this script should be runnable with
# `make test'.
# After `make install' it should work as `perl 110_lowlevel-utilities.t
#
# tests of low level utility routines

use strict;
use warnings;

use Test::More;

use Slurm::Sacctmgr::EntityBase;
use Slurm::Sacctmgr::EntityBaseRW;

my $ebase = 'Slurm::Sacctmgr::EntityBase';
my $ebrw = 'Slurm::Sacctmgr::EntityBaseRW';

our $num_tests_run = 0;

my ($rec, $name, $input, $got, $exp, $str2 );

#------------------------------------------------
#	Data conversion tests
#------------------------------------------------

#--------	_string2arrayref/ arrayref2string
my $tmparry1 = [ 'joe', 'steve', 'bob' ];
my $tmpstr1 = 'joe,steve,bob';
my @dataconv_str2array_tests = (
	# [ testname, string, array, str2 (what should get back ]
	[ 'test 1', $tmpstr1, $tmparry1, $tmpstr1 ],
	[ 'test 1 with spaces', '  joe ,  steve          ,bob      ', $tmparry1, $tmpstr1 ],
	[ 'test 1 whitespace', '  joe	,  steve          ,bob      ', $tmparry1, $tmpstr1 ],
	[ 'test 1 reordered', 'steve,bob,joe', [ 'steve', 'bob', 'joe' ], 'steve,bob,joe' ],
	[ 'test 1 duplicates', 'joe,steve,bob,joe', [ 'joe', 'steve', 'bob', 'joe' ], 
		'joe,steve,bob,joe' ],
);

foreach $rec (@dataconv_str2array_tests)
{	($name, $input, $exp, $str2) = @$rec;
	$got = $ebase->_string2arrayref($input);
	is_deeply($got, $exp, "Data conversion: _string2arrayref: $name");
	$num_tests_run++;
	$got = $ebase->_arrayref2string($exp);
	is($got,$str2, "Data conversion: _arrayref2string: $name");
	$num_tests_run++;
	$got = $ebase->_stringify_value($exp);
	is($got,$str2, "Data conversion: _stringify_value: $name");
	$num_tests_run++;
}

#--------	_string2hashref
my $tmphash1 = { cpu=>1000, node=>10, energy=>546.65, 'gres/gpu' => 7 };
$tmpstr1='cpu=1000,energy=546.65,gres/gpu=7,node=10'; #Always alphabetical by key/TRESname

my @dataconv_str2hash_tests = (
	# [ testname, string, array ]
	[ 'test hash 1', $tmpstr1, $tmphash1, $tmpstr1 ],
	[ 'test hash 1 (whitespace)', ' cpu=   1000  ,node	=10,	energy	=	546.65,	gres/gpu=7	', 
		$tmphash1, $tmpstr1 ],
	[ 'test hash 1 (reordered)', 'gres/gpu=7,cpu=1000,node=10,energy=546.65', $tmphash1, $tmpstr1 ],
);

foreach $rec (@dataconv_str2hash_tests)
{	($name, $input, $exp, $str2) = @$rec;
	$got = $ebase->_string2hashref($input);
	is_deeply($got, $exp, "Data conversion: _string2hashref: $name");
	$num_tests_run++;
	$got = $ebase->_hashref2string($exp);
	is($got,$str2, "Data conversion: _hashref2string: $name");
	$num_tests_run++;
	$got = $ebase->_stringify_value($exp);
	is($got,$str2, "Data conversion: _stringify_value: $name");
	$num_tests_run++;
}

#------------------------------------------------
#	_compare_values_deeply
#------------------------------------------------

my $tmpcomplex1 = 
	[ [ 1,2,4], undef, { a=> [1,2,7], b=>{ test1=>1, test2=>undef, test3=>['7e2', '8f3', '9g4'],  } }, 'hello' ];
my $tmpcomplex1b = 
	[ [ 1,2,4], undef, { a=> [1,2,7], b=>{ test1=>1, test2=>2,     test3=> [ '7e2', '8f3', '9g4'], } }, 'hello' ];
my $tmpcomplex2 = 
	{ xxx => [ 1,2,4], b => undef, c => { a=> [1,2,7], b=>{ test1=>1, test2=>undef, test3=>[] } }, x => 'hello' };
my $tmpcomplex2b = 
	{ xxx => [ 1,2,4], b => undef, c => { a=> [1,2,7], b=>{ test1=>3, test2=>undef, test3=>[] } }, x => 'hello' };

my @compvals_tests = (
	# name, val1, val2 , expected (boolean)
	[ 'undef==undef', undef, undef, 0 ],
	[ 'undef!=scalar', undef, 'aaa', 1 ],
	[ 'undef!=scalar', undef, 'aaa', 1 ],
	[ 'scalar!=undef', 'bbb', undef, 1 ],

	[ 'numeric comparison', '3.1416', '   +3.1416000   ', 0 ],
	[ 'numeric comparison 2', '   -3.14160000  ', '-3.14160', 0 ],
	[ 'numeric comparison 3', '   -.14  ', ' -0.14   ', 0 ],
	[ 'numeric comparison 4', '   .14  ', ' +0.14   ', 0 ],
	[ 'numeric comparison 5', '0', '  -0.000  ', 0 ],

	[ 'numeric-nonnum comparison 1', '0', ' -.  ', 1 ],
	[ 'numeric-nonnum comparison 2', 'one', '1', 1 ],
	[ 'numeric-nonnum comparison 3', '0', 'zero', 1 ],
	[ 'numeric-nonnum comparison 4', '7', '7e2', 1 ],
	[ 'numeric-nonnum comparison 5', '7', '7e0', 1 ], #We don't support scientific notation yet

	[ 'strings 1', 'aaa', 'aaa', 0 ],
	[ 'strings 1', 'aaa is not #43.67*3%',   'aaa is not #43.67*3%',  0 ],

	[ 'arrays 1', [ 'a', 'b', 'c', ], [ 'a', 'b', 'c' ], 0 ],
	[ 'arrays 2 (order)', [ 'c', 'b', 'a', ], [ 'a', 'b', 'c' ], 1 ],
	[ 'arrays 3 (repeats)', [ 'a', 'b', 'c', 'a' ], [ 'a', 'b', 'c', 'a' ], 0 ],
	[ 'arrays 4 (repeats 2)', [ 'a', 'b', 'c', 'a' ], [ 'a', 'b', 'c',  ], 1 ],
	[ 'arrays 5 (undef)', [ 'a', 'b', 'c', undef ], [ 'a', 'b', 'c'  ], 1 ],
	[ 'arrays 5 (undef2)', [ 'a', 'b', 'c', undef ], [ 'a', 'b', 'c', undef  ], 0 ],
	[ 'arrays 5 (null array)', [ ], [ ], 0 ],

	[ 'hashes 1', { a=>1, b=>2, c=>3 }, { a=>1, b=>2, c=>3 }, 0 ],
	[ 'hashes 1 (order)', { c=>3, b=>2, a=>1 }, { a=>1, b=>2, c=>3 }, 0 ],
	[ 'hashes 2', { c=>3, b=>2, a=>1, d=>4 }, { a=>1, b=>2, c=>3 }, 1 ],
	[ 'hashes 3', { c=>3, b=>2, d=>4 }, { a=>1, b=>2, c=>3 }, 1 ],
	[ 'hashes 4 (undef)', { c=>3, b=>2, d=>undef }, { a=>1, b=>2 }, 1 ],
	[ 'hashes 4 (undef2)', { a=>1, b=>2, d=>undef }, { a=>1, b=>2, d=>undef }, 0 ],
	[ 'hashes 5 (null hash)', { }, { }, 0 ],

	[ 'hash & array', [ 1,2,3 ], { 1=>1, 2=>2, 3=>3 } , 1 ],
	[ 'array & hash', { 1=>1, 2=>2, 3=>3 }, [ 1, 2, 3 ] , 1 ],

	[ 'complex1', $tmpcomplex1, $tmpcomplex2, 1 ],
	[ 'complex1', $tmpcomplex1, $tmpcomplex1, 0 ],
	[ 'complex1', $tmpcomplex2, $tmpcomplex2, 0 ],
	[ 'complex1', $tmpcomplex1, $tmpcomplex1b, 1 ],
	[ 'complex1', $tmpcomplex2, $tmpcomplex2b, 1 ],
);

my ($val1, $val2);
foreach $rec (@compvals_tests)
{	($name, $val1, $val2, $exp) = @$rec;
	my $rawgot = $ebrw->_compare_values_deeply($val1, $val2);
	$got = $rawgot?1:0;
	is($got, $exp, "_compare_values_deeply: $name");
	if ( $got && ! $exp )
	{	#We expect values to equate, but got something else
		note("Test: $name: got=$rawgot\n");
	}
	$num_tests_run++;
}



#------------------------------------------------
#	Finished
#------------------------------------------------
done_testing($num_tests_run);

