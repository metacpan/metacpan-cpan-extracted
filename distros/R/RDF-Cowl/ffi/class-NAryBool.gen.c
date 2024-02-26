#include "cowl.h"

/*
 * DO NOT EDIT
 *
 * Generated via maint/tt/Class.c.tt
 */


CowlNAryBool * COWL_WRAP_cowl_nary_bool (
	CowlNAryType type,
	CowlVector * operands
) {
	return cowl_nary_bool(
		type,
		operands
	);
}


CowlNAryType COWL_WRAP_cowl_nary_bool_get_type (
	CowlNAryBool * exp
) {
	return cowl_nary_bool_get_type(
		exp
	);
}


CowlVector * COWL_WRAP_cowl_nary_bool_get_operands (
	CowlNAryBool * exp
) {
	return cowl_nary_bool_get_operands(
		exp
	);
}

