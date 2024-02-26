#include "cowl.h"

/*
 * DO NOT EDIT
 *
 * Generated via maint/tt/Class.c.tt
 */


CowlDataPropAssertAxiom * COWL_WRAP_cowl_data_prop_assert_axiom (
	CowlAnyDataPropExp * prop,
	CowlAnyIndividual * subj,
	CowlLiteral * obj,
	CowlVector * annot
) {
	return cowl_data_prop_assert_axiom(
		prop,
		subj,
		obj,
		annot
	);
}


CowlDataPropAssertAxiom * COWL_WRAP_cowl_neg_data_prop_assert_axiom (
	CowlAnyDataPropExp * prop,
	CowlAnyIndividual * subj,
	CowlLiteral * obj,
	CowlVector * annot
) {
	return cowl_neg_data_prop_assert_axiom(
		prop,
		subj,
		obj,
		annot
	);
}


bool COWL_WRAP_cowl_data_prop_assert_axiom_is_negative (
	CowlDataPropAssertAxiom * axiom
) {
	return cowl_data_prop_assert_axiom_is_negative(
		axiom
	);
}


CowlDataPropExp * COWL_WRAP_cowl_data_prop_assert_axiom_get_prop (
	CowlDataPropAssertAxiom * axiom
) {
	return cowl_data_prop_assert_axiom_get_prop(
		axiom
	);
}


CowlIndividual * COWL_WRAP_cowl_data_prop_assert_axiom_get_subject (
	CowlDataPropAssertAxiom * axiom
) {
	return cowl_data_prop_assert_axiom_get_subject(
		axiom
	);
}


CowlLiteral * COWL_WRAP_cowl_data_prop_assert_axiom_get_object (
	CowlDataPropAssertAxiom * axiom
) {
	return cowl_data_prop_assert_axiom_get_object(
		axiom
	);
}


CowlVector * COWL_WRAP_cowl_data_prop_assert_axiom_get_annot (
	CowlDataPropAssertAxiom * axiom
) {
	return cowl_data_prop_assert_axiom_get_annot(
		axiom
	);
}

