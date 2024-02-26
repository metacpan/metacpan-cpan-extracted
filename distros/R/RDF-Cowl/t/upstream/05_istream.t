#!/usr/bin/env perl

use Test2::V0;

use lib 't/lib';

use RDF::Cowl;

use constant ONTO => 'corpus/example_pizza.owl';
use constant NS => "http://www.co-ode.org/ontologies/pizza/pizza.owl#";
use constant CLASS_NAME => "Food";

use RDF::Cowl::Lib::cowl_ret;

my $target_class = RDF::Cowl::Class->from_string(NS . CLASS_NAME);
our @CLASSES_REM;

# Axiom handler, invoked for each axiom in the ontology document.
sub handle_axiom {
	my ($axiom) = @_; # CowlAnyAxiom

	# We are only interested in subclass axioms.
	return RDF::Cowl::Lib::cowl_ret::OK unless $axiom->isa('RDF::Cowl::SubClsAxiom');

	# We are only interested in axioms where the superclass is the target class.
	my $sub_cls_axiom = $axiom;
	my $cls = $sub_cls_axiom->get_super;
	return RDF::Cowl::Lib::cowl_ret::OK unless $target_class->equals( $cls );

	# We are only interested in axioms where the subclass is atomic.
	$cls = $sub_cls_axiom->get_sub;
	return RDF::Cowl::Lib::cowl_ret::OK if $cls->get_type != RDF::Cowl::ClsExpType::CLASS;

	push @CLASSES_REM, $cls->get_iri->get_rem;

	return RDF::Cowl::Lib::cowl_ret::OK;
}

# See <sisinflab-swot/cowl/examples/05_istream.c>
subtest "Direct atomic subclasses of a class (input stream)" => sub {
	my $manager = RDF::Cowl::Manager->new;

	# Configure the ontology input stream.
	my $handlers = RDF::Cowl::IStreamHandlers->new( axiom => \&handle_axiom );
	my $stream = $manager->get_istream( $handlers );

	# Process the ontology as a stream.
	note "Atomic subclasses of @{[ CLASS_NAME ]}:";
	my $ret = $stream->process_path( ONTO );
	die "Failed to process" unless !$ret;

	is \@CLASSES_REM, bag {
		item 'IceCream';
		item 'Pizza';
		item 'PizzaBase';
		item 'PizzaTopping';
		end();
	}, 'Got Food subclasses';
};

done_testing;
