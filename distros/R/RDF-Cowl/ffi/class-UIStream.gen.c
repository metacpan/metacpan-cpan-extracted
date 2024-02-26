#include "cowl.h"

/*
 * DO NOT EDIT
 *
 * Generated via maint/tt/Class.c.tt
 */


ustream_ret COWL_WRAP_uistream_deinit (
	UIStream * stream
) {
	return uistream_deinit(
		stream
	);
}


ustream_ret COWL_WRAP_uistream_reset (
	UIStream * stream
) {
	return uistream_reset(
		stream
	);
}


UIStream * COWL_WRAP_uistream_std (
) {
	return uistream_std(
	);
}


ustream_ret COWL_WRAP_uistream_from_path (
	UIStream * stream,
	char const * path
) {
	return uistream_from_path(
		stream,
		path
	);
}


ustream_ret COWL_WRAP_uistream_from_file (
	UIStream * stream,
	FILE * file
) {
	return uistream_from_file(
		stream,
		file
	);
}


ustream_ret COWL_WRAP_uistream_from_strbuf (
	UIStream * stream,
	UStrBuf const * buf
) {
	return uistream_from_strbuf(
		stream,
		buf
	);
}


ustream_ret COWL_WRAP_uistream_from_string (
	UIStream * stream,
	char const * string
) {
	return uistream_from_string(
		stream,
		string
	);
}


ustream_ret COWL_WRAP_uistream_from_ustring (
	UIStream * stream,
	UString const * string
) {
	return uistream_from_ustring(
		stream,
		string
	);
}

