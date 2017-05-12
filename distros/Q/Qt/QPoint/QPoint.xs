/*
 * PerlQt interface to qpoint.h
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#include "ppoint.h"

MODULE = QPoint		PACKAGE = QPoint

PROTOTYPES: ENABLE

PPoint *
PPoint::new(xpos = 0, ypos = 0)
    CASE: items == 1
	CODE:
	RETVAL = new PPoint();
	OUTPUT:
	RETVAL
    CASE: items > 2
	int xpos
	int ypos

bool
QPoint::isNull()

void
QPoint::setX(x)
    int x

void
QPoint::setY(y)
    int y

int
QPoint::x()

int
QPoint::y()
