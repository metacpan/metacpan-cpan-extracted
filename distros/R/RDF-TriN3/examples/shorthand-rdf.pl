#!/usr/bin/perl

use 5.010;
use RDF::TriN3;

my $n3 = <<'NOTATION3';
@keywords is, of, a.
@dtpattern "\d{1,2}[a-z]{3}\d{4}" <http://example.com/day> .
@base <http://example.com/day/> .
@pattern    "(\d{1,2})(?<month>[A-Z][a-z]{2})(\d{4})" <$3/$2/$1> .
@base <http://example.org/> .
@term lit <#as_literal> .
#@import <http://buzzword.org.uk/2011/test.n3> .

#1Apr2003 lit 1apr2003 ; <foo> <bar> .
#<> dc:creator tobyink .
#tobyink foaf:name "Toby Inkster" .

<foo> = { :a :b :c . } .
[] a :Blah .
@pragma trig true .
<bar> = { :a :b :c . } .
@pragma trig false .
<baz> = { :a :b :c . } .

@pragma rdf true .
@pragma rdf 1 .
"Toby" :is_my :name .

@pragma blank-nodes false .
[] :is_my :name .

NOTATION3

my $parser = RDF::Trine::Parser::ShorthandRDF->new(profile => <<'STUFF');
@prefix dc: <http://purl.org/dc/terms/> .
STUFF

$parser->parse('http://example.org/', $n3, sub {say $_[0]->sse});
