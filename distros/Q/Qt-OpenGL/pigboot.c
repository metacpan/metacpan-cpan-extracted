/*
 * Bootstrap for PerlKDE
 *
 * Copyright (C) 2000, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README.LICENSE file which should be included with this library.
 *
 */

#include "pigperl.h"
#include "pigsymbol.h"
#include "pigclassinfo.h"
#include "pigconstant.h"

PIG_DECLARE_IMPORT_TABLE(pig)
PIG_DECLARE_EXPORT_TABLE(PIG_QGL)

PIG_GLOBAL_EXPORT_TABLE(pig)
    PIG_EXPORT_SUBTABLE(PIG_QGL)
PIG_EXPORT_ENDTABLE

extern struct pig_constant PIG_constant_QGL[];
extern struct pig_classinfo PIG_module[];

extern "C" XS(boot_Qt__OpenGL) {
    dXSARGS;

    pig_symbol_exchange(PIG_EXPORTTABLE(pig), PIG_IMPORTTABLE(pig),
			"Qt::OpenGL", "Qt");
    pig_load_classinfo(PIG_module);
    pig_load_constants("Qt::OpenGL", PIG_constant_QGL);

    XSRETURN_UNDEF;
}
