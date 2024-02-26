#include "cowl.h"

/*
 * DO NOT EDIT
 *
 * Generated via maint/tt/Class.c.tt
 */


ulib_uint COWL_WRAP_ustring_size (
	UString string
) {
	return ustring_size(
		string
	);
}


ulib_uint COWL_WRAP_ustring_length (
	UString string
) {
	return ustring_length(
		string
	);
}


UString COWL_WRAP_ustring_assign (
	char const * buf,
	size_t length
) {
	return ustring_assign(
		buf,
		length
	);
}


UString COWL_WRAP_ustring_copy (
	char const * buf,
	size_t length
) {
	return ustring_copy(
		buf,
		length
	);
}


UString COWL_WRAP_ustring_wrap (
	char const * buf,
	size_t length
) {
	return ustring_wrap(
		buf,
		length
	);
}


char * COWL_WRAP_ustring (
	UString * string,
	size_t length
) {
	return ustring(
		string,
		length
	);
}


UString COWL_WRAP_ustring_assign_buf (
	char const * buf
) {
	return ustring_assign_buf(
		buf
	);
}


UString COWL_WRAP_ustring_copy_buf (
	char const * buf
) {
	return ustring_copy_buf(
		buf
	);
}


UString COWL_WRAP_ustring_wrap_buf (
	char const * buf
) {
	return ustring_wrap_buf(
		buf
	);
}


UString COWL_WRAP_ustring_dup (
	UString string
) {
	return ustring_dup(
		string
	);
}


UString COWL_WRAP_ustring_concat (
	UString const * strings,
	ulib_uint count
) {
	return ustring_concat(
		strings,
		count
	);
}


UString COWL_WRAP_ustring_join (
	UString const * strings,
	ulib_uint count,
	UString sep
) {
	return ustring_join(
		strings,
		count,
		sep
	);
}


UString COWL_WRAP_ustring_repeating (
	UString string,
	ulib_uint times
) {
	return ustring_repeating(
		string,
		times
	);
}


bool COWL_WRAP_ustring_is_upper (
	UString string
) {
	return ustring_is_upper(
		string
	);
}


bool COWL_WRAP_ustring_is_lower (
	UString string
) {
	return ustring_is_lower(
		string
	);
}


UString COWL_WRAP_ustring_to_upper (
	UString string
) {
	return ustring_to_upper(
		string
	);
}


UString COWL_WRAP_ustring_to_lower (
	UString string
) {
	return ustring_to_lower(
		string
	);
}


ulib_uint COWL_WRAP_ustring_index_of (
	UString string,
	char needle
) {
	return ustring_index_of(
		string,
		needle
	);
}


ulib_uint COWL_WRAP_ustring_index_of_last (
	UString string,
	char needle
) {
	return ustring_index_of_last(
		string,
		needle
	);
}


ulib_uint COWL_WRAP_ustring_find (
	UString string,
	UString needle
) {
	return ustring_find(
		string,
		needle
	);
}


ulib_uint COWL_WRAP_ustring_find_last (
	UString string,
	UString needle
) {
	return ustring_find_last(
		string,
		needle
	);
}


bool COWL_WRAP_ustring_starts_with (
	UString string,
	UString prefix
) {
	return ustring_starts_with(
		string,
		prefix
	);
}


bool COWL_WRAP_ustring_ends_with (
	UString string,
	UString suffix
) {
	return ustring_ends_with(
		string,
		suffix
	);
}


bool COWL_WRAP_ustring_equals (
	UString lhs,
	UString rhs
) {
	return ustring_equals(
		lhs,
		rhs
	);
}


bool COWL_WRAP_ustring_precedes (
	UString lhs,
	UString rhs
) {
	return ustring_precedes(
		lhs,
		rhs
	);
}


int COWL_WRAP_ustring_compare (
	UString lhs,
	UString rhs
) {
	return ustring_compare(
		lhs,
		rhs
	);
}


ulib_uint COWL_WRAP_ustring_hash (
	UString string
) {
	return ustring_hash(
		string
	);
}


void COWL_WRAP_ustring_deinit (
	UString * string
) {
	ustring_deinit(
		string
	);
}


char * COWL_WRAP_ustring_deinit_return_data (
	UString * string
) {
	return ustring_deinit_return_data(
		string
	);
}


bool COWL_WRAP_ustring_is_null (
	UString string
) {
	return ustring_is_null(
		string
	);
}


bool COWL_WRAP_ustring_is_empty (
	UString string
) {
	return ustring_is_empty(
		string
	);
}

