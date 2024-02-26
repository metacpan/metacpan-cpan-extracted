#include "cowl.h"

/*
 * DO NOT EDIT
 *
 * Generated via maint/tt/Class.c.tt
 */


CowlDataHasValue * COWL_WRAP_cowl_data_has_value (
	CowlAnyDataPropExp * prop,
	CowlLiteral * value
) {
	return cowl_data_has_value(
		prop,
		value
	);
}


CowlDataPropExp * COWL_WRAP_cowl_data_has_value_get_prop (
	CowlDataHasValue * restr
) {
	return cowl_data_has_value_get_prop(
		restr
	);
}


CowlLiteral * COWL_WRAP_cowl_data_has_value_get_value (
	CowlDataHasValue * restr
) {
	return cowl_data_has_value_get_value(
		restr
	);
}

