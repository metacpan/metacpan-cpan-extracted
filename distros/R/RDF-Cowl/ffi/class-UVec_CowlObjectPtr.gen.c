#include "cowl.h"

/*
 * DO NOT EDIT
 *
 * Generated via maint/tt/Class.c.tt
 */


uvec_ret COWL_WRAP_uvec_reserve_CowlObjectPtr (
	UVec_CowlObjectPtr * vec,
	ulib_uint size
) {
	return uvec_reserve_CowlObjectPtr(
		vec,
		size
	);
}


uvec_ret COWL_WRAP_uvec_set_range_CowlObjectPtr (
	UVec_CowlObjectPtr * vec,
	CowlObjectPtr const * array,
	ulib_uint start,
	ulib_uint n
) {
	return uvec_set_range_CowlObjectPtr(
		vec,
		array,
		start,
		n
	);
}


uvec_ret COWL_WRAP_uvec_copy_CowlObjectPtr (
	UVec_CowlObjectPtr const * src,
	UVec_CowlObjectPtr * dest
) {
	return uvec_copy_CowlObjectPtr(
		src,
		dest
	);
}


void COWL_WRAP_uvec_copy_to_array_CowlObjectPtr (
	UVec_CowlObjectPtr const * vec,
	CowlObjectPtr array[]
) {
	uvec_copy_to_array_CowlObjectPtr(
		vec,
		array
	);
}


uvec_ret COWL_WRAP_uvec_shrink_CowlObjectPtr (
	UVec_CowlObjectPtr * vec
) {
	return uvec_shrink_CowlObjectPtr(
		vec
	);
}


uvec_ret COWL_WRAP_uvec_push_CowlObjectPtr (
	UVec_CowlObjectPtr * vec,
	CowlObjectPtr item
) {
	return uvec_push_CowlObjectPtr(
		vec,
		item
	);
}


CowlObjectPtr COWL_WRAP_uvec_pop_CowlObjectPtr (
	UVec_CowlObjectPtr * vec
) {
	return uvec_pop_CowlObjectPtr(
		vec
	);
}


CowlObjectPtr COWL_WRAP_uvec_remove_at_CowlObjectPtr (
	UVec_CowlObjectPtr * vec,
	ulib_uint idx
) {
	return uvec_remove_at_CowlObjectPtr(
		vec,
		idx
	);
}


uvec_ret COWL_WRAP_uvec_insert_at_CowlObjectPtr (
	UVec_CowlObjectPtr * vec,
	ulib_uint idx,
	CowlObjectPtr item
) {
	return uvec_insert_at_CowlObjectPtr(
		vec,
		idx,
		item
	);
}


void COWL_WRAP_uvec_remove_all_CowlObjectPtr (
	UVec_CowlObjectPtr * vec
) {
	uvec_remove_all_CowlObjectPtr(
		vec
	);
}


void COWL_WRAP_uvec_reverse_CowlObjectPtr (
	UVec_CowlObjectPtr * vec
) {
	uvec_reverse_CowlObjectPtr(
		vec
	);
}


ulib_uint COWL_WRAP_uvec_index_of_CowlObjectPtr (
	UVec_CowlObjectPtr const * vec,
	CowlObjectPtr item
) {
	return uvec_index_of_CowlObjectPtr(
		vec,
		item
	);
}


ulib_uint COWL_WRAP_uvec_index_of_reverse_CowlObjectPtr (
	UVec_CowlObjectPtr const * vec,
	CowlObjectPtr item
) {
	return uvec_index_of_reverse_CowlObjectPtr(
		vec,
		item
	);
}


bool COWL_WRAP_uvec_remove_CowlObjectPtr (
	UVec_CowlObjectPtr * vec,
	CowlObjectPtr item
) {
	return uvec_remove_CowlObjectPtr(
		vec,
		item
	);
}


bool COWL_WRAP_uvec_equals_CowlObjectPtr (
	UVec_CowlObjectPtr const * vec,
	UVec_CowlObjectPtr const * other
) {
	return uvec_equals_CowlObjectPtr(
		vec,
		other
	);
}


uvec_ret COWL_WRAP_uvec_push_unique_CowlObjectPtr (
	UVec_CowlObjectPtr * vec,
	CowlObjectPtr item
) {
	return uvec_push_unique_CowlObjectPtr(
		vec,
		item
	);
}


CowlObjectPtr * COWL_WRAP_uvec_data_CowlObjectPtr (
	UVec_CowlObjectPtr const * vec
) {
	return uvec_data_CowlObjectPtr(
		vec
	);
}


ulib_uint COWL_WRAP_uvec_size_CowlObjectPtr (
	UVec_CowlObjectPtr const * vec
) {
	return uvec_size_CowlObjectPtr(
		vec
	);
}


CowlObjectPtr COWL_WRAP_uvec_last_CowlObjectPtr (
	UVec_CowlObjectPtr const * vec
) {
	return uvec_last_CowlObjectPtr(
		vec
	);
}


UVec_CowlObjectPtr COWL_WRAP_uvec_get_range_CowlObjectPtr (
	UVec_CowlObjectPtr const * vec,
	ulib_uint start,
	ulib_uint len
) {
	return uvec_get_range_CowlObjectPtr(
		vec,
		start,
		len
	);
}


UVec_CowlObjectPtr COWL_WRAP_uvec_get_range_from_CowlObjectPtr (
	UVec_CowlObjectPtr const * vec,
	ulib_uint start
) {
	return uvec_get_range_from_CowlObjectPtr(
		vec,
		start
	);
}


void COWL_WRAP_uvec_deinit_CowlObjectPtr (
	UVec_CowlObjectPtr * vec
) {
	uvec_deinit_CowlObjectPtr(
		vec
	);
}


UVec_CowlObjectPtr COWL_WRAP_uvec_move_CowlObjectPtr (
	UVec_CowlObjectPtr * vec
) {
	return uvec_move_CowlObjectPtr(
		vec
	);
}


uvec_ret COWL_WRAP_uvec_expand_CowlObjectPtr (
	UVec_CowlObjectPtr * vec,
	ulib_uint size
) {
	return uvec_expand_CowlObjectPtr(
		vec,
		size
	);
}


uvec_ret COWL_WRAP_uvec_append_CowlObjectPtr (
	UVec_CowlObjectPtr * vec,
	UVec_CowlObjectPtr const * src
) {
	return uvec_append_CowlObjectPtr(
		vec,
		src
	);
}


uvec_ret COWL_WRAP_uvec_append_array_CowlObjectPtr (
	UVec_CowlObjectPtr * vec,
	CowlObjectPtr const * src,
	ulib_uint n
) {
	return uvec_append_array_CowlObjectPtr(
		vec,
		src,
		n
	);
}


bool COWL_WRAP_uvec_contains_CowlObjectPtr (
	UVec_CowlObjectPtr const * vec,
	CowlObjectPtr item
) {
	return uvec_contains_CowlObjectPtr(
		vec,
		item
	);
}

