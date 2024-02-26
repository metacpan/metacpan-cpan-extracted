#include "cowl.h"

/*
 * DO NOT EDIT
 *
 * Generated via maint/tt/Class.c.tt
 */


CowlObjPropDomainAxiom * COWL_WRAP_cowl_obj_prop_domain_axiom (
	CowlAnyObjPropExp * prop,
	CowlAnyClsExp * domain,
	CowlVector * annot
) {
	return cowl_obj_prop_domain_axiom(
		prop,
		domain,
		annot
	);
}


CowlObjPropExp * COWL_WRAP_cowl_obj_prop_domain_axiom_get_prop (
	CowlObjPropDomainAxiom * axiom
) {
	return cowl_obj_prop_domain_axiom_get_prop(
		axiom
	);
}


CowlClsExp * COWL_WRAP_cowl_obj_prop_domain_axiom_get_domain (
	CowlObjPropDomainAxiom * axiom
) {
	return cowl_obj_prop_domain_axiom_get_domain(
		axiom
	);
}


CowlVector * COWL_WRAP_cowl_obj_prop_domain_axiom_get_annot (
	CowlObjPropDomainAxiom * axiom
) {
	return cowl_obj_prop_domain_axiom_get_annot(
		axiom
	);
}

