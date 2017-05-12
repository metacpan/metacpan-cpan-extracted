use v5.10;
use strict;
use warnings;

use Syntax::Highlight::RDF;

my $hl = "Syntax::Highlight::RDF"->highlighter("PretDSL");

say "<style type='text/css'>";
say ".$_ { $Syntax::Highlight::RDF::STYLE{$_} }" for sort keys %Syntax::Highlight::RDF::STYLE;
say "</style>";
say "<pre>", $hl->highlight(\*DATA, "http://www.example.net/"), "</pre>";

__DATA__
@base <http://www.example.org/> .
@prefix foo: <http://example.com/foo#> .
@prefix quux: <quux#>.

`Foo-Bar`
	label      "Yee-hah!";
	dc:creator cpan:TOBYINK.

`Foo-Bar 0.001`
	issued     2012-02-01.
