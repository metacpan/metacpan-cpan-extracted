#!/usr/bin/perl

use 5.010;
use RDF::RDFa::Parser;
use RDF::Trine::Serializer;

my $file = URI::file->new_abs(shift);
my $opts = RDF::RDFa::Parser::Config->new(xhtml => '1.1');
my $rdfa = RDF::RDFa::Parser->new_from_url($file, $opts);
my $ser  = RDF::Trine::Serializer->new('NTriples');

print $ser->serialize_model_to_string($rdfa->graph);

