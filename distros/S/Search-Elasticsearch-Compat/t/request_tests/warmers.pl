#!perl

use Test::More;
use Test::Exception;

use strict;
use warnings;
no warnings 'redefine';

our ( $es, $es_version );
my $r;

SKIP: {
    skip "Warmers only supported in 0.20", 31
        if $es_version lt '0.20';

    ok $es->create_warmer( warmer => 'warmer_1', queryb => { foo => 1 } ),
        'warmer:all/all';
    ok $r = $es->warmer, 'get all warmers';

    ok $r->{es_test_1}
        && $r->{es_test_2}
        && 0 == @{ $r->{es_test_1}{warmers}{warmer_1}{types} }
        && 0 == @{ $r->{es_test_2}{warmers}{warmer_1}{types} },
        ' - warmer:all/all created';
    ok $es->delete_warmer( index => '_all', warmer => '*' ),
        ' delete all warmers';

    ok $es->create_warmer(
        warmer => 'warmer_1',
        index  => 'es_test_1',
        type   => 'type_1',
        queryb => { foo => 1 }
        ),
        'warmer:one/one';
    ok $r = $es->warmer, 'get all warmers';
    ok $r->{es_test_1}
        && !$r->{es_test_2}
        && 1 == @{ $r->{es_test_1}{warmers}{warmer_1}{types} },
        ' - warmer:one/one created';
    ok $es->delete_warmer( index => '_all', warmer => '*' ),
        ' delete all warmers';

    ok $es->create_warmer(
        warmer => 'warmer_1',
        index  => [ 'es_test_1', 'es_test_2' ],
        type   => [ 'type_1', 'type_2' ],
        queryb => { foo => 1 }
        ),
        'warmer:two/two';
    ok $r = $es->warmer, 'get all warmers';
    ok $r->{es_test_1}
        && $r->{es_test_2}
        && 2 == @{ $r->{es_test_1}{warmers}{warmer_1}{types} }
        && 2 == @{ $r->{es_test_2}{warmers}{warmer_1}{types} },
        ' - warmer:two/two created';

    ok $r= $es->warmer( index => 'es_test_1' ), 'get one index warmer';
    ok $r->{es_test_1} && !$r->{es_test_2}, ' -  one index warmer returned';

    ok $r= $es->warmer( index => [ 'es_test_1', 'es_test_2' ] ),
        'get two index warmers';
    ok $r->{es_test_1} && $r->{es_test_2}, ' -  two index warmers returned';

    throws_ok { $es->warmer( index => 'es_test_3' ) } qr/Missing/,
        'get bad index';
    ok !$es->warmer( index => 'es_test_3', ignore_missing => 1 ),
        'ignore missing index';

    ok $r= $es->warmer( warmer => 'warm*' ), 'get wildcard';
    ok $r->{es_test_1} && $r->{es_test_2}, ' - wildcard get';

    throws_ok { $es->warmer( warmer => 'bad*' ) } qr/Missing/, 'bad wildcard';
    ok !$es->warmer( warmer => 'bad*', ignore_missing => 1 ),
        'ignore bad wildcard';

    throws_ok { $es->delete_warmer( index => 'es_test_3', warmer => '*' ) }
    qr/Missing/, 'delete missing index';
    ok !$es->delete_warmer(
        index          => 'es_test_3',
        warmer         => '*',
        ignore_missing => 1
        ),
        'ignore delete missing index';

    throws_ok {
        $es->delete_warmer( index => 'es_test_2', warmer => 'bad*' );
    }
    qr/Missing/, 'delete missing wildcard';

    ok !$es->delete_warmer(
        index          => 'es_test_2',
        warmer         => 'bad*',
        ignore_missing => 1
        ),
        'ignore delete missing wildcard';
    ok $es->delete_warmer( index => 'es_test_2', warmer => 'warm*' ),
        ' delete wildcard';
    ok $r = $es->warmer(), 'get all warmers';
    ok $r->{es_test_1} && !$r->{es_test_2}, 'wildcard warmer deleted';

    ok $es->create_warmer(
        index   => 'es_test_1',
        warmer  => 'warmer_2',
        type    => [ 'type_1', 'type_2' ],
        queryb  => { foo => 1 },
        filterb => { foo => 1 },
        facets  => {
            bar => { filterb => { bar => 1 }, facet_filterb => { bar => 2 } }
        }
        ),
        'create warmer with searchbuilder';

    is_deeply $es->warmer( index => 'es_test_1' )
        ->{es_test_1}{warmers}{warmer_2},
        {
        "source" => {
            "filter" => { "term"  => { "foo" => 1 } },
            "query"  => { "match" => { "foo" => 1 } },
            "facets" => {
                "bar" => {
                    "filter"       => { "term" => { "bar" => 1 } },
                    "facet_filter" => { "term" => { "bar" => 2 } }
                }
            }
        },
        "types" => [ "type_1", "type_2" ]
        },
        'search builder warmer transformed';

    ok $es->delete_warmer( index => '_all', warmer => '*' ),
        ' delete all warmers';
}

1;

