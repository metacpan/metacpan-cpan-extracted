#include "cowl.h"

/*
 * DO NOT EDIT
 *
 * Generated via maint/tt/Class.c.tt
 */


CowlDeclAxiom * COWL_WRAP_cowl_decl_axiom (
	CowlAnyEntity * entity,
	CowlVector * annot
) {
	return cowl_decl_axiom(
		entity,
		annot
	);
}


CowlEntity * COWL_WRAP_cowl_decl_axiom_get_entity (
	CowlDeclAxiom * axiom
) {
	return cowl_decl_axiom_get_entity(
		axiom
	);
}


CowlVector * COWL_WRAP_cowl_decl_axiom_get_annot (
	CowlDeclAxiom * axiom
) {
	return cowl_decl_axiom_get_annot(
		axiom
	);
}

