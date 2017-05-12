use v5.10;
use strict;
use warnings;

use Syntax::Highlight::RDF;

my $hl   = "Syntax::Highlight::RDF"->highlighter("Turtle");

say "<style type='text/css'>";
say ".$_ { $Syntax::Highlight::RDF::STYLE{$_} }" for sort keys %Syntax::Highlight::RDF::STYLE;
say "</style>";
say "<pre>", $hl->highlight(\*DATA, "http://www.example.net/"), "</pre>";

__DATA__
@base <http://www.example.org/> .
@prefix foo: <http://example.com/foo#> .
@prefix quux: <quux#>.

<xyz>
   foo:bar 123;
   foo:baz "Yeah\"Baby\"Yeah";
   foo:bum quux:quuux.

