#include "cowl.h"

/*
 * DO NOT EDIT
 *
 * Generated via maint/tt/Class.c.tt
 */


CowlFacetRestr * COWL_WRAP_cowl_facet_restr (
	CowlIRI * facet,
	CowlLiteral * value
) {
	return cowl_facet_restr(
		facet,
		value
	);
}


CowlIRI * COWL_WRAP_cowl_facet_restr_get_facet (
	CowlFacetRestr * restr
) {
	return cowl_facet_restr_get_facet(
		restr
	);
}


CowlLiteral * COWL_WRAP_cowl_facet_restr_get_value (
	CowlFacetRestr * restr
) {
	return cowl_facet_restr_get_value(
		restr
	);
}

