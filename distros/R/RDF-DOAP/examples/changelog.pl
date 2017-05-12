use strict;
use warnings;

use RDF::DOAP;

my $url  = 'http://api.metacpan.org/source/TOBYINK/MooseX-XSAccessor-0.005/doap.ttl';
my $doap = 'RDF::DOAP'->from_url($url);
my $proj = $doap->project;

print $proj->changelog;
