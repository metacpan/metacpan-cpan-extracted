#!perl

use Test::More;
use Test::Exception;
use strict;
use warnings;
our $es;
my $r;

$es->index(
    index => 'es_test_1',
    type  => 'foo',
    id    => 1,
    data  => { text => 'foo bar baz', num => 1 }
);

ok $es->close_index( index => 'es_test_1' )->{ok}, 'Closed index';

wait_for_es();

throws_ok sub { $es->count( index => 'es_test_1', match_all => {} ) },
    qr/ClusterBlocked/, ' - cluster blocked';

ok $es->open_index( index => 'es_test_1' )->{ok}, 'Opened index';

wait_for_es();

is $es->count( index => 'es_test_1', match_all => {} )->{count}, 1,
    ' - index reopened';
1;
