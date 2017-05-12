#!/usr/bin/perl

use 5.010;
use lib "lib";
use RDF::Trine qw[iri statement literal variable];
use RDF::RDB2RDF::DirectMapping;
use RDF::RDB2RDF::DirectMapping::Store;

my $dbh    = DBI->connect("dbi:SQLite:dbname=t/library.sqlite");
my $mapper = RDF::RDB2RDF->new('DirectMapping', prefix=>'http://id.example.net/');
my $store  = RDF::RDB2RDF::DirectMapping::Store->new($dbh, $mapper);

sub sayit
{
	say $_[0]->as_string;
}

my $model = RDF::Trine::Model->new($store);

$model->add_statement(statement(
	iri('http://id.example.net/topics/topic_id-4'),
	iri('http://id.example.net/topics#label'),
	literal('Apes'),
));

$model->remove_statements(
	iri('http://id.example.net/topics/topic_id-4'),
	undef,
	undef,
);

#$model->as_stream->each(\&sayit);
