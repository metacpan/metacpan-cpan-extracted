#!/usr/bin/perl
use strict;
use warnings;

use Plucene::QueryParser;
use Plucene::Analysis::SimpleAnalyzer;

my $parser = Plucene::QueryParser->new({
		analyzer => Plucene::Analysis::SimpleAnalyzer->new(),
		default  => "text"
	});

require Test::More;

my @or_tests = (
	[ "test",             "Term",    "text:test" ],
	[ "newfield:test",    "Term",    "newfield:test" ],
	[ "one two",          "Boolean", "text:one text:two" ],
	[ "one.two",          "Phrase",  "text:\"one two\"" ],
	[ "one newfield:two", "Boolean", "text:one newfield:two" ],
	[ "+req",             "Boolean", "+text:req" ],
	[ "FOO AND BAR",      "Boolean", "+text:foo +text:bar" ],
	[ "+term -term term", "Boolean", "+text:term -text:term text:term" ],
	[
		"term AND \"phrase phrase\"",
		"Boolean",
		"+text:term +text:\"phrase phrase\""
	],
	[ "germ term^2.0", "Boolean", "text:germ text:term^2.0" ],
	[
		"(foo OR bar) AND (baz OR boo)",
		"Boolean",
		"+(text:foo text:bar) +(text:baz text:boo)"
	],
	[ "germ*",         "Prefix", "text:germ*" ],
	[ '"term germ"~2', "Phrase", 'text:"term germ"~2' ],
	[ '"term"~2',      "Term",   'text:term' ],

);

my @and_tests = (
	[ "test",             "Term",    "text:test" ],
	[ "notice",           "Term",    "text:notice" ],
	[ "newfield:test",    "Term",    "newfield:test" ],
	[ "one two",          "Boolean", "+text:one +text:two" ],
	[ "one.two",          "Phrase",  "text:\"one two\"" ],
	[ "one newfield:two", "Boolean", "+text:one +newfield:two" ],
	[ "+req",             "Boolean", "+text:req" ],
	[ "FOO AND BAR",      "Boolean", "+text:foo +text:bar" ],
	[ "+term -term term", "Boolean", "+text:term -text:term +text:term" ],
	[
		"term AND \"phrase phrase\"",
		"Boolean",
		"+text:term +text:\"phrase phrase\""
	],
	[ "germ term^2.0", "Boolean", "+text:germ +text:term^2.0" ],
	[
		"(foo OR bar) AND (baz OR boo)",
		"Boolean",
		"+(text:foo text:bar) +(text:baz text:boo)"
	]

);
Test::More->import(tests => 1 + 2 * (@or_tests + @and_tests));
isa_ok($parser, "Plucene::QueryParser");

sub do_tests {
	for (@_) {
		my ($input, $type, $round_trip) = @$_;
		my $query = $parser->parse($input);
		isa_ok($query, "Plucene::Search::${type}Query");
		is($query->to_string(""), $round_trip, "$input parsed OK ($round_trip)");
	}
}

$Plucene::QueryParser::DefaultOperator = "OR";
do_tests(@or_tests);
$Plucene::QueryParser::DefaultOperator = "AND";
do_tests(@and_tests);
