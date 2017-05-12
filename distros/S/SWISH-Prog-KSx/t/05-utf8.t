#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 12;
use strict;
use Data::Dump qw( dump );
use Search::Tools::UTF8;

#binmode Test::More->builder->output,         ":utf8";
#binmode Test::More->builder->failure_output, ":utf8";

use_ok('SWISH::Prog');
use_ok('SWISH::Prog::KSx::InvIndex');
use_ok('SWISH::Prog::KSx::Searcher');

ok( my $invindex = SWISH::Prog::KSx::InvIndex->new(
        clobber => 0,                 # KS handles this
        path    => 't/index.swish',
    ),
    "new invindex"
);

my $program = make_program();

ok( $program->index('t/utf8.xml'), "run program" );

is( $program->count, 1, "indexed test docs" );

ok( my $searcher
        = SWISH::Prog::KSx::Searcher->new( invindex => 't/index.swish', ),
    "new searcher"
);

ok( my $results = $searcher->search( to_utf8('niña') ), "search()" );

#diag( dump $results );

is( $results->hits, 1, "1 hit" );

ok( $results = $searcher->search( to_utf8('banaña') ), "search()" );

is( $results->hits, 1, "1 hit" );

sub make_program {
    ok( my $program = SWISH::Prog->new(
            invindex   => $invindex,
            aggregator => 'fs',
            indexer    => 'ks',
            config     => 't/config.xml',

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
    $program->config->FileRules( 'dirname contains (testindex|\.index)', 1 );
    $program->config->FileRules( 'filename contains \.conf',             1 );
    $program->config->FileRules( 'dirname contains mailfs',              1 );

    return $program;
}
