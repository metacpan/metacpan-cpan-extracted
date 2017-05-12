#!/usr/bin/perl

# SQL::String basic functionality tests

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}





# Does everything load?
use Test::More tests => 78;
use SQL::String ();





# Create a new plain SQL object
my $SQL = SQL::String->new( 'foo' );
isa_ok( $SQL, 'SQL::String' );
is( $SQL->sql, 'foo', '->sql returns expected SQL' );
is( "$SQL", 'foo', 'stringification returns expected value' );
my $rv = $SQL->params;
my @rv = $SQL->params;
is( $rv, 0, '->params returns correct in scalar context' );
is_deeply( \@rv, [ ], '->params returns correct in array context' );
$rv = $SQL->params_ref;
is_deeply( $rv, [ ], '->params_ref returns as expected' );
is( $SQL->stable, 1, '->stable returns true' );




# Test bad constructor calls
is( SQL::String->new(),       undef, 'Bad ->new() returns as expected'      );
is( SQL::String->new(undef),  undef, 'Bad ->new(undef) returns as expected' );
is( SQL::String->new([]),     undef, 'Bad ->new([]) returns as expected'    );
is( SQL::String->new(\"foo"), undef, 'Bad ->new(\"") returns as expected'   );
is( SQL::String->new({}),     undef, 'Bad ->new({}) returns as expected'    );





# A SQL object with one param
$SQL = SQL::String->new( 'foo = ?', 2 );
isa_ok( $SQL, 'SQL::String' );
is( $SQL->sql, 'foo = ?', '->sql returns expected SQL' );
is( "$SQL", 'foo = ?', 'stringification returns expected value' );
$rv = $SQL->params;
@rv = $SQL->params;
is( $rv, 1, '->params returns correct in scalar context' );
is_deeply( \@rv, [ 2 ], '->params returns correct in array context' );
$rv = $SQL->params_ref;
is_deeply( $rv, [ 2 ], '->params_ref returns as expected' );
is( $SQL->stable, 1, '->stable returns true' );





# A SQL object with bad params
$SQL = SQL::String->new( 'a = ?, b = ?, c = ?, d = ?, e = ?, f = ?, g = ?', 2, \"foo", 1, 4, 6, "Hello" );
isa_ok( $SQL, 'SQL::String' );
is( $SQL->sql, 'a = ?, b = ?, c = ?, d = ?, e = ?, f = ?, g = ?', '->sql returns expected SQL' );
is( "$SQL", 'a = ?, b = ?, c = ?, d = ?, e = ?, f = ?, g = ?', 'stringification returns expected value' );
$rv = $SQL->params;
@rv = $SQL->params;
is( $rv, 6, '->params returns correct in scalar context' );
is_deeply( \@rv, [ 2, \"foo", 1, 4, 6, "Hello" ], '->params returns correct in array context' );
$rv = $SQL->params_ref;
is_deeply( $rv, [ 2, \"foo", 1, 4, 6, "Hello" ], '->params_ref returns as expected' );
is( $SQL->stable, '', '->stable returns true' );




# Clone it
my $copy = $SQL->clone;
is_deeply( $copy, $SQL, '->clone matches original' );




# Test concatonation
my $One = SQL::String->new('foo = ?', 2);
isa_ok( $One, 'SQL::String' );
is( $One->sql, 'foo = ?', '->sql for new object matches expected' );
is_deeply( $One->params_ref, [ 2 ], '->params for new object matches expected' );

{
	local $SIG{__WARN__} = sub { ok( 1, 'Caught warning during undef concat' ) };
	isa_ok( $One->concat(undef), 'SQL::String' );
}
isa_ok( $One, 'SQL::String' );
is( $One->sql, 'foo = ?', '->sql does not change' );
is_deeply( $One->params_ref, [ 2 ], '->params does not change' );

isa_ok( $One->concat(' '), 'SQL::String' );
is( $One->sql, 'foo = ? ', '->sql adds new char' );
is_deeply( $One->params_ref, [ 2 ], '->params does not change' );

my $Two = SQL::String->new(', bar = ?', 3);
isa_ok( $Two, 'SQL::String' );
is( $Two->sql, ', bar = ?', '->sql for new object matches expected' );
is_deeply( $Two->params_ref, [ 3 ], '->params for new object matches expected' );

isa_ok( $One->concat($Two), 'SQL::String' );
is( $One->sql, 'foo = ? , bar = ?', '->sql is correct after object concat' );
is_deeply( $One->params_ref, [ 2, 3 ], '->params changes as expected' );





# Overloading

# .= overloading
$SQL  = SQL::String->new('foo = ?', 2);   isa_ok( $SQL,  'SQL::String' );
my $SQL2 = SQL::String->new(', bar = ?', 3); isa_ok( $SQL2, 'SQL::String' );
{
	local $SIG{__WARN__} = sub { ok( 1, 'Caught warning during undef concat' ) };
	$SQL .= undef;
}
isa_ok( $SQL, 'SQL::String' );
is( $SQL->sql, 'foo = ?', '->sql does not change' );
is_deeply( $SQL->params_ref, [ 2 ], '->params does not change' );

$SQL .= ' ';
is( $SQL->sql, 'foo = ? ', '->sql is correct after object concat' );
is_deeply( $SQL->params_ref, [ 2 ], '->params changes as expected' );

$SQL .= $SQL2;
isa_ok( $SQL, 'SQL::String' );
is( $SQL->sql, 'foo = ? , bar = ?', '->sql is correct after object concat' );
is_deeply( $SQL->params_ref, [ 2, 3 ], '->params changes as expected' );




# . overloading
$SQL  = SQL::String->new('foo = ?', 2);   isa_ok( $SQL,  'SQL::String' );
$SQL2 = SQL::String->new(', bar = ?', 3); isa_ok( $SQL2, 'SQL::String' );
my $SQL3;
{
	local $SIG{__WARN__} = sub { ok( 1, 'Caught warning during undef concat' ) };
	$SQL3 = $SQL . undef;
}
isa_ok( $SQL3, 'SQL::String' );
is( $SQL3->sql, 'foo = ?', '->sql does not change' );
is_deeply( $SQL3->params_ref, [ 2 ], '->params does not change' );

$SQL3 = $SQL . ' ';
is( $SQL3->sql, 'foo = ? ', '->sql is correct after object concat' );
is_deeply( $SQL3->params_ref, [ 2 ], '->params changes as expected' );

$SQL  = SQL::String->new('foo = ?', 2);   isa_ok( $SQL,  'SQL::String' );
$SQL3 = $SQL . $SQL2;
isa_ok( $SQL3, 'SQL::String' );
is( $SQL3->sql, 'foo = ?, bar = ?', '->sql is correct after object concat' );
is_deeply( $SQL3->params_ref, [ 2, 3 ], '->params changes as expected' );




# Reversed . overloading
$SQL  = SQL::String->new('foo = ?', 2);   isa_ok( $SQL,  'SQL::String' );
$SQL2 = SQL::String->new(', bar = ?', 3); isa_ok( $SQL2, 'SQL::String' );
$SQL3 = undef;
{
	local $SIG{__WARN__} = sub { ok( 1, 'Caught warning during undef concat' ) };
	$SQL3 = undef() . $SQL;
}
isa_ok( $SQL3, 'SQL::String' );
is( $SQL3->sql, 'foo = ?', '->sql does not change' );
is_deeply( $SQL3->params_ref, [ 2 ], '->params does not change' );

$SQL3 = ' ' . $SQL;
is( $SQL3->sql, ' foo = ?', '->sql is correct after object concat' );
is_deeply( $SQL3->params_ref, [ 2 ], '->params changes as expected' );




# Interpolation
$SQL  = SQL::String->new('foo = ?', 2); isa_ok( $SQL,  'SQL::String' );
$SQL2 = SQL::String->new('bar = ?', 3); isa_ok( $SQL2, 'SQL::String' );
$SQL3 = "update table set $SQL, $SQL2 where this = that";
is( $SQL3, 'update table set foo = ?, bar = ? where this = that',
	'SQL is correct after interpolation' );
