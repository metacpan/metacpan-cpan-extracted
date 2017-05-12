use v5.10;
use strict;
use warnings;

use Syntax::Highlight::RDF;

my $hl = "Syntax::Highlight::RDF"->highlighter("JSON");

say "<style type='text/css'>";
say ".$_ { $Syntax::Highlight::JSON2::STYLE{$_} }" for sort keys %Syntax::Highlight::JSON2::STYLE;
say "</style>";
say "<pre>", $hl->highlight(\*DATA, "http://www.example.net/"), "</pre>";

__DATA__
{
	"http://example.org/about": 
	{
		"http://purl.org/dc/elements/1.1/title":
		[
			{ "type": "literal" , "value": "Anna's Homepage" },
			{ "type": null, "value": 123.45 }
		]
	}
}
