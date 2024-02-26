#include "cowl.h"

/*
 * DO NOT EDIT
 *
 * Generated via maint/tt/Class.c.tt
 */


CowlSubAnnotPropAxiom * COWL_WRAP_cowl_sub_annot_prop_axiom (
	CowlAnnotProp * sub,
	CowlAnnotProp * super,
	CowlVector * annot
) {
	return cowl_sub_annot_prop_axiom(
		sub,
		super,
		annot
	);
}


CowlAnnotProp * COWL_WRAP_cowl_sub_annot_prop_axiom_get_sub (
	CowlSubAnnotPropAxiom * axiom
) {
	return cowl_sub_annot_prop_axiom_get_sub(
		axiom
	);
}


CowlAnnotProp * COWL_WRAP_cowl_sub_annot_prop_axiom_get_super (
	CowlSubAnnotPropAxiom * axiom
) {
	return cowl_sub_annot_prop_axiom_get_super(
		axiom
	);
}


CowlVector * COWL_WRAP_cowl_sub_annot_prop_axiom_get_annot (
	CowlSubAnnotPropAxiom * axiom
) {
	return cowl_sub_annot_prop_axiom_get_annot(
		axiom
	);
}

