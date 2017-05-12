#!/usr/bin/perl

use 5.010;
use RDF::Prefixes;

my $c = RDF::Prefixes->new({DC=>'http://example.com/'}, {syntax=>'sparql'});

say $c->get_qname('http://xmlns.com/foaf/0.1/homepage');
say $c->get_qname('http://xmlns.com/foaf/0.1/');
say $c->get_qname('http://example.com/example');
say $c->get_curie('http://purl.org/dc/terms/title');
say $c->get_curie('http://purl.org/dc/terms/');
say $c->get_curie('http://purl.org/dc/elements/1.0/title');
say $c->get_curie('http://purl.org/dc/elements/1.1/title');
say '----';
say $c;

