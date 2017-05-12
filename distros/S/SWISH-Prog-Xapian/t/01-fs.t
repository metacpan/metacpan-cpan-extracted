#!/usr/bin/env perl

use Test::More tests => 13;
use strict;

use_ok('SWISH::Prog');
use_ok('SWISH::Prog::Xapian::Searcher');
use_ok('SWISH::Prog::Xapian::InvIndex');

ok( my $invindex = SWISH::Prog::Xapian::InvIndex->new(
        clobber => 0,                 # Xapian handles this
        path    => 't/index.swish',
    ),
    "new invindex"
);

ok( my $program = SWISH::Prog->new(
        invindex   => $invindex,
        aggregator => 'fs',
        indexer    => 'xapian',
        config     => 't/config.xml',

        #filter     => sub { diag( "doc filter on " . $_[0]->url ) },
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

ok( $program->index('t/'), "run program" );

is( $program->count, 2, "indexed test docs" );

ok( my $searcher
        = SWISH::Prog::Xapian::Searcher->new( invindex => 't/index.swish', ),
    "new searcher"
);

ok( my $results = $searcher->search('test'), "search()" );

is( $results->hits, 1, "1 hit" );

ok( my $result = $results->next, "next result" );

is( $result->uri, 't/test.html', 'get uri' );

is( $result->title, "test html doc", "get title" );

#diag( $result->score );

END {
    unless ( $ENV{PERL_DEBUG} ) {
        $invindex->path->rmtree;
    }
}
