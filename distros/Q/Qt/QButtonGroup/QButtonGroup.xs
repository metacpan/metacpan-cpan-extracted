/*
 * PerlQt interface to qbttngrp.h
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#include "pbttngrp.h"
#include "pqt.h"

MODULE = QButtonGroup		PACKAGE = QButtonGroup

PROTOTYPES: ENABLE

PButtonGroup *
PButtonGroup::new(...)
    CASE: items == 1
	CODE:
	RETVAL = new PButtonGroup();
	OUTPUT:
	RETVAL
    CASE: sv_isobject(ST(1))
	PREINIT:
	QWidget *parent = (QWidget *)pextract(QWidget, 1);
	char *name = (items > 2) ? SvPV(ST(2), na) : 0;
	CODE:
	RETVAL = new PButtonGroup(parent, name);
	OUTPUT:
	RETVAL
    CASE:
	PREINIT:
	char *title = SvPV(ST(1), na);
	QWidget *parent = (items > 2) ? (QWidget *)pextract(QWidget, 2) : 0;
	char *name = (items > 3) ? SvPV(ST(3), na) : 0;
	CODE:
	RETVAL = new PButtonGroup(title, parent, name);
	OUTPUT:
	RETVAL

QButton *
QButtonGroup::find(id)
    int id

int
QButtonGroup::insert(button, id = -1)
    QButton *button
    int id

bool
QButtonGroup::isExclusive()

void
QButtonGroup::remove(button)
    QButton *button

void
QButtonGroup::setExclusive(b)
    bool b
