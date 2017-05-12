#!/usr/bin/perl

use RDFStore::NodeFactory;
use RDFStore::Parser::SiRPAC;
use RDFStore::Vocabulary::RDF;

my $factory = new RDFStore::NodeFactory();

my $p=new RDFStore::Parser::SiRPAC(
		Style => 'RDFStore::Parser::Styles::RDFStore::Model',
                NodeFactory =>          $factory,
                style_options   => { store_options => { FreeText => 1 } } );

my $model = $p->parsefile("http://www.kanzaki.com/info/rss.rdf");

#Stanford API
my $iterator = $model->find( undef, $RDFStore::Vocabulary::RDF::type, $factory->createResource("http://purl.org/rss/1.0/item") )->elements;

while ( my $st = $iterator->each ) {
	print "each: ",$st->toString,"\n";
	};

# or
for ( 	my $st = $iterator->first;
	$iterator->hasnext;
	$st = $iterator->next ) {
	print "for: ",$st->toString,"\n";
	};

#free-text Stanford API - i.e. literal contains 'XML' or 'recodings'
$iterator = $model->find( undef, $factory->createResource("http://purl.org/rss/1.0/title"), undef, undef, 0, 'xMl','recodings' )->elements;
while ( my $st = $iterator->each ) {
	print "freetext: ",$st->toString,"\n";
	};

#serialise back to some strawman RDF
my $strawman_rdf = $model->toStrawmanRDF;
