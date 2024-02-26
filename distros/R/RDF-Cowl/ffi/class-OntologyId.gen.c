#include "cowl.h"

/*
 * DO NOT EDIT
 *
 * Generated via maint/tt/Class.c.tt
 */


CowlOntologyId COWL_WRAP_cowl_ontology_id_anonymous (
) {
	return cowl_ontology_id_anonymous(
	);
}


bool COWL_WRAP_cowl_ontology_id_equals (
	CowlOntologyId lhs,
	CowlOntologyId rhs
) {
	return cowl_ontology_id_equals(
		lhs,
		rhs
	);
}


ulib_uint COWL_WRAP_cowl_ontology_id_hash (
	CowlOntologyId id
) {
	return cowl_ontology_id_hash(
		id
	);
}

