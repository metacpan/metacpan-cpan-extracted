#include "cowl.h"

/*
 * DO NOT EDIT
 *
 * Generated via maint/tt/Class.c.tt
 */


CowlClsAssertAxiom * COWL_WRAP_cowl_cls_assert_axiom (
	CowlAnyClsExp * exp,
	CowlAnyIndividual * ind,
	CowlVector * annot
) {
	return cowl_cls_assert_axiom(
		exp,
		ind,
		annot
	);
}


CowlClsExp * COWL_WRAP_cowl_cls_assert_axiom_get_cls_exp (
	CowlClsAssertAxiom * axiom
) {
	return cowl_cls_assert_axiom_get_cls_exp(
		axiom
	);
}


CowlIndividual * COWL_WRAP_cowl_cls_assert_axiom_get_ind (
	CowlClsAssertAxiom * axiom
) {
	return cowl_cls_assert_axiom_get_ind(
		axiom
	);
}


CowlVector * COWL_WRAP_cowl_cls_assert_axiom_get_annot (
	CowlClsAssertAxiom * axiom
) {
	return cowl_cls_assert_axiom_get_annot(
		axiom
	);
}

