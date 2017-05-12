use strict;
use warnings;
use Test::More tests => 17;

use_ok('SWISH::Prog');
use_ok('SWISH::Prog::Native::Indexer');
use_ok('SWISH::Prog::Aggregator::FS');
use_ok('SWISH::Prog::Config');

SKIP: {

    # is executable present?
    my $test = SWISH::Prog::Native::Indexer->new;
    if ( !$test->swish_check ) {
        skip "swish-e not installed", 13;
    }

    ok( my $config = SWISH::Prog::Config->new('t/test.conf'),
        "config from t/test.conf" );

    # skip our local config test files
    $config->FileRules( 'dirname contains config',              1 );
    $config->FileRules( 'filename is swish.xml',                1 );
    $config->FileRules( 'filename contains \.t',                1 );
    $config->FileRules( 'dirname contains (testindex|\.index)', 1 );
    $config->FileRules( 'filename contains \.conf',             1 );
    $config->FileRules( 'dirname contains mailfs',              1 );

    ok( my $invindex
            = SWISH::Prog::Native::InvIndex->new( path => 't/testindex', ),
        "new invindex"
    );

    ok( my $indexer = SWISH::Prog::Native::Indexer->new(
            invindex => $invindex,
            config   => $config,
        ),
        "new indexer"
    );

    ok( my $aggregator = SWISH::Prog::Aggregator::FS->new(
            indexer => $indexer,
            config  => $config,

            #verbose => 1,
            #debug   => 1,
        ),
        "new filesystem aggregator"
    );

    ok( my $prog = SWISH::Prog->new(
            aggregator => $aggregator,

            #verbose    => 1,
            config => $config,
        ),
        "new program"
    );

    ok( $prog->run('t/'), "run program" );

    is( $prog->count, 7, "indexed test docs" );

    # test with a search
SKIP: {

        eval { require SWISH::Prog::Native::Searcher; };
        if ($@) {
            skip "Cannot test Searcher without SWISH::API", 6;
        }
        ok( my $searcher
                = SWISH::Prog::Native::Searcher->new( invindex => $invindex,
                ),
            "new searcher"
        );
        ok( my $results = $searcher->search('gzip'), "do search" );
        is( $results->hits, 2, "2 gzip hits" );

        ok( my $results_OR = $searcher->search(
                qq/some words/, { default_boolop => 'OR' }
            ),
            "default_boolop=OR"
        );
        ok( my $results_AND = $searcher->search(
                qq/some words/, { default_boolop => 'AND' }
            ),
            "default_boolop=AND"
        );
        cmp_ok( $results_OR->hits, '>', $results_AND->hits,
            "OR hits > AND hits" );

    }

    # clean up header so other test counts work
    unlink('t/testindex/swish.xml') unless $ENV{PERL_DEBUG};

}
