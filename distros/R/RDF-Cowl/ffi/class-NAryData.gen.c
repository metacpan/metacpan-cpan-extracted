#include "cowl.h"

/*
 * DO NOT EDIT
 *
 * Generated via maint/tt/Class.c.tt
 */


CowlNAryData * COWL_WRAP_cowl_nary_data (
	CowlNAryType type,
	CowlVector * operands
) {
	return cowl_nary_data(
		type,
		operands
	);
}


CowlNAryType COWL_WRAP_cowl_nary_data_get_type (
	CowlNAryData * range
) {
	return cowl_nary_data_get_type(
		range
	);
}


CowlVector * COWL_WRAP_cowl_nary_data_get_operands (
	CowlNAryData * range
) {
	return cowl_nary_data_get_operands(
		range
	);
}

