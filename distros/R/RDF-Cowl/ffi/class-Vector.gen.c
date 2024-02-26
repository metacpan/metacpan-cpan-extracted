#include "cowl.h"

/*
 * DO NOT EDIT
 *
 * Generated via maint/tt/Class.c.tt
 */


CowlVector * COWL_WRAP_cowl_vector (
	UVec(CowlObjectPtr) * vec
) {
	return cowl_vector(
		vec
	);
}


UVec(CowlObjectPtr) const * COWL_WRAP_cowl_vector_get_data (
	CowlVector * vec
) {
	return cowl_vector_get_data(
		vec
	);
}


ulib_uint COWL_WRAP_cowl_vector_count (
	CowlVector * vec
) {
	return cowl_vector_count(
		vec
	);
}


CowlAny * COWL_WRAP_cowl_vector_get_item (
	CowlVector * vec,
	ulib_uint idx
) {
	return cowl_vector_get_item(
		vec,
		idx
	);
}


bool COWL_WRAP_cowl_vector_contains (
	CowlVector * vec,
	CowlAny * object
) {
	return cowl_vector_contains(
		vec,
		object
	);
}

