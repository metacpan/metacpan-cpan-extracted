#!/usr/bin/perl
################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################

use strict;
use warnings;

use Image::Size;

my $root = '../sprites';

opendir(my $dh, $root) or die "opendir fam: $!";

open(my $css, ">", "fam.css") or die "open fam.css: $!";
open(my $html, ">", "fam.html") or die "open fam.html: $!";

# binmode $css; binmode $html;

my @files = grep { -f join('/', $root, $_) } sort readdir($dh);

print $css "\n /* sprite: fam url(../result/generated.png); */\n";

print $html "<html>\n";
print $html "<head><title>FAM WebSprite</title></head>\n";
print $html "<link rel=\"stylesheet\" href=\"fam.css\">\n";

print $html "<style>DIV { float: left; margin: 5px; }</style>\n";
print $html "<body>\n";

foreach my $file (@files)
{

	my ($w, $h) = imgsize(join('/', $root, $file));

	next unless $w && $h;

	my $name = $file;

	$name=~s/\.[^\.]+$/-/g;
	$name=~s/\W+/-/g;
	$name=~s/_/-/g;
	$name=~s/^\-+//g;
	$name=~s/\-+$//g;

	printf $css "\n.%s\n", $name;
	printf $css "{\n";
	printf $css "	/* css-ref: fam; */\n";
	printf $css "	background-repeat: no-repeat;\n";
	printf $css "	background-position: left top;\n";
	printf $css "	width: %spx; height: %spx;\n", $w, $h;
	printf $css "	background-image: url('%s/%s');\n", $root, $file;
	printf $css "}\n";

	printf $html "<div class=\"%s\"></div>\n", $name;


}

print $html "</body>\n";
print $html "</html>";
