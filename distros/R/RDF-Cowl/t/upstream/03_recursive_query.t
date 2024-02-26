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
	my ($onto, $cls) = @_; # (CowlOntology, CowlAny)

	push @CLASSES_REM, $cls->get_iri->get_rem->to_string;

	# anonymous coderef to capture $onto in scope
	my $iter = sub {
		my ($cls) = @_;
		return for_each_cls($onto, $cls);
	};

	$onto->iterate_sub_classes( $cls, $iter, false );

	return true;
}

# See <sisinflab-swot/cowl/examples/03_recursive_query.c>
subtest "Atomic subclasses of a class recursively" => sub {
	my $manager = RDF::Cowl::Manager->new;
	my $onto = do { try { $manager->read_path(ONTO); }
		catch ($e) { die "Failed to load ontology @{[ ONTO ]}"; }
	};

	note "Atomic subclasses of @{[ CLASS_NAME ]}:";

	my $cls = RDF::Cowl::Class->from_string(NS . CLASS_NAME);

	# anonymous coderef to capture $onto in scope
	my $iter = sub {
		my ($cls) = @_;
		return for_each_cls($onto, $cls);
	};

	$onto->iterate_sub_classes( $cls, $iter, false );

	is \@CLASSES_REM, bag {
		prop size => 79;

		item 'Pizza';

		item 'PizzaBase';
		item 'ThinAndCrispyBase';

		item 'PizzaTopping';
		item 'RedOnionTopping';

		etc();
	}, 'Got Food subclasses recursively';
};

done_testing;
