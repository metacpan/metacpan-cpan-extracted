#!/usr/bin/perl -wl

use strict;
use warnings;

use Test::More tests => 3;
use Plucene::TestCase;
use Plucene::Document::DateSerializer;
use Plucene::Search::DateFilter;
use Time::Piece;
use Plucene::QueryParser;

our $ANALYZER = "Plucene::Analysis::WhitespaceAnalyzer";

my $entries = [
	[ 'aaa', "A day in May in 2003", 1054166400 ],    # May 29 2003
	[ 'aaa', 'Day of writing test',  1072692516 ],    # December 29 2003
	[ 'aab', 'Day of writing test',  1072692516 ],    # December 29 2003
	[ 'aac', 'Day of writing test',  1072692516 ],    # December 29 2003
	[ 'aab', "Christmas 2003",       1072310400 ],    # December 25 2003
	[ 'aaa', "Christmas 2003",       1072310400 ],    # December 25 2003
	[ 'aaa', "A day in May in 1978", 265248000 ],     # May 29 1978
];

new_index {
	for (@$entries) {
		my $doc = Plucene::Document->new();

		my @fields = @$_;
		$doc->add(Plucene::Document::Field->Text("content",     $fields[0]));
		$doc->add(Plucene::Document::Field->Text("explanation", $fields[1]));
		$doc->add(
			Plucene::Document::Field->Text(
				"date", freeze_date(Time::Piece->new($fields[2]))));
		$WRITER->add_document($doc);
		$WRITER->optimize();
	}
};

my $filter = Plucene::Search::DateFilter->new({
		field => "date",
		from  => Time::Piece->new("1070236800"),    # 1st Dec 2003
		to    => Time::Piece->new("1072742400"),    # 30th Dec
	});
isa_ok($filter, "Plucene::Search::DateFilter");

my $searcher = Plucene::Search::IndexSearcher->new($DIR);

my $qp = Plucene::QueryParser->new({
		analyzer => $ANALYZER->new(),
		default  => "content"
	});

my $query = $qp->parse("aaa");

my $hits = $searcher->search($query, $filter);

is($hits->length, 2, "Correct number of results");
my @docs = @{ $hits->{hit_docs} };
is_deeply([ map { $_->{id} } @docs ], [ 5, 1 ], "Correct results");
