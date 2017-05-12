/*
 * PerlQt interface to qrangect.h
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#include "prangect.h"

MODULE = QRangeControl		PACKAGE = QRangeControl

PROTOTYPES: ENABLE

PRangeControl *
PRangeControl::new(...)
    CASE: items == 1
	CODE:
	RETVAL = new PRangeControl();
    CASE: items > 5
	PREINIT:
	int minValue = SvIV(ST(1));
	int maxValue = SvIV(ST(2));
	int lineStep = SvIV(ST(3));
	int pageStep = SvIV(ST(4));
	int value = SvIV(ST(5));
	CODE:
	RETVAL =
	    new PRangeControl(minValue, maxValue, lineStep, pageStep, value);
    CASE:
	CODE:
	croak("Usage: new %s;\nUsage: new %s(minValue, maxValue, lineStep, pageStep, value);", CLASS, CLASS);

void
QRangeControl::addLine()

void
QRangeControl::addPage()

int
QRangeControl::lineStep()

int
QRangeControl::maxValue()

int
QRangeControl::minValue()

int
QRangeControl::pageStep()

void
QRangeControl::setRange(minValue, maxValue)
    int minValue
    int maxValue

void
QRangeControl::setSteps(line, page)
    int line
    int page

void
QRangeControl::setValue(value)
    int value

void
QRangeControl::subtractLine()

void
QRangeControl::subtractPage()

int
QRangeControl::value()