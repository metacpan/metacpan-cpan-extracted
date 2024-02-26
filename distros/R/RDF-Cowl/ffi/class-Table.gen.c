#include "cowl.h"

/*
 * DO NOT EDIT
 *
 * Generated via maint/tt/Class.c.tt
 */


CowlTable * COWL_WRAP_cowl_table (
	UHash(CowlObjectTable) * table
) {
	return cowl_table(
		table
	);
}


UHash(CowlObjectTable) const * COWL_WRAP_cowl_table_get_data (
	CowlTable * table
) {
	return cowl_table_get_data(
		table
	);
}


ulib_uint COWL_WRAP_cowl_table_count (
	CowlTable * table
) {
	return cowl_table_count(
		table
	);
}


CowlAny * COWL_WRAP_cowl_table_get_value (
	CowlTable * table,
	CowlAny * key
) {
	return cowl_table_get_value(
		table,
		key
	);
}


CowlAny * COWL_WRAP_cowl_table_get_any (
	CowlTable * table
) {
	return cowl_table_get_any(
		table
	);
}


bool COWL_WRAP_cowl_table_contains (
	CowlTable * table,
	CowlAny * key
) {
	return cowl_table_contains(
		table,
		key
	);
}

