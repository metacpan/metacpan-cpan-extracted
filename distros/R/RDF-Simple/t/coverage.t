
# $Id: coverage.t,v 1.1 2009/04/11 15:50:20 Martin Exp $

use strict;
use warnings;

use blib;
use RDF::Simple::Parser;
use RDF::Simple::Serialiser;
use Test::More 'no_plan';

my $ser = new RDF::Simple::Serialiser;
isa_ok($ser, q{RDF::Simple::Serialiser});
my $par = new RDF::Simple::Parser;
isa_ok($par, q{RDF::Simple::Parser});

pass(q{parse_file()...});
$par->parse_file();
pass(q{parse_file('')...});
$par->parse_file(q{});
pass(q{parse_uri()...});
$par->parse_uri();
pass(q{parse_uri('')...});
$par->parse_uri(q{});
my $sRDFEmpty = <<EMPTY;
<?xml version="1.0" encoding="UTF-8"?>
<rdf:RDF
xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
>
</rdf:RDF>
EMPTY
pass(q{parse 'empty' rdf...});
$par->parse_rdf($sRDFEmpty);
undef $/;
my $sRDFFeatures = <DATA>;
pass(q{parse rdf with special features...});
$par->parse_rdf($sRDFFeatures);
$ser->genid;
$ser->serialise;
$ser->genid();
$ser->genid(q{});
$ser->genid(q{fubar});
pass(q{all done});


__END__
<?xml version="1.0" encoding="UTF-8"?>
<rdf:RDF
xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
xmlns:cd="http://www.recshop.fake/cd#"
xmlns:s="http://example.org/students/vocab#"
xmlns:exterms="http://www.example.org/terms/"
xmlns:dc="http://purl.org/dc/elements/1.1/"
xmlns:xsd="http://www.w3.org/2001/XMLSchema#"
xml:base="http://www.example.com/2002/04/products"
>

  <rdf:Description rdf:ID="book12345">
     <dc:title rdf:parseType="Literal">
       <span xml:lang="en">
         The <em>&lt;br /&gt;</em> Element Considered Harmful.
       </span>
     </dc:title>
  </rdf:Description>

<rdf:Description
rdf:about="http://www.recshop.fake/cd/BeatlesBag">
  <cd:artist>
    <rdf:Bag>
      <rdf:li>John</rdf:li>
      <rdf:li>Paul</rdf:li>
      <rdf:li>George</rdf:li>
      <rdf:li>Ringo</rdf:li>
    </rdf:Bag>
  </cd:artist>
</rdf:Description>

<rdf:Description
rdf:about="http://www.recshop.fake/cd/BeatlesSeq">
  <cd:artist>
    <rdf:Seq>
      <rdf:li>George</rdf:li>
      <rdf:li>John</rdf:li>
      <rdf:li>Paul</rdf:li>
      <rdf:li>Ringo</rdf:li>
    </rdf:Seq>
  </cd:artist>
</rdf:Description>

<rdf:Description
rdf:about="http://www.recshop.fake/cd/BeatlesAlt">
  <cd:format>
    <rdf:Alt>
      <rdf:li>CD</rdf:li>
      <rdf:li>Record</rdf:li>
      <rdf:li>Tape</rdf:li>
    </rdf:Alt>
  </cd:format>
</rdf:Description>

   <rdf:Description rdf:about="http://example.org/courses/6.001">
      <s:students rdf:parseType="Collection">
            <rdf:Description rdf:about="http://example.org/students/Amy"/>
            <rdf:Description rdf:about="http://example.org/students/Mohamed"/>
            <rdf:Description rdf:about="http://example.org/students/Johann"/>
      </s:students>
   </rdf:Description>

  <rdf:Description rdf:about="http://www.example.com/2002/04/products#item10245">
     <exterms:weight rdf:parseType="Resource">
       <rdf:value rdf:datatype="xsd:decimal">2.4</rdf:value>
       <exterms:units rdf:resource="http://www.example.org/units/kilograms"/>
     </exterms:weight>
  </rdf:Description>

</rdf:RDF>
