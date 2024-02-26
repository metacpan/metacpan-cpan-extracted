#include "cowl.h"

/*
 * DO NOT EDIT
 *
 * Generated via maint/tt/Class.c.tt
 */


CowlDataPropDomainAxiom * COWL_WRAP_cowl_data_prop_domain_axiom (
	CowlAnyDataPropExp * prop,
	CowlAnyClsExp * domain,
	CowlVector * annot
) {
	return cowl_data_prop_domain_axiom(
		prop,
		domain,
		annot
	);
}


CowlDataPropExp * COWL_WRAP_cowl_data_prop_domain_axiom_get_prop (
	CowlDataPropDomainAxiom * axiom
) {
	return cowl_data_prop_domain_axiom_get_prop(
		axiom
	);
}


CowlClsExp * COWL_WRAP_cowl_data_prop_domain_axiom_get_domain (
	CowlDataPropDomainAxiom * axiom
) {
	return cowl_data_prop_domain_axiom_get_domain(
		axiom
	);
}


CowlVector * COWL_WRAP_cowl_data_prop_domain_axiom_get_annot (
	CowlDataPropDomainAxiom * axiom
) {
	return cowl_data_prop_domain_axiom_get_annot(
		axiom
	);
}

