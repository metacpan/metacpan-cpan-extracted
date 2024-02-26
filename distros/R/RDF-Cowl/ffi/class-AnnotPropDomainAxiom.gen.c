#include "cowl.h"

/*
 * DO NOT EDIT
 *
 * Generated via maint/tt/Class.c.tt
 */


CowlAnnotPropDomainAxiom * COWL_WRAP_cowl_annot_prop_domain_axiom (
	CowlAnnotProp * prop,
	CowlIRI * domain,
	CowlVector * annot
) {
	return cowl_annot_prop_domain_axiom(
		prop,
		domain,
		annot
	);
}


CowlAnnotProp * COWL_WRAP_cowl_annot_prop_domain_axiom_get_prop (
	CowlAnnotPropDomainAxiom * axiom
) {
	return cowl_annot_prop_domain_axiom_get_prop(
		axiom
	);
}


CowlIRI * COWL_WRAP_cowl_annot_prop_domain_axiom_get_domain (
	CowlAnnotPropDomainAxiom * axiom
) {
	return cowl_annot_prop_domain_axiom_get_domain(
		axiom
	);
}


CowlVector * COWL_WRAP_cowl_annot_prop_domain_axiom_get_annot (
	CowlAnnotPropDomainAxiom * axiom
) {
	return cowl_annot_prop_domain_axiom_get_annot(
		axiom
	);
}

