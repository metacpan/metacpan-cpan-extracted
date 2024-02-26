#include "cowl.h"

/*
 * DO NOT EDIT
 *
 * Generated via maint/tt/Class.c.tt
 */


CowlAny * COWL_WRAP_cowl_retain (
	CowlAny * object
) {
	return cowl_retain(
		object
	);
}


void COWL_WRAP_cowl_release (
	CowlAny * object
) {
	cowl_release(
		object
	);
}


CowlObjectType COWL_WRAP_cowl_get_type (
	CowlAny * object
) {
	return cowl_get_type(
		object
	);
}


bool COWL_WRAP_cowl_is_entity (
	CowlAny * object
) {
	return cowl_is_entity(
		object
	);
}


bool COWL_WRAP_cowl_is_axiom (
	CowlAny * object
) {
	return cowl_is_axiom(
		object
	);
}


bool COWL_WRAP_cowl_is_cls_exp (
	CowlAny * object
) {
	return cowl_is_cls_exp(
		object
	);
}


bool COWL_WRAP_cowl_is_obj_prop_exp (
	CowlAny * object
) {
	return cowl_is_obj_prop_exp(
		object
	);
}


bool COWL_WRAP_cowl_is_data_prop_exp (
	CowlAny * object
) {
	return cowl_is_data_prop_exp(
		object
	);
}


bool COWL_WRAP_cowl_is_individual (
	CowlAny * object
) {
	return cowl_is_individual(
		object
	);
}


bool COWL_WRAP_cowl_is_data_range (
	CowlAny * object
) {
	return cowl_is_data_range(
		object
	);
}


CowlIRI * COWL_WRAP_cowl_get_iri (
	CowlAny * object
) {
	return cowl_get_iri(
		object
	);
}


CowlString * COWL_WRAP_cowl_to_string (
	CowlAny * object
) {
	return cowl_to_string(
		object
	);
}


CowlString * COWL_WRAP_cowl_to_debug_string (
	CowlAny * object
) {
	return cowl_to_debug_string(
		object
	);
}


bool COWL_WRAP_cowl_equals (
	CowlAny * lhs,
	CowlAny * rhs
) {
	return cowl_equals(
		lhs,
		rhs
	);
}


bool COWL_WRAP_cowl_equals_iri_string (
	CowlAny * object,
	UString iri_str
) {
	return cowl_equals_iri_string(
		object,
		iri_str
	);
}


ulib_uint COWL_WRAP_cowl_hash (
	CowlAny * object
) {
	return cowl_hash(
		object
	);
}


bool COWL_WRAP_cowl_iterate_primitives (
	CowlAny * object,
	CowlPrimitiveFlags flags,
	CowlIterator * iter
) {
	return cowl_iterate_primitives(
		object,
		flags,
		iter
	);
}

