#!perl

use Test::More;
use strict;
use warnings;
our $es;
my $r;

### BULK INDEXING ###
drop_indices();
$es->create_index( index => 'es_test_1' );
wait_for_es();
$es->put_mapping(
    index   => 'es_test_1',
    type    => 'test',
    mapping => {
        properties =>
            { text => { type => 'string' }, num => { type => 'integer' } }
    }
);

wait_for_es();

ok $r= $es->bulk(
    refresh => 1,
    actions => [
        {   index => {
                index => 'es_test_1',
                type  => 'test',
                id    => 1,
                data  => { text => 'foo', num => 1 }
            }
        },
        {   index => {
                index => 'es_test_1',
                type  => 'test',
                id    => 2,
                data  => { text => 'foo', num => 1 }
            }
        },
        {   create => {
                index => 'es_test_1',
                type  => 'test',
                id    => 3,
                data  => { text => 'foo', num => 1 }
            }
        },
        {   index => {
                index => 'es_test_1',
                type  => 'test',
                id    => 4,
                data  => { text => 'foo', num => 'bar' }
            }
        },
        { delete => { index => 'es_test_1', type => 'test', id => 2 } }
    ]
    ),
    'Bulk actions';

is @{ $r->{actions} }, 5, ' - 5 actions';
is @{ $r->{results} }, 5, ' - 5 results';
is @{ $r->{errors} },  1, ' - 1 error';
ok $r->{errors}[0]{action}, ' - error has action';
like( $r->{errors}[0]{error},
    qr/NumberFormatException/, ' - error has message' );
is $es->count( match_all => {} )->{count}, 2, ' - 2 docs indexed';

my $hits = $es->search( query => { match_all => {} } )->{hits}{hits};

is @{ $es->bulk_create( { refresh => 1, docs => $hits } )->{results} }, 2,
    ' - roundtrip - bulk_create';

is $es->count( match_all => {} )->{count}, 2, ' - 2 docs created';

is @{ $es->bulk_index( { refresh => 1, docs => $hits } )->{results} }, 2,
    ' - roundtrip - bulk_index';

is $es->count( match_all => {} )->{count}, 2, ' - 2 docs reindexed';

is @{
    $es->bulk_delete(
        docs => [
            map { { _index => 'es_test_1', _type => 'test', _id => $_ } }
                ( 1, 3 )
        ],
        refresh => 1,
    )->{results}
    },
    2, ' - bulk_delete';

is $es->count( match_all => {} )->{count}, 0, ' - 2 docs deleted';

ok $r= $es->bulk(
    refresh => 1,
    actions => [
        {   index => {
                index   => 'es_test_1',
                type    => 'test',
                id      => 1,
                data    => { text => 'foo', num => 1 },
                version => 10
            }
        },
        {   index => {
                index        => 'es_test_1',
                type         => 'test',
                id           => 2,
                data         => { text => 'foo', num => 1 },
                version      => 10,
                version_type => 'external'
            }
        },
        {   create => {
                index   => 'es_test_1',
                type    => 'test',
                id      => 3,
                data    => { text => 'foo', num => 1 },
                version => 10
            }
        },
        {   create => {
                index        => 'es_test_1',
                type         => 'test',
                id           => 4,
                data         => { text => 'foo', num => 1 },
                version      => 10,
                version_type => 'external'
            }
        },
    ],
    )->{results},
    'Bulk versions';

like $r->[0]{index}{error}, qr/Conflict/, ' - index version conflict';
ok $r->[1]{index}{ok},       ' - index external version ok';
like $r->[2]{create}{error}, qr/Conflict/, ' - create version conflict';
ok $r->[3]{create}{ok},      ' - create external version ok';

ok $r = $es->bulk(
    refresh     => 1,
    index       => 'es_test_1',
    type        => 'test',
    consistency => 'quorum',
    replication => 'async',
    actions     => [
        { index => { id => 5, data => { text => 'foo' } } },
        { index => { id => 6, type => 'test_2', data => { text => 'bar' } } },
        {   index =>
                { id => 7, index => 'es_test_2', data => { text => 'baz' } }
        },
    ]
)->{results}, 'Inherited params';

ok $r->[0]{index}{_index} eq 'es_test_1'
    && $r->[0]{index}{_type} eq 'test'
    && $r->[0]{index}{_id} == 5, ' - doc 1';
ok $r->[1]{index}{_index} eq 'es_test_1'
    && $r->[1]{index}{_type} eq 'test_2'
    && $r->[1]{index}{_id} == 6, ' - doc 2';
ok $r->[2]{index}{_index} eq 'es_test_2'
    && $r->[2]{index}{_type} eq 'test'
    && $r->[2]{index}{_id} == 7, ' - doc 3';

# Raw JSON data

ok $es->bulk(
    actions => [
        {   index => {
                index => 'es_test_1',
                type  => 'type_1',
                id    => 6,
                data  => '{"text": "bar","num":124}'
            }
        },
        {   create => {
                index => 'es_test_1',
                type  => 'type_1',
                id    => 7,
                data  => '{"text": "baz","num":125}'
            }
        }
    ]
    ),
    'Bulk raw JSON';

ok $r= $es->get(
    index => 'es_test_1',
    type  => 'type_1',
    id    => 6
    )->{_source},
    ' - get doc 1';

ok $r->{text} eq 'bar' && $r->{num} == 124, ' - doc 1 OK';

ok $r= $es->get(
    index => 'es_test_1',
    type  => 'type_1',
    id    => 7
    )->{_source},
    ' - get doc 2';

ok $r->{text} eq 'baz' && $r->{num} == 125, ' - doc 2 OK';

1
