#ifndef PIGTYPE_BASE_H
#define PIGTYPE_BASE_H

/*
 * Pig support for the basic C++ types
 *
 * Copyright (C) 1999, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README.LICENSE file which should be included with this library.
 *
 */

#include "pigtype.h"

PIG_DECLARE_TYPE(pig_type_bool)
PIG_DECLARE_TYPE(pig_type_char)
PIG_DECLARE_TYPE(pig_type_cstring)
PIG_DECLARE_TYPE(pig_type_double)
PIG_DECLARE_TYPE(pig_type_long_double)
PIG_DECLARE_TYPE(pig_type_enum)
PIG_DECLARE_TYPE(pig_type_float)
PIG_DECLARE_TYPE(pig_type_int)
PIG_DECLARE_TYPE(pig_type_long)
PIG_DECLARE_TYPE(pig_type_short)
PIG_DECLARE_TYPE(pig_type_uint)
PIG_DECLARE_TYPE(pig_type_ptr)
PIG_DECLARE_TYPE(pig_type_boolptr)
PIG_DECLARE_TYPE(pig_type_floatptr)
PIG_DECLARE_TYPE(pig_type_doubleptr);
PIG_DECLARE_TYPE(pig_type_intptr)
PIG_DECLARE_TYPE(pig_type_intref)

PIG_DECLARE_TYPE(pig_type_intarray)
PIG_DECLARE_TYPE(pig_type_shortarray)
PIG_DECLARE_TYPE(pig_type_intarrayitems)
PIG_DECLARE_TYPE(pig_type_shortarrayitems)

PIGTYPE_ALL(pig_type_bool, bool)
PIGTYPE_ALL(pig_type_char, char)
PIGTYPE_ALL(pig_type_cstring, const char *)
PIGTYPE_ALL(pig_type_double, double)
PIGTYPE_ALL(pig_type_long_double, long double)
PIGTYPE_ALL(pig_type_enum, int)
PIGTYPE_ALL(pig_type_float, float)
PIGTYPE_ALL(pig_type_int, int)
PIGTYPE_ALL(pig_type_long, long)
PIGTYPE_ALL(pig_type_short, short)
PIGTYPE_ALL(pig_type_uint, unsigned int)
PIGTYPE_ALL(pig_type_ptr, void *)
PIGTYPE_ALL(pig_type_boolptr, bool *)
PIGTYPE_ALL(pig_type_floatptr, float *)
PIGTYPE_ALL(pig_type_doubleptr, double *)
PIGTYPE_ALL(pig_type_intptr, int *)
PIGTYPE_ALL(pig_type_intref, int &)

PIGTYPE_ALL(pig_type_intarray, int *)
PIGTYPE_ALL(pig_type_shortarray, short *)
PIGTYPE_ARGUMENT2(pig_type_intarrayitems, int, int)
PIGTYPE_ARGUMENT2(pig_type_shortarrayitems, int, int)

#define pig_type_internal_defargument(x) x

PIG_IMPORT_TABLE(pigtype_base)
    PIG_IMPORT_TYPE(pig_type_bool, "bool")
    PIG_IMPORT_TYPE(pig_type_char, "char")
    PIG_IMPORT_TYPE(pig_type_cstring, "const char*")
    PIG_IMPORT_TYPE(pig_type_double, "double")
    PIG_IMPORT_TYPE(pig_type_long_double, "long double")
    PIG_IMPORT_TYPE(pig_type_enum, "enum")
    PIG_IMPORT_TYPE(pig_type_float, "float")
    PIG_IMPORT_TYPE(pig_type_int, "int")
    PIG_IMPORT_TYPE(pig_type_long, "long")
    PIG_IMPORT_TYPE(pig_type_short, "short")
    PIG_IMPORT_TYPE(pig_type_uint, "uint")
    PIG_IMPORT_TYPE(pig_type_ptr, "*")
    PIG_IMPORT_TYPE(pig_type_boolptr, "bool*")
    PIG_IMPORT_TYPE(pig_type_floatptr, "float*")
    PIG_IMPORT_TYPE(pig_type_doubleptr, "double*")
    PIG_IMPORT_TYPE(pig_type_intptr, "int*")
    PIG_IMPORT_TYPE(pig_type_intref, "int&")
    PIG_IMPORT_TYPE(pig_type_intarray, "int[]")
    PIG_IMPORT_TYPE(pig_type_shortarray, "short[]")
    PIG_IMPORT_TYPE(pig_type_intarrayitems, "sizeof(int[])")
    PIG_IMPORT_TYPE(pig_type_shortarrayitems, "sizeof(short[])")
PIG_IMPORT_ENDTABLE

#endif  // PIGTYPE_BASE_H
