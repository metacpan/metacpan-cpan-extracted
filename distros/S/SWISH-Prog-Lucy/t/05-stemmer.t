#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 19;
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

# no stemming
my $program = make_program();

ok( $program->index('t/'), "run program" );

is( $program->count, 2, "indexed test docs" );

ok( my $searcher = SWISH::Prog::Lucy::Searcher->new(
        invindex             => 't/index.swish',
        find_relevant_fields => 1,
    ),
    "new searcher"
);

ok( my $results = $searcher->search('appl'), "search()" );

#diag( dump $results );

is( $results->hits, 0, "0 hits for stem when stemming is off" );

# with stemming
$invindex->path->rmtree();
ok( $invindex = SWISH::Prog::Lucy::InvIndex->new(
        clobber => 0,                 # Lucy handles this
        path    => 't/index.swish',
    ),
    "new invindex"
);
$program = make_program(1);

ok( $program->index('t/'), "run program" );

is( $program->count, 2, "indexed test docs" );

ok( $searcher = SWISH::Prog::Lucy::Searcher->new(
        invindex             => 't/index.swish',
        find_relevant_fields => 1,
    ),
    "new searcher"
);

ok( $results = $searcher->search('appl'), "search()" );

#diag( dump $results );

is( $results->hits, 1, "1 hit for stem when stemming is on" );

ok( my $result = $results->next, "next result" );

is( $result->uri, 't/test.html', 'get uri' );

sub make_program {
    my $use_stemmer = shift;
    ok( my $program = SWISH::Prog->new(
            invindex   => $invindex,
            aggregator => 'fs',
            indexer    => 'lucy',
            config =>
                ( $use_stemmer ? 't/config.xml' : 't/config-nostemmer.xml' ),
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
    $program->config->FileRules( 'filename is fields.xml',               1 );
    $program->config->FileRules( 'filename is config-nostemmer.xml',     1 );
    $program->config->FileRules( 'filename contains \.t',                1 );
    $program->config->FileRules( 'dirname contains (testindex|\.index)', 1 );
    $program->config->FileRules( 'filename contains \.conf',             1 );
    $program->config->FileRules( 'dirname contains mailfs',              1 );

    return $program;
}

END {
    unless ( $ENV{PERL_DEBUG} ) {
        undef $searcher;
        undef $results;
        undef $result;
        my $index = $invindex->path;
        undef $invindex;
        $index->rmtree;
    }
}
