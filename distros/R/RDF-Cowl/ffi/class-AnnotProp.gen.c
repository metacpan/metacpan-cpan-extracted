#include "cowl.h"

/*
 * DO NOT EDIT
 *
 * Generated via maint/tt/Class.c.tt
 */


CowlAnnotProp * COWL_WRAP_cowl_annot_prop (
	CowlIRI * iri
) {
	return cowl_annot_prop(
		iri
	);
}


CowlAnnotProp * COWL_WRAP_cowl_annot_prop_from_string (
	UString string
) {
	return cowl_annot_prop_from_string(
		string
	);
}


CowlIRI * COWL_WRAP_cowl_annot_prop_get_iri (
	CowlAnnotProp * prop
) {
	return cowl_annot_prop_get_iri(
		prop
	);
}

