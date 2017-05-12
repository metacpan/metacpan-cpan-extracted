#!perl

use Test::More;
use strict;
use warnings;
our ( $es, $es_version );
my $r;

ok $es->update(
    index  => 'es_test_1',
    type   => 'type_1',
    id     => 7,
    script => 'ctx._source.extra= "foo"'
    ),
    'Update doc';

is $es->get( index => 'es_test_1', type => 'type_1', id => 7, refresh => 1 )
    ->{_source}{extra}, 'foo', ' - doc updated';

ok $es->update(
    index             => 'es_test_1',
    type              => 'type_1',
    id                => 7,
    script            => 'ctx._source.extra= "foo"',
    params            => { foo => 'bar' },
    ignore_missing    => 1,
    percolate         => '*',
    retry_on_conflict => 3,
    timeout           => '30s',
    replication       => 'sync',
    consistency       => 'quorum',
    routing           => 'xx',
    parent            => 'xx',
    )
    || 1,
    ' - all opts';

SKIP: {
    skip "upsert only supported in version 0.20", 6
        if $es_version lt '0.20';
    ok $r= $es->update(
        index  => 'es_test_1',
        type   => 'type_1',
        id     => 1000,
        script => 'ctx._source.extra="foo"',
        upsert => { bar => 'baz' },
        fields => ['_source']
        ),
        ' - upsert missing';

    is $r->{get}{_source}{bar}, 'baz', ' - doc upserted';
    ok !$r->{get}{_source}{extra}, ' - script not run';

    ok $r= $es->update(
        index  => 'es_test_1',
        type   => 'type_1',
        id     => 1000,
        script => 'ctx._source.extra="foo"',
        upsert => { bar => 'baz' },
        fields => ['_source']
        ),
        ' - upsert existing';

    is $r->{get}{_source}{bar},   'baz', ' - doc upserted';
    is $r->{get}{_source}{extra}, 'foo', ' - script run';

    ok $r= $es->update(
        index  => 'es_test_1',
        type   => 'type_1',
        id     => 1000,
        doc    => { lala => 'po' },
        fields => ['_source']
        ),
        ' - update via doc';

    is $r->{get}{_source}{lala}, 'po', ' - doc merged';
}

1
