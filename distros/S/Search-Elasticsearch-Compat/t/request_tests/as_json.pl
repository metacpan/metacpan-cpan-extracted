#!perl

use Test::More;
use strict;
use warnings;
our $es;
my $r;

my $json = $es->JSON;

ok $r = $es->cluster_health( as_json => 1 ), 'As JSON';
isa_ok $json->decode($r), 'HASH', ' - is JSON';

ok $r = $es->bulk_index(
    docs => [
        { index => 'es_test_1', type => 'type_1', data => { text => 'foo' } }
    ],
    as_json => 1
    ),
    ' - bulk as JSON';
isa_ok $json->decode($r), 'HASH', ' - is JSON';

is_deeply $json->decode( $es->bulk( actions => [], as_json => 1 ) ),
    { actions => [], results => [] }, ' - no actions';

1;
