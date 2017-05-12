#!/usr/bin/perl

use RDF::TrineShortcuts;
use RDF::KML::Exporter;

my $data = <<TURTLE;

\@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
\@prefix geo:  <http://www.w3.org/2003/01/geo/wgs84_pos#> .

[]
	rdfs:label "Test"@en ;
	a geo:Point ;
	geo:lat 1.23 ;
	geo:long 4.56 .

[]
	a geo:Point ;
	geo:alt 0;
	geo:lat 7.23 ;
	geo:long 8.56 .

TURTLE

my $e = RDF::KML::Exporter->new;
print $e->export_kml(rdf_parse($data,type=>'turtle'))->render;
