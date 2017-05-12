#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 17;
use SWISH::Prog::KSx::Indexer;
use SWISH::Prog::KSx::Searcher;
use SWISH::Prog::KSx::InvIndex;
use SWISH::Prog::Doc;

ok( my $invindex = SWISH::Prog::KSx::InvIndex->new(
        clobber => 0,                 # KS handles this
        path    => 't/index.swish',
    ),
    "new invindex"
);

ok( my $indexer = SWISH::Prog::KSx::Indexer->new( invindex => $invindex ),
    "new indexer" );

ok( my $doc = SWISH::Prog::Doc->new(
        url     => 'foo/bar',
        content => '<doc><title>round 1</title></doc>',
        type    => 'application/xml'
    ),
    "new doc, round 1"
);

ok( $indexer->process($doc), "process doc" );
is( $indexer->finish(), 1, "finish indexer with 1 total docs" );

ok( my $searcher = SWISH::Prog::KSx::Searcher->new( invindex => $invindex ),
    "new searcher" );

ok( my $results = $searcher->search(qq/swishtitle="round 1"/),
    "search for round 1" );
is( $results->hits, 1, "1 match" );

# update doc
ok( my $doc2 = SWISH::Prog::Doc->new(
        url     => 'foo/bar',
        content => '<doc><title>round 2</title></doc>',
        type    => 'application/xml'
    ),
    "new doc, round 2"
);

ok( my $indexer2 = SWISH::Prog::KSx::Indexer->new( invindex => $invindex ),
    "new indexer2" );
ok( $indexer2->process($doc2), "process doc2" );
is( $indexer2->finish(), 1, "finish indexer with 1 total docs" );

# search again with old searcher object. should find updated doc.
ok( $results = $searcher->search(qq/swishtitle="round 2"/),
    "search for round 2" );
is( $results->hits, 1, "1 match" );

# new searcher object should find the same thing
ok( my $searcher2 = SWISH::Prog::KSx::Searcher->new( invindex => $invindex ),
    "new searcher2"
);
ok( $results = $searcher2->search(qq/swishtitle="round 2"/),
    "search for round 2" );
is( $results->hits, 1, "1 match" );

END {
    unless ( $ENV{PERL_DEBUG} ) {
        $invindex->path->rmtree;
    }
}
