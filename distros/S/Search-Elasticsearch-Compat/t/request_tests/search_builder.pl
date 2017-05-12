#!perl

use Test::More;
use Test::Differences;
use Test::Exception;

use strict;
use warnings;
no warnings 'redefine';

our $es;
my $r;

package ElasticSearch::SB::Mock;
sub request { return $_[1]->{body} }

package main;

our $em = { (%$es) };
@ElasticSearch::SB::Mock::ISA = ( ref $es );
bless $em, 'ElasticSearch::SB::Mock';

# SEARCH

SKIP: {
    skip "You must have ElasticSearch::SearchBuilder to run these tests", 1
        unless eval { require ElasticSearch::SearchBuilder; 1 };

    eq_or_diff $em->search( queryb => 'foo' )->{query},
        { match => { _all => 'foo' } }, 'search-queryb';
    eq_or_diff $em->search( filterb => 'foo' )->{filter},
        { term => { _all => 'foo' } }, 'search-filterb';
    eq_or_diff $em->search(
        facets => {
            terms_facet => {
                terms         => { field => 'foo' },
                facet_filterb => { k     => 'v' }
            },
            filter_facet => {
                filterb       => { k => [ 1, 2 ] },
                facet_filterb => { k => 'v' }
            },
            query_facet => { queryb => 'bar', facet_filterb => { p => 1 } }
        }
        ),
        {
        facets => {
            terms_facet => {
                terms        => { field => 'foo' },
                facet_filter => { term  => { k => 'v' } }
            },
            filter_facet => {
                filter       => { terms => { k => [ 1, 2 ] } },
                facet_filter => { term  => { k => 'v' } }
            },
            query_facet => {
                query        => { match => { _all => 'bar' } },
                facet_filter => { term  => { p    => 1 } }
            }
        }
        },
        'search-facets';

    throws_ok { $em->search( query => 'foo', queryb => 'bar' ) }
    qr/Cannot specify queryb and query/, 'search query,queryb';
    throws_ok { $em->search( filter => 'foo', filterb => 'bar' ) }
    qr/Cannot specify filterb and filter/, 'search filter,filterb';
    throws_ok {
        $em->search(
            facets => { f => { filter => 'foo', filterb => 'bar' } } );
    }
    qr/Cannot specify filterb and filter/, 'search facets filter,filterb';
    throws_ok {
        $em->search( facets => { f => { query => 'foo', queryb => 'bar' } } );
    }
    qr/Cannot specify queryb and query/, 'search facets query,queryb';
    throws_ok {
        $em->search( facets =>
                { f => { facet_filter => 'foo', facet_filterb => 'bar' } } );
    }
    qr/Cannot specify facet_filterb and facet_filter/,
        'search facets facet_filter,facet_filterb';

    # CREATE PERCOLATOR

    eq_or_diff $em->create_percolator(
        index      => 'foo',
        percolator => 'bar',
        queryb     => { foo => 'bar' }
        ),
        { query => { match => { foo => 'bar' } } },
        'percolator queryb';
    throws_ok {
        $em->create_percolator(
            index      => 'foo',
            percolator => 'bar',
            query      => 'foo',
            queryb     => { foo => 'bar' }
        );
    }
    qr/Cannot specify queryb and query/, 'percolator query,queryb';

    # MLT
    eq_or_diff $em->mlt(
        index   => 'index',
        type    => 'type',
        id      => 1,
        filterb => { foo => 'bar' }
        ),
        { filter => { term => { foo => 'bar' } } }, 'mlt filterb';

    throws_ok {
        $em->mlt(
            index   => 'index',
            type    => 'type',
            id      => 1,
            filterb => { foo => 'bar' },
            filter  => 'bar'
        );
    }
    qr/Cannot specify filterb and filter/, 'mlt filter,filterb';

    # COUNT
    eq_or_diff $em->count( queryb => { -all => 1 } ), { match_all => {} },
        'count queryb';
    throws_ok {
        $em->count( queryb => { -all => 1 }, query => { match_all => {} } );
    }
    qr/Cannot specify queryb and query/, 'count query,queryb';

    # DELETE_BY_QUERY
    eq_or_diff $em->delete_by_query( queryb => { -all => 1 } ),
        { match_all => {} }, 'delete_by_query queryb';
    throws_ok {
        $em->delete_by_query(
            queryb => { -all      => 1 },
            query  => { match_all => {} }
        );
    }
    qr/Cannot specify queryb and query/, 'delete_by_query query,queryb';

    # ALIASES
    eq_or_diff $em->aliases(
        actions => [
            {   add => {
                    index   => 'foo',
                    alias   => 'foo',
                    filterb => { foo => 'bar' }
                }
            }
        ]
        ),
        {
        'actions' => [
            {   'add' => {
                    'index'  => 'foo',
                    'filter' => { 'term' => { 'foo' => 'bar' } },
                    'alias'  => 'foo'
                }
            }
        ]
        },
        , 'aliases filterb';

    # EMPTY
    ok !defined $em->search( queryb => {} )->{query}, 'search-queryb-empty';

    ok !defined $em->search( filterb => {} )->{filter},
        'search-filterb-empty';

    eq_or_diff $em->search( queryb => { -all => 1, -filter => {} } )->{query},
        { match_all => {} }, 'search-queryb-filterb-empty';

    eq_or_diff $em->search( facets =>
            { foo => { terms => { field => 'foo' }, facet_filterb => {} } } )
        ->{facets},
        { foo => { terms => { field => 'foo' } } }, 'facet-filterb';

}

1
