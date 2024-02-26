#include "cowl.h"

/*
 * DO NOT EDIT
 *
 * Generated via maint/tt/Class.c.tt
 */


CowlAnnotAssertAxiom * COWL_WRAP_cowl_annot_assert_axiom (
	CowlAnnotProp * prop,
	CowlAnyAnnotValue * subject,
	CowlAnyAnnotValue * value,
	CowlVector * annot
) {
	return cowl_annot_assert_axiom(
		prop,
		subject,
		value,
		annot
	);
}


CowlAnnotProp * COWL_WRAP_cowl_annot_assert_axiom_get_prop (
	CowlAnnotAssertAxiom * axiom
) {
	return cowl_annot_assert_axiom_get_prop(
		axiom
	);
}


CowlAnnotValue * COWL_WRAP_cowl_annot_assert_axiom_get_subject (
	CowlAnnotAssertAxiom * axiom
) {
	return cowl_annot_assert_axiom_get_subject(
		axiom
	);
}


CowlAnnotValue * COWL_WRAP_cowl_annot_assert_axiom_get_value (
	CowlAnnotAssertAxiom * axiom
) {
	return cowl_annot_assert_axiom_get_value(
		axiom
	);
}


CowlVector * COWL_WRAP_cowl_annot_assert_axiom_get_annot (
	CowlAnnotAssertAxiom * axiom
) {
	return cowl_annot_assert_axiom_get_annot(
		axiom
	);
}

