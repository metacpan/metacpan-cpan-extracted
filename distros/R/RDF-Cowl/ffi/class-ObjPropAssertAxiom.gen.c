#include "cowl.h"

/*
 * DO NOT EDIT
 *
 * Generated via maint/tt/Class.c.tt
 */


CowlObjPropAssertAxiom * COWL_WRAP_cowl_obj_prop_assert_axiom (
	CowlAnyObjPropExp * prop,
	CowlAnyIndividual * subject,
	CowlAnyIndividual * object,
	CowlVector * annot
) {
	return cowl_obj_prop_assert_axiom(
		prop,
		subject,
		object,
		annot
	);
}


CowlObjPropAssertAxiom * COWL_WRAP_cowl_neg_obj_prop_assert_axiom (
	CowlAnyObjPropExp * prop,
	CowlAnyIndividual * subject,
	CowlAnyIndividual * object,
	CowlVector * annot
) {
	return cowl_neg_obj_prop_assert_axiom(
		prop,
		subject,
		object,
		annot
	);
}


bool COWL_WRAP_cowl_obj_prop_assert_axiom_is_negative (
	CowlObjPropAssertAxiom * axiom
) {
	return cowl_obj_prop_assert_axiom_is_negative(
		axiom
	);
}


CowlObjPropExp * COWL_WRAP_cowl_obj_prop_assert_axiom_get_prop (
	CowlObjPropAssertAxiom * axiom
) {
	return cowl_obj_prop_assert_axiom_get_prop(
		axiom
	);
}


CowlIndividual * COWL_WRAP_cowl_obj_prop_assert_axiom_get_subject (
	CowlObjPropAssertAxiom * axiom
) {
	return cowl_obj_prop_assert_axiom_get_subject(
		axiom
	);
}


CowlIndividual * COWL_WRAP_cowl_obj_prop_assert_axiom_get_object (
	CowlObjPropAssertAxiom * axiom
) {
	return cowl_obj_prop_assert_axiom_get_object(
		axiom
	);
}


CowlVector * COWL_WRAP_cowl_obj_prop_assert_axiom_get_annot (
	CowlObjPropAssertAxiom * axiom
) {
	return cowl_obj_prop_assert_axiom_get_annot(
		axiom
	);
}

