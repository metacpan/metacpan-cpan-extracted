#!perl

use Test::More;
use strict;
use warnings;
our $es;
my $r;

### INDEX STATUS ###
my $indices;
ok $indices = $es->index_status()->{indices}, 'Index status - all';
ok $indices->{'es_test_1'}, ' - Index 1 exists';
ok $indices->{'es_test_2'}, ' - Index 2 exists';

is $es->cluster_state->{metadata}{indices}{'es_test_2'}{settings}
    {"index.number_of_shards"}, 3, ' - Index 2 settings';

throws_ok { $es->index_status( index => 'foo' ) } qr/Missing/,
    ' - index missing';

ok $r= $es->index_status( index => 'es_test_1', recovery => 1, snapshot => 1 )
    ->{indices}{es_test_1}{shards}{0}, ' - recovery and snapshot';

ok $r->[0]{peer_recovery} || $r->[0]{gateway_recovery}, ' - recovery';

1;
