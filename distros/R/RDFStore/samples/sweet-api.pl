#!/usr/bin/perl

use RDFStore::NodeFactory;
use RDFStore::Parser::SiRPAC;
use RDFStore::Vocabulary::RDF;  # handy prepared properties and classes from RDF, RDFS and DAML+OIL namespaces
use RDFStore::Vocabulary::RDFS; # otherwise you need to create them via the RDFStore::NodeFactory
use RDFStore::Vocabulary::DAML;

my $factory = new RDFStore::NodeFactory();

my $p=new RDFStore::Parser::SiRPAC(
		Style => 'RDFStore::Parser::Styles::RDFStore::Model',
                NodeFactory =>          $factory,
                style_options   => { store_options => { FreeText => 1 } } ); # by default free-text indexing of literals is not done i.e. faster :)

my $model = $p->parsefile("http://sweet.jpl.nasa.gov/sweet/humanactivities.daml");

#Stanford API
my $iterator = $model->find( undef, $RDFStore::Vocabulary::RDF::type, $RDFStore::Vocabulary::DAML::Class )->elements;

while ( my $st = $iterator->each ) {
	print "each: ",$st->toString,"\n";
	};

# or
for ( 	my $st = $iterator->first;
	$iterator->hasnext;
	$st = $iterator->next ) {
	print "for: ",$st->toString,"\n";
	my $subject = $st->subject;
	my $predicate = $st->predicate;
	};

#free-text Stanford API - i.e. and rdfs:label which contains the words 'Management' or 'Storage'
# NOTE: 
#       1) stemming on words is not yet available as feature
#       2) the 4th parameter to find() is for the context of the triples (not used or explained here - still sperimental and diffuclt to eplain still :)
#
$iterator = $model->find( undef, $RDFStore::Vocabulary::RDFS::label, undef, undef, 0, 'MANAgemeNT','STORaGe' )->elements; # note the case insesitive match on free-text
while ( my $st = $iterator->each ) {
	print "freetext: ",$st->toString,"\n";
	};

#or if you want to parse and store your ontology at the same time
my $p1=new RDFStore::Parser::SiRPAC(
		Style => 'RDFStore::Parser::Styles::RDFStore::Model',
                NodeFactory =>          $factory,
                style_options   => { store_options => { Name => 'daml', Sync => 1, FreeText => 1 } } ); # which stores *on disk* the BDB files in the subdir daml/

my $model1 = $p1->parsefile("http://sweet.jpl.nasa.gov/sweet/humanactivities.daml");

my $iterator1 = $model1->find( undef, $RDFStore::Vocabulary::RDF::type, $RDFStore::Vocabulary::DAML::Class )->elements;
while ( my $object = $iterator1->each_object ) {
	print "(stored) each: ",$object->toString,"\n";
	};

# or if you do have the files already parsed and stored into daml/ subdir on disk
my $model2 = new RDFStore::Model( Name => 'daml', nodeFactory => $factory , Mode => 'r' );

my $iterator2 = $model2->find( undef, $RDFStore::Vocabulary::RDF::type, $RDFStore::Vocabulary::DAML::Class )->elements;
while ( my $subject = $iterator2->each_subject ) {
	print "(previously stored) each: ",$subject->toString,"\n";
	};
