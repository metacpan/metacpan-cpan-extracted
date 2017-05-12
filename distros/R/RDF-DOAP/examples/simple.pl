use strict;
use warnings;

use RDF::DOAP;

my $url  = 'http://api.metacpan.org/source/TOBYINK/MooX-ClassAttribute-0.008/META.ttl';
my $doap = 'RDF::DOAP'->from_url($url);
my $proj = $doap->project;

print $proj->dump_json;

