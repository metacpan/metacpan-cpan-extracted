#ifndef PIGFUNC_BASE_H
#define PIGFUNC_BASE_H

/*
 * Integral functions for the operation of Pig.
 *
 * Copyright (C) 1999, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README.LICENSE file which should be included with this library.
 *
 */

#include "pigfunc.h"

PIG_DECLARE_VOID_FUNC_2(pig_begin, void *, const char *)
PIG_DECLARE_VOID_FUNC_2(pig_begin_virtual, const class pig_virtual *, const char *)
PIG_DECLARE_VOID_FUNC_0(pig_lastargument)
PIG_DECLARE_VOID_FUNC_0(pig_end)

PIG_DECLARE_FUNC_0(int, pig_argumentcount)
PIG_DECLARE_FUNC_1(unsigned int, pig_argument_info, int)

PIG_DECLARE_FUNC_2(int, pig_find_in_array, const char *, const char **)
PIG_DECLARE_VOID_FUNC_2(pig_ambiguous, const char *, const char *)

PIG_DECLARE_VOID_FUNC_2(pig_call_method, const class pig_virtual *, const char *)
PIG_DECLARE_VOID_FUNC_2(pig_call_retmethod, const class pig_virtual *, const char *)
PIG_DECLARE_VOID_FUNC_0(pig_return_nothing)

PIG_IMPORT_TABLE(pigfunc_base)
    PIG_IMPORT_FUNC(pig_begin)
    PIG_IMPORT_FUNC(pig_begin_virtual)
    PIG_IMPORT_FUNC(pig_lastargument)
    PIG_IMPORT_FUNC(pig_end)

    PIG_IMPORT_FUNC(pig_argumentcount)
    PIG_IMPORT_FUNC(pig_argument_info)

    PIG_IMPORT_FUNC(pig_find_in_array)
    PIG_IMPORT_FUNC(pig_ambiguous)

    PIG_IMPORT_FUNC(pig_call_method)
    PIG_IMPORT_FUNC(pig_call_retmethod)
    PIG_IMPORT_FUNC(pig_return_nothing)
PIG_IMPORT_ENDTABLE

#endif  // PIGFUNC_BASE_H
