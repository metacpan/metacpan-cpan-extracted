/*
 *
 */

#ifndef CONVERT_H_
#define CONVERT_H_

#include "ps_parser.h"
#include "ps_parser_internal.h"

#define PS_XS_PREFER_HASH  1
#define PS_XS_PREFER_ARRAY 2
#define PS_XS_PREFER_UNDEF 4

SV* _convert_recurse(const ps_node *, int, const char *);

#endif /* CONVERT_H_ */

/* vim:set et ts=4 sw=4 syntax=c.doxygen: */

