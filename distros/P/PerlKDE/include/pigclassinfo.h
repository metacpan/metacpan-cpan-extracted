#ifndef PIGCLASSINFO_H
#define PIGCLASSINFO_H

/*
 * Functions for processing pig_classinfo structure arrays
 *
 * Copyright (C) 1999, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README.LICENSE file which should be included with this library.
 *
 */

#include "pig.h"
#include "pigfunc.h"

PIG_DECLARE_VOID_FUNC_2(pig_load_methods, const char *, pig_method *)
PIG_DECLARE_VOID_FUNC_2(pig_load_isa, const char *, const char **)
PIG_DECLARE_VOID_FUNC_1(pig_load_classinfo, pig_classinfo *)
PIG_DECLARE_VOID_FUNC_2(pig_classinfo_store, const char *, struct pig_classinfo *)
PIG_DECLARE_FUNC_1(struct pig_classinfo *, pig_classinfo_fetch, const char *)
PIG_DECLARE_FUNC_1(const char *, pig_map_class, const char *)
PIG_DECLARE_FUNC_1(const char *, pig_unmap_class, const char *)

PIG_IMPORT_TABLE(pigclassinfo)
    PIG_IMPORT_FUNC(pig_load_methods)
    PIG_IMPORT_FUNC(pig_load_isa)
    PIG_IMPORT_FUNC(pig_load_classinfo)
    PIG_IMPORT_FUNC(pig_classinfo_store)
    PIG_IMPORT_FUNC(pig_classinfo_fetch)
    PIG_IMPORT_FUNC(pig_map_class)
    PIG_IMPORT_FUNC(pig_unmap_class)
PIG_IMPORT_ENDTABLE

#define pig_classinfo_hv PIG_VARIABLE(pig_classinfo_hv)
#define pig_classmap_hv PIG_VARIABLE(pig_classmap_hv)
#define pig_classunmap_hv PIG_VARIABLE(pig_classunmap_hv)

#endif  // PIGCLASSINFO_H
