#!/usr/bin/perl
use Test::More tests => 10;
use_ok("Plucene::SearchEngine::Index");

my $indexer = Plucene::SearchEngine::Index->new(dir => "t/test_index");
isa_ok($indexer, "Plucene::SearchEngine::Index");

my ($hash) = Plucene::SearchEngine::Index::File->examine("MANIFEST");
is($hash->{filename}{data}[0], "MANIFEST", "filename stored");
isa_ok($hash->{modified}{data}[0], "Time::Piece", "Last mod date stored");
is($hash->{text}{data}[0], "Changes\n", "First line stored");
my $doc = $hash->document;
isa_ok($doc, "Plucene::Document");
$indexer->index($doc);

use_ok("Plucene::SearchEngine::Query");

my $query = Plucene::SearchEngine::Query->new(dir => "t/test_index");
isa_ok($query, "Plucene::SearchEngine::Query");
my @docs = $query->search("Changes");
is(scalar @docs, 1, "Found one document");
like($docs[0], qr/MANIFEST/, "Found the right doc");
