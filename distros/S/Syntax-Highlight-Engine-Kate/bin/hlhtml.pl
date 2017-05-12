#!/usr/bin/perl -w

# Copyright (c) 2005 Hans Jeuken. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use strict;
use Term::ANSIColor;

use Syntax::Highlight::Engine::Kate;


unless (@ARGV) { die "You must supply a language mode as parameter" };
my $syntax = shift @ARGV;

my $hl = new Syntax::Highlight::Engine::Kate(
	language => $syntax,
	substitutions => {
		'<' => '&lt;',
		'>' => '&gt;',
		'&' => '&amp;',
		' ' => '&nbsp;',
		"\t" => '&nbsp;&nbsp;&nbsp;',
		"\n" => "<BR>\n",
	},
	format_table => {
		Alert => ['<font color="#0000ff">', '</font>'],
		BaseN => ['<font color="#007f00">', '</font>'],
		BString => ['<font color="#c9a7ff">', '</font>'],
		Char => ['<font color="#ff00ff">', '</font>'],
		Comment => ['<font color="#7f7f7f"><i>', '</i></font>'],
		DataType => ['<font color="#0000ff">', '</font>'],
		DecVal => ['<font color="#00007f">', '</font>'],
		Error => ['<font color="#ff0000"><b><i>', '</i></b></font>'],
		Float => ['<font color="#00007f">', '</font>'],
		Function => ['<font color="#007f00">', '</font>'],
		IString => ['<font color="#ff0000">', ''],
		Keyword => ['<b>', '</b>'],
		Normal => ['', ''],
		Operator => ['<font color="#ffa500">', '</font>'],
		Others => ['<font color="#b03060">', '</font>'],
		RegionMarker => ['<font color="#96b9ff"><i>', '</i></font>'],
		Reserved => ['<font color="#9b30ff"><b>', '</b></font>'],
		String => ['<font color="#ff0000">', '</font>'],
		Variable => ['<font color="#0000ff"><b>', '</b></font>'],
		Warning => ['<font color="#0000ff"><b><i>', '</font>'],
		
	},
);

print "<html>\n<head>\n</head>\n<body>\n";

my $text = "";

while (my $in = <>) {
	$text = $text . $in;
#	print $hl->highlightText($in);
}
print $hl->highlightText($text);
print "</body>\n</html>\n"
