#!perl

use Test::More;
use strict;
use warnings;
our $es;
my $r;

ok $es->create(
    index   => 'es_test_1',
    type    => 'type_1',
    id      => 1,
    data    => { text => 'foo', num => 123 },
    refresh => 1
)->{ok}, 'Create document';

throws_ok {
    $es->create(
        index => 'es_test_1',
        type  => 'type_1',
        id    => 1,
        data  => { text => 'foo', num => 123 }
    );
}
qr/Conflict/, ' - create conflict';

ok $es->create(
    index   => 'es_test_1',
    type    => 'type_1',
    data    => { text => 'foo', num => 123 },
    refresh => 1
)->{_id} ne '_create', 'Create document without ID';

ok $es->index(
    index   => 'es_test_1',
    type    => 'type_1',
    id      => 1,
    data    => { text => 'foo', num => 123 },
    refresh => 1
)->{ok}, 'Index document';

throws_ok {
    $es->index(
        index   => 'es_test_1',
        type    => 'type_1',
        id      => 1,
        version => 1,
        data    => { text => 'foo', num => 123 }
    );
}
qr/Conflict/, ' - index conflict 1';

throws_ok {
    $es->index(
        index   => 'es_test_1',
        type    => 'type_1',
        id      => 1,
        version => 3,
        data    => { text => 'foo', num => 123 }
    );
}
qr/Conflict/, ' - index conflict 2';

is eval {
    $es->index(
        index   => 'es_test_1',
        type    => 'type_1',
        id      => 1,
        version => 1,
        data    => { text => 'foo', num => 123 }
    );
}
    || $@->{-vars}{current_version}, 2,
    'Conflict error has current version';

ok $es->index(
    index   => 'es_test_1',
    type    => 'type_1',
    id      => 1,
    version => 2,
    data    => { text => 'foo', num => 123 },
    refresh => 1
)->{ok}, ' - index correct version';

is $es->index(
    index        => 'es_test_1',
    type         => 'type_1',
    id           => 5,
    version      => 10,
    version_type => 'external',
    data         => { text => 'foo', num => 123 },
    refresh      => 1
)->{_version}, 10, ' - index version_type external';

is $es->index(
    index        => 'es_test_1',
    type         => 'type_1',
    id           => 6,
    version      => 10,
    version_type => 'external',
    data         => { text => 'foo', num => 123 },
    refresh      => 1
)->{_version}, 10, ' - create version_type external';

# RAW JSON DATA
ok $es->index(
    index => 'es_test_1',
    type  => 'type_1',
    id    => 6,
    data  => '{"text": "bar","num":124}'
    ),
    'Index JSON';

ok $r= $es->get(
    index => 'es_test_1',
    type  => 'type_1',
    id    => 6
    )->{_source},
    ' - get doc';

ok $r->{text} eq 'bar' && $r->{num} == 124, ' - doc OK';

ok $es->create(
    index => 'es_test_1',
    type  => 'type_1',
    id    => 7,
    data  => '{"text": "baz","num":125}'
    ),
    'Create JSON';

ok $r= $es->get(
    index => 'es_test_1',
    type  => 'type_1',
    id    => 7
    )->{_source},
    ' - get doc';

ok $r->{text} eq 'baz' && $r->{num} == 125, ' - doc OK';

1
