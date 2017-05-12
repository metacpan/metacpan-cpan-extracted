#!perl

use Test::More;
use strict;
use warnings;
our $es;
my $r;

throws_ok { $es->delete( index => 'es_test_1', type => 'type_1', id => 2 ) }
qr/Missing/, 'Delete - missing';
ok !$es->delete(
    index          => 'es_test_1',
    type           => 'type_1',
    id             => 2,
    ignore_missing => 1
    ),
    ' - ignore missing';

throws_ok {
    $es->delete(
        index   => 'es_test_1',
        type    => 'type_1',
        id      => 1,
        version => 1
    );
}
qr/Conflict/, ' - version conflict';

ok $es->delete(
    index       => 'es_test_1',
    type        => 'type_1',
    id          => 1,
    version     => 3,
    refresh     => 1,
    replication => 'async',
    consistency => 'all'
)->{ok}, ' - version delete with options';

1
