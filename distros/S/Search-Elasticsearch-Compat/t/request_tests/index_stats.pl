#!perl

use Test::More;
use strict;
use warnings;
our $es;
my $r;

### INDEX STATS ###

ok $r= $es->index_stats()->{_all}, 'Index status - all';

ok $r->{indices}{es_test_1}
    && $r->{indices}{es_test_2},
    ' - all indices';

ok $r->{total}{indexing}
    && $r->{total}{store}
    && $r->{total}{docs},
    ' - default stats';

ok $r= $es->index_stats(
    index    => 'es_test_1',
    types    => 'type_1',
    clear    => 1,
    indexing => 1
)->{_all}, ' - clear';

ok $r->{indices}{es_test_1}
    && !$r->{indices}{es_test_2},
    ' - one index';

ok $r->{total}{indexing}
    && !$r->{total}{store}
    && !$r->{total}{docs},
    ' - cleared stats';

ok $r= $es->index_stats(
    clear    => 1,
    docs     => 1,
    get      => 1,
    store    => 1,
    indexing => 1,
    flush    => 1,
    merge    => 1,
    refresh  => 1,
    types    => [ 'type_1', 'type_2' ],
    level    => 'shards'
    )->{_all}{indices}{es_test_1},
    ' - all options';

ok $r->{shards}, ' - shards';

$r = $r->{total};
ok $r->{docs}
    && $r->{store}
    && $r->{flush}
    && $r->{get}
    && $r->{indexing}
    && $r->{merges}
    && $r->{refresh},
    ' - all stats';

ok $r= $es->index_stats( all => 1 )->{_all}{indices}{es_test_1},
    ' - all flag';

$r = $r->{total};
ok $r->{docs}
    && $r->{store}
    && $r->{flush}
    && $r->{get}
    && $r->{indexing}
    && $r->{merges}
    && $r->{refresh},
    ' - all stats';

ok $es->search( index => 'es_test_1', stats => 'foo' ),
    ' - search with stats';
ok $r= $es->index_stats( clear => 1, search => 1, groups => 'foo' )
    ->{_all}{primaries}{search}{groups}{foo}, ' - stats with groups';

throws_ok { $es->index_stats( index => 'foo' ) } qr/Missing/,
    ' - index missing';

1;
