#include "cowl.h"

/*
 * DO NOT EDIT
 *
 * Generated via maint/tt/Class.c.tt
 */


CowlDisjUnionAxiom * COWL_WRAP_cowl_disj_union_axiom (
	CowlClass * cls,
	CowlVector * disjoints,
	CowlVector * annot
) {
	return cowl_disj_union_axiom(
		cls,
		disjoints,
		annot
	);
}


CowlClass * COWL_WRAP_cowl_disj_union_axiom_get_class (
	CowlDisjUnionAxiom * axiom
) {
	return cowl_disj_union_axiom_get_class(
		axiom
	);
}


CowlVector * COWL_WRAP_cowl_disj_union_axiom_get_disjoints (
	CowlDisjUnionAxiom * axiom
) {
	return cowl_disj_union_axiom_get_disjoints(
		axiom
	);
}


CowlVector * COWL_WRAP_cowl_disj_union_axiom_get_annot (
	CowlDisjUnionAxiom * axiom
) {
	return cowl_disj_union_axiom_get_annot(
		axiom
	);
}

