#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use List::Util qw(sum);
use IO::Scalar;

use Plucene::Analysis::Standard::StandardAnalyzer;

use Test::More tests => 19;

my %tests = (
	SimpleAnalyzer => [
		[ "foo bar FOO BAR"            => [ "foo", "bar", "foo", "bar" ] ],
		[ "foo      bar .  FOO <> BAR" => [ "foo", "bar", "foo", "bar" ] ],
		[ "foo.bar.FOO.BAR"            => [ "foo", "bar", "foo", "bar" ] ],
		[ "U.S.A."                     => [ "u",   "s",   "a" ] ],
		[ "C++"                        => ["c"] ],
		[ "B2B"             => [ "b",      "b" ] ],
		[ "2B"              => ["b"] ],
		[ "\"QUOTED\" word" => [ "quoted", "word" ] ],
	],

	WhitespaceAnalyzer => [
		[ "foo bar FOO BAR" => [ "foo", "bar", "FOO", "BAR" ] ],
		[
			"foo      bar .  FOO <> BAR" =>
				[ "foo", "bar", ".", "FOO", "<>", "BAR" ]
		],
		[ "foo.bar.FOO.BAR" => ["foo.bar.FOO.BAR"] ],
		[ "U.S.A."          => ["U.S.A."] ],
		[ "C++"             => ["C++"] ],
		[ "B2B"             => ["B2B"] ],
		[ "2B"              => ["2B"] ],
		[ "\"QUOTED\" word" => [ "\"QUOTED\"", "word" ] ],
	],

	StopAnalyzer => [
		[ "foo bar FOO BAR"              => [ "foo", "bar", "foo", "bar" ] ],
		[ "foo a bar such FOO THESE BAR" => [ "foo", "bar", "foo", "bar" ] ],
	]);

for my $analyzer (keys %tests) {
	my $class = "Plucene::Analysis::$analyzer";
	eval "require $class";
	my $a = $class->new;
	for (@{ $tests{$analyzer} }) {
		my ($input, $output) = @$_;
		my $stream = $a->tokenstream({
				field  => "dummy",
				reader => IO::Scalar->new(\$input) });
		my @data;
		push @data, $_->text while $_ = $stream->next;
		is_deeply(\@data, $output, "$class analyzed $input");
	}
}

{    # StandardAnalyzer is a subclass of Analyzer
	isa_ok +Plucene::Analysis::Standard::StandardAnalyzer->new =>
		'Plucene::Analysis::Analyzer';
}
