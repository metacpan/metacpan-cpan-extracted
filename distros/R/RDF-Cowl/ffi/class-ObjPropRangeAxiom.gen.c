#include "cowl.h"

/*
 * DO NOT EDIT
 *
 * Generated via maint/tt/Class.c.tt
 */


CowlObjPropRangeAxiom * COWL_WRAP_cowl_obj_prop_range_axiom (
	CowlAnyObjPropExp * prop,
	CowlAnyClsExp * range,
	CowlVector * annot
) {
	return cowl_obj_prop_range_axiom(
		prop,
		range,
		annot
	);
}


CowlObjPropExp * COWL_WRAP_cowl_obj_prop_range_axiom_get_prop (
	CowlObjPropRangeAxiom * axiom
) {
	return cowl_obj_prop_range_axiom_get_prop(
		axiom
	);
}


CowlClsExp * COWL_WRAP_cowl_obj_prop_range_axiom_get_range (
	CowlObjPropRangeAxiom * axiom
) {
	return cowl_obj_prop_range_axiom_get_range(
		axiom
	);
}


CowlVector * COWL_WRAP_cowl_obj_prop_range_axiom_get_annot (
	CowlObjPropRangeAxiom * axiom
) {
	return cowl_obj_prop_range_axiom_get_annot(
		axiom
	);
}

