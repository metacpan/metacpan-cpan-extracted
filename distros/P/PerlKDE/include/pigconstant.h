#ifndef PIGCONSTANT_H
#define PIGCONSTANT_H

/*
 * Functions for progressing constants in pig_constant structures
 *
 * Copyright (C) 1999, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README.LICENSE file which should be included with this library.
 *
 */

#include "pig.h"
#include "pigfunc.h"

PIG_DECLARE_VOID_FUNC_2(pig_load_constants, const char *, pig_constant *)

PIG_IMPORT_TABLE(pigconstant)
    PIG_IMPORT_FUNC(pig_load_constants)
PIG_IMPORT_ENDTABLE

#endif  // PIGCONSTANT_H
