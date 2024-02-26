package RDF::Cowl;
# ABSTRACT: A lightweight API for working with OWL 2 ontologies
$RDF::Cowl::VERSION = '1.0.0';
use strict;
use warnings;

use RDF::Cowl::Lib qw(arg);
use RDF::Cowl::Lib::Types;

use RDF::Cowl::Lib::cowl_ret;
#use RDF::Cowl::ErrorLoc; # TODO
use RDF::Cowl::Error;
#use RDF::Cowl::SyntaxError; # TODO

# Flags
use RDF::Cowl::PrimitiveFlags;
use RDF::Cowl::StringOpts;

# Structs
use RDF::Cowl::Ulib::UString;
use RDF::Cowl::OntologyId;
use RDF::Cowl::OntologyHeader;

# Internal data structures
use RDF::Cowl::Ulib::UVec_CowlObjectPtr;

# Callback structs
use RDF::Cowl::ErrorHandler;
use RDF::Cowl::ImportLoader;
use RDF::Cowl::IStreamHandlers;
use RDF::Cowl::StreamWriter;
use RDF::Cowl::Reader;
use RDF::Cowl::Writer;
use RDF::Cowl::Iterator;

# Enums
use RDF::Cowl::AnnotValueType;
use RDF::Cowl::AxiomType;
use RDF::Cowl::CardType;
use RDF::Cowl::CharAxiomType;
use RDF::Cowl::ClsExpType;
use RDF::Cowl::DataRangeType;
use RDF::Cowl::EntityType;
use RDF::Cowl::NAryAxiomType;
use RDF::Cowl::NAryType;
use RDF::Cowl::ObjectType;
use RDF::Cowl::PrimitiveType;
use RDF::Cowl::QuantType;

# I/O
use RDF::Cowl::Ulib::UOStream;
use RDF::Cowl::IStream;
use RDF::Cowl::OStream;

# Vocabularies
use RDF::Cowl::XSDVocab;
use RDF::Cowl::RDFVocab;
use RDF::Cowl::RDFSVocab;
use RDF::Cowl::OWLVocab;

# Class system
use RDF::Cowl::Object;

# Classes
use RDF::Cowl::AnnotAssertAxiom;
use RDF::Cowl::Annotation;
use RDF::Cowl::AnnotProp;
use RDF::Cowl::AnnotPropDomainAxiom;
use RDF::Cowl::AnnotPropRangeAxiom;
use RDF::Cowl::AnnotValue;
use RDF::Cowl::AnonInd;
use RDF::Cowl::Axiom;
use RDF::Cowl::Class;
use RDF::Cowl::ClsAssertAxiom;
use RDF::Cowl::ClsExp;
use RDF::Cowl::DataCard;
use RDF::Cowl::DataCompl;
use RDF::Cowl::DataHasValue;
use RDF::Cowl::DataOneOf;
use RDF::Cowl::DataProp;
use RDF::Cowl::DataPropAssertAxiom;
use RDF::Cowl::DataPropDomainAxiom;
use RDF::Cowl::DataPropExp;
use RDF::Cowl::DataPropRangeAxiom;
use RDF::Cowl::DataQuant;
use RDF::Cowl::DataRange;
use RDF::Cowl::Datatype;
use RDF::Cowl::DatatypeDefAxiom;
use RDF::Cowl::DatatypeRestr;
use RDF::Cowl::DeclAxiom;
use RDF::Cowl::DisjUnionAxiom;
use RDF::Cowl::Entity;
use RDF::Cowl::FacetRestr;
use RDF::Cowl::FuncDataPropAxiom;
use RDF::Cowl::HasKeyAxiom;
use RDF::Cowl::Individual;
use RDF::Cowl::InvObjProp;
use RDF::Cowl::InvObjPropAxiom;
use RDF::Cowl::IRI;
use RDF::Cowl::Literal;
use RDF::Cowl::Manager;
use RDF::Cowl::NamedInd;
use RDF::Cowl::NAryBool;
use RDF::Cowl::NAryClsAxiom;
use RDF::Cowl::NAryData;
use RDF::Cowl::NAryDataPropAxiom;
use RDF::Cowl::NAryIndAxiom;
use RDF::Cowl::NAryObjPropAxiom;
use RDF::Cowl::ObjCard;
use RDF::Cowl::ObjCompl;
use RDF::Cowl::ObjHasSelf;
use RDF::Cowl::ObjHasValue;
use RDF::Cowl::ObjOneOf;
use RDF::Cowl::ObjProp;
use RDF::Cowl::ObjPropAssertAxiom;
use RDF::Cowl::ObjPropCharAxiom;
use RDF::Cowl::ObjPropDomainAxiom;
use RDF::Cowl::ObjPropExp;
use RDF::Cowl::ObjPropRangeAxiom;
use RDF::Cowl::ObjQuant;
use RDF::Cowl::Ontology;
use RDF::Cowl::Primitive;
use RDF::Cowl::String;
use RDF::Cowl::SubAnnotPropAxiom;
use RDF::Cowl::SubClsAxiom;
use RDF::Cowl::SubDataPropAxiom;
use RDF::Cowl::SubObjPropAxiom;
use RDF::Cowl::SymTable;
use RDF::Cowl::Table;
use RDF::Cowl::Vector;

my $ffi = RDF::Cowl::Lib->ffi;

our ($_ERROR_HANDLER, $_IMPORT_LOADER);

$ffi->attach( [ "cowl_init" => "init" ] =>
	[
	],
	=> "cowl_ret"
);

$ffi->attach( [ "cowl_set_error_handler" => "set_error_handler" ] =>
	[
		arg "CowlErrorHandler" => "handler",
	],
	=> "void",
	=> sub {
		my ($xs, $class, $handler) = @_;
		$_ERROR_HANDLER = $handler;
		$xs->($handler);
	},
);

$ffi->attach( [ "cowl_set_import_loader" => "set_import_loader" ] =>
	[
		arg "CowlImportLoader" => "loader",
	],
	=> "void",
	=> sub {
		my ($xs, $class, $loader) = @_;
		$_IMPORT_LOADER = $loader;
		$xs->($loader);
	},
);

###

sub import {
	__PACKAGE__->init;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

RDF::Cowl - A lightweight API for working with OWL 2 ontologies

=head1 VERSION

version 1.0.0

=head1 SYNOPSIS

  use RDF::Cowl;
  
  use boolean;
  use constant ONTO => 'corpus/example_pizza.owl';
  use constant NS => "http://www.co-ode.org/ontologies/pizza/pizza.owl#";
  use constant CLASS_NAME => "Food";
  
  my $manager = RDF::Cowl::Manager->new;
  my $onto = do { try { $manager->read_path(ONTO) }
    catch($e) { die "Failed to load ontology @{[ ONTO ]}: $e"; }
  };
  
  my $cls = RDF::Cowl::Class->from_string(NS . CLASS_NAME);
  
  my @subclasses;
  $onto->iterate_sub_classes( $cls, sub ($subclass) {
    push @subclasses, $subclass->get_iri->get_rem
      if $subclass->isa('RDF::Cowl::Class');
  
    return true;
  }, false );

  is \@subclasses, bag {
    item 'IceCream';
    item 'Pizza';
    item 'PizzaBase';
    item 'PizzaTopping';
    end();
  }, 'Got Food direct subclasses';

=head1 DESCRIPTION

Cowl provides an API for parsing, querying, editing, and writing OWL 2
ontologies. It currently supports processing OWL2 Functional Syntax.

=head1 EXAMPLES

For now, the best place to look for example code is the tests under the
C<t/upstream> directory.

=head1 SEE ALSO

=over 4

=item * L<Cowl documentation|https://swot.sisinflab.poliba.it/cowl>

=item * L<Alien::Cowl>

=back

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
