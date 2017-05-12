#!perl -Tw

use strict;
use warnings;

use Test::More qw(no_plan);
use SeeAlso::Source;
use SeeAlso::Identifier;

my $cache;

$cache = eval { require Cache::Memory; Cache::Memory->new }
    or diag( 'Skipping cache test with Cache::Memory' );
test_cache( $cache ) if $cache;

# Not supported yet
if (0) {
$cache = eval { require CHI; CHI->new( driver => 'Memory' ) }
    or diag( 'Skipping cache test with CHI' );
test_cache( $cache ) if $cache;
}

ok(1);

sub test_cache {
    my $cache = shift;

    my $value = 1;
    my $query_method = sub {
        my $id = shift;
        my $r = SeeAlso::Response->new( $id );
        $r->add( $value );
        $value++;
        return $r;
    };
    my $source = new SeeAlso::Source( $query_method, cache => $cache );
    is( $source->query('0')->as_string, '["0",["1"],[""],[""]]', 'cache (1)' );
    is( $source->query('0')->as_string, '["0",["1"],[""],[""]]', 'cache (2)' );
    is( $source->query('0', force => 1 )->as_string, '["0",["2"],[""],[""]]', 'cache (3)' );
    is( $source->query('0')->as_string, '["0",["2"],[""],[""]]', 'cache (4)' );
    $cache->clear;
    is( $source->query('0')->as_string, '["0",["3"],[""],[""]]', 'cache (5)' );
}
