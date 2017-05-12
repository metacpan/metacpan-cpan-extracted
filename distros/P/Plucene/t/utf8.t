#!/usr/bin/perl

# This tests that Unicode data can be written and retrieved successfully.

use strict;
use warnings;

use Test::More tests => 2;

use Plucene::TestCase;

{
	$ANALYZER = "Plucene::Analysis::WhitespaceAnalyzer";
	if ($] < 5.007) {
		new_index {
			add_document(text => "bar foo baz");
			add_document(text => "bar f\x{f2}o baz");
			add_document(text => "bar f\x{14d}o baz");
		};

		my $hits = search("text:f\x{14d}o");
		my @ids = sort map $_->{id}, @{ $hits->{hit_docs} };
		is_deeply(\@ids, [2], "Right documents");
		$hits = search("text:f\x{f2}o");
		@ids = sort map $_->{id}, @{ $hits->{hit_docs} };
		is_deeply(\@ids, [1], "Right documents");
	} else {
		use Encode;
		my $foo1 = encode('utf8',       'foo');
		my $foo2 = encode('iso-8859-1', 'foo');
		new_index {
			add_document(text => "bar foo baz");
			add_document(text => "bar $foo1 baz");
			add_document(text => "bar $foo2 baz");
		};
		my $hits = search("text:$foo1");
		my @ids = sort map $_->{id}, @{ $hits->{hit_docs} };
		is_deeply(\@ids, [ 0, 1, 2 ], "Right documents");
		$hits = search("text:$foo2");
		@ids = sort map $_->{id}, @{ $hits->{hit_docs} };
		is_deeply(\@ids, [ 0, 1, 2 ], "Right documents");
	}
}
