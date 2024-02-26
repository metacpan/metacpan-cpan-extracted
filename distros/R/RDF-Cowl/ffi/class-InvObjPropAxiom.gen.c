#include "cowl.h"

/*
 * DO NOT EDIT
 *
 * Generated via maint/tt/Class.c.tt
 */


CowlInvObjPropAxiom * COWL_WRAP_cowl_inv_obj_prop_axiom (
	CowlAnyObjPropExp * first,
	CowlAnyObjPropExp * second,
	CowlVector * annot
) {
	return cowl_inv_obj_prop_axiom(
		first,
		second,
		annot
	);
}


CowlObjPropExp * COWL_WRAP_cowl_inv_obj_prop_axiom_get_first_prop (
	CowlInvObjPropAxiom * axiom
) {
	return cowl_inv_obj_prop_axiom_get_first_prop(
		axiom
	);
}


CowlObjPropExp * COWL_WRAP_cowl_inv_obj_prop_axiom_get_second_prop (
	CowlInvObjPropAxiom * axiom
) {
	return cowl_inv_obj_prop_axiom_get_second_prop(
		axiom
	);
}


CowlVector * COWL_WRAP_cowl_inv_obj_prop_axiom_get_annot (
	CowlInvObjPropAxiom * axiom
) {
	return cowl_inv_obj_prop_axiom_get_annot(
		axiom
	);
}

