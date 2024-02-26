#include "cowl.h"

/*
 * DO NOT EDIT
 *
 * Generated via maint/tt/Class.c.tt
 */


CowlSubObjPropAxiom * COWL_WRAP_cowl_sub_obj_prop_axiom (
	CowlAnyObjPropExp * sub,
	CowlAnyObjPropExp * super,
	CowlVector * annot
) {
	return cowl_sub_obj_prop_axiom(
		sub,
		super,
		annot
	);
}


CowlSubObjPropAxiom * COWL_WRAP_cowl_sub_obj_prop_chain_axiom (
	CowlVector * sub,
	CowlAnyObjPropExp * super,
	CowlVector * annot
) {
	return cowl_sub_obj_prop_chain_axiom(
		sub,
		super,
		annot
	);
}


CowlAny * COWL_WRAP_cowl_sub_obj_prop_axiom_get_sub (
	CowlSubObjPropAxiom * axiom
) {
	return cowl_sub_obj_prop_axiom_get_sub(
		axiom
	);
}


CowlObjPropExp * COWL_WRAP_cowl_sub_obj_prop_axiom_get_super (
	CowlSubObjPropAxiom * axiom
) {
	return cowl_sub_obj_prop_axiom_get_super(
		axiom
	);
}


CowlVector * COWL_WRAP_cowl_sub_obj_prop_axiom_get_annot (
	CowlSubObjPropAxiom * axiom
) {
	return cowl_sub_obj_prop_axiom_get_annot(
		axiom
	);
}

