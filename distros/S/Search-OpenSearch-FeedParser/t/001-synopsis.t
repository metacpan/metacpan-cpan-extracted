#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 10;
use Data::Dump qw( dump );

SKIP: {
    eval "use Search::OpenSearch::Response::XML";
    if ($@) {
        skip "Search::OpenSearch::Response::XML required for tests", 10;
    }

    use_ok('Search::OpenSearch::FeedParser');

    ok( my $parser = Search::OpenSearch::FeedParser->new(), "new parser" );

    # dummy content
    my @results;
    for my $ltr ( ( 'a' .. 'z' ) ) {
        push @results,
            {
            title   => $ltr,
            summary => $ltr,
            mtime   => 1234567890,
            uri     => 'http://dezi.org/' . $ltr
            };
    }
    my $response = Search::OpenSearch::Response::XML->new(
        query       => 'any letter',
        total       => scalar @results,
        page_size   => scalar @results,
        results     => [@results],
        build_time  => 0.2,
        search_time => 0.1,
    );
    ok( my $feed = $parser->parse($response), "parse response" );
    #diag( dump $feed );

    is( $feed->total,       $response->total,       "total match" );
    is( $feed->query,       $response->query,       "query match" );
    is( $feed->build_time,  $response->build_time,  "build_time match" );
    is( $feed->search_time, $response->search_time, "search_time match" );
    is( $feed->page_size,   $response->page_size,   "page_size match" );
    is( $feed->entries->[0]->{uri},
        'http://dezi.org/a', 'first entry uri ok' );
    is( $feed->entries->[0]->{mtime}, 1234567890, 'first entry mtime ok' );
}
