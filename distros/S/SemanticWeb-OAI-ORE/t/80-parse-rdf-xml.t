#!perl -T
#
# Test code related to resource maps in RDF/XML for Data Conservancy
#
# $Id: 80-parse-rdf-xml.t,v 1.8 2010-12-06 14:44:02 simeon Exp $
use strict;

use warnings;
use Test::More;
plan('tests'=>49);

use_ok( 'SemanticWeb::OAI::ORE::ReM' );
use_ok( 'SemanticWeb::OAI::ORE::RDFXML' );
use_ok( 'SemanticWeb::OAI::ORE::Constant' );

use SemanticWeb::OAI::ORE::Constant qw(:all);

{
  my $rem=SemanticWeb::OAI::ORE::ReM->new('debug'=>1);
  my $file="t/examples/datamodel-overview/combined.rdf.dump";
  ok( $rem->parsefile('rdfxml',$file,'http://example/ReM-1'), "Parse $file as RDF/XML");
  ok( $rem->is_valid, 'valid resource map obtained'.($rem->errstr?': '.$rem->errstr:'') );
  is( $rem->model->countStmts, 15, 'got 15 statements' );
  is( $rem->uri, 'http://example/ReM-1', "check ReM-1");
  is( $rem->aggregation, 'http://example/A-1', "check A-1");
  my @ars=sort $rem->aggregated_resources;
  is( $ars[0], 'http://example/AR-1', "check AR-1");
  is( $ars[1], 'http://example/AR-2', "check AR-2");
  is( $ars[2], 'http://example/AR-3', "check AR-3");
  is( $rem->creator->uri, 'http://example/X', "check ReM creator uri X" );
  #print $rem->model->as_n3('sorted');
}

{
  my $rem=SemanticWeb::OAI::ORE::ReM->new('debug'=>1);
  my $file="t/examples/data_conservancy/ResourceMap1.xml";
  ok( $rem->parsefile('rdfxml',$file), "Parse $file as RDF/XML, no URI of ReM supplied");
  ok( $rem->is_valid, 'valid resource map obtained'.($rem->errstr?': '.$rem->errstr:'') );
  is( $rem->model->countStmts, 39, 'got 39 statements' );
  is( $rem->uri, 'http://datapub.example.com/ResourceMap', "check ReM URI");
  is( $rem->aggregation, 'http://datapub.example.com/Aggregation', "check Agg URI");
  my @ars=sort $rem->aggregated_resources;
  is( $ars[0], 'file://README', "check first ar: file://README");
  is( scalar(@ars), 5, "check number of ars: 5");
  is( ref($rem->creator), 'SemanticWeb::OAI::ORE::Agent', "check ReM creator is agent" );
  is( $rem->creator->name, 'datapub web app', "check ReM creator name" );
  is( $rem->creator->mbox, undef, "check ReM creator mbox" );
  is( $rem->creator->real_uri, undef, "check ReM uri is bnode" );
  
  # Title
  my $ttitle="A simple title";
  is( $rem->aggregation_metadata_literal('http://purl.org/dc/elements/1.1/title'), $ttitle, 'metadata: check title' );
  is( $rem->aggregation_metadata_literal('dc:title'), $ttitle, 'metadata: check title' );

  # Authors
  my @authors=$rem->aggregation_metadata('dcterms:creator');
  is( scalar(@authors), 3, '3 authors');
}

{
  my $rem=SemanticWeb::OAI::ORE::ReM->new('debug'=>1);
  my $file="t/examples/data_conservancy/ResourceMap2.xml";
  ok( $rem->parsefile('rdfxml',$file), "Parse $file as RDF/XML");
  ok( $rem->is_valid, 'valid resource map obtained'.($rem->errstr?': '.$rem->errstr:'') );
  is( $rem->model->countStmts, 172, 'got 172 statements' );
  is( $rem->uri, 'http://datapub.dataconservancy.org/ResourceMap', "check ReM URI");
  is( $rem->aggregation, 'http://datapub.dataconservancy.org/Aggregation', "check Agg URI");
  my @ars=sort $rem->aggregated_resources;
  is( $ars[0], 'file:///gbfits2.fits', "check first ar: file://Document");
  is( scalar(@ars), 21, "check number of ars: ");
  is( ref($rem->creator), 'SemanticWeb::OAI::ORE::Agent', "check ReM creator is agent" );
  is( $rem->creator->name, 'datapub web app', "check ReM creator name" );
  is( $rem->creator->mbox, undef, "check ReM creator mbox" );
  is( $rem->creator->real_uri, undef, "check ReM uri is bnode" );
  
  # Title
  my $ttitle="The Second Survey of the Molecular Clouds in the Large Magellanic Cloud by NANTEN I: Catalog of Molecular Clouds";
  is( $rem->aggregation_metadata_literal('http://purl.org/dc/elements/1.1/title'), $ttitle, 'metadata: check title' );
  is( $rem->aggregation_metadata_literal('dc:title'), $ttitle, 'metadata: check title' );

  # Authors
  my @authors=$rem->aggregation_metadata('dcterms:creator');
  is( scalar(@authors), 11, '11 authors');
}

# Test parsing from string
SKIP: {
  my $rem=SemanticWeb::OAI::ORE::ReM->new('debug'=>1);
  my $file="t/examples/data_conservancy/ResourceMap2.xml";
  open(my $fh, '<', $file) || skip("Failed to open $file, cannot run parse as string test",3);
  local $/=undef;
  my $rdfxml=<$fh>;
  close($fh);
  ok( $rem->parse('rdfxml',$rdfxml), "Parse $file as RDF/XML string");
  ok( $rem->is_valid, 'valid resource map obtained'.($rem->errstr?': '.$rem->errstr:'') );
  is( $rem->model->countStmts, 172, 'got 172 statements' );
}

# Test parsing from URI
SKIP: {
  my $uri_rem='http://www.openarchives.org/ore/1.0/rdfxml-examples/ex3_8.rdfxml';
  if (not $ENV{TEST_WITH_NETWORK}) {
    skip("Set TEST_WITH_NETWORK  to run test of parseuri on $uri_rem",6);
  }
  # First form, via parseuri
  {
    my $rem=SemanticWeb::OAI::ORE::ReM->new;
    ok( $rem->parseuri('rdfxml',$uri_rem), "Parse $uri_rem as RDF/XML with rem->parseuri");
    $rem->uri('http://arxiv.org/rem/rdf/astro-ph/0601007'); # does not match location
    ok( $rem->is_valid, 'valid resource map obtained'.($rem->errstr?': '.$rem->errstr:'') );
    is( $rem->model->countStmts, 110, 'got 110 statements' );
  }
  # Second form, via parse
  {
    my $rem=SemanticWeb::OAI::ORE::ReM->new;
    ok( $rem->parse('rdfxml',undef,$uri_rem), "Parse $uri_rem as RDF/XML with rem->parse");
    $rem->uri('http://arxiv.org/rem/rdf/astro-ph/0601007'); # does not match location
    ok( $rem->is_valid, 'valid resource map obtained'.($rem->errstr?': '.$rem->errstr:'') );
    is( $rem->model->countStmts, 110, 'got 110 statements' );
  }
}