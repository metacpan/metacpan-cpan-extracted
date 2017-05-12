#!perl

use File::Temp qw/ tempfile /;
use Carp;
use Test::More tests => 8;

BEGIN { use_ok NLP::GATE }

use strict;
use FindBin;

diag( "Testing NLP::GATE::Document $NLP::GATE::Document::VERSION, Perl $], $^X" );

can_ok("NLP::GATE::Document", 'new');

my $doc1 = NLP::GATE::Document->new();
isa_ok($doc1, 'NLP::GATE::Document');

can_ok($doc1,qw( fromXML fromXMLFile getAnnotationSet getFeature getFeatureType getText getTextForAnnotation
  new setAnnotationSet setFeature setFeatureType setText toXML ) );

ok($doc1->setText("Some text for the document"),'Can set document text');

my $ann1_1 = NLP::GATE::Annotation->new("AType1",3,11);
$ann1_1->setFeature("f1","v1");
$ann1_1->setFeature("f2","true");
$ann1_1->setFeatureType("f2","java.lang.Boolean");
$ann1_1->setFeature("f3",123);
$ann1_1->setFeatureType("f3","java.lang.Integer");

my $annset1 = NLP::GATE::AnnotationSet->new();
$annset1->add($ann1_1);

my $annset2 = NLP::GATE::AnnotationSet->new();
my $ann2_1 = NLP::GATE::Annotation->new("AType2",2,14);

$doc1->setAnnotationSet($annset1);
$doc1->setAnnotationSet($annset2,"MyAnnotations");

my $xml = $doc1->toXML();

my $doc2 = NLP::GATE::Document->new();
$doc2->fromXML($xml);

is_deeply($doc1,$doc2,"same after toXML and fromXML");

my $toAppend = "this is the appended text";
my ($from,$to) = $doc2->appendText($toAppend);
my $appendAnn = NLP::GATE::Annotation->new("APPENDED",$from,$to);
my $appendedText = $doc2->getTextForAnnotation($appendAnn);

is($appendedText,$toAppend,"correctly return offsets for appended text");

my $doc3 = NLP::GATE::Document->new();
my $doc4 = NLP::GATE::Document->new();
#diag( "Parsing a big document, this can take a while ...." );
$doc3->fromXMLFile("$FindBin::RealBin/doc_enc1.xml");
$xml = $doc3->toXML();
$doc4->fromXML($xml);

is_deeply($doc3,$doc4,"same after toXML and fromXML for external doc");

#my $fn = "/tmp/GATE_doc_enc1_$$.xml";
my (undef, $fn) = tempfile(UNLINK=>1);
open(OUT,">:utf8","$fn") or die "Cannot open $fn for writing $!";
print OUT $xml;
close OUT;



diag( "NLP::GATE::Document tested" );
