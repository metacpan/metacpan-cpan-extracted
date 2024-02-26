#include "cowl.h"

/*
 * DO NOT EDIT
 *
 * Generated via maint/tt/Class.c.tt
 */


CowlManager * COWL_WRAP_cowl_ostream_get_manager (
	CowlOStream * stream
) {
	return cowl_ostream_get_manager(
		stream
	);
}


CowlSymTable * COWL_WRAP_cowl_ostream_get_sym_table (
	CowlOStream * stream
) {
	return cowl_ostream_get_sym_table(
		stream
	);
}


cowl_ret COWL_WRAP_cowl_ostream_write_header (
	CowlOStream * stream,
	CowlOntologyHeader header
) {
	return cowl_ostream_write_header(
		stream,
		header
	);
}


cowl_ret COWL_WRAP_cowl_ostream_write_axiom (
	CowlOStream * stream,
	CowlAnyAxiom * axiom
) {
	return cowl_ostream_write_axiom(
		stream,
		axiom
	);
}


cowl_ret COWL_WRAP_cowl_ostream_write_footer (
	CowlOStream * stream
) {
	return cowl_ostream_write_footer(
		stream
	);
}


cowl_ret COWL_WRAP_cowl_ostream_write_ontology (
	CowlOStream * stream,
	CowlOntology * ontology
) {
	return cowl_ostream_write_ontology(
		stream,
		ontology
	);
}

