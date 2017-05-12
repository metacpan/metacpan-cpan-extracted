#!perl

use Test::More;
use strict;
use warnings;
our $es;
my $r;

### INDEX EXISTS  ###

ok $es->index_exists(), 'Index exists';
ok $es->index_exists( index => 'es_test_1' ), ' - one';
ok $es->index_exists( index => [ 'es_test_1', 'es_test_2' ] ), ' - two';
ok !$es->index_exists( index => ['foo'] ), ' - missing';

#### REFRESH INDEX ###
ok $es->refresh_index()->{ok}, 'Refresh index';

### FLUSH INDEX ###
ok $es->flush_index()->{ok}, 'Flush index';
ok $es->flush_index( refresh => 1 )->{ok}, ' - with refresh';
ok $es->flush_index( full    => 1 )->{ok}, ' - with full';

### OPTIMIZE INDEX ###
ok $es->optimize_index()->{ok}, 'Optimize all indices';
ok $es->optimize_index( only_deletes => 1 )->{ok}, ' - only_deletes';
ok $es->optimize_index( flush        => 0 )->{ok}, ' - without flush';
ok $es->optimize_index( refresh      => 0 )->{ok}, ' - without refresh';
ok $es->optimize_index( wait_for_merge => 0 )->{ok},
    ' - without wait_for_merge';
ok $es->optimize_index( max_num_segments => 1 )->{ok},
    ' - with max_num_segments';

### SNAPSHOT INDEX ###
ok $es->snapshot_index()->{ok},   'Snapshot all indices';
ok $es->gateway_snapshot()->{ok}, ' - with gateway_snapshot';
ok $es->snapshot_index( index => [ 'es_test_1', 'es_test_2' ], )->{ok},
    'Snapshot test indices';
ok $es->gateway_snapshot( index => [ 'es_test_1', 'es_test_2' ] )->{ok},
    ' - with gateway_snapshot';

for my $method (
    qw(refresh_index flush_index optimize_index snapshot_index gateway_snapshot)
    )
{
    throws_ok { $es->$method( index => 'foo' ) } qr/Missing/,
        "$method index missing";
}

1
