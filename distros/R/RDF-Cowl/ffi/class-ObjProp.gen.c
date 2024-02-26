#include "cowl.h"

/*
 * DO NOT EDIT
 *
 * Generated via maint/tt/Class.c.tt
 */


CowlObjProp * COWL_WRAP_cowl_obj_prop (
	CowlIRI * iri
) {
	return cowl_obj_prop(
		iri
	);
}


CowlObjProp * COWL_WRAP_cowl_obj_prop_from_string (
	UString string
) {
	return cowl_obj_prop_from_string(
		string
	);
}


CowlIRI * COWL_WRAP_cowl_obj_prop_get_iri (
	CowlObjProp * prop
) {
	return cowl_obj_prop_get_iri(
		prop
	);
}

