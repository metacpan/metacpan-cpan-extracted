#!/usr/bin/perl

use lib "lib";
use RDF::RDB2RDF::DirectMapping;
use RDF::TrineShortcuts;

my $dbh    = DBI->connect('dbi:Pg:dbname=mytest3');
my $mapper = RDF::RDB2RDF->new('DirectMapping', prefix=>'http://id.example.net/', rdfs=>1);
print $mapper->process_turtle([$dbh,'public']);
