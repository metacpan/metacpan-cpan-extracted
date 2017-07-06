/*
 *
 */

#ifndef CONVERT_H_
#define CONVERT_H_

#include "ps_parser.h"
#include "ps_parser_internal.h"

enum type_preference {
    PREFER_HASH,
    PREFER_ARRAY,
    PREFER_UNDEF
};

SV* _convert_recurse(const ps_node *, enum type_preference, const char *);

#endif /* CONVERT_H_ */

/* vim:set et ts=4 sw=4 syntax=c.doxygen: */

