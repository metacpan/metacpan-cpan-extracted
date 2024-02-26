#include "cowl.h"

/*
 * DO NOT EDIT
 *
 * Generated via maint/tt/Class.c.tt
 */


CowlDatatypeRestr * COWL_WRAP_cowl_datatype_restr (
	CowlDatatype * datatype,
	CowlVector * restrictions
) {
	return cowl_datatype_restr(
		datatype,
		restrictions
	);
}


CowlDatatype * COWL_WRAP_cowl_datatype_restr_get_datatype (
	CowlDatatypeRestr * restr
) {
	return cowl_datatype_restr_get_datatype(
		restr
	);
}


CowlVector * COWL_WRAP_cowl_datatype_restr_get_restrictions (
	CowlDatatypeRestr * restr
) {
	return cowl_datatype_restr_get_restrictions(
		restr
	);
}

