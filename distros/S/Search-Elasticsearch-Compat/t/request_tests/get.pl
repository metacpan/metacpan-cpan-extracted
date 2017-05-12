#!perl

use Test::More;
use strict;
use warnings;
our $es;
my $r;

is $es->get( index => 'es_test_1', type => 'type_1', id => 1 )->{_id}, 1,
    'Get document';

is $es->get( index => 'es_test_1', type => 'type_1', id => 1, refresh => 1 )
    ->{_id}, 1,
    ' - with refresh';

is $es->get(
    index  => 'es_test_1',
    type   => 'type_1',
    id     => 1,
    fields => 'num'
)->{fields}{num}, 123, ' - specify fields';

ok $r= $es->get(
    index  => 'es_test_1',
    type   => 'type_1',
    id     => 1,
    fields => []
    ),
    ' - specify no fields';
ok !$r->{fields} && !$r->{_source}, ' - no fields returned';

throws_ok { $es->get( index => 'es_test_1', type => 'type_1', id => 2 ) }
qr/Missing/, ' - id missing';
throws_ok { $es->get( index => 'es_test_1', type => 'type_3', id => 1 ) }
qr/Missing/, ' - type missing';
throws_ok { $es->get( index => 'es_test_3', type => 'type_1', id => 1 ) }
qr/Missing/, ' - index missing';

ok !$es->get(
    index          => 'es_test_1',
    type           => 'type_1',
    id             => 2,
    ignore_missing => 1
    ),
    ' - id ignore missing';
ok !$es->get(
    index          => 'es_test_1',
    type           => 'type_3',
    id             => 1,
    ignore_missing => 1
    ),
    ' - type ignore missing';
ok !$es->get(
    index          => 'es_test_3',
    type           => 'type_1',
    id             => 1,
    ignore_missing => 1
    ),
    ' - index ignore missing';

is $es->get( index => 'es_test_1', id => 1 )->{_id}, 1, ' - get without type';

1,
