#!/usr/bin/perl

# t/05.scalar.t - check scalar manipulation object

use Test::More qw( no_plan );
use strict;
use warnings;
use lib './lib';
use JSON;
use Nice::Try;

BEGIN { use_ok( 'Module::Generic::Array' ) || BAIL_OUT( "Unable to load Module::Generic::Array" ); }
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

# first
# In void context returns a string
my $word = $a2->first;
ok( !ref( $word ), 'first in void context returns a simple string' );
is( $word, 'I' );
my $word_obj = $a2->first->clone;
isa_ok( $word_obj, 'Module::Generic::Scalar', 'first in object context returns a Module::Generic::Scalar object' );

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
$word_obj = $a->get(14)->clone;
isa_ok( $word_obj, 'Module::Generic::Scalar', 'get in object context' );
is( $word_obj, 'right', 'get returned value' );

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

ok( $a->has( 'say' ), 'has' );

is( $a->index(14), 'right', 'index' );
$word_obj = $a->index(14)->clone;
isa_ok( $word_obj, 'Module::Generic::Scalar', 'index in object context' );
is( $word_obj, 'right', 'index returned value' );

my $join = $a2->join( ',' );
isa_ok( $join, 'Module::Generic::Scalar', 'join produces scalar object' );
is( $join, 'I,disapprove,but', 'join' );

isa_ok( $a->keys, 'Module::Generic::Array', 'keys to array object class' );
is( $a->keys->length, 18, 'length' );
ok( $a->keys->length == $a->length, 'length (bis)' );

# last
# In void context returns a string
$word = $a2->last;
ok( !ref( $word ), 'last in void context returns a simple string' );
is( $word, 'but' );
$word_obj = $a2->last->clone;
isa_ok( $word_obj, 'Module::Generic::Scalar', 'last in object context returns a Module::Generic::Scalar object' );
is( $word_obj, 'but' );

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
my $a_pop = Module::Generic::Array->new( [ qw( hello world ) ] );
$word = $a_pop->pop->clone;
isa_ok( $word, 'Module::Generic::Scalar', 'pop in object context' );
is( $word, 'world', 'pop value in object context' );

is( $map->push( qw( again and again ) )->length, 12, 'push' );
is( $a2->clone->push_arrayref( $map )->length, 15, 'push_arrayref' );
is( $a2->clone->reset->length, 0, 'reset' );
is( $a2->reverse->as_string, 'but disapprove I', 'reverse' );
$a2->set( [qw( this has been set )] );
is( "@$a2", 'this has been set', 'set' );

is( $a2->shift, 'this', 'shift' );
$a_pop = Module::Generic::Array->new( [ qw( hello world ) ] );
$word = $a_pop->shift->clone;
isa_ok( $word, 'Module::Generic::Scalar', 'shift in object context' );
is( $word, 'hello', 'shift value in object context' );

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

# splice in object context
my $a_splice = Module::Generic::Array->new( [CORE::split( /[[:blank:]]+/, $s )] );
my $splice_ret = $a_splice->splice( 7, 3 )->clone;
isa_ok( $splice_ret, 'Module::Generic::Array', 'splice in object context' );
is( "@$splice_ret", 'I will defend', 'splice returned value in object context' );
$a_splice = Module::Generic::Array->new( [CORE::split( /[[:blank:]]+/, $s )] );
$splice_ret = $a_splice->splice( 7 )->clone;
isa_ok( $splice_ret, 'Module::Generic::Array', 'splice in object context' );
is( "@$splice_ret", 'I will defend to the death your right to say it', 'splice returned value in object context' );

is( $a2->clone->undef->length, 0, 'undef' );
is( $a2->values->as_string, 'This should have been set', 'values' );

my $array1 = [qw( John Paul )];
my $array2 = Module::Generic::Array->new;
my $array3 = Module::Generic::Array->new;
@$array2 = @$array1;
isa_ok( $array2, 'Module::Generic::Array', 'Array keeps class' );
is( $array2->join( ' ' ), 'John Paul', 'Assigned array' );
$array3 = $array2;

my $a3 = Module::Generic::Array->new( [qw( Jack John Peter Gabriel Raphael Emmanuel )] );
is( $a3->offset( 2, 3 )->join( ' ' )->scalar, 'Peter Gabriel Raphael', 'offset' );
is( $a3->offset( 2, -3 )->join( ' ' )->scalar, 'Emmanuel Jack John Peter', 'offset' );
is( $a3->offset( 2, -1 )->join( ' ' )->scalar, 'John Peter', 'offset' );
is( $a3->offset( -2, 3 )->join( ' ' )->scalar, 'Raphael Emmanuel Jack', 'offset' );
is( $a3->offset( 3 )->join( ' ' )->scalar, 'Gabriel Raphael Emmanuel', 'offset' );

my $a4 = Module::Generic::Array->new( [qw( Jack John Peter )] );
my $a5 = Module::Generic::Array->new( [qw( Gabriel Raphael Emmanuel )] );
$a4->merge( $a5 );
is( $a4->join( ' ' )->scalar, 'Jack John Peter Gabriel Raphael Emmanuel', 'merge' );

ok( "@$a4", 'Jack John Peter Gabriel Raphael Emmanuel' );
$a4->for(sub
{
    my( $i, $v ) = @_;
    if( $v eq 'Peter' )
    # if( $v == 5 )
    {
        $a4->splice( $i, 1 );
        # perl is smart and cal gracefully handle the lack of offset change if occurrence is NOT repeating wice or more consecutively
        # return( \-1 );
    }
    return( 1 );
});
is( "@$a4", 'Jack John Gabriel Raphael Emmanuel', 'for changing offset position' );

my $a6 = Module::Generic::Array->new( [qw( Jack John Peter Peter Gabriel Raphael Emmanuel )] );
$a6->for(sub
{
    my( $i, $v ) = @_;
    if( $v eq 'Peter' )
    {
        $a6->splice( $i, 1 );
        # failure to do this, because of repeating occurence of "Peter", perl would fail
        return( \-1 );
    }
    return( 1 );
});
is( "@$a6", 'Jack John Gabriel Raphael Emmanuel', 'for changing offset position' );

my $a7 = Module::Generic::Array->new( [qw( Jack John Peter Gabriel Raphael Peter Emmanuel )] );
$a7->for(sub
{
    my( $i, $v ) = @_;
    if( $v eq 'Peter' )
    {
        $a7->splice( $i, 1 );
        # return( \-1 );
    }
    return( 1 );
});
is( "@$a7", 'Jack John Gabriel Raphael Emmanuel', 'for changing offset position' );

# using return method to tell specific loop to terminate
my $a8 = Module::Generic::Array->new( [ 1..10 ] );
my $a9 = Module::Generic::Array->new( [ 21..30 ] );
my $pos;
$a8->for(sub
{
    my( $i, $n ) = @_;
    $pos = $n;
    $a9->for(sub
    {
        my( $j, $v ) = @_;
        $a8->return( undef() ) if( $n == 7 && $v == 27 );
    });
});
is( $pos, 7, 'return undef' );
is( scalar( keys( %$Module::Generic::Array::RETURN ) ), 0, 'return registry cleanup' );

my $a10 = Module::Generic::Array->new( [qw( Jack John Peter Paul Gabriel Raphael Emmanuel )] );
my $a11 = Module::Generic::Array->new;
$a10->for(sub
{
    my( $i, $n ) = @_;
    $a11->push( $n );
    # tell it to skip Peter
    $a10->return( +1 ) if( $n eq 'John' );
    return( 1 );
});
is( "@$a11", 'Jack John Paul Gabriel Raphael Emmanuel', 'return skip 1' );

$a11->reset;
$pos = 0;
$a8->for(sub
{
    my( $i, $n ) = @_;
    $pos = $n;
    $a9->for(sub
    {
        my( $j, $v ) = @_;
        # should have no effect, because $a10 is sending the return value and $a10 is not an enclosing loop
        $a10->return( undef() ) if( $n == 7 && $v == 27 );
    });
});
is( $pos, 10, 'ineffective return' );

# modifying $i in situ
$a10->for(sub
{
    my( $i, $n ) = @_;
    $a11->push( $n );
    $_[0]++ if( $n eq 'John' );
    return(1);
});
is( "@$a11", 'Jack John Paul Gabriel Raphael Emmanuel', 'modying $i directly' );

my $dummy = { class => 'Coucou' };
my $a12 = Module::Generic::Array->new( ['Jack', 'John', $dummy, 'Paul', 'Peter', 'Gabriel', $dummy, 'Peter', 'Raphael', 'Emmanuel'] );
my $res12 = $a12->unique;
my $expect12 = Module::Generic::Array->new( ['Jack', 'John', $dummy, 'Paul', 'Peter', 'Gabriel', 'Raphael', 'Emmanuel'] );
ok( $res12 eq $expect12, 'unique' );
$a12->unique(1);
ok( $a12 eq $expect12, 'unique in-place' );

$a12->remove( $dummy, qw( John Paul Peter Emmanuel ) );
is( "@$a12", 'Jack Gabriel Raphael', 'remove' );

my $a13 = Module::Generic::Array->new( [qw( 1 2 3 4 5 6 7 8 9 10 )] );
my $even = $a13->even;
is( "@$even", '1 3 5 7 9', 'even' );
my $odd = $a13->odd;
is( "@$odd", '2 4 6 8 10', 'odd' );

my $a14 = Module::Generic::Array->new( [qw( Jack John Paul Peter )] );
my $j = JSON->new->convert_blessed;
try
{
    my $json = $j->encode( $a14 );
    is( $json, '["Jack","John","Paul","Peter"]', 'TO_JSON' );
}
catch( $e )
{
    # diag( "Error encoding: $e" );
    fail( 'TO_JSON' );
}

done_testing();
