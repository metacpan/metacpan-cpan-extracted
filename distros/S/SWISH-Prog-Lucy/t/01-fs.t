#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 40;
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

is( $program->count, 2, "indexed test docs" );

ok( my $searcher = SWISH::Prog::Lucy::Searcher->new(
        invindex             => 't/index.swish',
        find_relevant_fields => 1,
    ),
    "new searcher"
);

ok( my $results = $searcher->search('test'), "search()" );

#diag( dump $results );

is( $results->hits, 1, "1 hit" );

is_deeply(
    $results->property_map,
    {   bar     => "foobar",
        lastmod => "swishlastmodified",
        title   => "swishtitle"
    },
    "property_map"
);

ok( my $result = $results->next, "next result" );

#diag( dump $result->property_map );

is( $result->uri, 't/test.html', 'get uri' );

is( $result->title, "test html doc", "get title" );

is( $result->mtime,
    $result->get_property('lastmod'),
    "get_property() respects aliases"
);

is( $result->relevant_fields->[0],
    "swishtitle", "relevant field == swishtitle" );

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
    diag( 'result2: ' . dump $result2->relevant_fields );

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
    diag( 'result3: ' . dump $result3->relevant_fields );
}
is_deeply( \@results, [qw( t/test.html t/test.xml )], "results sorted ok" );

# test wildcard query
ok( my $results4 = $searcher->search('S?M*'), "search()" );
is( $results4->hits, 2, "2 hits" );

ok( my $results5 = $searcher->search('running*'),
    "search stemmable wildcard" );
is( $results5->hits, 1, "1 hit" );

#diag( $results5->query );
#diag( dump $results5->query->as_lucy_query->dump );

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

ok( my $results_relevant = $searcher->search('2009*'), "search for 2009*" );
while ( my $rr = $results_relevant->next ) {
    my $f = $rr->relevant_fields;

    diag( $rr->uri . ' : ' . dump $f );
    is( scalar @$f, 2, "2 relevant fields" );
    is_deeply( $f, [ "timestamp", "date" ], "got relevant fields in order" );
}

###################################
## helper functions

sub make_program {
    ok( my $program = SWISH::Prog->new(
            invindex     => $invindex,
            aggregator   => 'fs',
            indexer      => 'lucy',
            config       => 't/config.xml',
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
    $program->config->FileRules( 'filename is fields.xml',               1 );
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
