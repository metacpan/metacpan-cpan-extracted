#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 15;
use strict;
use Data::Dump qw( dump );
use Search::Tools::UTF8;

#binmode Test::More->builder->output,         ":utf8";
#binmode Test::More->builder->failure_output, ":utf8";

use_ok('SWISH::Prog');
use_ok('SWISH::Prog::Lucy::InvIndex');
use_ok('SWISH::Prog::Lucy::Searcher');

ok( my $invindex = SWISH::Prog::Lucy::InvIndex->new(
        clobber => 0,                 # Lucy handles this
        path    => 't/index.swish',
    ),
    "new invindex"
);

my $program = make_program();

ok( $program->index('t/'), "run program" );

is( $program->count, 1, "indexed test docs" );

ok( my $searcher = SWISH::Prog::Lucy::Searcher->new(
        invindex             => 't/index.swish',
        find_relevant_fields => 1,
    ),
    "new searcher"
);

# case-sensitive search
ok( my $results = $searcher->search('GLOWER'), "search()" );

#diag( dump $results );

is( $results->hits, 1, "1 hit" );

ok( my $result = $results->next, "next result" );

#diag( dump $result->property_map );

is( $result->uri, 't/fields.xml', 'get uri' );

is( $result->relevant_fields->[0],
    "tokenizecasesensitive", "relevant field == tokenizecasesensitive" );

# test partial match against stored-only field
#diag( dump $searcher );
ok( $results = $searcher->search('bar:small'),
    "search in non-tokenized field" );
is( $results->hits, 0, "no hits" );

#show_results_by_uri($results);

###################################
## helper functions

sub make_program {
    ok( my $program = SWISH::Prog->new(
            invindex     => $invindex,
            aggregator   => 'fs',
            indexer      => 'lucy',
            config       => 't/fields.conf',
            indexer_opts => { highlightable_fields => 1, },

            #verbose    => 1,
            #debug      => 1,
        ),
        "new program"
    );

    # skip the index dir every time
    # the '1' arg indicates to append the value, not replace.
    $program->config->FileRules( 'dirname is index.swish',               1 );
    $program->config->FileRules( 'filename is config.xml',               1 );
    $program->config->FileRules( 'filename is config-nostemmer.xml',     1 );
    $program->config->FileRules( 'filename contains \.t',                1 );
    $program->config->FileRules( 'filename is test.html',                1 );
    $program->config->FileRules( 'filename is test.xml',                 1 );
    $program->config->FileRules( 'dirname contains (testindex|\.index)', 1 );
    $program->config->FileRules( 'filename contains \.conf',             1 );
    $program->config->FileRules( 'dirname contains mailfs',              1 );

    return $program;
}

sub show_results_by_uri {
    my ($results) = @_;
    while ( my $r = $results->next ) {
        diag( $r->uri );
    }
}

END {
    unless ( $ENV{PERL_DEBUG} ) {
        $invindex->path->rmtree;
    }
}
