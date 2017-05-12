#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use lib "lib";
use PepXML::Parser;

plan tests => 5;

my $p = PepXML::Parser->new();

my $pepxmlfile = $p->parse("t/small.sample.pep.xml");

cmp_ok( $pepxmlfile->msms_pipeline_analysis->date, 'eq', "2015-04-09T18:54:11" );
cmp_ok( $pepxmlfile->msms_pipeline_analysis->xmlns, 'eq', "http://regis-web.systemsbiology.net/pepXML" );
cmp_ok( $pepxmlfile->msms_pipeline_analysis->xmlns_xsi, 'eq', "http://www.w3.org/2001/XMLSchema-instance" );
cmp_ok( $pepxmlfile->msms_pipeline_analysis->xmlns_schemaLocation, 'eq', "http://sashimi.sourceforge.net/schema_revision/pepXML/pepXML_v117.xsd" );
cmp_ok( $pepxmlfile->msms_pipeline_analysis->summary_xml, 'eq', "/scratch/nesvi_flux/andykong/Pandey_mzXML_ms2/Adult_Adrenalgland_Gel_Elite_49_f01.pep.xml" );
