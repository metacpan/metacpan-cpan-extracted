#include "cowl.h"

/*
 * DO NOT EDIT
 *
 * Generated via maint/tt/Class.c.tt
 */


CowlSubClsAxiom * COWL_WRAP_cowl_sub_cls_axiom (
	CowlAnyClsExp * sub,
	CowlAnyClsExp * super,
	CowlVector * annot
) {
	return cowl_sub_cls_axiom(
		sub,
		super,
		annot
	);
}


CowlClsExp * COWL_WRAP_cowl_sub_cls_axiom_get_sub (
	CowlSubClsAxiom * axiom
) {
	return cowl_sub_cls_axiom_get_sub(
		axiom
	);
}


CowlClsExp * COWL_WRAP_cowl_sub_cls_axiom_get_super (
	CowlSubClsAxiom * axiom
) {
	return cowl_sub_cls_axiom_get_super(
		axiom
	);
}


CowlVector * COWL_WRAP_cowl_sub_cls_axiom_get_annot (
	CowlSubClsAxiom * axiom
) {
	return cowl_sub_cls_axiom_get_annot(
		axiom
	);
}

