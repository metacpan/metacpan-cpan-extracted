#include "cowl.h"

/*
 * DO NOT EDIT
 *
 * Generated via maint/tt/Class.c.tt
 */


CowlNamedInd * COWL_WRAP_cowl_named_ind (
	CowlIRI * iri
) {
	return cowl_named_ind(
		iri
	);
}


CowlNamedInd * COWL_WRAP_cowl_named_ind_from_string (
	UString string
) {
	return cowl_named_ind_from_string(
		string
	);
}


CowlIRI * COWL_WRAP_cowl_named_ind_get_iri (
	CowlNamedInd * ind
) {
	return cowl_named_ind_get_iri(
		ind
	);
}

