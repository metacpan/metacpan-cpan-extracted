#include "cowl.h"

/*
 * DO NOT EDIT
 *
 * Generated via maint/tt/Class.c.tt
 */


CowlNAryDataPropAxiom * COWL_WRAP_cowl_nary_data_prop_axiom (
	CowlNAryAxiomType type,
	CowlVector * props,
	CowlVector * annot
) {
	return cowl_nary_data_prop_axiom(
		type,
		props,
		annot
	);
}


CowlNAryAxiomType COWL_WRAP_cowl_nary_data_prop_axiom_get_type (
	CowlNAryDataPropAxiom * axiom
) {
	return cowl_nary_data_prop_axiom_get_type(
		axiom
	);
}


CowlVector * COWL_WRAP_cowl_nary_data_prop_axiom_get_props (
	CowlNAryDataPropAxiom * axiom
) {
	return cowl_nary_data_prop_axiom_get_props(
		axiom
	);
}


CowlVector * COWL_WRAP_cowl_nary_data_prop_axiom_get_annot (
	CowlNAryDataPropAxiom * axiom
) {
	return cowl_nary_data_prop_axiom_get_annot(
		axiom
	);
}

