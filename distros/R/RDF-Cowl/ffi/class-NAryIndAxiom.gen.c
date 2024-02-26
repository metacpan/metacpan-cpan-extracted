#include "cowl.h"

/*
 * DO NOT EDIT
 *
 * Generated via maint/tt/Class.c.tt
 */


CowlNAryIndAxiom * COWL_WRAP_cowl_nary_ind_axiom (
	CowlNAryAxiomType type,
	CowlVector * individuals,
	CowlVector * annot
) {
	return cowl_nary_ind_axiom(
		type,
		individuals,
		annot
	);
}


CowlNAryAxiomType COWL_WRAP_cowl_nary_ind_axiom_get_type (
	CowlNAryIndAxiom * axiom
) {
	return cowl_nary_ind_axiom_get_type(
		axiom
	);
}


CowlVector * COWL_WRAP_cowl_nary_ind_axiom_get_individuals (
	CowlNAryIndAxiom * axiom
) {
	return cowl_nary_ind_axiom_get_individuals(
		axiom
	);
}


CowlVector * COWL_WRAP_cowl_nary_ind_axiom_get_annot (
	CowlNAryIndAxiom * axiom
) {
	return cowl_nary_ind_axiom_get_annot(
		axiom
	);
}

