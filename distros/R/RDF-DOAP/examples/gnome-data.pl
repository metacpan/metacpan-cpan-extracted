use strict;
use warnings;

use RDF::DOAP;

my $url  = 'http://ftp.heanet.ie/mirrors/gnome/sources/banshee/banshee.doap#type=.rdf';
my $doap = 'RDF::DOAP'->from_url($url);
my $proj = $doap->project;

print $proj->dump_json;

