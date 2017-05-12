#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 13;
use Plucene::TestCase;
use Plucene::Search::TermQuery;

new_index {
	add_document(myfield => "a c");
	add_document(myfield => "b c");
	add_document(myfield => "a c");
	$WRITER->optimize;
};

my @scores;
my $searcher = Plucene::Search::IndexSearcher->new($DIR);
isa_ok($searcher, "Plucene::Search::IndexSearcher");

my @terms =
	map { Plucene::Index::Term->new({ field => "myfield", text => $_ }) }
	qw(a b c);

{
	my $query = Plucene::Search::TermQuery->new({ term => $terms[1] });
	isa_ok($query, "Plucene::Search::TermQuery");

	my $collector = Plucene::Search::HitCollector->new(
		collect => sub {
			my ($self, $doc, $score) = @_;
			Test::More::ok(1, "Collected a hit");
			Test::More::is($doc, 1, "In the correct document");
			Test::More::is(sprintf("%0.2f", $score), "1.00", "Score is correct");
		});

	isa_ok($collector, "Plucene::Search::HitCollector");
	$searcher->search_hc($query, $collector);
}

my @expected_docs = (0, 2);
{
	my $query = Plucene::Search::TermQuery->new({ term => $terms[0] });
	isa_ok($query, "Plucene::Search::TermQuery");

	my $collector = Plucene::Search::HitCollector->new(
		collect => sub {
			my ($self, $doc, $score) = @_;
			Test::More::ok(1, "Collected a hit");
			Test::More::is($doc, (shift @expected_docs), "In the correct document");
		});

	isa_ok($collector, "Plucene::Search::HitCollector");
	$searcher->search_hc($query, $collector);
}

is(@expected_docs, 0, "No hits remain uncollected");
