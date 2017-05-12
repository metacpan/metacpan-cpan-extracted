/*
 * The global import symbol-table for PerlQt
 *
 * Copyright (C) 1999, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README.LICENSE file which should be included with this library.
 *
 */

#define PIGPTR_DEFINITION
#include "pig.h"
#include "pig_import_KDE.h"
#include "pigclassinfo.h"
#include "pigconstant.h"
#include "pigfunc_base.h"
#include "pigfunc_object.h"
#include "pigfunc_qt.h"
#include "pigperl.h"
#include "pigtype_base.h"
#include "pigtype_kde.h"
#include "pigtype_object.h"
#include "pigtype_qt.h"
#include "pigvirtual.h"

PIG_GLOBAL_IMPORT_TABLE(pig)
    PIG_IMPORT_SUBTABLE(PIG_KDE)
    PIG_IMPORT_SUBTABLE(pigclassinfo)
    PIG_IMPORT_SUBTABLE(pigconstant)
    PIG_IMPORT_SUBTABLE(pigfunc_base)
    PIG_IMPORT_SUBTABLE(pigfunc_object)
    PIG_IMPORT_SUBTABLE(pigperl)
    PIG_IMPORT_SUBTABLE(pigtype_base)
    PIG_IMPORT_SUBTABLE(pigtype_object)
    PIG_IMPORT_SUBTABLE(pigvirtual)

    PIG_IMPORT_SUBTABLE(pigfunc_qt)
    PIG_IMPORT_SUBTABLE(pigtype_qt)

    PIG_IMPORT_SUBTABLE(pigtype_kde)
PIG_IMPORT_ENDTABLE
