#include "cowl.h"

/*
 * DO NOT EDIT
 *
 * Generated via maint/tt/Class.c.tt
 */


CowlSubDataPropAxiom * COWL_WRAP_cowl_sub_data_prop_axiom (
	CowlAnyDataPropExp * sub,
	CowlAnyDataPropExp * super,
	CowlVector * annot
) {
	return cowl_sub_data_prop_axiom(
		sub,
		super,
		annot
	);
}


CowlDataPropExp * COWL_WRAP_cowl_sub_data_prop_axiom_get_sub (
	CowlSubDataPropAxiom * axiom
) {
	return cowl_sub_data_prop_axiom_get_sub(
		axiom
	);
}


CowlDataPropExp * COWL_WRAP_cowl_sub_data_prop_axiom_get_super (
	CowlSubDataPropAxiom * axiom
) {
	return cowl_sub_data_prop_axiom_get_super(
		axiom
	);
}


CowlVector * COWL_WRAP_cowl_sub_data_prop_axiom_get_annot (
	CowlSubDataPropAxiom * axiom
) {
	return cowl_sub_data_prop_axiom_get_annot(
		axiom
	);
}

