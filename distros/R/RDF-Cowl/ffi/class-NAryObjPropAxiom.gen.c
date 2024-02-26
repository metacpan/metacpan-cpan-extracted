#include "cowl.h"

/*
 * DO NOT EDIT
 *
 * Generated via maint/tt/Class.c.tt
 */


CowlNAryObjPropAxiom * COWL_WRAP_cowl_nary_obj_prop_axiom (
	CowlNAryAxiomType type,
	CowlVector * props,
	CowlVector * annot
) {
	return cowl_nary_obj_prop_axiom(
		type,
		props,
		annot
	);
}


CowlNAryAxiomType COWL_WRAP_cowl_nary_obj_prop_axiom_get_type (
	CowlNAryObjPropAxiom * axiom
) {
	return cowl_nary_obj_prop_axiom_get_type(
		axiom
	);
}


CowlVector * COWL_WRAP_cowl_nary_obj_prop_axiom_get_props (
	CowlNAryObjPropAxiom * axiom
) {
	return cowl_nary_obj_prop_axiom_get_props(
		axiom
	);
}


CowlVector * COWL_WRAP_cowl_nary_obj_prop_axiom_get_annot (
	CowlNAryObjPropAxiom * axiom
) {
	return cowl_nary_obj_prop_axiom_get_annot(
		axiom
	);
}

