#include "cowl.h"

/*
 * DO NOT EDIT
 *
 * Generated via maint/tt/Class.c.tt
 */


CowlDataProp * COWL_WRAP_cowl_data_prop (
	CowlIRI * iri
) {
	return cowl_data_prop(
		iri
	);
}


CowlDataProp * COWL_WRAP_cowl_data_prop_from_string (
	UString string
) {
	return cowl_data_prop_from_string(
		string
	);
}


CowlIRI * COWL_WRAP_cowl_data_prop_get_iri (
	CowlDataProp * prop
) {
	return cowl_data_prop_get_iri(
		prop
	);
}

