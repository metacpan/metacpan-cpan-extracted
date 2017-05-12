#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 38;

use_ok('SWISH::Prog');
use_ok('SWISH::Prog::Native::Indexer');
use_ok('SWISH::Prog::Aggregator::FS');
use_ok('SWISH::Prog::Config');

SKIP: {

    # is executable present?
    my $test = SWISH::Prog::Native::Indexer->new;
    if ( !$test->swish_check ) {
        skip "swish-e not installed", 34;
    }

    ok( my $invindex
            = SWISH::Prog::Native::InvIndex->new( path => 't/testindex', ),
        "new invindex"
    );

    ok( my $config = SWISH::Prog::Config->new('t/test.conf'),
        "config from t/test.conf" );

    # skip our local config test files
    $config->FileRules( 'dirname contains config',              1 );
    $config->FileRules( 'filename is swish.xml',                1 );
    $config->FileRules( 'filename contains \.t',                1 );
    $config->FileRules( 'dirname contains (testindex|\.index)', 1 );
    $config->FileRules( 'filename contains \.conf',             1 );
    $config->FileRules( 'dirname contains mailfs',              1 );

    ok( my $indexer = SWISH::Prog::Native::Indexer->new(
            invindex => $invindex,
            config   => $config
        ),
        "new indexer"
    );

    ok( my $aggregator = SWISH::Prog::Aggregator::FS->new(
            indexer => $indexer,

            #verbose => 1,
            #debug   => 1,
        ),
        "new filesystem aggregator"
    );

    ok( my $prog = SWISH::Prog->new(
            aggregator => $aggregator,

            #filter => sub { diag( "doc filter on " . $_[0]->url ) },

            #verbose    => 1,
        ),
        "new program"
    );

    ok( $prog->run('t/'), "run program" );

    is( $prog->count, 7, "indexed test docs" );

    # test with a search
SKIP: {

        eval { require SWISH::Prog::Native::Searcher; };
        if ($@) {
            skip "Cannot test Searcher without SWISH::API", 27;
        }
        ok( my $searcher
                = SWISH::Prog::Native::Searcher->new( invindex => $invindex,
                ),
            "new searcher"
        );

        my $query = 'foo or words';
        ok( my $results
                = $searcher->search( $query,
                { order => 'swishdocpath ASC' } ),
            "do search"
        );
        is( $results->hits, 5, "5 hits" );
        ok( my $result = $results->next, "results->next" );
        diag( $result->swishdocpath );
        is( $result->swishtitle, 'test gzip html doc', "get swishtitle" );
        is( $result->get_property('swishtitle'),
            $result->swishtitle, "get_property(swishtitle)" );

        # test all the built-in properties and their method shortcuts
        my @methods = qw(
            swishdocpath
            uri
            swishlastmodified
            mtime
            swishtitle
            title
            swishdescription
            summary
            swishrank
            score
        );

        for my $m (@methods) {
            ok( defined $result->$m,               "get $m" );
            ok( defined $result->get_property($m), "get_property($m)" );
        }

        # test an aliased property
        is( $result->get_property('lastmod'),
            $result->swishlastmodified, "aliased PropertyName fetched" );
    }

    # clean up index
    $invindex->path->rmtree;

}
