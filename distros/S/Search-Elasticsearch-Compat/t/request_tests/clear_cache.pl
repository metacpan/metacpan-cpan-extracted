#!perl

use Test::More;
use strict;
use warnings;
our $es;
my $r;

no warnings 'redefine';

### CLEAR INDEX CACHE ###
ok $es->clear_cache->{ok}, 'Clear all index caches';
ok $es->clear_cache( index => 'es_test_1' )->{ok}, ' - just index 1';
ok $es->clear_cache( index => [ 'es_test_1', 'es_test_2' ] )->{ok},
    ' - index 1 and 2';

$es->index(
    index => 'es_test_1',
    type  => 'foo',
    id    => 1,
    data  => { text => 'foo bar baz', num => 1 }
);
wait_for_es();

populate_caches();

ok $es->clear_cache( field_data => 1 )->{ok}, ' - clear field cache';
my $caches = used_caches();
ok !$caches->{field}, ' - field cache cleared';
ok $caches->{filter}, ' - filter cache not cleared';

populate_caches();
ok $es->clear_cache( filter => 1 )->{ok}, ' - clear filter cache';
$caches = used_caches();
ok $caches->{field}, ' - field cache not cleared';

# filter cache not cleared immediately anymore
# instead, scheduled for later clearance
#ok !$caches->{filter}, ' - filter cache cleared';

# cannot check for id and bloom caches yet

ok $es->clear_cache( id => 1, bloom => 1 )->{ok}, ' - cache types';

throws_ok { $es->clear_cache( index => 'foo' ) } qr/Missing/,
    ' - index missing';

#===================================
sub used_caches {
#===================================
    my %cache = (
        field  => 0,
        filter => 0
    );
    for ( values %{ $es->nodes_stats->{nodes} } ) {
        $cache{field}  += $_->{indices}{cache}{field_size_in_bytes};
        $cache{filter} += $_->{indices}{cache}{filter_size_in_bytes};
    }
    return \%cache;
}

#===================================
sub populate_caches {
#===================================
    $es->search(
        query => {
            filtered => {
                filter => { term  => { num => 1 } },
                query  => { range => { num => { gt => 0, lt => 5 } } }
            }
        },
        sort => { num => 'asc' }
    );
    sleep 1;    ## otherwise cached results
    my $caches = used_caches();
    ok $caches->{field},  ' - field cache populated';
    ok $caches->{filter}, ' - filter cache populated';

}
1
