#!perl

use Test::More;
use strict;
use warnings;
our $es;
my $r;

isa_ok $r= $es->msearch(
    index   => 'es_test_1',
    type    => 'type_1',
    queries => [
        { query => { match_all => {} } },
        {   index => 'es_test_2',
            type  => 'type_2',
            query => { match_all => {} }
        },
    ],
    ),
    'ARRAY',
    'msearch array';

is $r->[0]{hits}{hits}[0]{_index}, 'es_test_1', ' - default index';
is $r->[0]{hits}{hits}[0]{_type},  'type_1',    ' - default type';
is $r->[1]{hits}{hits}[0]{_index}, 'es_test_2', ' - custom index';
is $r->[1]{hits}{hits}[0]{_type},  'type_2',    ' - custom type';

isa_ok $r= $es->msearch(
    index   => 'es_test_1',
    type    => 'type_1',
    queries => {
        first  => { query => { match_all => {} } },
        second => {
            index => 'es_test_2',
            type  => 'type_2',
            query => { match_all => {} }
        },
    },
    ),
    'HASH',
    'msearch hash';

is $r->{first}{hits}{hits}[0]{_index},  'es_test_1', ' - default index';
is $r->{first}{hits}{hits}[0]{_type},   'type_1',    ' - default type';
is $r->{second}{hits}{hits}[0]{_index}, 'es_test_2', ' - custom index';
is $r->{second}{hits}{hits}[0]{_type},  'type_2',    ' - custom type';

ok $r= $es->msearch(
    queries => [
        {   index => [ 'es_test_1', 'es_test_2' ],
            type  => [ 'type_1',    'type_2' ],

            queryb  => { text => 'foo' },
            filterb => { num  => { 'gt' => 15 } },

            facets => { foo => { terms => { field => 'text' } } },
            from   => 0,
            size   => 10,
            sort => { date => 'asc' },
            highlight =>
                { fields => { text => { number_of_fragments => 0 } } },
            fields => [ 'text', 'num' ],

            explain        => 1,
            indices_boost  => { es_test_1 => 1 },
            min_score      => 0,
            partial_fields => { include => '*' },
            preference     => '_primary',
            routing        => [ 1 .. 5 ],
            script_fields  => {},
            search_type    => 'query_then_fetch',
            stats          => [ 'group_1', 'group_2' ],
            timeout        => '30s',
            track_scores   => 1,
            version        => 1,
        }
    ]
)->[0], '-all params';

ok $r->{hits}{hits}[0]{_score},       ' - score';
ok $r->{hits}{hits}[0]{_version},     ' - version';
ok $r->{hits}{hits}[0]{sort},         ' - sort';
ok $r->{hits}{hits}[0]{fields},       ' - field';
ok $r->{hits}{hits}[0]{highlight},    ' - highlight';
ok $r->{hits}{hits}[0]{_explanation}, ' - explain';
ok $r->{facets}, ' - facets';

is_deeply $es->msearch( queries => [] ), [], ' - empty array';
is_deeply $es->msearch( queries => {} ), {}, ' - empty hash';

is $es->msearch( queries => [], as_json => 1 ), "[]", ' - empty json array';
is $es->msearch( queries => {}, as_json => 1 ), "{}", ' - empty json hash';

1;
