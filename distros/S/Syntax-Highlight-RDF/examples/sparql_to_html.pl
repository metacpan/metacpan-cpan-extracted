use v5.10;
use strict;
use warnings;

use Syntax::Highlight::RDF;

my $hl   = "Syntax::Highlight::RDF"->highlighter("SPARQL");

say "<style type='text/css'>";
say ".$_ { $Syntax::Highlight::RDF::STYLE{$_} }" for sort keys %Syntax::Highlight::RDF::STYLE;
say "</style>";
say "<pre>", $hl->highlight(\*DATA, "http://www.example.net/"), "</pre>";

__DATA__
PREFIX foaf: <http://xmlns.com/foaf/0.1/>
SELECT ?mbox ?hpage
WHERE  { ?x foaf:name "Toby Inkster"@en-gb .
         OPTIONAL { ?x foaf:mbox ?mbox } .
         OPTIONAL { ?x foaf:homepage ?hpage }
       }
