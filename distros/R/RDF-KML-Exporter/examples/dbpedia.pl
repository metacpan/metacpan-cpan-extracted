#!/usr/bin/perl

use RDF::KML::Exporter;

my $place = shift
	or die "usage: dbpedia.pl Glasgow\n(or some other place)\n";

print RDF::KML::Exporter->export_kml("http://dbpedia.org/data/${place}")->render;
