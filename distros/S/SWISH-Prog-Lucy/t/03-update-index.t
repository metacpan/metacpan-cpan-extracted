use Test::More tests => 31;
use strict;
use Data::Dump qw( dump );

use_ok('SWISH::Prog');
use_ok('SWISH::Prog::Lucy::InvIndex');
use_ok('SWISH::Prog::Lucy::Searcher');

ok( my $invindex = SWISH::Prog::Lucy::InvIndex->new(
        clobber => 0,                 # Lucy handles this
        path    => 't/index.swish',
    ),
    "new invindex"
);

my $passes = 0;
my $searcher;
while ( ++$passes < 4 ) {

    diag("pass $passes");
    ok( my $program = SWISH::Prog->new(
            invindex   => $invindex,
            aggregator => 'fs',
            indexer    => 'lucy',
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
    $program->config->FileRules( 'filename is fields.xml',               1 );
    $program->config->FileRules( 'filename contains \.t',                1 );
    $program->config->FileRules( 'dirname contains (testindex|\.index)', 1 );
    $program->config->FileRules( 'filename contains \.conf',             1 );
    $program->config->FileRules( 'dirname contains mailfs',              1 );

    ok( $program->index('t/'), "run program" );

    is( $program->count, 2, "indexed test docs" );

    if ( !$searcher ) {
        ok( $searcher = SWISH::Prog::Lucy::Searcher->new(
                invindex => 't/index.swish',
            ),
            "new searcher"
        );
    }
    else {
        pass("searcher already defined");
    }
    ok( my $results = $searcher->search('test'), "search()" );

    #diag( dump $results );

    is( $results->hits, 1, "1 hit" );

    ok( my $result = $results->next, "next result" );

    is( $result->uri, 't/test.html', 'get uri' );

    is( $result->title, "test html doc", "get title" );
}

END {
    unless ( $ENV{PERL_DEBUG} ) {
        $invindex->path->rmtree;
    }
}
