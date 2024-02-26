#include "cowl.h"

/*
 * DO NOT EDIT
 *
 * Generated via maint/tt/Class.c.tt
 */


CowlManager * COWL_WRAP_cowl_istream_get_manager (
	CowlIStream * stream
) {
	return cowl_istream_get_manager(
		stream
	);
}


CowlSymTable * COWL_WRAP_cowl_istream_get_sym_table (
	CowlIStream * stream
) {
	return cowl_istream_get_sym_table(
		stream
	);
}


cowl_ret COWL_WRAP_cowl_istream_handle_iri (
	CowlIStream * stream,
	CowlIRI * iri
) {
	return cowl_istream_handle_iri(
		stream,
		iri
	);
}


cowl_ret COWL_WRAP_cowl_istream_handle_version (
	CowlIStream * stream,
	CowlIRI * version
) {
	return cowl_istream_handle_version(
		stream,
		version
	);
}


cowl_ret COWL_WRAP_cowl_istream_handle_import (
	CowlIStream * stream,
	CowlIRI * import
) {
	return cowl_istream_handle_import(
		stream,
		import
	);
}


cowl_ret COWL_WRAP_cowl_istream_handle_annot (
	CowlIStream * stream,
	CowlAnnotation * annot
) {
	return cowl_istream_handle_annot(
		stream,
		annot
	);
}


cowl_ret COWL_WRAP_cowl_istream_handle_axiom (
	CowlIStream * stream,
	CowlAnyAxiom * axiom
) {
	return cowl_istream_handle_axiom(
		stream,
		axiom
	);
}


cowl_ret COWL_WRAP_cowl_istream_process_path (
	CowlIStream * stream,
	UString path
) {
	return cowl_istream_process_path(
		stream,
		path
	);
}


cowl_ret COWL_WRAP_cowl_istream_process_file (
	CowlIStream * stream,
	FILE * file
) {
	return cowl_istream_process_file(
		stream,
		file
	);
}


cowl_ret COWL_WRAP_cowl_istream_process_string (
	CowlIStream * stream,
	UString const * string
) {
	return cowl_istream_process_string(
		stream,
		string
	);
}


cowl_ret COWL_WRAP_cowl_istream_process_stream (
	CowlIStream * stream,
	UIStream * istream
) {
	return cowl_istream_process_stream(
		stream,
		istream
	);
}


cowl_ret COWL_WRAP_cowl_istream_process_ontology (
	CowlIStream * stream,
	CowlOntology * ontology
) {
	return cowl_istream_process_ontology(
		stream,
		ontology
	);
}

