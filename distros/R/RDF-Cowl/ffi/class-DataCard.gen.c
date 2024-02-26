#include "cowl.h"

/*
 * DO NOT EDIT
 *
 * Generated via maint/tt/Class.c.tt
 */


CowlDataCard * COWL_WRAP_cowl_data_card (
	CowlCardType type,
	CowlAnyDataPropExp * prop,
	CowlAnyDataRange * range,
	ulib_uint cardinality
) {
	return cowl_data_card(
		type,
		prop,
		range,
		cardinality
	);
}


CowlCardType COWL_WRAP_cowl_data_card_get_type (
	CowlDataCard * restr
) {
	return cowl_data_card_get_type(
		restr
	);
}


CowlDataPropExp * COWL_WRAP_cowl_data_card_get_prop (
	CowlDataCard * restr
) {
	return cowl_data_card_get_prop(
		restr
	);
}


CowlDataRange * COWL_WRAP_cowl_data_card_get_range (
	CowlDataCard * restr
) {
	return cowl_data_card_get_range(
		restr
	);
}


ulib_uint COWL_WRAP_cowl_data_card_get_cardinality (
	CowlDataCard * restr
) {
	return cowl_data_card_get_cardinality(
		restr
	);
}

