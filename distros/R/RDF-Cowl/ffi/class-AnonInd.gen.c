#include "cowl.h"

/*
 * DO NOT EDIT
 *
 * Generated via maint/tt/Class.c.tt
 */


CowlAnonInd * COWL_WRAP_cowl_anon_ind (
	CowlString * id
) {
	return cowl_anon_ind(
		id
	);
}


CowlAnonInd * COWL_WRAP_cowl_anon_ind_from_string (
	UString string
) {
	return cowl_anon_ind_from_string(
		string
	);
}


CowlString * COWL_WRAP_cowl_anon_ind_get_id (
	CowlAnonInd * ind
) {
	return cowl_anon_ind_get_id(
		ind
	);
}

