#!/usr/bin/perl
BEGIN
{
    use Test::More qw( no_plan );
    use strict;
    use warnings;
    use utf8;
    use Cwd qw( abs_path );
    use lib abs_path( './lib' );
    use Config;
    use JSON;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN { use_ok( 'Module::Generic::Hash' ) || BAIL_OUT( "Unable to load Module::Generic::Hash" ); }

my $hash =
{
    first_name => 'John',
    last_name => 'Doe',
    age => 30,
    email => 'john.doe@example.com',
};

my @keysA = sort( keys( %$hash ) );

my $h = Module::Generic::Hash->new( $hash );
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
is( $h->as_json( order => 1 ), '{"age":30,"email":"john.doe@example.com","first_name":"John","last_name":"Doe"}', 'as_json' );
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
is( $h->json( order => 1 ), '{"age":30,"email":"john.doe@example.com","first_name":"John","last_name":"Doe"}', 'Hash as terse json' );
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


$h->debug(3);
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

my $hash4 = { name => 'John Doe', age => 42, location => 'here' };
my $h4 = Module::Generic::Hash->new( $hash4 );
my $j = JSON->new->convert_blessed->canonical;
eval
{
    my $json = $j->encode( $h4 );
    is( $json, '{"age":42,"location":"here","name":"John Doe"}', 'TO_JSON' );
};
if( $@ )
{
    # diag( "Error encoding: $e" );
    fail( 'TO_JSON' );
}

subtest 'Thread-safe hash operations' => sub
{
    SKIP:
    {
        if( !$Config{useithreads} )
        {
            skip( 'Threads not available', 2 );
        }

        require threads;
        require threads::shared;

        my @threads = map
        {
            threads->create(sub
            {
                my $tid = threads->tid();
                my $h = Module::Generic::Hash->new( first_name => "John" );
                if( !$h->merge( { tid => $tid } ) )
                {
                    diag( "Thread $tid: Failed to merge: ", $h->error ) if( $DEBUG );
                    return(0);
                }
                if( !$h->exists( 'tid' ) )
                {
                    diag( "Thread $tid: Merged key 'tid' does not exist" ) if( $DEBUG );
                    return(0);
                }
                return(1);
            });
        } 1..5;

        my $success = 1;
        for my $thr ( @threads )
        {
            $success &&= $thr->join();
        }

        ok( $success, 'All threads merged successfully' );
        ok( !defined( $Module::Generic::Hash::KEY_OBJECT ) || $Module::Generic::Hash::KEY_OBJECT == 0, 'Global $KEY_OBJECT unchanged' );
    };
};

done_testing();

__END__
