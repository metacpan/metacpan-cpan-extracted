#include "cowl.h"

/*
 * DO NOT EDIT
 *
 * Generated via maint/tt/Class.c.tt
 */


ustream_ret COWL_WRAP_uostream_deinit (
	UOStream * stream
) {
	return uostream_deinit(
		stream
	);
}


ustream_ret COWL_WRAP_uostream_flush (
	UOStream * stream
) {
	return uostream_flush(
		stream
	);
}


UOStream * COWL_WRAP_uostream_std (
) {
	return uostream_std(
	);
}


UOStream * COWL_WRAP_uostream_stderr (
) {
	return uostream_stderr(
	);
}


UOStream * COWL_WRAP_uostream_null (
) {
	return uostream_null(
	);
}


ustream_ret COWL_WRAP_uostream_to_path (
	UOStream * stream,
	char const * path
) {
	return uostream_to_path(
		stream,
		path
	);
}


ustream_ret COWL_WRAP_uostream_to_file (
	UOStream * stream,
	FILE * file
) {
	return uostream_to_file(
		stream,
		file
	);
}


ustream_ret COWL_WRAP_uostream_to_strbuf (
	UOStream * stream,
	UStrBuf * buf
) {
	return uostream_to_strbuf(
		stream,
		buf
	);
}


ustream_ret COWL_WRAP_uostream_to_multi (
	UOStream * stream
) {
	return uostream_to_multi(
		stream
	);
}


ustream_ret COWL_WRAP_uostream_add_substream (
	UOStream * stream,
	UOStream const * other
) {
	return uostream_add_substream(
		stream,
		other
	);
}

