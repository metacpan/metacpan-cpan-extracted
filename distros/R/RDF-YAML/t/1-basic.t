# $File: //member/autrijus/RDF-YAML/t/1-basic.t $ $Author: autrijus $
# $Revision: #2 $ $Change: 8524 $ $DateTime: 2003/10/22 05:20:04 $

use strict;
use FindBin;
use File::Spec;
use Test::More tests => 9;

# XXX - this test suite badly needs a rewrite.

use_ok('RDF::YAML');

my $obj = RDF::YAML->new;
isa_ok($obj, 'RDF::YAML');

my $sample = File::Spec->catfile($FindBin::Bin, 'sample.yml');

isa_ok( $obj->parse_file($sample), 'ARRAY', 'parse_file' );
isa_ok( $obj->get_ns, 'HASH', 'get_ns' );

use_ok('RDF::Simple::Parser');

my %namespaces = ( 'rss' => 'http://purl.org/rss/1.0/' );
isa_ok( $obj->add_ns( \%namespaces ), 'HASH', 'add_ns' );
is( $obj->get_ns->{rss}, 'http://purl.org/rss/1.0/', 'add_ns works' );

my @triples = RDF::Simple::Parser->new->parse_rdf(join '', <DATA>);
isa_ok( $obj->set_triples( \@triples ), 'ARRAY', 'set_triples' );
ok($obj->dump_string, 'dump_string works');

__DATA__
<?xml version="1.0" encoding="UTF-8"?>

<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:sy="http://purl.org/rss/1.0/modules/syndication/" xmlns:admin="http://webns.net/mvcb/" xmlns="http://purl.org/rss/1.0/">

<channel rdf:about="http://glob.autrijus.org/">
<title>Autrijus.Home</title>
<link>http://glob.autrijus.org/</link>
<description>Autrijus Tang
</description>
<dc:language>en-us</dc:language>
<dc:creator></dc:creator>
<dc:date>2002-12-15T16:35:34+08:00</dc:date>
<admin:generatorAgent rdf:resource="http://www.movabletype.org/?v=2.51" />

<items>
<rdf:Seq>
<rdf:li rdf:resource="http://glob.autrijus.org/archives/000016.html" />
</rdf:Seq>
</items>

</channel>


<item rdf:about="http://glob.autrijus.org/archives/000016.html">
<title>The Elixir Initiative</title>
<link>http://glob.autrijus.org/archives/000016.html</link>
<description>Located at http://meta.elixus.org/, this anarchistic non-organization meets every Sunday afternoon at the Cozy Caf&amp;eacute; (#23 Section 3 Li-Shui Street), debate...</description>
<dc:subject>01Team</dc:subject>
<dc:creator>autrijus</dc:creator>
<dc:date>2002-12-15T16:35:34+08:00</dc:date>
</item>


</rdf:RDF>
