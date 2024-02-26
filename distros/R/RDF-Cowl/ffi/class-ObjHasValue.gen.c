#include "cowl.h"

/*
 * DO NOT EDIT
 *
 * Generated via maint/tt/Class.c.tt
 */


CowlObjHasValue * COWL_WRAP_cowl_obj_has_value (
	CowlAnyObjPropExp * prop,
	CowlAnyIndividual * individual
) {
	return cowl_obj_has_value(
		prop,
		individual
	);
}


CowlObjPropExp * COWL_WRAP_cowl_obj_has_value_get_prop (
	CowlObjHasValue * exp
) {
	return cowl_obj_has_value_get_prop(
		exp
	);
}


CowlIndividual * COWL_WRAP_cowl_obj_has_value_get_ind (
	CowlObjHasValue * exp
) {
	return cowl_obj_has_value_get_ind(
		exp
	);
}

