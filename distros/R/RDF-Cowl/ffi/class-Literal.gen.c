#include "cowl.h"

/*
 * DO NOT EDIT
 *
 * Generated via maint/tt/Class.c.tt
 */


CowlLiteral * COWL_WRAP_cowl_literal (
	CowlDatatype * dt,
	CowlString * value,
	CowlString * lang
) {
	return cowl_literal(
		dt,
		value,
		lang
	);
}


CowlLiteral * COWL_WRAP_cowl_literal_from_string (
	UString dt,
	UString value,
	UString lang
) {
	return cowl_literal_from_string(
		dt,
		value,
		lang
	);
}


CowlDatatype * COWL_WRAP_cowl_literal_get_datatype (
	CowlLiteral * literal
) {
	return cowl_literal_get_datatype(
		literal
	);
}


CowlString * COWL_WRAP_cowl_literal_get_value (
	CowlLiteral * literal
) {
	return cowl_literal_get_value(
		literal
	);
}


CowlString * COWL_WRAP_cowl_literal_get_lang (
	CowlLiteral * literal
) {
	return cowl_literal_get_lang(
		literal
	);
}

