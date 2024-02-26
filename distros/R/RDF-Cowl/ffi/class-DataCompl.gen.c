#include "cowl.h"

/*
 * DO NOT EDIT
 *
 * Generated via maint/tt/Class.c.tt
 */


CowlDataCompl * COWL_WRAP_cowl_data_compl (
	CowlAnyDataRange * operand
) {
	return cowl_data_compl(
		operand
	);
}


CowlDataRange * COWL_WRAP_cowl_data_compl_get_operand (
	CowlDataCompl * range
) {
	return cowl_data_compl_get_operand(
		range
	);
}

