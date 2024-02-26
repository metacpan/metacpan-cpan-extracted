#include "cowl.h"

/*
 * DO NOT EDIT
 *
 * Generated via maint/tt/Class.c.tt
 */


CowlIRI * COWL_WRAP_cowl_iri (
	CowlString * prefix,
	CowlString * suffix
) {
	return cowl_iri(
		prefix,
		suffix
	);
}


CowlIRI * COWL_WRAP_cowl_iri_from_string (
	UString string
) {
	return cowl_iri_from_string(
		string
	);
}


CowlString * COWL_WRAP_cowl_iri_get_ns (
	CowlIRI * iri
) {
	return cowl_iri_get_ns(
		iri
	);
}


CowlString * COWL_WRAP_cowl_iri_get_rem (
	CowlIRI * iri
) {
	return cowl_iri_get_rem(
		iri
	);
}


bool COWL_WRAP_cowl_iri_has_rem (
	CowlIRI * iri
) {
	return cowl_iri_has_rem(
		iri
	);
}

