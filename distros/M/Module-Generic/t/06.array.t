#!/usr/bin/perl
BEGIN
{
    use strict;
    use warnings;
    use Cwd qw( abs_path );
    use lib abs_path( './lib' );
    use vars qw( $DEBUG );
    use Test::More qw( no_plan );
    use Config;
    use JSON;
    # use Nice::Try;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    use_ok( 'Module::Generic::Array' ) || BAIL_OUT( "Unable to load Module::Generic::Array" );
    use_ok( 'Module::Generic::Scalar' ) || BAIL_OUT( "Unable to load Module::Generic::Scalar" );
}
# use warnings 'Module::Generic::Array';
# no warnings 'Module::Generic::Array';
use strict;
use warnings;

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

my $ar_split = Module::Generic::Array->new->split( qr/[[:blank:]\h]+/, "I disapprove of what you say, but I will defend to the death your right to say it" );
isa_ok( $ar_split, 'Module::Generic::Array', 'split returns an Module::Generic::Array' );
is( $ar_split->length, 18, 'split array size' ); # 18
# or in list context and using the method as a class method
my @split_words = Module::Generic::Array->split( qr/[[:blank:]\h]+/, "I disapprove of what you say, but I will defend to the death your right to say it" );
is( scalar( @split_words ), 18, 'split array size in list context' ); # 18

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
    return(1);
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
    return(1);
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
    return(1);
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
        #$a8->return( undef() ) if( $n == 7 && $v == 27 );
        $a8->break if( $n == 7 && $v == 27 );
    });
});
is( $pos, 7, 'return undef' );
# is( scalar( keys( %$Module::Generic::Array::RETURN ) ), 0, 'return registry cleanup' );

my $a10 = Module::Generic::Array->new( [qw( Jack John Peter Paul Gabriel Raphael Emmanuel )] );
my $a11 = Module::Generic::Array->new;
$a10->for(sub
{
    my( $i, $n ) = @_;
    $a11->push( $n );
    # tell it to skip Peter
    $a10->return(+1) if( $n eq 'John' );
    return(1);
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
        # $a10->return( undef() ) if( $n == 7 && $v == 27 );
        $a10->break if( $n == 7 && $v == 27 );
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
eval
{
    my $json = $j->encode( $a14 );
    is( $json, '["Jack","John","Paul","Peter"]', 'TO_JSON' );
};
if( $@ )
{
    # diag( "Error encoding: $e" );
    fail( 'TO_JSON' );
}

my $cardinals = [qw( first second third fourth fifth sixth seventh eighth ninth tenth )];
for( 0..$#$cardinals )
{
    my $method = $cardinals->[ $_ ];
    is( $a13->$method, ($_ + 1), $cardinals->[$_] );
}

my $val = $a14->get_null(1);
is( $val, 'John', 'get_null(1) in scalar context' );
$val = $a14->get_null(1)->length;
is( $val, 4, 'get_null(1) in object context' );
$val = $a14->get_null(4);
# isa_ok( $val, 'Module::Generic::Null', 'get_null(4) out of bound returns Module::Generic::Null' );
ok( !defined( $val ), 'get_null(4) out of bound returns undef' );
$val = $a14->get_null(4)->dummy;
# There is a race exception with Test::More whereby even if undef is returned, Test::More will give me an empty string.
is( $val => '', 'get_null(4)->dummy (using Module::Generic::Null) out of bound returns empty string' );

$a = Module::Generic::Array->new( 30..39 );
is( $a->length, 10, 'array allocation for pack' );
$s = $a->pack( 'H2' x 10 );
isa_ok( $s, 'Module::Generic::Scalar', 'pack returns a Module::Generic::Scalar object' );
is( $s->scalar, '0123456789', 'pack' );

my $intersec1 = [qw( Jack John Paul Peter )];
my $intersec2 = [qw( Emmanuel Gabriel Raphael Peter Michel )];
my $intersec = Module::Generic::Array->new( $intersec1 )->intersection( $intersec2 );
isa_ok( $intersec, 'Module::Generic::Array', 'intersection returns an Module::Generic::Array object' );
is_deeply( $intersec, [qw( Peter )], 'intersection' );
is( $intersec->length, 1, 'intersection size' );
is( $intersec->first, 'Peter', 'intersection value' );
$intersec = Module::Generic::Array->new( $intersec1 )->intersection( Module::Generic::Array->new( $intersec2 ) );
is_deeply( $intersec, [qw( Peter )], 'intersection using array objects' );

my $values = Module::Generic::Array->new( [qw( 9 5 12 3 7 )] );
my $max = $values->max;
isa_ok( $max, 'Module::Generic::Scalar', 'max return a Module::Generic::Scalar object' );
is( "$max", 12, 'max' );

my $max_list = Module::Generic::Array->new;
# $max is undef
my $max_val  = $max_list->max;
# returns false
ok( !$max_val->defined, 'max on empty list returns undef as an object' );

my $min = $values->min;
is( "$min", 3, 'min' );

my $ex1 = Module::Generic::Array->new( [qw( Jack John Paul Peter )] );
my $other = Module::Generic::Array->new( [qw( Emmanuel Gabriel Paul Peter Raphael )] );
my $ex2 = $ex1->except( $other );
is( "@$ex2", "Jack John" );

my $a2h = Module::Generic::Array->new( [qw( Jack John Peter Gabriel Raphael Emmanuel )] );
my $hashified = $a2h->as_hash;
isa_ok( $hashified => 'Module::Generic::Hash' );
is_deeply( $hashified => { Jack => 0, John => 1, Peter => 2, Gabriel => 3, Raphael => 4, Emmanuel => 5 }, 'as_hash' );

subtest 'callback' => sub
{
    $Module::Generic::Array::DEBUG = $DEBUG;
    diag( "Setting \$Module::Generic::Array::DEBUG to '$Module::Generic::Array::DEBUG'" ) if( $DEBUG );
    my $test = Module::Generic::Array->new( qw( John Peter Paul ) );
    is( $test->length, 3, 'init' );
    ok( !tied( @$test ), 'not tied' );
    $test->callback( add => sub
    {
        my $this = shift( @_ );
        my( $pos, $ref ) = @$this{qw( start added )};
        diag( "Adding ", scalar( @$ref ), " element ('", join( "', '", @$ref ), "') at offset $pos" ) if( $DEBUG );
        is( $pos, 3, 'push' );
        return(1);
    });
    $test->push( 'Gabriel' );
    diag( "Elements are: '", $test->join( "', '" ), "'" ) if( $DEBUG );
    is( $test->last, 'Gabriel', 'push (2)' );
    $test->callback( add => sub
    {
        my $this = shift( @_ );
        my( $pos, $ref ) = @$this{qw( start added )};
        diag( "Adding ", scalar( @$ref ), " element ('", join( "', '", @$ref ), "') at offset $pos" ) if( $DEBUG );
        is( $pos, 0, 'unshift' );
        return(1);
    });
    $test->unshift( 'Emmanuel' );
    is( $test->first, 'Emmanuel', 'unshift (2)' );
    $test->callback( add => sub
    {
        my $this = shift( @_ );
        my( $pos, $ref ) = @$this{qw( start added )};
        diag( "Adding ", scalar( @$ref ), " element ('", join( "', '", @$ref ), "') at offset $pos" ) if( $DEBUG );
        is( $pos, 2, 'splice' );
        return(1);
    });
    $test->splice( 2, 0, 'Raphael' );
    is( $test->index(2), 'Raphael', 'splice (2)' );
    
    # Now do removing tests
    diag( "Now do removing tests" ) if( $DEBUG );
    diag( "Elements are: '", $test->join( "', '" ), "'" ) if( $DEBUG );
    $test->callback( remove => sub
    {
        my $this = shift( @_ );
        my( $from, $to ) = @$this{qw( start end )};
        diag( "Removing data from position $from to $to: '", $test->offset( $from, ( $to - $from ) )->join( "', '" ), "'" ) if( $DEBUG );
        is( $from, 5, 'pop' );
        is( $to, 5, 'pop (1)' );
        return(1);
    });
    my $removed = $test->pop;
    is( $removed, 'Gabriel', 'pop (2)' );
    $test->callback( remove => sub
    {
        my $this = shift( @_ );
        my( $from, $to ) = @$this{qw( start end )};
        diag( "Removing data from position $from to $to: '", $test->offset( $from, ( $to - $from ) )->join( "', '" ), "'" ) if( $DEBUG );
        is( $from, 0, 'shift (start position)' );
        is( $to, 0, 'shift (end position)' );
        return(1);
    });
    $removed = $test->shift;
    is( $removed, 'Emmanuel', 'shift (2)' );
    $test->callback( remove => sub
    {
        my $this = shift( @_ );
        my( $from, $to ) = @$this{qw( start end )};
        diag( "Removing data from position $from to $to: '", $test->offset( $from, ( $to - $from ) )->join( "', '" ), "'" ) if( $DEBUG );
        is( $from, 1, 'splice (start position)' );
        is( $to, 2, 'splice (end position)' );
        is( join( ' ', @$test[ 1, 2 ] ), 'Raphael Peter', 'splice (1)' );
        return(1);
    });
    my @removed = $test->splice( 1, 2 );
    is( scalar( @removed ), 2, 'splice (2)' );
    is( "@removed", 'Raphael Peter', 'splice (3)' );
    
    diag( "Elements are: '", $test->join( "', '" ), "'" ) if( $DEBUG );
    $test->callback( remove => sub
    {
        my $this = shift( @_ );
        my( $from, $to ) = @$this{qw( start end )};
        my $caller = [caller];
        diag( "Removing data from position $from to $to: '", $test->offset( $from, ( $to - $from ) )->join( "', '" ), "' called from package ", $caller->[0], " at line ", $caller->[2] ) if( $DEBUG );
        # diag( "Removing data from position $from to $to: '", join( "', '", @$test[ $from...$to ] ), "' called from package ", $caller->[0], " at line ", $caller->[2] ) if( $DEBUG );
        # diag( "Removing data from position $from to $to called from package ", $caller->[0], " at line ", $caller->[2] ) if( $DEBUG );
        is( $from, 1, 'delete (start position)' );
        is( $to, 1, 'delete (end position)' );
        return(1);
    });
    # diag( "Removing '", $test->[1], "'" ) if( $DEBUG );
    $removed = delete( $test->[1] );
    is( $removed, 'Paul', 'delete (2)' );
    
    diag( "No check blocking addition." ) if( $DEBUG );
    diag( "Elements are: '", $test->join( "', '" ), "'" ) if( $DEBUG );
    $test->callback( add => sub
    {
        my $this = shift( @_ );
        my( $pos, $ref ) = @$this{qw( start added )};
        diag( "Attempting to add ", scalar( @$ref ), " element ('", join( "', '", @$ref ), "') at offset $pos" ) if( $DEBUG );
        is( $pos, 1, 'push' );
        return;
    });
    $test->push( qw( Madeleine Isabelle Gabrielle ) );
    is( $test->length, 1, 'push rejected' );

    $test->callback( add => sub
    {
        my $this = shift( @_ );
        my( $pos, $ref ) = @$this{qw( start added )};
        diag( "Attempting to add ", scalar( @$ref ), " element ('", join( "', '", @$ref ), "') at offset $pos" ) if( $DEBUG );
        is( $pos, 0, 'unshift' );
        return;
    });
    # $test->unshift( qw( Madeleine Isabelle Gabrielle ) );
    $test->unshift( qw( Madeleine ) );
    is( $test->length, 1, 'unshift rejected' );

    diag( "Elements are: '", $test->join( "', '" ), "'" ) if( $DEBUG );
    $test->callback( add => sub
    {
        my $this = shift( @_ );
        my( $pos, $ref ) = @$this{qw( start added )};
        diag( "Attempting to add ", scalar( @$ref ), " element ('", join( "', '", @$ref ), "') at offset $pos" ) if( $DEBUG );
        is( $pos, 2, 'direct insertion' );
        return;
    });
    $test->[2] = 'Samuel';
    is( $test->length, 1, 'direct insertion rejected' );
    $test->callback( add => sub
    {
        my $this = shift( @_ );
        my( $pos, $ref ) = @$this{qw( start added )};
        diag( "Attempting to add ", scalar( @$ref ), " element ('", join( "', '", @$ref ), "') at offset $pos" ) if( $DEBUG );
        is( $pos, 2, 'splice insertion rejected' );
        return;
    });
    $test->splice( 2, 0, qw( Marie Madeleine ) );
    is( $test->length, 1, 'splice insertion rejected (2)' );

    diag( "Elements are: '", $test->join( "', '" ), "'" ) if( $DEBUG );
    $test->callback( remove => sub
    {
        my $this = shift( @_ );
        my( $from, $to ) = @$this{qw( start end )};
        my $caller = [caller];
        diag( "Removing data from position $from to $to: '", $test->offset( $from, ( $to - $from ) )->join( "', '" ), "' called from package ", $caller->[0], " at line ", $caller->[2] ) if( $DEBUG );
        is( $from, 0, 'shift rejected (start position)' );
        is( $to, 0, 'shift rejected (end position)' );
        return;
    });
    $removed = $test->shift;
    is( $removed, undef, 'shift rejected' );
    is( $test->length, 1, 'shift rejected' );
    $test->callback( add => undef );
    $test->push( qw( Madeleine Isabelle Gabrielle ) );
    is( $test->length, 4, 'remove callback' );
    diag( "Elements are: '", $test->join( "', '" ), "'" ) if( $DEBUG );
    
    $test->callback( remove => sub
    {
        my $this = shift( @_ );
        my( $from, $to ) = @$this{qw( start end )};
        my $caller = [caller];
        diag( "Removing data from position $from to $to: '", $test->offset( $from, ( $to - $from ) )->join( "', '" ), "' called from package ", $caller->[0], " at line ", $caller->[2] ) if( $DEBUG );
        is( $from, 3, 'shift rejected (start position)' );
        is( $to, 3, 'shift rejected (end position)' );
        return;
    });
    $removed = $test->pop;
    is( $removed, undef, 'pop rejected' );
    is( $test->length, 4, 'pop rejected' );
    
    $test->callback( remove => sub
    {
        my $this = shift( @_ );
        my( $from, $to ) = @$this{qw( start end )};
        my $caller = [caller];
        diag( "Removing data from position $from to $to: '", $test->offset( $from, ( $to - $from ) )->join( "', '" ), "' called from package ", $caller->[0], " at line ", $caller->[2] ) if( $DEBUG );
        is( $from, 2, 'direct removal rejected (start position)' );
        is( $to, 2, 'direct removal rejected (end position)' );
        return;
    });
    $removed = delete( $test->[2] );
    is( $removed, undef, 'direct removal' );
    is( $test->length, 4, 'direct removal' );
    
    $test->callback( remove => sub
    {
        my $this = shift( @_ );
        my( $from, $to ) = @$this{qw( start end )};
        my $caller = [caller];
        diag( "Removing data from position $from to $to: '", $test->offset( $from, ( $to - $from ) )->join( "', '" ), "' called from package ", $caller->[0], " at line ", $caller->[2] ) if( $DEBUG );
        is( $from, 1, 'splice removal rejected (start position)' );
        is( $to, 2, 'splice removal rejected (end position)' );
        return;
    });
    @removed = $test->splice( 1, 2 );
    is( scalar( @removed ), 0, 'splice removed rejected' );
    
    diag( "Removing callbacks" ) if( $DEBUG );
    $test->callback( add => undef );
    $test->callback( remove => undef );
    ok( !tied( @$test ), 'callbacks removed' );
};

subtest 'filter' => sub
{
    my $a = Module::Generic::Array->new( [qw( John Jack Peter Gabriel Samuel )] );
    my $n = -1;
    my $new = $a->filter(sub
    {
        is( $_[0], $a->[ ++$n ], "value at index $n" );
        is( $n, $_[1], "value at index $n" );
        is( ref( $_[2] ), ref( $a ), 'array object' );
        substr( $_, 0, 1 ) ne 'J';
    });
    is( $new->length, 3 );
    is( "@$new", 'Peter Gabriel Samuel' );
    # With a first object argument
    $n = -1;
    $new = $a->filter(sub
    {
        isa_ok( $_[0], 'Module::Generic::Array', "'this' additional value pass" );
        is( $_[1], $a->[ ++$n ], "value at index $n" );
        is( $n, $_[2], "value at index $n" );
        is( ref( $_[3] ), ref( $a ), 'array object' );
        substr( $_, 0, 1 ) ne 'J';
    }, $a);
};

subtest 'threaded usage' => sub
{
    SKIP:
    {
        if( !$Config{useithreads} )
        {
            skip( 'Threads are not available on this system', 1 );
        }

        require threads;
        threads->import();

        # Basic threaded operations
        my $thr = threads->create(sub
        {
            my $a = Module::Generic::Array->new([ 1..3 ]);
            my $sum = 0;
            $a->foreach(sub
            {
                $sum += $_;
            });
            return( $sum );
        });

        my $result = $thr->join;
        is( $result, 6, 'Sum of array in thread is correct' );

        # Multiple concurrent modifications
        my @threads;
        for my $i (1..5)
        {
            push @threads, threads->create(sub
            {
                my $a = Module::Generic::Array->new([ 1 .. 5 ]);
                $a->push( 6, 7 );
                $a->splice( 3, 2 ); # Remove 2 elements starting at index 3
                return( scalar( @$a ) );
            });
        }

        foreach my $thr ( @threads )
        {
            my $len = $thr->join;
            is( $len, 5, 'Array modified in thread has correct length after splice and push' );
        }

        # Threaded read/write consistency
        my $shared_array = Module::Generic::Array->new([ 1..10 ]);

        my @worker_threads;
        foreach my $n (1..3)
        {
            push @worker_threads, threads->create(sub
            {
                my $arr = Module::Generic::Array->new( [ 1..10 ] );
                $arr->push( $n * 100 );
                return( [ $arr->list ] );
            });
        }

        foreach my $thr ( @worker_threads )
        {
            my $list = $thr->join;
            ok( scalar( grep { $_ == 100 || $_ == 200 || $_ == 300 } @$list ) > 0, 'Array was updated by thread with expected value' );
        }
    };
};

done_testing();
