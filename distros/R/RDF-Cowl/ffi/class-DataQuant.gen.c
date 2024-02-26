#include "cowl.h"

/*
 * DO NOT EDIT
 *
 * Generated via maint/tt/Class.c.tt
 */


CowlDataQuant * COWL_WRAP_cowl_data_quant (
	CowlQuantType type,
	CowlAnyDataPropExp * prop,
	CowlAnyDataRange * range
) {
	return cowl_data_quant(
		type,
		prop,
		range
	);
}


CowlQuantType COWL_WRAP_cowl_data_quant_get_type (
	CowlDataQuant * restr
) {
	return cowl_data_quant_get_type(
		restr
	);
}


CowlDataPropExp * COWL_WRAP_cowl_data_quant_get_prop (
	CowlDataQuant * restr
) {
	return cowl_data_quant_get_prop(
		restr
	);
}


CowlDataRange * COWL_WRAP_cowl_data_quant_get_range (
	CowlDataQuant * restr
) {
	return cowl_data_quant_get_range(
		restr
	);
}

