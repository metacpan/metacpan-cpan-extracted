#!/usr/bin/perl -w

# Copyright (c) 2005 Hans Jeuken. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use strict;
use Term::ANSIColor;

use Syntax::Highlight::Engine::Kate;


unless (@ARGV) { die "You must supply a syntax mode as parameter" };
my $syntax = shift @ARGV;

my $hl = new Syntax::Highlight::Engine::Kate(
	language => $syntax,
	substitutions => {
		"\n" => color('reset') . "\n",
	},
	format_table => {
		Alert => [color('white bold on_green'), color('reset')],
		BaseN => [color('green'), color('reset')],
		BString => [color('red bold'), color('reset')],
		Char => [color('magenta'), color('reset')],
		Comment => [color('white bold on_blue'), color('reset')],
		DataType => [color('blue'), color('reset')],
		DecVal => [color('blue bold'), color('reset')],
		Error => [color('yellow bold on_red'), color('reset')],
		Float => [color('blue bold'), color('reset')],
		Function => [color('yellow bold on_blue'), color('reset')],
		IString => [color('red'), color('reset')],
		Keyword => [color('bold'), color('reset')],
		Normal => [color('reset'), color('reset')],
		Operator => [color('green'), color('reset')],
		Others => [color('yellow bold on_green'), color('reset')],
		RegionMarker => [color('black on_yellow bold'), color('reset')],
		Reserved => [color('magenta on_blue'), color('reset')],
		String => [color('red'), color('reset')],
		Variable => [color('blue on_red bold'), color('reset')],
		Warning => [color('green bold on_red'), color('reset')],
		
	},
);

my $newline = color('reset') . "\n";

while (my $in = <>) {
#	print $in;
	my $res = $hl->highlightText($in);
#	$res =~ s/\n/$newline/g;
	print $res;
}
