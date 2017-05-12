use Test::More 'no_plan';
use Test::Deep;
use lib '../lib';
use NG;

my $hash = new Hashtable;

isa_ok $hash, 'Hashtable';

$hash->put( 'key1', 1 );
$hash->put( 'key2', 2 );
$hash->put( 'key3', 3 );

is $hash->get('key1'), 1;

cmp_deeply $hash->keys->sort(sub{
	my ($a, $b) = @_;
	return $a cmp $b
}), Array->new( 'key1', 'key2', 'key3' );
cmp_deeply $hash->values,       Array->new( 2,      1,      3 );
cmp_deeply $hash->values->sort, Array->new( 1,      2,      3 );

$hash->remove('key1');

cmp_deeply $hash->keys,   Array->new( 'key2', 'key3' );
cmp_deeply $hash->values, Array->new( 2,      3 );

$hash->each(
    sub {
        my ( $key, $val ) = @_;
        $hash->put( $key, $val + 1 );
    }
);

cmp_deeply $hash->values, Array->new( 3, 4 );
