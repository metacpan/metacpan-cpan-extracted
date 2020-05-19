# -*- perl -*-

# t/03.hash.t - check for hash object

use Test::More qw( no_plan );
use strict;
use warnings;
use utf8;

BEGIN { use_ok( 'Module::Generic' ) || BAIL_OUT( "Unable to load Module::Generic" ); }

my $hash =
{
    first_name => 'John',
    last_name => 'Doe',
    age => 30,
    email => 'john.doe@example.com',
};

my @keysA = sort( keys( %$hash ) );

my $h = Module::Generic::Hash->new( $hash,
{
    debug => 3,
});
isa_ok( $h, 'Module::Generic::Hash', 'Hash object class' );
my $keys = $h->keys;
isa_ok( $keys, 'Module::Generic::Array', 'Keys as array reference' );
ok( $keys eq [@keysA], 'Comparing two arrays of keys' );
my @keysB = keys( %$h );
# diag( "@keysB" );

# diag( "Removing one key from array A, and testing again." );
$keys->pop;
ok( $keys ne [@keysA], 'two arrays of keys mismatch' );
# diag( $h->as_string );
my $str = '{
  "age" => 30,
  "email" => "john.doe\@example.com",
  "first_name" => "John",
  "last_name" => "Doe"
}
';
is( $h->as_string, $str, 'Hash as string' );
# No, that was a dumb idea
# is( "$h", $str, 'Hash stringified' );
my $json = '{
   "age" : 30,
   "email" : "john.doe@example.com",
   "first_name" : "John",
   "last_name" : "Doe"
}
';
is( $h->json({ pretty => 1 }), $json, 'Hash as json' );
# Terse version
is( $h->json(), '{"age":30,"email":"john.doe@example.com","first_name":"John","last_name":"Doe"}', 'Hash as terse json' );
$h->{role} = 'customer';
ok( $h->defined( 'role' ), 'Defined' );
my $old = $h->delete( 'role' );
is( $old, 'customer', 'Removed value' );
ok( !$h->defined( 'role' ), 'Removed key is undefined' );
$h->each(sub
{
    my( $k, $v ) = @_;
    is( $v, $hash->{ $k }, 'Checking hash value with each' );
});
ok( exists( $h->{age} ), 'exists' );
ok( $h->exists( 'age' ), 'exists method' );
$h->for(sub{
    my( $k, $v ) = @_;
    is( $v, $hash->{ $k }, 'Checking hash value with for/foreach' );
});
is( $h->length, 4, 'Hash size' );
my $hash2 =
{
    address =>
    {
    line1 => '1-2-3 Kudan-minami, Chiyoda-ku',
    line2 => 'Big bld 7F',
    postal_code => '123-4567',
    city => 'Tokyo',
    country => 'jp',
    },
    last_name => 'Smith',
};

my $h2 = Module::Generic::Hash->new( $hash2 );
ok( $h > $h2, 'HashA > HashB' );
ok( $h gt $h2, 'HashA gt HashB' );
ok( $h >= $h2, 'HashA >= HashB' );
ok( !($h < $h2), 'HashA < HashB -> false' );
ok( $h2 < $h, 'HashB < HashA' );
ok( $h2 lt $h, 'HashB lt HashA' );
ok( $h2 <= $h, 'HashB <= HashA' );
ok( $h > 2, 'HashA > 2' );
ok( !($h > 10), 'HashA > 10 -> false' );
ok( 3 < $h, '3 < HashA' );
ok( $h2 < 10, 'HashB < 10' );
ok( 7 >= $h2, '7 >= HashB' );


$h->debug( 3 );
is( $h->debug, 3, 'Internal method (debug)' );
# without overwriting
$h->merge( $hash2, { overwrite => 0 });
is( $h->{last_name}, 'Doe', 'Merge without overwriting' );
$h->merge( $hash2 );
is( $h->{address}->{city}, 'Tokyo', 'Checking merged hash' );
is( $h->{last_name}, 'Smith', 'Merge with overwriting' );
# diag( $h->as_string );
is( $h->length, 5, 'Hash size after merge' );
my $vals = $h->values(sub{
    ref( $_[0] ) ? () : $_[0];
}, { sort => 1 });
isa_ok( $vals, 'Module::Generic::Array', 'values class' );
is( $vals->join( ',' ), '30,John,Smith,john.doe@example.com', 'values' );
my $h3 = $h->clone;
# diag( "\$h3 is " . $h3->as_string );
ok( $h3 eq $h, 'Comparing hashes (eq)' );
ok( $h ne $h2, 'Comparing hashes (ne)' );
