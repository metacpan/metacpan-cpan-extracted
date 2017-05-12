/*
 * PerlQt interface to qchkbox.h
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#include "pchkbox.h"
#include "pqt.h"

MODULE = QCheckBox		PACKAGE = QCheckBox

PROTOTYPES: ENABLE

PCheckBox *
PCheckBox::new(...)
    CASE: items == 1
	CODE:
	RETVAL = new PCheckBox();
	OUTPUT:
	RETVAL
    CASE: sv_isobject(ST(1))
	PREINIT:
	QWidget *parent = pextract(QWidget, 1);
	char *name = (items > 2) ? SvPV(ST(2), na) : 0;
	CODE:
	RETVAL = new PCheckBox(parent, name);
	OUTPUT:
	RETVAL
    CASE: items > 2
	PREINIT:
	char *text = SvPV(ST(1), na);
	QWidget *parent = pextract(QWidget, 2);
	char *name = (items > 3) ? SvPV(ST(3), na) : 0;
	CODE:
	RETVAL = new PCheckBox(text, parent, name);
	OUTPUT:
	RETVAL

bool
QCheckBox::isChecked()

void
QCheckBox::setChecked(check)
    bool check