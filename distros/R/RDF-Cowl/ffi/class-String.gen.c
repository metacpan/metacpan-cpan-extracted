#include "cowl.h"

/*
 * DO NOT EDIT
 *
 * Generated via maint/tt/Class.c.tt
 */


CowlString * COWL_WRAP_cowl_string (
	UString string
) {
	return cowl_string(
		string
	);
}


CowlString * COWL_WRAP_cowl_string_opt (
	UString string,
	CowlStringOpts opts
) {
	return cowl_string_opt(
		string,
		opts
	);
}


CowlString * COWL_WRAP_cowl_string_empty (
) {
	return cowl_string_empty(
	);
}


CowlString * COWL_WRAP_cowl_string_intern (
	CowlString * string
) {
	return cowl_string_intern(
		string
	);
}


char * COWL_WRAP_cowl_string_release_copying_cstring (
	CowlString * string
) {
	return cowl_string_release_copying_cstring(
		string
	);
}


char const * COWL_WRAP_cowl_string_get_cstring (
	CowlString * string
) {
	return cowl_string_get_cstring(
		string
	);
}


ulib_uint COWL_WRAP_cowl_string_get_length (
	CowlString * string
) {
	return cowl_string_get_length(
		string
	);
}


UString const * COWL_WRAP_cowl_string_get_raw (
	CowlString * string
) {
	return cowl_string_get_raw(
		string
	);
}


CowlString * COWL_WRAP_cowl_string_concat (
	CowlString * lhs,
	CowlString * rhs
) {
	return cowl_string_concat(
		lhs,
		rhs
	);
}

