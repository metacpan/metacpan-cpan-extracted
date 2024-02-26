#include "cowl.h"

/*
 * DO NOT EDIT
 *
 * Generated via maint/tt/Class.c.tt
 */


CowlManager * COWL_WRAP_cowl_manager (
) {
	return cowl_manager(
	);
}


void COWL_WRAP_cowl_manager_set_reader (
	CowlManager * manager,
	CowlReader reader
) {
	cowl_manager_set_reader(
		manager,
		reader
	);
}


void COWL_WRAP_cowl_manager_set_writer (
	CowlManager * manager,
	CowlWriter writer
) {
	cowl_manager_set_writer(
		manager,
		writer
	);
}


void COWL_WRAP_cowl_manager_set_import_loader (
	CowlManager * manager,
	CowlImportLoader loader
) {
	cowl_manager_set_import_loader(
		manager,
		loader
	);
}


void COWL_WRAP_cowl_manager_set_error_handler (
	CowlManager * manager,
	CowlErrorHandler handler
) {
	cowl_manager_set_error_handler(
		manager,
		handler
	);
}


CowlOntology * COWL_WRAP_cowl_manager_get_ontology (
	CowlManager * manager,
	CowlOntologyId const * id
) {
	return cowl_manager_get_ontology(
		manager,
		id
	);
}


CowlOntology * COWL_WRAP_cowl_manager_read_path (
	CowlManager * manager,
	UString path
) {
	return cowl_manager_read_path(
		manager,
		path
	);
}


CowlOntology * COWL_WRAP_cowl_manager_read_file (
	CowlManager * manager,
	FILE * file
) {
	return cowl_manager_read_file(
		manager,
		file
	);
}


CowlOntology * COWL_WRAP_cowl_manager_read_string (
	CowlManager * manager,
	UString const * string
) {
	return cowl_manager_read_string(
		manager,
		string
	);
}


CowlOntology * COWL_WRAP_cowl_manager_read_stream (
	CowlManager * manager,
	UIStream * stream
) {
	return cowl_manager_read_stream(
		manager,
		stream
	);
}


cowl_ret COWL_WRAP_cowl_manager_write_path (
	CowlManager * manager,
	CowlOntology * ontology,
	UString path
) {
	return cowl_manager_write_path(
		manager,
		ontology,
		path
	);
}


cowl_ret COWL_WRAP_cowl_manager_write_file (
	CowlManager * manager,
	CowlOntology * ontology,
	FILE * file
) {
	return cowl_manager_write_file(
		manager,
		ontology,
		file
	);
}


cowl_ret COWL_WRAP_cowl_manager_write_strbuf (
	CowlManager * manager,
	CowlOntology * ontology,
	UStrBuf * buf
) {
	return cowl_manager_write_strbuf(
		manager,
		ontology,
		buf
	);
}


cowl_ret COWL_WRAP_cowl_manager_write_stream (
	CowlManager * manager,
	CowlOntology * ontology,
	UOStream * stream
) {
	return cowl_manager_write_stream(
		manager,
		ontology,
		stream
	);
}


CowlIStream * COWL_WRAP_cowl_manager_get_istream (
	CowlManager * manager,
	CowlIStreamHandlers handlers
) {
	return cowl_manager_get_istream(
		manager,
		handlers
	);
}


CowlIStream * COWL_WRAP_cowl_manager_get_istream_to_ontology (
	CowlManager * manager,
	CowlOntology * ontology
) {
	return cowl_manager_get_istream_to_ontology(
		manager,
		ontology
	);
}


CowlOStream * COWL_WRAP_cowl_manager_get_ostream (
	CowlManager * manager,
	UOStream * stream
) {
	return cowl_manager_get_ostream(
		manager,
		stream
	);
}

