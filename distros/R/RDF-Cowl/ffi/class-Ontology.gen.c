#include "cowl.h"

/*
 * DO NOT EDIT
 *
 * Generated via maint/tt/Class.c.tt
 */


CowlManager * COWL_WRAP_cowl_ontology_get_manager (
	CowlOntology * onto
) {
	return cowl_ontology_get_manager(
		onto
	);
}


CowlSymTable * COWL_WRAP_cowl_ontology_get_sym_table (
	CowlOntology * onto
) {
	return cowl_ontology_get_sym_table(
		onto
	);
}


CowlOntologyId COWL_WRAP_cowl_ontology_get_id (
	CowlOntology * onto
) {
	return cowl_ontology_get_id(
		onto
	);
}


void COWL_WRAP_cowl_ontology_set_iri (
	CowlOntology * onto,
	CowlIRI * iri
) {
	cowl_ontology_set_iri(
		onto,
		iri
	);
}


void COWL_WRAP_cowl_ontology_set_version (
	CowlOntology * onto,
	CowlIRI * version
) {
	cowl_ontology_set_version(
		onto,
		version
	);
}


CowlVector * COWL_WRAP_cowl_ontology_get_annot (
	CowlOntology * onto
) {
	return cowl_ontology_get_annot(
		onto
	);
}


cowl_ret COWL_WRAP_cowl_ontology_add_annot (
	CowlOntology * onto,
	CowlAnnotation * annot
) {
	return cowl_ontology_add_annot(
		onto,
		annot
	);
}


void COWL_WRAP_cowl_ontology_remove_annot (
	CowlOntology * onto,
	CowlAnnotation * annot
) {
	cowl_ontology_remove_annot(
		onto,
		annot
	);
}


CowlOntology * COWL_WRAP_cowl_ontology_get_import (
	CowlOntology * onto,
	CowlIRI * iri
) {
	return cowl_ontology_get_import(
		onto,
		iri
	);
}


CowlIRI * COWL_WRAP_cowl_ontology_get_import_iri (
	CowlOntology * onto,
	CowlOntology * import
) {
	return cowl_ontology_get_import_iri(
		onto,
		import
	);
}


cowl_ret COWL_WRAP_cowl_ontology_add_import (
	CowlOntology * onto,
	CowlIRI * import
) {
	return cowl_ontology_add_import(
		onto,
		import
	);
}


void COWL_WRAP_cowl_ontology_remove_import (
	CowlOntology * onto,
	CowlIRI * import
) {
	cowl_ontology_remove_import(
		onto,
		import
	);
}


cowl_ret COWL_WRAP_cowl_ontology_add_axiom (
	CowlOntology * onto,
	CowlAnyAxiom * axiom
) {
	return cowl_ontology_add_axiom(
		onto,
		axiom
	);
}


void COWL_WRAP_cowl_ontology_remove_axiom (
	CowlOntology * onto,
	CowlAnyAxiom * axiom
) {
	cowl_ontology_remove_axiom(
		onto,
		axiom
	);
}


ulib_uint COWL_WRAP_cowl_ontology_axiom_count (
	CowlOntology * onto,
	bool imports
) {
	return cowl_ontology_axiom_count(
		onto,
		imports
	);
}


ulib_uint COWL_WRAP_cowl_ontology_imports_count (
	CowlOntology * onto,
	bool imports
) {
	return cowl_ontology_imports_count(
		onto,
		imports
	);
}


ulib_uint COWL_WRAP_cowl_ontology_axiom_count_for_type (
	CowlOntology * onto,
	CowlAxiomType type,
	bool imports
) {
	return cowl_ontology_axiom_count_for_type(
		onto,
		type,
		imports
	);
}


ulib_uint COWL_WRAP_cowl_ontology_axiom_count_for_primitive (
	CowlOntology * onto,
	CowlAnyPrimitive * primitive,
	bool imports
) {
	return cowl_ontology_axiom_count_for_primitive(
		onto,
		primitive,
		imports
	);
}


ulib_uint COWL_WRAP_cowl_ontology_primitives_count (
	CowlOntology * onto,
	CowlPrimitiveFlags flags,
	bool imports
) {
	return cowl_ontology_primitives_count(
		onto,
		flags,
		imports
	);
}


bool COWL_WRAP_cowl_ontology_has_primitive (
	CowlOntology * onto,
	CowlAnyPrimitive * primitive,
	bool imports
) {
	return cowl_ontology_has_primitive(
		onto,
		primitive,
		imports
	);
}


bool COWL_WRAP_cowl_ontology_has_axiom (
	CowlOntology * onto,
	CowlAnyAxiom * axiom,
	bool imports
) {
	return cowl_ontology_has_axiom(
		onto,
		axiom,
		imports
	);
}


bool COWL_WRAP_cowl_ontology_iterate_primitives (
	CowlOntology * onto,
	CowlPrimitiveFlags flags,
	CowlIterator * iter,
	bool imports
) {
	return cowl_ontology_iterate_primitives(
		onto,
		flags,
		iter,
		imports
	);
}


bool COWL_WRAP_cowl_ontology_iterate_imports (
	CowlOntology * onto,
	CowlIterator * iter,
	bool imports
) {
	return cowl_ontology_iterate_imports(
		onto,
		iter,
		imports
	);
}


bool COWL_WRAP_cowl_ontology_iterate_import_iris (
	CowlOntology * onto,
	CowlIterator * iter,
	bool imports
) {
	return cowl_ontology_iterate_import_iris(
		onto,
		iter,
		imports
	);
}


bool COWL_WRAP_cowl_ontology_iterate_axioms (
	CowlOntology * onto,
	CowlIterator * iter,
	bool imports
) {
	return cowl_ontology_iterate_axioms(
		onto,
		iter,
		imports
	);
}


bool COWL_WRAP_cowl_ontology_iterate_axioms_of_type (
	CowlOntology * onto,
	CowlAxiomType type,
	CowlIterator * iter,
	bool imports
) {
	return cowl_ontology_iterate_axioms_of_type(
		onto,
		type,
		iter,
		imports
	);
}


bool COWL_WRAP_cowl_ontology_iterate_axioms_for_primitive (
	CowlOntology * onto,
	CowlAnyPrimitive * primitive,
	CowlIterator * iter,
	bool imports
) {
	return cowl_ontology_iterate_axioms_for_primitive(
		onto,
		primitive,
		iter,
		imports
	);
}


bool COWL_WRAP_cowl_ontology_iterate_sub_classes (
	CowlOntology * onto,
	CowlClass * owl_class,
	CowlIterator * iter,
	bool imports
) {
	return cowl_ontology_iterate_sub_classes(
		onto,
		owl_class,
		iter,
		imports
	);
}


bool COWL_WRAP_cowl_ontology_iterate_super_classes (
	CowlOntology * onto,
	CowlClass * owl_class,
	CowlIterator * iter,
	bool imports
) {
	return cowl_ontology_iterate_super_classes(
		onto,
		owl_class,
		iter,
		imports
	);
}


bool COWL_WRAP_cowl_ontology_iterate_eq_classes (
	CowlOntology * onto,
	CowlClass * owl_class,
	CowlIterator * iter,
	bool imports
) {
	return cowl_ontology_iterate_eq_classes(
		onto,
		owl_class,
		iter,
		imports
	);
}


bool COWL_WRAP_cowl_ontology_iterate_types (
	CowlOntology * onto,
	CowlAnyIndividual * ind,
	CowlIterator * iter,
	bool imports
) {
	return cowl_ontology_iterate_types(
		onto,
		ind,
		iter,
		imports
	);
}

