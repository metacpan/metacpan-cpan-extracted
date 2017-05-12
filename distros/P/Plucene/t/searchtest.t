#!/usr/bin/perl -w

use Test::More tests => 12;
use strict;
use warnings;

use Plucene::TestCase;
use Plucene::QueryParser;

new_index {
	add_document(contents => $_) for (
		"a b c d e",
		"a b c d e a b c d e",
		"a b c d e f g h i j",
		"a c e",
		"e c a",
		"a c e a c e",
		"a c e a b c"
	);
	$WRITER->optimize;
};

my $searcher = Plucene::Search::IndexSearcher->new($DIR);
my %queries  = (
	"a b"       => [ 4, 3, 5, 2, 1, 0, 6 ],
	"\"a c e\"" => [ 6, 3, 5 ],
	"b -a"      => [],
);

# We don't use TestCase's search method here because we are testing lots
# of different things

my $parser = Plucene::QueryParser->new({
		analyzer => $ANALYZER->new(),
		default  => "contents"
	});

for my $q_text (keys %queries) {
	my $q = $parser->parse($q_text);
	isa_ok($q, "Plucene::Search::Query");
	is($q->to_string("contents"), $q_text, "to_string round-trips OK");
	my $hits = $searcher->search($q);
	is($hits->length, @{ $queries{$q_text} }, "Correct number of results");
	is_deeply([ map { $_->{id} } @{ $hits->{hit_docs} } ],
		$queries{$q_text}, "Correct document IDs returned. (in order)");
}
