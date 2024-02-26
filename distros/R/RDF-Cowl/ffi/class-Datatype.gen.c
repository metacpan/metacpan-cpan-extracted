#include "cowl.h"

/*
 * DO NOT EDIT
 *
 * Generated via maint/tt/Class.c.tt
 */


CowlDatatype * COWL_WRAP_cowl_datatype (
	CowlIRI * iri
) {
	return cowl_datatype(
		iri
	);
}


CowlDatatype * COWL_WRAP_cowl_datatype_from_string (
	UString string
) {
	return cowl_datatype_from_string(
		string
	);
}


CowlIRI * COWL_WRAP_cowl_datatype_get_iri (
	CowlDatatype * dt
) {
	return cowl_datatype_get_iri(
		dt
	);
}

