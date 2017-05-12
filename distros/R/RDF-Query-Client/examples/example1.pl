#!/usr/bin/perl

use strict;
use warnings;
use lib 'lib/';
use feature ":5.10";
use RDF::Query::Client;
use Data::Dumper;

my $sparql_ask
	= "PREFIX dc: <http://purl.org/dc/elements/1.1/>\n"
	. "ASK WHERE { ?book dc:title ?title . }" ;

my $sparql_select
	= "PREFIX dc: <http://purl.org/dc/elements/1.1/>\n"
	. "SELECT * WHERE { ?book dc:title ?title . } ORDER BY ?book" ;

my $sparql_construct
	= "PREFIX dc: <http://purl.org/dc/elements/1.1/>\n"
	. "CONSTRUCT { ?book <http://purl.org/dc/terms/title> ?title . }\n"
	. "WHERE { ?book dc:title ?title . }" ;
	
my $q_ask       = new RDF::Query::Client($sparql_ask);
my $q_select    = new RDF::Query::Client($sparql_select);
my $q_construct = new RDF::Query::Client($sparql_construct);

my $r_ask       = $q_ask->execute('http://sparql.org/books')
	or die $q_ask->error;
my $r_select    = $q_select->execute('http://sparql.org/books')
	or die $q_select->error;
my $r_construct = $q_construct->execute('http://sparql.org/books')
	or die $q_construct->error;

say "ASK results in a boolean"
	if $r_ask->is_boolean;
say $r_ask->get_boolean ? 'true' : 'false';
say "====";

say "SELECT results in bindings"
	if $r_select->is_bindings;
while (my $row = $r_select->next)
{
	foreach my $k (keys %$row)
	{
		my $v = $row->{$k};
		say sprintf("%s=%s", $k, $v->as_string);
	}
	say "--";
}
say "====";

say "CONSTRUCT results in a graph"
	if $r_construct->is_graph;
while (my $row = $r_construct->next)
{
	say $row->as_string;
}
say "====";

say "Testing get()";
my @list = $q_select->get('http://sparql.org/books');
print Dumper(\@list);
say "====";
