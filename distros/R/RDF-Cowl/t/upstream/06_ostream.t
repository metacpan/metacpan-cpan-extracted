#!/usr/bin/env perl

use Test2::V0;

use lib 't/lib';

use RDF::Cowl;
use Path::Tiny qw(path);
use boolean;

use constant PATH => "porcini_pizza.owl";

use constant IMPORT_IRI => "http://www.co-ode.org/ontologies/pizza";
use constant IMPORT_NS => IMPORT_IRI . "/pizza.owl#";

use constant IRI => "http://foo.com/ontologies/porcini_pizza";
use constant NS => IRI . "/porcini_pizza.owl#";

# See <sisinflab-swot/cowl/examples/06_ostream.c>
subtest "Creating a new ontology document (output stream)" => sub {
	note("Generating ontology @{[  PATH  ]}... ");

	my $tmpdir = Path::Tiny->tempdir;
	my $PATH = path($tmpdir)->child(PATH);

	my @parts;

	my $ostream = RDF::Cowl::Ulib::UOStream->new;
	$ostream->to_path( "$PATH" );

	my $manager = RDF::Cowl::Manager->new;
	my $stream  = $manager->get_ostream( $ostream );

	# Optional: setup prefixes so that IRIs can be rendered in their prefixed form.
	# RDF::Cowl::SymTable
	my $st = $stream->get_sym_table;
	push @parts, [
		<<~EOF, 'empty prefix'
		Prefix(:=<http://foo.com/ontologies/porcini_pizza/porcini_pizza.owl#>)
		EOF
	];
	$st->register_prefix_raw( "", NS, false );
	push @parts, [
		<<~EOF, 'pizza prefix',
		Prefix(pizza:=<http://www.co-ode.org/ontologies/pizza/pizza.owl#>)
		EOF
	];
	$st->register_prefix_raw( "pizza", IMPORT_NS, false );

	# Write the ontology header.
	push @parts, [
		<<~EOF, 'ontology IRI',
		Ontology(<http://foo.com/ontologies/porcini_pizza>
		EOF
	];
	my $iri        = RDF::Cowl::IRI->from_string( IRI );
	push @parts, [
		<<~EOF, 'import IRIs',
		Import(<http://www.co-ode.org/ontologies/pizza>)
		EOF
	];
	my $import_iri = RDF::Cowl::IRI->from_string( IMPORT_IRI );

	my $imports = [ $import_iri ];

	my $header = RDF::Cowl::OntologyHeader->new(
		id      => RDF::Cowl::OntologyId->new( iri => $iri ),
		imports => $imports,
	);

	$stream->write_header( $header );

	# Write the axioms.

	# Declaration(Class(:PorciniTopping))
	push @parts, [
		<<~EOF, 'declare PorciniTopping',
		Declaration(Class(:PorciniTopping))
		EOF
	];
	my $porcini = RDF::Cowl::Class->from_string(NS."PorciniTopping");
	my $axiom = RDF::Cowl::DeclAxiom->new($porcini, );
	$stream->write_axiom( $axiom );

	# Declaration(Class(:Porcini))
	push @parts, [
		<<~EOF, 'declare Porcini pizza',
		Declaration(Class(:Porcini))
		EOF
	];
	my $porcini_pizza = RDF::Cowl::Class->from_string(NS."Porcini");
	$axiom = RDF::Cowl::DeclAxiom->new($porcini_pizza,);
	$stream->write_axiom( $axiom );

	# SubClassOf(:PorciniTopping pizza:MushroomTopping)
	push @parts, [
		<<~EOF, 'PorciniTopping is subclass of MushroomTopping',
		SubClassOf(:PorciniTopping pizza:MushroomTopping)
		EOF
	];
	my $mushroom = RDF::Cowl::Class->from_string( IMPORT_NS."MushroomTopping" );
	$axiom = RDF::Cowl::SubClsAxiom->new($porcini, $mushroom,);
	$stream->write_axiom( $axiom );

	# SubClassOf(:Porcini pizza:NamedPizza)
	push @parts, [
		<<~EOF, 'Porcini pizza is a subclass of NamedPizza',
		SubClassOf(:Porcini pizza:NamedPizza)
		EOF
	];
	my $named_pizza = RDF::Cowl::Class->from_string( IMPORT_NS."NamedPizza");
	$axiom = RDF::Cowl::SubClsAxiom->new( $porcini_pizza, $named_pizza, );
	$stream->write_axiom( $axiom );

	# SubClassOf(:Porcini
	# ObjectSomeValuesFrom(pizza:hasTopping pizza:MozzarellaTopping))
	push @parts, [
		<<~EOF, 'Porcini pizza has MozzarellaTopping'
		SubClassOf(:Porcini
		ObjectSomeValuesFrom(pizza:hasTopping pizza:MozzarellaTopping))
		EOF
	];
	my $has_topping = RDF::Cowl::ObjProp->from_string(IMPORT_NS."hasTopping");
	my $mozzarella = RDF::Cowl::Class->from_string( IMPORT_NS."MozzarellaTopping" );
	my $obj_quant = RDF::Cowl::ObjQuant->new(RDF::Cowl::QuantType::SOME, $has_topping,
                                             $mozzarella);
	$axiom = RDF::Cowl::SubClsAxiom->new( $porcini_pizza, $obj_quant, );
	$stream->write_axiom( $axiom );

	# SubClassOf(:Porcini
	# ObjectSomeValuesFrom(pizza:hasTopping :PorciniTopping))
	push @parts, [
		<<~EOF, 'Porcini pizza has PorciniTopping'
		SubClassOf(:Porcini
		ObjectSomeValuesFrom(pizza:hasTopping :PorciniTopping))
		EOF
	];
	$obj_quant = RDF::Cowl::ObjQuant->new(RDF::Cowl::QuantType::SOME, $has_topping, $porcini);
	$axiom = RDF::Cowl::SubClsAxiom->new($porcini_pizza, $obj_quant,);
	$stream->write_axiom( $axiom );

	# SubClassOf(:Porcini ObjectAllValuesFrom(pizza:hasTopping
	# ObjectUnionOf(pizza:MozzarellaTopping :PorciniTopping)))
	push @parts, [
		<<~EOF, 'Porcini pizza has (MozzarellaTopping union PorciniTopping)'
		SubClassOf(:Porcini ObjectAllValuesFrom(pizza:hasTopping
		ObjectUnionOf(pizza:MozzarellaTopping :PorciniTopping)))
		EOF
	];
	my $operands = [ $mozzarella, $porcini ];
	my $closure = RDF::Cowl::NAryBool->new( RDF::Cowl::NAryType::UNION, $operands );
	$obj_quant = RDF::Cowl::ObjQuant->new( RDF::Cowl::QuantType::ALL, $has_topping, $closure);
	$axiom = RDF::Cowl::SubClsAxiom->new($porcini_pizza, $obj_quant, );
	$stream->write_axiom( $axiom );

	# Finally, write the footer.
	push @parts, [
		<<~EOF, 'footer'
		)
		EOF
	];
	$stream->write_footer;

	note("done!");

	# write it out right now
	$ostream->flush;

	is [ path($PATH)->lines_utf8 ], array {
		for my $part (@parts) {
			item $part->[0] =~ s/\n(?!\z)/ /sgr;
		}
		end;
	}, "got contents in @{[ PATH ]}";
};

done_testing;
