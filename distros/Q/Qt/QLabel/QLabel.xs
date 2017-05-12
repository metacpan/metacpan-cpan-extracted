/*
 * PerlQt interface to qlabel.h
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#include "plabel.h"

MODULE = QLabel		PACKAGE = QLabel

PROTOTYPES: ENABLE

PLabel *
PLabel::new(...)
    CASE: items == 1
	CODE:
	RETVAL = new PLabel();
	OUTPUT:
	RETVAL
    CASE: sv_isobject(ST(1))
	PREINIT:
	QWidget *parent = (QWidget *)extract_ptr(ST(1), "QWidget");
	char *name = (items > 2) ? SvPV(ST(2), na) : 0;
	WFlags f = (items > 3) ? (WFlags)SvIV(ST(3)) : 0;
	CODE:
	RETVAL = new PLabel(parent, name, f);
	OUTPUT:
	RETVAL
    CASE:
	PREINIT:
	char *text = SvPV(ST(1), na);
	QWidget *parent = (items > 2) ?
	    (QWidget *)extract_ptr(ST(2), "QWidget") : 0;
	char *name = (items > 3) ? SvPV(ST(3), na) : 0;
	WFlags f = (items > 4) ? (WFlags)SvIV(ST(4)) : 0;
	CODE:
	RETVAL = new PLabel(text, parent, name, f);
	OUTPUT:
	RETVAL

int
QLabel::alignment()

bool
QLabel::autoResize()

QWidget *
QLabel::buddy()

int
QLabel::margin()

QPixmap *
QLabel::pixmap()

void
QLabel::setAlignment(alignment)
    int alignment

void
QLabel::setAutoResize(b)
    bool b

void
QLabel::setBuddy(buddy)
    QWidget *buddy

void
QLabel::setMargin(margin)
    int margin

void
QLabel::setNum(num)
    CASE: SvIOK(ST(1))
	int num
	CODE:
	THIS->setNum(num);
    CASE:
	double num
	CODE:
	THIS->setNum(num);

void
QLabel::setPixmap(pixmap)
    QPixmap *pixmap
    CODE:
    THIS->setPixmap(*pixmap);

void
QLabel::setText(text)
    char *text

const char *
QLabel::text()
