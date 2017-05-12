#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 34;
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

ok( $program->index('t/'), "run program" );

is( $program->count, 3, "indexed test docs" );

ok( my $searcher
        = SWISH::Prog::KSx::Searcher->new( invindex => 't/index.swish', ),
    "new searcher"
);

ok( my $results = $searcher->search('test'), "search()" );

#diag( dump $results );

is( $results->hits, 1, "1 hit" );

ok( my $result = $results->next, "next result" );

is( $result->uri, 't/test.html', 'get uri' );

is( $result->title, "test html doc", "get title" );

diag( $result->score );

# test limit
ok( my $results2 = $searcher->search(
        'some', { limit => [ [qw( date 2010-01-01 2010-12-31 )] ] }
    ),
    "search()"
);
is( $results2->hits, 1, "1 hit" );

my $utf8_title = sprintf( "%c%s%c", 8220, qq/ima xml doc/, 8221 );

#Search::Tools::describe($utf8_title);
#diag($utf8_title);

while ( my $result2 = $results2->next ) {
    my $title = sprintf( "%s %s", $result2->title, "AND MORE" );

    #print STDERR $title . "\n";
    if ( !is_flagged_utf8($title) ) {
        warn("not flagged utf8");
    }

    #Search::Tools::describe($title);
    #diag( $result2->uri );
    #diag( $result2->title );
    #diag( $result2->score );
    #diag($title);
    is( $result2->uri,   't/test.xml', 'get uri' );
    is( $result2->title, $utf8_title,  "get title" );

}

# test sort
ok( my $results3 = $searcher->search(
        'some', { order => 'swishdocpath asc swishrank desc' }
    ),
    "search()"
);
is( $results3->hits, 2, "2 hits" );
my @results;
while ( my $result3 = $results3->next ) {
    push @results, $result3->swishdocpath;
}
is_deeply( \@results, [qw( t/test.html t/test.xml )], "results sorted ok" );

# test wildcard query
ok( my $results4 = $searcher->search('S?M*'), "search()" );
is( $results4->hits, 2, "2 hits" );

ok( my $results5 = $searcher->search('running*'),
    "search stemmable wildcard" );
is( $results5->hits, 1, "1 hit" );

ok( my $results6 = $searcher->search(qq/"text here"~4/), "search proximity" );
is( $results6->hits, 1, "1 hit" );

ok( my $results7 = $searcher->search(qq/(som* or word*) and here/),
    "compound wildcard" );
is( $results7->hits, 2, "2 hits for compound wildcard query" );

# break the query parser
eval { $results7 = $searcher->search(qq/"out touch~2/); };
ok( $@, "query parser catches poor syntax" );

# boolop
ok( my $results_OR
        = $searcher->search( qq/some words/, { default_boolop => 'OR' } ),
    "search with boolop=OR"
);
ok( my $results_AND
        = $searcher->search( qq/some words/, { default_boolop => 'AND' } ),
    "search with boolop=AND"
);
cmp_ok( $results_OR->hits, '>', $results_AND->hits,
    "OR gives more hits than AND" );

# properties/aliases
ok( my $sorted_by_title = $searcher->search( qq/some/, { order => 'title' } ),
    "search sorted by title"
);
show_results_by_uri($sorted_by_title);
ok( my $sorted_by_lastmod
        = $searcher->search( qq/some/, { order => 'lastmod' } ),
    "search sorted by lastmod"
);
show_results_by_uri($sorted_by_lastmod);

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
