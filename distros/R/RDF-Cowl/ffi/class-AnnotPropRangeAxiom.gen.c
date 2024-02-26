#include "cowl.h"

/*
 * DO NOT EDIT
 *
 * Generated via maint/tt/Class.c.tt
 */


CowlAnnotPropRangeAxiom * COWL_WRAP_cowl_annot_prop_range_axiom (
	CowlAnnotProp * prop,
	CowlIRI * range,
	CowlVector * annot
) {
	return cowl_annot_prop_range_axiom(
		prop,
		range,
		annot
	);
}


CowlAnnotProp * COWL_WRAP_cowl_annot_prop_range_axiom_get_prop (
	CowlAnnotPropRangeAxiom * axiom
) {
	return cowl_annot_prop_range_axiom_get_prop(
		axiom
	);
}


CowlIRI * COWL_WRAP_cowl_annot_prop_range_axiom_get_range (
	CowlAnnotPropRangeAxiom * axiom
) {
	return cowl_annot_prop_range_axiom_get_range(
		axiom
	);
}


CowlVector * COWL_WRAP_cowl_annot_prop_range_axiom_get_annot (
	CowlAnnotPropRangeAxiom * axiom
) {
	return cowl_annot_prop_range_axiom_get_annot(
		axiom
	);
}

