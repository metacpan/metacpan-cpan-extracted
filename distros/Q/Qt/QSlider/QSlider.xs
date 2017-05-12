/*
 * PerlQt interface to qslider.h
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#include "pslider.h"
#include "prect.h"
#include "pqt.h"
#include "enum.h"

#define STORE_key(key) enumIV(hv, MSTR(key), QSlider::key)
#define STORE_keys(key, copy) enum2IV(hv, MSTR(key), MSTR(copy), QSlider::copy)

inline void init_enum() {
    HV *hv = perl_get_hv("QSlider::Orientation", TRUE | GV_ADDMULTI);

    STORE_key(Horizontal);
    STORE_key(Vertical);

    hv = perl_get_hv("QSlider::TickSetting", TRUE | GV_ADDMULTI);

    STORE_key(NoMarks);
    STORE_keys(Above, Left);
    STORE_keys(Below, Right);
    STORE_key(Both);
}

MODULE = QSlider		PACKAGE = QSlider

PROTOTYPES: ENABLE

BOOT:
    init_enum();

PSlider *
PSlider::new(...)
    CASE: items == 1
	CODE:
	RETVAL = new PSlider();
	OUTPUT:
	RETVAL
    CASE: items < 4 && sv_isobject(ST(1))
	PREINIT:
	QWidget *parent = (QWidget *)extract_ptr(ST(1), "QWidget");
	const char *name = (items > 2) ? SvPV(ST(2), na) : 0;
	CODE:
	RETVAL = new PSlider(parent, name);
	OUTPUT:
	RETVAL
    CASE: items < 5 && sv_isobject(ST(2))
	PREINIT:
	QSlider::Orientation orientation =
	    (QSlider::Orientation) SvIV(ST(1));
	QWidget *parent = (items > 2) ?
	    (QWidget *)extract_ptr(ST(2), "QWidget") : 0;
	const char *name = (items > 3) ? SvPV(ST(3), na) : 0;
	CODE:
	RETVAL = new PSlider(orientation, parent, name);
	OUTPUT:
	RETVAL
    CASE: items > 6
	PREINIT:
	int minValue = SvIV(ST(1));
	int maxValue = SvIV(ST(2));
	int step = SvIV(ST(3));
	int value = SvIV(ST(4));
	QSlider::Orientation orientation =
	    (QSlider::Orientation) SvIV(ST(5));
	QWidget *parent = (items > 6) ? pextract(QWidget, 6) : 0;
	const char *name = (items > 7) ? SvPV(ST(7), na) : 0;
	CODE:
	RETVAL = new PSlider(minValue, maxValue, step, value, orientation,
			     parent, name);
	OUTPUT:
	RETVAL

void
QSlider::addStep()

QSlider::Orientation
QSlider::orientation()

void
QSlider::setOrientation(orientation)
    QSlider::Orientation orientation

void
QSlider::setTickmarks(s)
    QSlider::TickSetting s

void
QSlider::setTracking(enable)
    bool enable

void
QSlider::setValue(value)
    int value

PRect *
QSlider::sliderRect()
    CODE:
    RETVAL = new PRect(THIS->sliderRect());
    OUTPUT:
    RETVAL

void
QSlider::subtractStep()

int
QSlider::tickInterval()

QSlider::TickSetting
QSlider::tickmarks()

bool
QSlider::tracking()
