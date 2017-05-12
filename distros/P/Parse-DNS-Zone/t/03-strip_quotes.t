#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
use Test::More;
use Parse::DNS::Zone;

sub strip { Parse::DNS::Zone::_strip_quotes(@_) }
sub unstrip { Parse::DNS::Zone::_unstrip_quotes(@_) }

my %strip = (
	'no quotes' => ['no quotes'],
	'with escaped \"' => ['with escaped \"'],

	'with "quotes"' => ['with "$str[0]"', '"quotes"'],
	'with "two" "quotes"' => [
		'with "$str[0]" "$str[1]"', '"two"', '"quotes"'
	],
	'with "same" "same" quote' => [
		'with "$str[0]" "$str[1]" quote', '"same"', '"same"'
	],
	'with "escaped \" in quote"' => [
		'with "$str[0]"', '"escaped \" in quote"'
	],
);

plan tests => int keys(%strip) * 2;

is_deeply [strip($_)], $strip{$_}, "strip quotes from '$_'"
	for sort keys %strip;
is unstrip(@{$strip{$_}}), $_, "unstrip quotes for '$_'"
	for sort keys %strip;
