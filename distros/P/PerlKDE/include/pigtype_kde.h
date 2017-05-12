#ifndef PIGTYPE_KDE_H
#define PIGTYPE_KDE_H

/*
 * Pig support for types required by PerlKDE
 *
 * Copyright (C) 2000, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README.LICENSE file which should be included with this library.
 *
 */

#include "pigfunc.h"
#include "pigtype.h"

PIG_DECLARE_TYPE(pig_type_kde_const_KPath_ptr)

PIGTYPE_ARGUMENT(pig_type_kde_const_KPath_ptr, const void *)

PIG_IMPORT_TABLE(pigtype_kde)
    PIG_IMPORT_TYPE(pig_type_kde_const_KPath_ptr, "KDE const KPath*")
PIG_IMPORT_ENDTABLE

#endif  // PIGTYPE_KDE_H
