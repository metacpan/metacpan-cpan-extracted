/*
 * PerlQt interface to qpushbt.h
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#include "ppushbt.h"

MODULE = QPushButton		PACKAGE = QPushButton		

PROTOTYPES: ENABLE

PPushButton *
PPushButton::new(...)
    CASE: items == 1 || sv_isobject(ST(1))
	PREINIT:
	QWidget *parent = (items > 1) ?
	    (QWidget *)extract_ptr(ST(1), "QWidget") : 0;
        char *name = (items > 2) ? SvPV(ST(2), na) : 0;
	CODE:
	RETVAL = new PPushButton(parent, name);
	OUTPUT:
	RETVAL
    CASE:
	PREINIT:
	char *text = SvPV(ST(1), na);
	QWidget *parent = (items > 2) ?
	    (QWidget *)extract_ptr(ST(2), "QWidget") : 0;
	char *name = (items > 3) ? SvPV(ST(2), na) : 0;
	CODE:
	RETVAL = new PPushButton(text, parent, name);
	OUTPUT:
	RETVAL

bool
QPushButton::autoDefault()

bool
QPushButton::isDefault()

void
QPushButton::setAutoDefault(autoDef)
    bool autoDef

void
QPushButton::setDefault(def)
    bool def
