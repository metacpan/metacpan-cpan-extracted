/*
 * PerlQt interface to qscrbar.h
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#include "pscrbar.h"

#define STORE_key(key) enumIV(hv, MSTR(key), QScrollBar::key)

inline HV *init_Orientation(HV *hv) {
    register SV **svp = NULL;

    STORE_key(Horizontal);
    STORE_key(Vertical);

    return hv;
}

inline void load_enum() {
    SvREADONLY_on(init_Orientation(perl_get_hv("QScrollBar::Orientation",
					       TRUE | GV_ADDMULTI)));
}

MODULE = QScrollBar		PACKAGE = QScrollBar

PROTOTYPES: ENABLE

BOOT:
    load_enum();

PScrollBar *
PScrollBar::new(...)
    CASE: items == 1
	CODE:
	RETVAL = new PScrollBar();
	OUTPUT:
	RETVAL
	    CASE: items < 4 && sv_isobject(ST(1))
	PREINIT:
	QWidget *parent = (QWidget *)extract_ptr(ST(1), "QWidget");
	const char *name = (items > 2) ? SvPV(ST(2), na) : 0;
	CODE:
	RETVAL = new PScrollBar(parent, name);
	OUTPUT:
	RETVAL
    CASE: items < 5 && sv_isobject(ST(2))
	PREINIT:
	QScrollBar::Orientation orientation =
	    (QScrollBar::Orientation) SvIV(ST(1));
	QWidget *parent = (items > 2) ?
	    (QWidget *)extract_ptr(ST(2), "QWidget") : 0;
	const char *name = (items > 3) ? SvPV(ST(3), na) : 0;
	CODE:
	RETVAL = new PScrollBar(orientation, parent, name);
	OUTPUT:
	RETVAL
    CASE: items > 6
	PREINIT:
	int minValue = SvIV(ST(1));
	int maxValue = SvIV(ST(2));
	int LineStep = SvIV(ST(3));
	int PageStep = SvIV(ST(4));
	int value = SvIV(ST(5));
	QScrollBar::Orientation orientation =
	    (QScrollBar::Orientation) SvIV(ST(6));
	QWidget *parent = (items > 7) ?
	    (QWidget *)extract_ptr(ST(7), "QWidget") : 0;
	const char *name = (items > 8) ? SvPV(ST(8), na) : 0;
	CODE:
	RETVAL = new PScrollBar(minValue, maxValue, LineStep, PageStep, value,
				orientation, parent, name);
	OUTPUT:
	RETVAL
    CASE:
	CODE:
	croak("Usage: new %s(QWidget = undef, name = undef);\nUsage: new %s(orientation, QWidget = undef, name = undef);\nUsage: new %s(minValue, maxValue, LineStep, PageStep, value, orientation, QWidget = undef, name = undef);", CLASS, CLASS, CLASS);

QScrollBar::Orientation
QScrollBar::orientation()

void
QScrollBar::setOrientation(orientation)
    QScrollBar::Orientation orientation

void
QScrollBar::setRange(minValue, maxValue)
    int minValue
    int maxValue

void
QScrollBar::setTracking(enable)
    bool enable

void
QScrollBar::setValue(value)
    int value

bool
QScrollBar::tracking()