
# This is a test for RT#43688, empty element

use strict;
use warnings;

use Test::More 'no_plan';

use blib;
use RDF::Simple::Parser;

my $o = new RDF::Simple::Parser;
isa_ok($o, q{RDF::Simple::Parser});
my $sRDF = join(q{}, <DATA>);
my @triples = $o->parse_rdf($sRDF);
is(scalar(@triples), 2, 'got two triples');
is($triples[1]->[2], q{}, 'got empty string in proper place');

if (0)
  {
  foreach my $triple (@triples)
    {
    print STDERR join("\n", map { qq"value$_: $triple->[$_]" } (0..2)), "\n\n";
    } # foreach
  } # if

__END__
<?xml version="1.0" encoding="UTF-8"?>
<rdf:RDF
 xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
 xmlns:cet="http://cet.ncsa.uiuc.edu/2007/"
 xmlns:dc="http://purl.org/dc/elements/1.1/"
 xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#">
   <cet:Dataset rdf:about="http://nees.ncsa.uiuc.edu/2009/ns/file#113347">
     <dc:description/>
   </cet:Dataset>
</rdf:RDF>
