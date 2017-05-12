#!/usr/bin/env perl

use Test::More;

### Test class supplying mock queries to cache
package My::Test::Cachee;

use 5.010;

sub new {
    state $i = 1;
    bless {
        serial => $i++,
        sth    => { Active => 1, Database => { Active => 1 } }
      },
      shift;
}

sub sth {
    return shift->{sth};
}

package main;

require_ok('Rose::DBx::CannedQuery::SimpleQueryCache');
my $cache = new_ok('Rose::DBx::CannedQuery::SimpleQueryCache');

my $dummy0   = My::Test::Cachee->new();
my $dummy1   = My::Test::Cachee->new();
my $dummy2   = My::Test::Cachee->new();
my $keyargs  = { some => 'args', for => 'key  ' };
my $keyargs2 = { other => 'args', for => 'key' };

ok( $cache->add_query_to_cache( $dummy0, $keyargs ), 'Add item to cache' );

$cache->add_query_to_cache( $dummy2, $keyargs2 );

is( $cache->get_query_from_cache($keyargs),
    $dummy0, 'Retrieve item from cache' );
is(
    $cache->get_query_from_cache(
        { map { tr/A-Za-z/a-zA-Z/; s/ /  /; $_ } %$keyargs }
    ),
    $dummy0,
    'Non-significant changes to arguments'
);
ok( !$cache->get_query_from_cache( { no => 'thing' } ),
    'Nothing returned for non-cached key' );

$dummy0->{sth}->{Active} = $dummy0->{sth}->{Database}->{Active} = 0;
ok(
    !$cache->get_query_from_cache($keyargs),
    'Nothing returned for inactive query'
);

$dummy0->{sth}->{Active} = $dummy0->{sth}->{Database}->{Active} = 1;
ok(
    !$cache->get_query_from_cache($keyargs),
    'Inactive query dropped from cache'
);

$cache->add_query_to_cache( $dummy0, $keyargs );
ok( $cache->add_query_to_cache( $dummy1, $keyargs ), 'Replace item in cache' );
is( $cache->get_query_from_cache($keyargs),
    $dummy1, 'Retrieve new item from cache' );

ok( $cache->remove_query_from_cache($keyargs), 'Remove object' );
ok( !$cache->get_query_from_cache($keyargs),   'Removed object is gone' );
is( $cache->get_query_from_cache($keyargs2),
    $dummy2, 'Other object still there' );

ok( $cache->clear_query_cache,                'Clear cache' );
ok( !$cache->get_query_from_cache($keyargs2), 'Cached object is gone' );

done_testing;
