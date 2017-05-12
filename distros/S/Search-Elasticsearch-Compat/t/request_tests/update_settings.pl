#!perl

use Test::More;
use strict;
use warnings;
our $es;
my $r;

### UPDATE SETTINGS ###
ok $es->update_index_settings(
    index    => 'es_test_1',
    settings => { number_of_replicas => 2 }
    ),
    'Update index settings';

wait_for_es();

is $es->index_settings( index => 'es_test_1' )
    ->{'es_test_1'}{settings}{'index.number_of_replicas'}, 2,
    ' - has 2 replicas';

ok $es->update_index_settings(
    index    => 'es_test_1',
    settings => { number_of_replicas => 1 }
    ),
    ' - reset to 1 replica';

wait_for_es();

is $es->index_settings( index => 'es_test_1' )
    ->{'es_test_1'}{settings}{'index.number_of_replicas'}, 1,
    ' - has 1 replica';

throws_ok {
    $es->update_index_settings(
        index    => 'foo',
        settings => { number_of_replicas => 1 }
        ),
        ;
}
qr/Missing/, ' - index missing';

1;
