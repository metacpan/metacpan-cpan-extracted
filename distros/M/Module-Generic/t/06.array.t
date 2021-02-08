#!/usr/bin/perl

# t/05.scalar.t - check scalar manipulation object

use Test::More qw( no_plan );
use strict;
use warnings;
use lib './lib';

BEGIN { use_ok( 'Module::Generic' ) || BAIL_OUT( "Unable to load Module::Generic" ); }
# use warnings 'Module::Generic::Array';
# no warnings 'Module::Generic::Array';

my $s = Module::Generic::Scalar->new( 'I disapprove of what you say, but I will defend to the death your right to say it' );
my $a = $s->split( qr/[[:blank:]]+/ );
# diag( Dumper( $a ) );
isa_ok( $a, 'Module::Generic::Array' );
is( $a->length, 18, 'length' );
my $h = \%$a;
# diag( Dumper( $h ) );
isa_ok( $h, 'Module::Generic::Hash' );
is( CORE::exists( $a->{disapprove} ), 1, 'array to hash' );
is( "@$a", 'I disapprove of what you say, but I will defend to the death your right to say it', 'array as string' );
no warnings 'Module::Generic::Array';
is( $a->delete( 'not-integer' ), $a, 'delete with non-integer offset' );
use warnings 'Module::Generic::Array';
my $a2 = $a->clone;
is( $a2->delete( 2 )->as_string, 'of', 'delete with offset' );
is( "@$a2", 'I disapprove what you say, but I will defend to the death your right to say it', 'array after delete' );
$a2->delete( 2, 3 );
is( "@$a2", 'I disapprove but I will defend to the death your right to say it', 'delete with offset and length' );
$a2->delete( 3, $a2->length );
is( "@$a2", 'I disapprove but', 'delete till the end' );
# $i starts from 0
# diag( "$a" );
$a->each(sub{
    my( $i, $v ) = @_;
    return( 1 ) unless( $i == 9 );
    is( $v, 'defend', 'each' );
    return( 0 );
});
ok( $a->exists( 'defend' ), 'exists with bare word' );
ok( $a->exists( qr/DefEnd/i ), 'exists with regular expression' );
ok( !$a->exists( 'DefEnd' ), 'not exist' );
my $res = $a->exists( qr/you/ );
isa_ok( $res, 'Module::Generic::Number', 'Result object class' );
$a->for(sub
{
    my( $i, $v ) = @_;
    return( 1 ) unless( $i == 14 );
    is( $v, 'right', 'for' );
    return( 0 );
});

$res = '';
$a->foreach(sub
{
    my( $v ) = @_;
    $res .= $v;
});
my $s_no_sp = $s->clone;
$s_no_sp->replace( qr/[[:blank:]]+/, '' );
is( $res, $s_no_sp, 'foreach' );

is( $a->get(14), 'right', 'get' );

$res = $a->grep( 'say' );
## diag( Dumper( $res ) );
isa_ok( $res, 'Module::Generic::Array', 'grep' );
is( $res->length, 2, 'grep result total' );
$res = $a->grep( qr/^you[r]?$/ );
is( $res->length, 2, 'gre with regexp' );

is( ($a->list)[14], 'right', 'list' );

$res = $a->grep(sub
{
    $_[0] =~ /(of|to|the)/i;
});
is( "@$res", 'of to the to', 'grep using code' );

my $join = $a2->join( ',' );
isa_ok( $join, 'Module::Generic::Scalar', 'join produces scalar object' );
is( $join, 'I,disapprove,but', 'join' );

isa_ok( $a->keys, 'Module::Generic::Array', 'keys to array object class' );
is( $a->keys->length, 18, 'length' );
ok( $a->keys->length == $a->length, 'length (bis)' );

my $map = $a->map(sub
{
    return( length( $_[0] ) <= 3 ? $_[0] : () );
});
## diag( Dumper( $map ) );
is( "@$map", 'I of you but I to the to say it', 'map' );

my $a_temp = Module::Generic::Array->new( [qw( Trying local variable )] );
my $map2 = $a_temp->map(sub
{
    return( "_${_}_" );
})->join( '-' );
is( $map2, '_Trying_-_local_-_variable_', 'map with local variable' );

my @list = $a->map(sub
{
    return( length( $_[0] ) <= 3 ? $_[0] : () );
});
is( join( ',', @list ), 'I,of,you,but,I,to,the,to,say,it', 'map as list' );

is( $map->pop, 'it', 'pop' );
is( $map->push( qw( again and again ) )->length, 12, 'push' );
is( $a2->clone->push_arrayref( $map )->length, 15, 'push_arrayref' );
is( $a2->clone->reset->length, 0, 'reset' );
is( $a2->reverse->as_string, 'but disapprove I', 'reverse' );
$a2->set( [qw( this has been set )] );
is( "@$a2", 'this has been set', 'set' );
is( $a2->shift, 'this', 'shift' );
is( $a2->size, 2, 'size' );
ok( $a2->length->is_positive, 'Accessing number object method' );
is( $a->sort->as_string, 'I I but death defend disapprove it of right say say, the to to what will you your', 'sort' );
is( $a->sort(sub
{
    $_[1] cmp $_[0];
})->as_string, 'your you will what to to the say, say right of it disapprove defend death but I I', 'sort with code' );

# splice with no argument will behave as pop
is( $a2->clone->splice->length, 0, 'splice with no argument remove everything' );
is( $a2->unshift( 'This' )->as_string, 'This has been set', 'unshift' );
# diag( "Array is: $a2" );
is( $a2->splice( 1, 1, qw( should have ) )->as_string, 'This should have been set', 'splice with replacement' );
is( $a2->clone->undef->length, 0, 'undef' );
is( $a2->values->as_string, 'This should have been set', 'values' );

my $array1 = [qw( John Paul )];
my $array2 = Module::Generic::Array->new;
my $array3 = Module::Generic::Array->new;
@$array2 = @$array1;
isa_ok( $array2, 'Module::Generic::Array', 'Array keeps class' );
is( $array2->join( ' ' ), 'John Paul', 'Assigned array' );
$array3 = $array2;
