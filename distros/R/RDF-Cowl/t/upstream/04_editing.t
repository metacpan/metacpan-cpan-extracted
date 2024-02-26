#!/usr/bin/env perl

use Test2::V0;

use lib 't/lib';

use RDF::Cowl;
use Path::Tiny qw(path);
use Feature::Compat::Try;
use Text::Diff;
use feature qw(state);

use constant IN_PATH => 'corpus/example_pizza.owl';
use constant NS => "http://www.co-ode.org/ontologies/pizza/pizza.owl#";

sub new_cowl_class {
	my ($name) = @_;
	return RDF::Cowl::Class->from_string(NS . $name);
}

# See <sisinflab-swot/cowl/examples/04_editing.c>
subtest "Ontology editing and serialization to file" => sub {
	my @parts;
	note "Reading ontology @{[ IN_PATH ]}...";
	my $manager = RDF::Cowl::Manager->new;
	my $onto = do { try { $manager->read_path(IN_PATH); }
		catch ($e) { die "Failed to load ontology @{[ IN_PATH ]}"; }
	};

	note "done!";

	# Declaration(Class(pizza:PorciniTopping))
	push @parts, [
		<<~EOF, 'declare PorciniTopping',
		Declaration(Class(pizza:PorciniTopping))
		EOF
	];
	my $porcini_topping = new_cowl_class("PorciniTopping");
	my $axiom = RDF::Cowl::DeclAxiom->new($porcini_topping,);
	$onto->add_axiom($axiom);

	# Declaration(Class(pizza:Porcini))
	push @parts, [
		<<~EOF, 'declare Porcini pizza',
		Declaration(Class(pizza:Porcini))
		EOF
	];
	my $porcini = new_cowl_class("Porcini");
	$axiom = RDF::Cowl::DeclAxiom->new($porcini,);
	$onto->add_axiom($axiom);

	# SubClassOf(pizza:PorciniTopping pizza:MushroomTopping)
	push @parts, [
		<<~EOF, 'PorciniTopping is subclass of MushroomTopping',
		SubClassOf(pizza:PorciniTopping pizza:MushroomTopping)
		EOF
	];
	my $mushroom_topping = new_cowl_class("MushroomTopping");
	$axiom = RDF::Cowl::SubClsAxiom->new($porcini_topping, $mushroom_topping, );
	$onto->add_axiom($axiom);

	# SubClassOf(pizza:Porcini pizza:NamedPizza)
	push @parts, [
		<<~EOF, 'Porcini pizza is a subclass of NamedPizza',
		SubClassOf(pizza:Porcini pizza:NamedPizza)
		EOF
	];
	my $named_pizza = new_cowl_class("NamedPizza");
	$axiom = RDF::Cowl::SubClsAxiom->new($porcini, $named_pizza, );
	$onto->add_axiom($axiom);

	# SubClassOf(pizza:Porcini
	# ObjectSomeValuesFrom(pizza:hasTopping pizza:MozzarellaTopping))
	push @parts, [
		<<~EOF, 'Porcini pizza has MozzarellaTopping'
		SubClassOf(pizza:Porcini
		ObjectSomeValuesFrom(pizza:hasTopping pizza:MozzarellaTopping))
		EOF
	];
	my $has_topping = RDF::Cowl::ObjProp->from_string(NS . "hasTopping");
	my $mozzarella_topping = new_cowl_class("MozzarellaTopping");
	my $obj_quant = RDF::Cowl::ObjQuant->new(RDF::Cowl::QuantType::SOME, $has_topping,
                                             $mozzarella_topping);
	$axiom = RDF::Cowl::SubClsAxiom->new($porcini, $obj_quant, );
	$onto->add_axiom($axiom);

	# SubClassOf(pizza:Porcini
	# ObjectSomeValuesFrom(pizza:hasTopping pizza:PorciniTopping))
	push @parts, [
		<<~EOF, 'Porcini pizza has PorciniTopping'
		SubClassOf(pizza:Porcini
		ObjectSomeValuesFrom(pizza:hasTopping pizza:PorciniTopping))
		EOF
	];
	$obj_quant = RDF::Cowl::ObjQuant->new( RDF::Cowl::QuantType::SOME, $has_topping, $porcini_topping);
	$axiom = RDF::Cowl::SubClsAxiom->new($porcini, $obj_quant, );
	$onto->add_axiom($axiom);

	# SubClassOf(pizza:Porcini ObjectAllValuesFrom(pizza:hasTopping
	# ObjectUnionOf(pizza:MozzarellaTopping pizza:PorciniTopping)))
	push @parts, [
		<<~EOF, 'Porcini pizza has (MozzarellaTopping union PorciniTopping)'
		SubClassOf(pizza:Porcini ObjectAllValuesFrom(pizza:hasTopping
		ObjectUnionOf(pizza:MozzarellaTopping pizza:PorciniTopping)))
		EOF
	];
	my $operands = [ $mozzarella_topping, $porcini_topping ];
	my $closure = RDF::Cowl::NAryBool->new( RDF::Cowl::NAryType::UNION, $operands );
	$obj_quant = RDF::Cowl::ObjQuant->new( RDF::Cowl::QuantType::ALL, $has_topping, $closure);
	$axiom = RDF::Cowl::SubClsAxiom->new($porcini, $obj_quant, );
	$onto->add_axiom($axiom);

	# Serialize the edited ontology to a new file.
	my $tmp = Path::Tiny->tempdir;
	my ($OUT_PATH_ORIG, $OUT_PATH_NEW) = map {
		state $tmp_path = path($tmp);
		$tmp_path->child($_);
	} qw( example_pizza_old.owl example_pizza_new.owl );

	my $ret;
	note("Writing ontology @{[ $OUT_PATH_NEW->basename ]}... ");
	$ret = $manager->write_path($onto, "$OUT_PATH_NEW");
	die "Failed to write" if $ret;

	my $onto_orig = do { try { $manager->read_path(IN_PATH); }
		catch ($e) { die "Failed to load ontology @{[ IN_PATH ]}"; }
	};
	note("Writing ontology @{[ $OUT_PATH_ORIG->basename ]}... ");
	$ret = $manager->write_path($onto_orig, "$OUT_PATH_ORIG");
	die "Failed to write" if $ret;

	note "done!";

	#system( qw(diff), $OUT_PATH_ORIG, $OUT_PATH_NEW );
	my $diff = diff "$OUT_PATH_ORIG", "$OUT_PATH_NEW", { STYLE => "Context", CONTEXT => 0 };
	my @diff_lines = grep { /^[+-] / } split /\n/, $diff;

	is \@diff_lines, bag {
		for my $part (@parts) {
			item "+ " . $part->[0]
				=~ s/\n(?!\z)/ /sgr
				=~ s/\n\z//sgr;
		}
		end;
	}, 'difference between old and new ontologies matches';
};

done_testing;
