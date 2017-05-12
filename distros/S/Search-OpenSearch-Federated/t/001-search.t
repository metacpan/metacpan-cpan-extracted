#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 10;
use Data::Dump qw( dump );
use lib 'lib';

use_ok('Search::OpenSearch::Federated');

SKIP: {

    if ( !$ENV{SOS_TEST} ) {
        diag "set SOS_TEST env var to test Federated results";
        skip "set SOS_TEST env var to test Federated results", 9;
    }

    my $type = $ENV{SOS_TYPE} || 'XML';

    ok( my $ms = Search::OpenSearch::Federated->new(
            urls => [
                "$ENV{SOS_TEST}/search?f=1&q=dezi&t=$type",
                "$ENV{SOS_TEST}/search?f=1&q=release&t=$type",
            ],
            timeout => 2,
            debug   => 1,
        ),
        "new Federated object"
    );

    #diag( dump($ms) );

    ok( my $resp = $ms->search(), "search()" );

    #diag dump($resp);

    is( ref($resp), 'ARRAY', "response is an ARRAY ref" );

    ok( scalar(@$resp) > 1, "more than one result" );

    ok( $resp->[0]->{score}, "first result has a score" );

    my $prev_score;
    my $failed_sort = 0;
R: for my $r (@$resp) {
        if ( !defined $prev_score ) {
            $prev_score = $r->{score};
        }
        if ( $r->{score} > $prev_score ) {
            $failed_sort = 1;
            last R;
        }
        $prev_score = $r->{score};
    }

    ok( !$failed_sort, "results sorted by score" );

    ok( $ms->total(), "get total" );

    is( ref( $ms->subtotals ), 'HASH', "subtotals is a hash ref" );

    #diag( dump $ms->subtotals );

    is( ref( $ms->facets ), "HASH", "facets is a hash ref" );

    #diag( dump $ms->facets );

}
