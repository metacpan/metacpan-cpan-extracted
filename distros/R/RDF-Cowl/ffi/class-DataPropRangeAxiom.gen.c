#include "cowl.h"

/*
 * DO NOT EDIT
 *
 * Generated via maint/tt/Class.c.tt
 */


CowlDataPropRangeAxiom * COWL_WRAP_cowl_data_prop_range_axiom (
	CowlAnyDataPropExp * prop,
	CowlAnyDataRange * range,
	CowlVector * annot
) {
	return cowl_data_prop_range_axiom(
		prop,
		range,
		annot
	);
}


CowlDataPropExp * COWL_WRAP_cowl_data_prop_range_axiom_get_prop (
	CowlDataPropRangeAxiom * axiom
) {
	return cowl_data_prop_range_axiom_get_prop(
		axiom
	);
}


CowlDataRange * COWL_WRAP_cowl_data_prop_range_axiom_get_range (
	CowlDataPropRangeAxiom * axiom
) {
	return cowl_data_prop_range_axiom_get_range(
		axiom
	);
}


CowlVector * COWL_WRAP_cowl_data_prop_range_axiom_get_annot (
	CowlDataPropRangeAxiom * axiom
) {
	return cowl_data_prop_range_axiom_get_annot(
		axiom
	);
}

