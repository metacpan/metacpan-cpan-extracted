#include "cowl.h"

/*
 * DO NOT EDIT
 *
 * Generated via maint/tt/Class.c.tt
 */


bool COWL_WRAP_utime_equals (
	UTime const * a,
	UTime const * b
) {
	return utime_equals(
		a,
		b
	);
}


UString COWL_WRAP_utime_to_string (
	UTime const * time
) {
	return utime_to_string(
		time
	);
}


bool COWL_WRAP_utime_from_string (
	UTime * time,
	UString const * string
) {
	return utime_from_string(
		time,
		string
	);
}

