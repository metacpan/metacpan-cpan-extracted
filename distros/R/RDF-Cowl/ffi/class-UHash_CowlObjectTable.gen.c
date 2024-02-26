#include "cowl.h"

/*
 * DO NOT EDIT
 *
 * Generated via maint/tt/Class.c.tt
 */


void COWL_WRAP_uhash_deinit_CowlObjectTable (
	UHash_CowlObjectTable * h
) {
	uhash_deinit_CowlObjectTable(
		h
	);
}


uhash_ret COWL_WRAP_uhash_copy_CowlObjectTable (
	UHash_CowlObjectTable const * src,
	UHash_CowlObjectTable * dest
) {
	return uhash_copy_CowlObjectTable(
		src,
		dest
	);
}


uhash_ret COWL_WRAP_uhash_copy_as_set_CowlObjectTable (
	UHash_CowlObjectTable const * src,
	UHash_CowlObjectTable * dest
) {
	return uhash_copy_as_set_CowlObjectTable(
		src,
		dest
	);
}


void COWL_WRAP_uhash_clear_CowlObjectTable (
	UHash_CowlObjectTable * h
) {
	uhash_clear_CowlObjectTable(
		h
	);
}


ulib_uint COWL_WRAP_uhash_get_CowlObjectTable (
	UHash_CowlObjectTable const * h,
	CowlAny * key
) {
	return uhash_get_CowlObjectTable(
		h,
		key
	);
}


uhash_ret COWL_WRAP_uhash_resize_CowlObjectTable (
	UHash_CowlObjectTable * h,
	ulib_uint new_size
) {
	return uhash_resize_CowlObjectTable(
		h,
		new_size
	);
}


uhash_ret COWL_WRAP_uhash_put_CowlObjectTable (
	UHash_CowlObjectTable * h,
	CowlAny * key,
	ulib_uint * idx
) {
	return uhash_put_CowlObjectTable(
		h,
		key,
		idx
	);
}


void COWL_WRAP_uhash_delete_CowlObjectTable (
	UHash_CowlObjectTable * h,
	ulib_uint x
) {
	uhash_delete_CowlObjectTable(
		h,
		x
	);
}


CowlAny * COWL_WRAP_uhmap_get_CowlObjectTable (
	UHash_CowlObjectTable const * h,
	CowlAny * key,
	CowlAny * if_missing
) {
	return uhmap_get_CowlObjectTable(
		h,
		key,
		if_missing
	);
}


bool COWL_WRAP_uhset_is_superset_CowlObjectTable (
	UHash_CowlObjectTable const * h1,
	UHash_CowlObjectTable const * h2
) {
	return uhset_is_superset_CowlObjectTable(
		h1,
		h2
	);
}


uhash_ret COWL_WRAP_uhset_union_CowlObjectTable (
	UHash_CowlObjectTable * h1,
	UHash_CowlObjectTable const * h2
) {
	return uhset_union_CowlObjectTable(
		h1,
		h2
	);
}


void COWL_WRAP_uhset_intersect_CowlObjectTable (
	UHash_CowlObjectTable * h1,
	UHash_CowlObjectTable const * h2
) {
	uhset_intersect_CowlObjectTable(
		h1,
		h2
	);
}


ulib_uint COWL_WRAP_uhset_hash_CowlObjectTable (
	UHash_CowlObjectTable const * h
) {
	return uhset_hash_CowlObjectTable(
		h
	);
}


CowlAny * COWL_WRAP_uhset_get_any_CowlObjectTable (
	UHash_CowlObjectTable const * h,
	CowlAny * if_empty
) {
	return uhset_get_any_CowlObjectTable(
		h,
		if_empty
	);
}


bool COWL_WRAP_uhash_is_map_CowlObjectTable (
	UHash_CowlObjectTable const * h
) {
	return uhash_is_map_CowlObjectTable(
		h
	);
}


UHash_CowlObjectTable COWL_WRAP_uhash_move_CowlObjectTable (
	UHash_CowlObjectTable * h
) {
	return uhash_move_CowlObjectTable(
		h
	);
}


ulib_uint COWL_WRAP_uhash_next_CowlObjectTable (
	UHash_CowlObjectTable const * h,
	ulib_uint i
) {
	return uhash_next_CowlObjectTable(
		h,
		i
	);
}


bool COWL_WRAP_uhset_equals_CowlObjectTable (
	UHash_CowlObjectTable const * h1,
	UHash_CowlObjectTable const * h2
) {
	return uhset_equals_CowlObjectTable(
		h1,
		h2
	);
}

