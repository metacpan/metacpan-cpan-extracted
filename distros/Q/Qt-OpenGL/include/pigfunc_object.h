#ifndef PIGFUNC_OBJECT_H
#define PIGFUNC_OBJECT_H

/*
 * Support functions for the object data-types for Pig
 *
 * Copyright (C) 1999, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README.LICENSE file which should be included with this library.
 *
 */

#include "pigfunc.h"

PIG_DECLARE_VOID_FUNC_0(pig_object_break);
PIG_DECLARE_VOID_FUNC_0(pig_object_continue);
PIG_DECLARE_FUNC_0(bool, pig_object_can_delete)
PIG_DECLARE_VOID_FUNC_2(pig_object_destroy, void *, class pig_virtual *)
PIG_DECLARE_FUNC_2(int, pig_object_isa, int, const char *)

PIG_IMPORT_TABLE(pigfunc_object)
    PIG_IMPORT_FUNC(pig_object_break)
    PIG_IMPORT_FUNC(pig_object_continue)
    PIG_IMPORT_FUNC(pig_object_can_delete)
    PIG_IMPORT_FUNC(pig_object_destroy)
    PIG_IMPORT_FUNC(pig_object_isa)
PIG_IMPORT_ENDTABLE

#endif  // PIGFUNC_OBJECT_H
