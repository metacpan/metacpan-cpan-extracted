#!perl

use Test::More;
use strict;
use warnings;
our ( $es, $es_version );
my $r;

SKIP: {
    skip "type_exists only supported in version 0.20", 6
        if $es_version lt '0.20';

    ok $es->type_exists( type => 'type_1' ), ' - all/type_1 exists';
    ok $es->type_exists( type => [ 'type_1', 'type_2' ] ),
        ' - all/type_1&2 exist';
    ok !$es->type_exists( type => [ 'type_1', 'type_3' ] ),
        ' - all/type_1&3 do not exist';

    ok $es->type_exists( index => 'es_test_1', type => 'type_1' ),
        ' - es1/type_1 exists';
    ok $es->type_exists(
        index => [ 'es_test_1', 'es_test_2' ],
        type  => 'type_1'
        ),
        ' - es1&2/type_1 exist';
    ok !$es->type_exists(
        index => [ 'es_test_1', 'es_test_3' ],
        type  => 'type_1'
        ),
        ' - es1&3/type_1 do not exist';
}
1
