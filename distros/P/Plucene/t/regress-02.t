#!/usr/bin/perl -w

use strict;
use warnings;

require Test::More;
use Plucene::TestCase;
$ANALYZER = "Plucene::Analysis::WhitespaceAnalyzer";

my $entries = [
	{ 'message' => join " ", 1 .. 128 },
	{ 'message' => 129, },
	{ 'message' => 130, },
];
die $@ if $@;
Test::More->import(tests => 130 + scalar @$entries);

new_index {
	for (@$entries) {
		my $doc = Plucene::Document->new();

		while (my ($key, $val) = each %$_) {
			next unless $key eq "message";
			$doc->add(Plucene::Document::Field->Text($key, $val));
		}
		$WRITER->add_document($doc);
		$WRITER->optimize();
		ok(1, "worked");
	}
};

# Check they're all there.

for (1 .. 130) {
	is(search("message:$_")->length, 1, "$_ was found");
}

