use strict;
use warnings;

use RDF::DOAP;

my $url  = 'http://api.metacpan.org/source/DOY/Moose-2.0604/doap.rdf';
my $doap = 'RDF::DOAP'->from_url($url);
my $proj = $doap->project;

print($proj->name, "\n");   # Moose
print($_->name, "\n")
	for @{ $proj->maintainer };
