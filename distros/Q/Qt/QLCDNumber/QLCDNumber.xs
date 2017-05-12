/*
 * PerlQt interface to qlcdnum.h
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#include "plcdnum.h"

MODULE = QLCDNumber		PACKAGE = QLCDNumber

PROTOTYPES: ENABLE

PLCDNumber *
PLCDNumber::new(...)
    CASE: items == 1 || sv_isobject(ST(1))
	PREINIT:
	QWidget *parent = (items > 1) ?
	    (QWidget *)extract_ptr(ST(1), "QWidget") : 0;
	const char *name = (items > 2) ? SvPV(ST(2), na) : 0;
	CODE:
	RETVAL = new PLCDNumber(parent, name);
	OUTPUT:
	RETVAL
    CASE:
	PREINIT:
	uint numDigits = SvIV(ST(1));
	QWidget *parent = (items > 2) ?
	    (QWidget *)extract_ptr(ST(2), "QWidget") : 0;
	const char *name = (items > 3) ? SvPV(ST(3), na) : 0;
	CODE:
	RETVAL = new PLCDNumber(numDigits, parent, name);
	OUTPUT:
	RETVAL

bool
QLCDNumber::checkOverflow(num)
    CASE: SvIOK(ST(1))
	int num
    CASE:
	double num

void
QLCDNumber::display(value)
    CASE: SvIOK(ST(1))
	int value
    CASE: SvNOK(ST(1))
	double value
    CASE:
	char *value

int
QLCDNumber::intValue()

QLCDNumber::Mode
QLCDNumber::mode()

int
QLCDNumber::numDigits()

void
QLCDNumber::setBinMode()

void
QLCDNumber::setDecMode()

void
QLCDNumber::setHexMode()

void
QLCDNumber::setMode(mode)
    QLCDNumber::Mode mode

void
QLCDNumber::setNumDigits(nDigits)
    int nDigits

void
QLCDNumber::setOctMode()

void
QLCDNumber::setSmallDecimalPoint(b)
    bool b

bool
QLCDNumber::smallDecimalPoint()

double
QLCDNumber::value()