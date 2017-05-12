use Test::More 'no_plan';
use Test::Deep;
use lib '../lib';
use NG;

my $hash = new SHashtable;

isa_ok $hash, 'SHashtable';

$hash->put( 'key1', 1 );
$hash->put( 'key2', 2 );
$hash->put( 'key3', 3 );

is $hash->get('key1'), 1;

my $array = new Array;
$hash->each(
    sub {
        my ( $key, $val ) = @_;
        $array->push( $key );
    }
);

cmp_deeply $array, Array->new( 'key1', 'key2', 'key3' );
