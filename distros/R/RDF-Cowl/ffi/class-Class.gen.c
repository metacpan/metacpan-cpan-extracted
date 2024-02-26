#include "cowl.h"

/*
 * DO NOT EDIT
 *
 * Generated via maint/tt/Class.c.tt
 */


CowlClass * COWL_WRAP_cowl_class (
	CowlIRI * iri
) {
	return cowl_class(
		iri
	);
}


CowlClass * COWL_WRAP_cowl_class_from_string (
	UString string
) {
	return cowl_class_from_string(
		string
	);
}


CowlIRI * COWL_WRAP_cowl_class_get_iri (
	CowlClass * cls
) {
	return cowl_class_get_iri(
		cls
	);
}

