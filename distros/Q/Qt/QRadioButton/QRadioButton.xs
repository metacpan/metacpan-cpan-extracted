/*
 * PerlQt interface to qradiobt.h
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#include "pradiobt.h"
#include "pqt.h"

MODULE = QRadioButton		PACKAGE = QRadioButton

PROTOTYPES: ENABLE

PRadioButton *
PRadioButton::new(...)
    CASE: items == 1
	CODE:
	RETVAL = new PRadioButton();
	OUTPUT:
	RETVAL
    CASE: sv_isobject(ST(1))
	PREINIT:
	QWidget *parent = pextract(QWidget, 1);
	char *name = (items > 2) ? SvPV(ST(2), na) : 0;
	CODE:
	RETVAL = new PRadioButton(parent, name);
	OUTPUT:
	RETVAL
    CASE:
	PREINIT:
	char *text = SvPV(ST(1), na);
	QWidget *parent = (items > 2) ? pextract(QWidget, 2) : 0;
	char *name = (items > 3) ? SvPV(ST(3), na) : 0;
	CODE:
	RETVAL = new PRadioButton(text, parent, name);
	OUTPUT:
	RETVAL

bool
QRadioButton::isChecked()

void
QRadioButton::setChecked(b)
    bool b
