#include "cowl.h"

/*
 * DO NOT EDIT
 *
 * Generated via maint/tt/Class.c.tt
 */


CowlObjCard * COWL_WRAP_cowl_obj_card (
	CowlCardType type,
	CowlAnyObjPropExp * prop,
	CowlAnyClsExp * filler,
	ulib_uint cardinality
) {
	return cowl_obj_card(
		type,
		prop,
		filler,
		cardinality
	);
}


CowlCardType COWL_WRAP_cowl_obj_card_get_type (
	CowlObjCard * restr
) {
	return cowl_obj_card_get_type(
		restr
	);
}


CowlObjPropExp * COWL_WRAP_cowl_obj_card_get_prop (
	CowlObjCard * restr
) {
	return cowl_obj_card_get_prop(
		restr
	);
}


CowlClsExp * COWL_WRAP_cowl_obj_card_get_filler (
	CowlObjCard * restr
) {
	return cowl_obj_card_get_filler(
		restr
	);
}


ulib_uint COWL_WRAP_cowl_obj_card_get_cardinality (
	CowlObjCard * restr
) {
	return cowl_obj_card_get_cardinality(
		restr
	);
}

