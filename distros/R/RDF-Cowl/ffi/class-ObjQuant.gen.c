#include "cowl.h"

/*
 * DO NOT EDIT
 *
 * Generated via maint/tt/Class.c.tt
 */


CowlObjQuant * COWL_WRAP_cowl_obj_quant (
	CowlQuantType type,
	CowlAnyObjPropExp * prop,
	CowlAnyClsExp * filler
) {
	return cowl_obj_quant(
		type,
		prop,
		filler
	);
}


CowlQuantType COWL_WRAP_cowl_obj_quant_get_type (
	CowlObjQuant * restr
) {
	return cowl_obj_quant_get_type(
		restr
	);
}


CowlObjPropExp * COWL_WRAP_cowl_obj_quant_get_prop (
	CowlObjQuant * restr
) {
	return cowl_obj_quant_get_prop(
		restr
	);
}


CowlClsExp * COWL_WRAP_cowl_obj_quant_get_filler (
	CowlObjQuant * restr
) {
	return cowl_obj_quant_get_filler(
		restr
	);
}

