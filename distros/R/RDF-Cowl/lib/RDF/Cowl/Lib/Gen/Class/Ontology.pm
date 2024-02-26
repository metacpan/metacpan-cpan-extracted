package RDF::Cowl::Lib::Gen::Class::Ontology;
# ABSTRACT: Private class for RDF::Cowl::Ontology
$RDF::Cowl::Lib::Gen::Class::Ontology::VERSION = '1.0.0';
## DO NOT EDIT
## Generated via maint/tt/Class.pm.tt

package # hide from PAUSE
  RDF::Cowl::Ontology;

use strict;
use warnings;
use feature qw(state);
use Devel::StrictMode qw( STRICT );
use RDF::Cowl::Lib qw(arg);
use RDF::Cowl::Lib::Types qw(:all);
use Types::Common qw(Maybe BoolLike PositiveOrZeroInt Str StrMatch InstanceOf);
use Type::Params -sigs;

my $ffi = RDF::Cowl::Lib->ffi;


# cowl_ontology_get_manager
$ffi->attach( [
 "COWL_WRAP_cowl_ontology_get_manager"
 => "get_manager" ] =>
	[
		arg "CowlOntology" => "onto",
	],
	=> "CowlManager"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlOntology, { name => "onto", },
			],
		);

		$RETVAL = $xs->( &$signature );

		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 0;
		$RETVAL = $RETVAL->retain;
		return $RETVAL;
	}
);


# cowl_ontology_get_sym_table
$ffi->attach( [
 "COWL_WRAP_cowl_ontology_get_sym_table"
 => "get_sym_table" ] =>
	[
		arg "CowlOntology" => "onto",
	],
	=> "CowlSymTable"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlOntology, { name => "onto", },
			],
		);

		$RETVAL = $xs->( &$signature );

		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 0;
		$RETVAL = $RETVAL->retain;
		return $RETVAL;
	}
);


# cowl_ontology_get_id
$ffi->attach( [
 "COWL_WRAP_cowl_ontology_get_id"
 => "get_id" ] =>
	[
		arg "CowlOntology" => "onto",
	],
	=> "CowlOntologyId"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlOntology, { name => "onto", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_ontology_set_iri
$ffi->attach( [
 "COWL_WRAP_cowl_ontology_set_iri"
 => "set_iri" ] =>
	[
		arg "CowlOntology" => "onto",
		arg "CowlIRI" => "iri",
	],
	=> "void"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlOntology, { name => "onto", },
				CowlIRI, { name => "iri", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_ontology_set_version
$ffi->attach( [
 "COWL_WRAP_cowl_ontology_set_version"
 => "set_version" ] =>
	[
		arg "CowlOntology" => "onto",
		arg "CowlIRI" => "version",
	],
	=> "void"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlOntology, { name => "onto", },
				CowlIRI, { name => "version", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_ontology_get_annot
$ffi->attach( [
 "COWL_WRAP_cowl_ontology_get_annot"
 => "get_annot" ] =>
	[
		arg "CowlOntology" => "onto",
	],
	=> "CowlVector"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlOntology, { name => "onto", },
			],
		);

		$RETVAL = $xs->( &$signature );

		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 0;
		$RETVAL = $RETVAL->retain;
		return $RETVAL;
	}
);


# cowl_ontology_add_annot
$ffi->attach( [
 "COWL_WRAP_cowl_ontology_add_annot"
 => "add_annot" ] =>
	[
		arg "CowlOntology" => "onto",
		arg "CowlAnnotation" => "annot",
	],
	=> "cowl_ret"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlOntology, { name => "onto", },
				CowlAnnotation, { name => "annot", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_ontology_remove_annot
$ffi->attach( [
 "COWL_WRAP_cowl_ontology_remove_annot"
 => "remove_annot" ] =>
	[
		arg "CowlOntology" => "onto",
		arg "CowlAnnotation" => "annot",
	],
	=> "void"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlOntology, { name => "onto", },
				CowlAnnotation, { name => "annot", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_ontology_get_import
$ffi->attach( [
 "COWL_WRAP_cowl_ontology_get_import"
 => "get_import" ] =>
	[
		arg "CowlOntology" => "onto",
		arg "CowlIRI" => "iri",
	],
	=> "CowlOntology"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlOntology, { name => "onto", },
				CowlIRI, { name => "iri", },
			],
		);

		$RETVAL = $xs->( &$signature );

		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 0;
		$RETVAL = $RETVAL->retain;
		return $RETVAL;
	}
);


# cowl_ontology_get_import_iri
$ffi->attach( [
 "COWL_WRAP_cowl_ontology_get_import_iri"
 => "get_import_iri" ] =>
	[
		arg "CowlOntology" => "onto",
		arg "CowlOntology" => "import",
	],
	=> "CowlIRI"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlOntology, { name => "onto", },
				CowlOntology, { name => "import", },
			],
		);

		$RETVAL = $xs->( &$signature );

		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 0;
		$RETVAL = $RETVAL->retain;
		return $RETVAL;
	}
);


# cowl_ontology_add_import
$ffi->attach( [
 "COWL_WRAP_cowl_ontology_add_import"
 => "add_import" ] =>
	[
		arg "CowlOntology" => "onto",
		arg "CowlIRI" => "import",
	],
	=> "cowl_ret"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlOntology, { name => "onto", },
				CowlIRI, { name => "import", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_ontology_remove_import
$ffi->attach( [
 "COWL_WRAP_cowl_ontology_remove_import"
 => "remove_import" ] =>
	[
		arg "CowlOntology" => "onto",
		arg "CowlIRI" => "import",
	],
	=> "void"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlOntology, { name => "onto", },
				CowlIRI, { name => "import", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_ontology_add_axiom
$ffi->attach( [
 "COWL_WRAP_cowl_ontology_add_axiom"
 => "add_axiom" ] =>
	[
		arg "CowlOntology" => "onto",
		arg "CowlAnyAxiom" => "axiom",
	],
	=> "cowl_ret"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlOntology, { name => "onto", },
				CowlAnyAxiom, { name => "axiom", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_ontology_remove_axiom
$ffi->attach( [
 "COWL_WRAP_cowl_ontology_remove_axiom"
 => "remove_axiom" ] =>
	[
		arg "CowlOntology" => "onto",
		arg "CowlAnyAxiom" => "axiom",
	],
	=> "void"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlOntology, { name => "onto", },
				CowlAnyAxiom, { name => "axiom", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_ontology_axiom_count
$ffi->attach( [
 "COWL_WRAP_cowl_ontology_axiom_count"
 => "axiom_count" ] =>
	[
		arg "CowlOntology" => "onto",
		arg "bool" => "imports",
	],
	=> "ulib_uint"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlOntology, { name => "onto", },
				BoolLike|InstanceOf["boolean"], { name => "imports", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_ontology_imports_count
$ffi->attach( [
 "COWL_WRAP_cowl_ontology_imports_count"
 => "imports_count" ] =>
	[
		arg "CowlOntology" => "onto",
		arg "bool" => "imports",
	],
	=> "ulib_uint"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlOntology, { name => "onto", },
				BoolLike|InstanceOf["boolean"], { name => "imports", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_ontology_axiom_count_for_type
$ffi->attach( [
 "COWL_WRAP_cowl_ontology_axiom_count_for_type"
 => "axiom_count_for_type" ] =>
	[
		arg "CowlOntology" => "onto",
		arg "CowlAxiomType" => "type",
		arg "bool" => "imports",
	],
	=> "ulib_uint"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlOntology, { name => "onto", },
				CowlAxiomType, { name => "type", },
				BoolLike|InstanceOf["boolean"], { name => "imports", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_ontology_axiom_count_for_primitive
$ffi->attach( [
 "COWL_WRAP_cowl_ontology_axiom_count_for_primitive"
 => "axiom_count_for_primitive" ] =>
	[
		arg "CowlOntology" => "onto",
		arg "CowlAnyPrimitive" => "primitive",
		arg "bool" => "imports",
	],
	=> "ulib_uint"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlOntology, { name => "onto", },
				CowlAnyPrimitive, { name => "primitive", },
				BoolLike|InstanceOf["boolean"], { name => "imports", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_ontology_primitives_count
$ffi->attach( [
 "COWL_WRAP_cowl_ontology_primitives_count"
 => "primitives_count" ] =>
	[
		arg "CowlOntology" => "onto",
		arg "CowlPrimitiveFlags" => "flags",
		arg "bool" => "imports",
	],
	=> "ulib_uint"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlOntology, { name => "onto", },
				CowlPrimitiveFlags, { name => "flags", },
				BoolLike|InstanceOf["boolean"], { name => "imports", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_ontology_has_primitive
$ffi->attach( [
 "COWL_WRAP_cowl_ontology_has_primitive"
 => "has_primitive" ] =>
	[
		arg "CowlOntology" => "onto",
		arg "CowlAnyPrimitive" => "primitive",
		arg "bool" => "imports",
	],
	=> "bool"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlOntology, { name => "onto", },
				CowlAnyPrimitive, { name => "primitive", },
				BoolLike|InstanceOf["boolean"], { name => "imports", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_ontology_has_axiom
$ffi->attach( [
 "COWL_WRAP_cowl_ontology_has_axiom"
 => "has_axiom" ] =>
	[
		arg "CowlOntology" => "onto",
		arg "CowlAnyAxiom" => "axiom",
		arg "bool" => "imports",
	],
	=> "bool"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlOntology, { name => "onto", },
				CowlAnyAxiom, { name => "axiom", },
				BoolLike|InstanceOf["boolean"], { name => "imports", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_ontology_iterate_primitives
$ffi->attach( [
 "COWL_WRAP_cowl_ontology_iterate_primitives"
 => "iterate_primitives" ] =>
	[
		arg "CowlOntology" => "onto",
		arg "CowlPrimitiveFlags" => "flags",
		arg "CowlIterator" => "iter",
		arg "bool" => "imports",
	],
	=> "bool"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlOntology, { name => "onto", },
				CowlPrimitiveFlags, { name => "flags", },
				CowlIterator, { name => "iter", },
				BoolLike|InstanceOf["boolean"], { name => "imports", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_ontology_iterate_imports
$ffi->attach( [
 "COWL_WRAP_cowl_ontology_iterate_imports"
 => "iterate_imports" ] =>
	[
		arg "CowlOntology" => "onto",
		arg "CowlIterator" => "iter",
		arg "bool" => "imports",
	],
	=> "bool"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlOntology, { name => "onto", },
				CowlIterator, { name => "iter", },
				BoolLike|InstanceOf["boolean"], { name => "imports", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_ontology_iterate_import_iris
$ffi->attach( [
 "COWL_WRAP_cowl_ontology_iterate_import_iris"
 => "iterate_import_iris" ] =>
	[
		arg "CowlOntology" => "onto",
		arg "CowlIterator" => "iter",
		arg "bool" => "imports",
	],
	=> "bool"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlOntology, { name => "onto", },
				CowlIterator, { name => "iter", },
				BoolLike|InstanceOf["boolean"], { name => "imports", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_ontology_iterate_axioms
$ffi->attach( [
 "COWL_WRAP_cowl_ontology_iterate_axioms"
 => "iterate_axioms" ] =>
	[
		arg "CowlOntology" => "onto",
		arg "CowlIterator" => "iter",
		arg "bool" => "imports",
	],
	=> "bool"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlOntology, { name => "onto", },
				CowlIterator, { name => "iter", },
				BoolLike|InstanceOf["boolean"], { name => "imports", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_ontology_iterate_axioms_of_type
$ffi->attach( [
 "COWL_WRAP_cowl_ontology_iterate_axioms_of_type"
 => "iterate_axioms_of_type" ] =>
	[
		arg "CowlOntology" => "onto",
		arg "CowlAxiomType" => "type",
		arg "CowlIterator" => "iter",
		arg "bool" => "imports",
	],
	=> "bool"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlOntology, { name => "onto", },
				CowlAxiomType, { name => "type", },
				CowlIterator, { name => "iter", },
				BoolLike|InstanceOf["boolean"], { name => "imports", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_ontology_iterate_axioms_for_primitive
$ffi->attach( [
 "COWL_WRAP_cowl_ontology_iterate_axioms_for_primitive"
 => "iterate_axioms_for_primitive" ] =>
	[
		arg "CowlOntology" => "onto",
		arg "CowlAnyPrimitive" => "primitive",
		arg "CowlIterator" => "iter",
		arg "bool" => "imports",
	],
	=> "bool"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlOntology, { name => "onto", },
				CowlAnyPrimitive, { name => "primitive", },
				CowlIterator, { name => "iter", },
				BoolLike|InstanceOf["boolean"], { name => "imports", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_ontology_iterate_sub_classes
$ffi->attach( [
 "COWL_WRAP_cowl_ontology_iterate_sub_classes"
 => "iterate_sub_classes" ] =>
	[
		arg "CowlOntology" => "onto",
		arg "CowlClass" => "owl_class",
		arg "CowlIterator" => "iter",
		arg "bool" => "imports",
	],
	=> "bool"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlOntology, { name => "onto", },
				CowlClass, { name => "owl_class", },
				CowlIterator, { name => "iter", },
				BoolLike|InstanceOf["boolean"], { name => "imports", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_ontology_iterate_super_classes
$ffi->attach( [
 "COWL_WRAP_cowl_ontology_iterate_super_classes"
 => "iterate_super_classes" ] =>
	[
		arg "CowlOntology" => "onto",
		arg "CowlClass" => "owl_class",
		arg "CowlIterator" => "iter",
		arg "bool" => "imports",
	],
	=> "bool"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlOntology, { name => "onto", },
				CowlClass, { name => "owl_class", },
				CowlIterator, { name => "iter", },
				BoolLike|InstanceOf["boolean"], { name => "imports", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_ontology_iterate_eq_classes
$ffi->attach( [
 "COWL_WRAP_cowl_ontology_iterate_eq_classes"
 => "iterate_eq_classes" ] =>
	[
		arg "CowlOntology" => "onto",
		arg "CowlClass" => "owl_class",
		arg "CowlIterator" => "iter",
		arg "bool" => "imports",
	],
	=> "bool"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlOntology, { name => "onto", },
				CowlClass, { name => "owl_class", },
				CowlIterator, { name => "iter", },
				BoolLike|InstanceOf["boolean"], { name => "imports", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_ontology_iterate_types
$ffi->attach( [
 "COWL_WRAP_cowl_ontology_iterate_types"
 => "iterate_types" ] =>
	[
		arg "CowlOntology" => "onto",
		arg "CowlAnyIndividual" => "ind",
		arg "CowlIterator" => "iter",
		arg "bool" => "imports",
	],
	=> "bool"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlOntology, { name => "onto", },
				CowlAnyIndividual, { name => "ind", },
				CowlIterator, { name => "iter", },
				BoolLike|InstanceOf["boolean"], { name => "imports", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

RDF::Cowl::Lib::Gen::Class::Ontology - Private class for RDF::Cowl::Ontology

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
