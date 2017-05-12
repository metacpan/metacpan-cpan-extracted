#!/usr/bin/perl -w

use strict;
use Test::Simple tests => 2;

use SVG::Metadata;

my $svgmeta = new SVG::Metadata();

$svgmeta->addKeyword('foo');
$svgmeta->addKeyword('bar','baz');

# Validate text output
my $text = qq(Title:\\s*
Author:\\s*
License:\\s*
Keywords:\\s*bar
\\s*baz
\\s*foo);
ok( $svgmeta->to_text() =~ m|$text|m);

print $text;

print $svgmeta->to_text();

# Validate rdf output
my $rdf = qq(
\\s*<dc:subject>
\\s*<rdf:Bag>
\\s*<rdf:li>bar</rdf:li>
\\s*<rdf:li>baz</rdf:li>
\\s*<rdf:li>foo</rdf:li>
\\s*</rdf:Bag>
\\s*</dc:subject>);
ok( $svgmeta->to_rdf() =~ m/$rdf/m);

