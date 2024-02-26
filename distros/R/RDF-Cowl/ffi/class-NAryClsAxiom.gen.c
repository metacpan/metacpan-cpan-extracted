#include "cowl.h"

/*
 * DO NOT EDIT
 *
 * Generated via maint/tt/Class.c.tt
 */


CowlNAryClsAxiom * COWL_WRAP_cowl_nary_cls_axiom (
	CowlNAryAxiomType type,
	CowlVector * classes,
	CowlVector * annot
) {
	return cowl_nary_cls_axiom(
		type,
		classes,
		annot
	);
}


CowlNAryAxiomType COWL_WRAP_cowl_nary_cls_axiom_get_type (
	CowlNAryClsAxiom * axiom
) {
	return cowl_nary_cls_axiom_get_type(
		axiom
	);
}


CowlVector * COWL_WRAP_cowl_nary_cls_axiom_get_classes (
	CowlNAryClsAxiom * axiom
) {
	return cowl_nary_cls_axiom_get_classes(
		axiom
	);
}


CowlVector * COWL_WRAP_cowl_nary_cls_axiom_get_annot (
	CowlNAryClsAxiom * axiom
) {
	return cowl_nary_cls_axiom_get_annot(
		axiom
	);
}

