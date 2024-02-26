#include "cowl.h"

/*
 * DO NOT EDIT
 *
 * Generated via maint/tt/Class.c.tt
 */


CowlTable * COWL_WRAP_cowl_sym_table_get_prefix_ns_map (
	CowlSymTable * st,
	bool reverse
) {
	return cowl_sym_table_get_prefix_ns_map(
		st,
		reverse
	);
}


CowlString * COWL_WRAP_cowl_sym_table_get_ns (
	CowlSymTable * st,
	CowlString * prefix
) {
	return cowl_sym_table_get_ns(
		st,
		prefix
	);
}


CowlString * COWL_WRAP_cowl_sym_table_get_prefix (
	CowlSymTable * st,
	CowlString * ns
) {
	return cowl_sym_table_get_prefix(
		st,
		ns
	);
}


cowl_ret COWL_WRAP_cowl_sym_table_register_prefix (
	CowlSymTable * st,
	CowlString * prefix,
	CowlString * ns,
	bool overwrite
) {
	return cowl_sym_table_register_prefix(
		st,
		prefix,
		ns,
		overwrite
	);
}


cowl_ret COWL_WRAP_cowl_sym_table_register_prefix_raw (
	CowlSymTable * st,
	UString prefix,
	UString ns,
	bool overwrite
) {
	return cowl_sym_table_register_prefix_raw(
		st,
		prefix,
		ns,
		overwrite
	);
}


cowl_ret COWL_WRAP_cowl_sym_table_unregister_prefix (
	CowlSymTable * st,
	CowlString * prefix
) {
	return cowl_sym_table_unregister_prefix(
		st,
		prefix
	);
}


cowl_ret COWL_WRAP_cowl_sym_table_unregister_ns (
	CowlSymTable * st,
	CowlString * ns
) {
	return cowl_sym_table_unregister_ns(
		st,
		ns
	);
}


cowl_ret COWL_WRAP_cowl_sym_table_merge (
	CowlSymTable * dst,
	CowlSymTable * src,
	bool overwrite
) {
	return cowl_sym_table_merge(
		dst,
		src,
		overwrite
	);
}


CowlIRI * COWL_WRAP_cowl_sym_table_get_full_iri (
	CowlSymTable * st,
	UString ns,
	UString rem
) {
	return cowl_sym_table_get_full_iri(
		st,
		ns,
		rem
	);
}


CowlIRI * COWL_WRAP_cowl_sym_table_parse_full_iri (
	CowlSymTable * st,
	UString short_iri
) {
	return cowl_sym_table_parse_full_iri(
		st,
		short_iri
	);
}

