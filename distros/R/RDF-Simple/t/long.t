
# This is a test for RT#43688 part 2, long string element gets truncated

use strict;
use warnings;

use Test::More 'no_plan';

use blib;
use RDF::Simple::Parser;

my $o = new RDF::Simple::Parser;
isa_ok($o, q{RDF::Simple::Parser});
my $sRDF = join(q{}, <DATA>);
my @triples = $o->parse_rdf($sRDF);
is(scalar(@triples), 4, 'got four triples');
is(length($triples[1]->[2]), 1177, 'got long string in proper place');
is(length($triples[3]->[2]), 1177, 'got long string in proper place');

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
   <cet:Dataset rdf:about="http://nees.ncsa.uiuc.edu/2009/ns/file#111AAA">
<dc:description>
These experiments are part of a collaborative research project to study soil-foundation-structure interaction.  A continuous reinforced concrete bridge supported on drilled shaft foundations was selected as the prototype structure for investigation.  Two, 1/4-scale, reinforced concrete bents were constructed at a test site in southeast Austin.  The primary difference between the two specimens was the clear height of the columns.  Bent 1 had two, 12-in. diameter columns with a clear height of 6 ft.  The clear height of the columns in Bent 2 was 3 ft.  All four shafts had an embedded depth of 12 ft.  The soil at the site was classified as nonplastic silt and the entire lengths of the shafts were above the water table.  The two bents were tested dynamically during June and July 2005.  Three types of dynamic tests were conducted.  A modal hammer was used to excite the specimens using low-amplitude impulsive loads.  T-Rex, a triaxial mobile shaker, was used to shake the ground near the bents and the linear shaker from Thumper was attached to the specimens at midspan of the beams.  Static, pull-over tests are planned following the completion of the dynamic tests.
</dc:description>
   </cet:Dataset>
   <cet:Dataset rdf:about="http://nees.ncsa.uiuc.edu/2009/ns/file#222BBB">
<dc:description>
These experiments are part of a collaborative research project to study soil-foundation-structure interaction.  A continuous reinforced concrete bridge supported on drilled shaft foundations was selected as the prototype structure for investigation.  Two, 1/4-scale, reinforced concrete bents were constructed at a test site in southeast Austin.  The primary difference between the two specimens was the clear height of the columns.  Bent 1 had two, 12-in. diameter columns with a clear height of 6 ft.  The clear height of the columns in Bent 2 was 3 ft.  All four shafts had an embedded depth of 12 ft.  The soil at the site was classified as nonplastic silt and the entire lengths of the shafts were above the water table.  The two bents were tested dynamically during June and July 2005.  Three types of dynamic tests were conducted.  A modal hammer was used to excite the specimens using low-amplitude impulsive loads.  T-Rex, a triaxial mobile shaker, was used to shake the ground near the bents and the linear shaker from Thumper was attached to the specimens at midspan of the beams.  Static, pull-over tests are planned following the completion of the dynamic tests.
</dc:description>
   </cet:Dataset>
</rdf:RDF>
