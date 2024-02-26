#!/usr/bin/env perl

use Test2::V0;

use lib 't/lib';

use RDF::Cowl;
use Feature::Compat::Try;

use boolean;
use constant ONTO => 'corpus/example_pizza.owl';
use constant NS => "http://www.co-ode.org/ontologies/pizza/pizza.owl#";
use constant CLASS_NAME => "Food";

our @CLASSES_REM;

sub for_each_cls {
	my ($cls) = @_; # (CowlAny)
	return true unless $cls->isa('RDF::Cowl::Class');

	push @CLASSES_REM, $cls->get_iri->get_rem;

	return true;
}

# See <sisinflab-swot/cowl/examples/02_query.c>
subtest "Direct atomic subclasses of a class" => sub {
	my $manager = RDF::Cowl::Manager->new;
	my $onto = do { try { $manager->read_path(ONTO) }
		catch($e) { die "Failed to load ontology @{[ ONTO ]}: $e"; }
	};

	note "Atomic subclasses of @{[ CLASS_NAME ]}:";

	my $cls = RDF::Cowl::Class->from_string(NS . CLASS_NAME);

	$onto->iterate_sub_classes( $cls, \&for_each_cls, false );

	is \@CLASSES_REM, bag {
		item 'IceCream';
		item 'Pizza';
		item 'PizzaBase';
		item 'PizzaTopping';
		end();
	}, 'Got Food subclasses';
};

done_testing;
