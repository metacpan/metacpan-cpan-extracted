#include "cowl.h"

/*
 * DO NOT EDIT
 *
 * Generated via maint/tt/Class.c.tt
 */


CowlObjPropCharAxiom * COWL_WRAP_cowl_obj_prop_char_axiom (
	CowlCharAxiomType type,
	CowlAnyObjPropExp * prop,
	CowlVector * annot
) {
	return cowl_obj_prop_char_axiom(
		type,
		prop,
		annot
	);
}


CowlCharAxiomType COWL_WRAP_cowl_obj_prop_char_axiom_get_type (
	CowlObjPropCharAxiom * axiom
) {
	return cowl_obj_prop_char_axiom_get_type(
		axiom
	);
}


CowlObjPropExp * COWL_WRAP_cowl_obj_prop_char_axiom_get_prop (
	CowlObjPropCharAxiom * axiom
) {
	return cowl_obj_prop_char_axiom_get_prop(
		axiom
	);
}


CowlVector * COWL_WRAP_cowl_obj_prop_char_axiom_get_annot (
	CowlObjPropCharAxiom * axiom
) {
	return cowl_obj_prop_char_axiom_get_annot(
		axiom
	);
}

