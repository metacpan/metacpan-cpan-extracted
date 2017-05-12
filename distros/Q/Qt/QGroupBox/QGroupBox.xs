/*
 * PerlQt interface to qgrpbox.h
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#include "pgrpbox.h"
#include "pqt.h"

MODULE = QGroupBox		PACKAGE = QGroupBox

PROTOTYPES: ENABLE

PGroupBox *
PGroupBox::new(...)
    CASE: items == 1
	CODE:
	RETVAL = new PGroupBox();
	OUTPUT:
	RETVAL
    CASE: sv_isobject(ST(1))
	PREINIT:
	QWidget *parent = pextract(QWidget, 1);
	char *name = (items > 2) ? SvPV(ST(2), na) : 0;
	CODE:
	RETVAL = new PGroupBox(parent, name);
	OUTPUT:
	RETVAL
    CASE:
	PREINIT:
	char *title = SvPV(ST(1), na);
	QWidget *parent = (items > 2) ? pextract(QWidget, 2) : 0;
	char *name = (items > 3) ? SvPV(ST(3), na) : 0;
	CODE:
	RETVAL = new PGroupBox(title, parent, name);
	OUTPUT:
	RETVAL

int
QGroupBox::alignment()

void
QGroupBox::setAlignment(alignment)
    int alignment

void
QGroupBox::setTitle(title)
    char *title

const char *
QGroupBox::title()