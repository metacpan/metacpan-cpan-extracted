#include "cowl.h"

/*
 * DO NOT EDIT
 *
 * Generated via maint/tt/Class.c.tt
 */


CowlDatatypeDefAxiom * COWL_WRAP_cowl_datatype_def_axiom (
	CowlDatatype * dt,
	CowlAnyDataRange * range,
	CowlVector * annot
) {
	return cowl_datatype_def_axiom(
		dt,
		range,
		annot
	);
}


CowlDatatype * COWL_WRAP_cowl_datatype_def_axiom_get_datatype (
	CowlDatatypeDefAxiom * axiom
) {
	return cowl_datatype_def_axiom_get_datatype(
		axiom
	);
}


CowlDataRange * COWL_WRAP_cowl_datatype_def_axiom_get_range (
	CowlDatatypeDefAxiom * axiom
) {
	return cowl_datatype_def_axiom_get_range(
		axiom
	);
}


CowlVector * COWL_WRAP_cowl_datatype_def_axiom_get_annot (
	CowlDatatypeDefAxiom * axiom
) {
	return cowl_datatype_def_axiom_get_annot(
		axiom
	);
}

