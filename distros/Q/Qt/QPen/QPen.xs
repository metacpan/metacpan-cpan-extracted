/*
 * PerlQt interface to qpen.h
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#include "ppen.h"

#define STORE_key(key) enumIV(hv, MSTR(key), key)

inline void init_enum() {
    HV *hv = perl_get_hv("QPen::PenStyle", TRUE | GV_ADDMULTI);

    STORE_key(NoPen);
    STORE_key(SolidLine);
    STORE_key(DashLine);
    STORE_key(DotLine);
    STORE_key(DashDotLine);
    STORE_key(DashDotDotLine);
}

MODULE = QPen		PACKAGE = QPen

PROTOTYPES: ENABLE

BOOT:
    init_enum();

PPen *
PPen::new(...)
    CASE: items == 1
	CODE:
	RETVAL = new PPen();
	OUTPUT:
	RETVAL
    CASE: !sv_isobject(ST(1))
	PREINIT:
	PenStyle style = (PenStyle)SvIV(ST(1));
	CODE:
	RETVAL = new PPen(style);
	OUTPUT:
	RETVAL
    CASE:
	PREINIT:
	QColor *color = (QColor *)extract_ptr(ST(1), "QColor");
	uint width = (items > 2) ? SvIV(ST(2)) : 0;
	PenStyle style = (items > 3) ? (PenStyle)SvIV(ST(3)) : SolidLine;
	CODE:
	RETVAL = new PPen(*color, width, style);
	OUTPUT:
	RETVAL

PColor *
QPen::color()
    CODE:
    RETVAL = new PColor(THIS->color());
    OUTPUT:
    RETVAL

void
QPen::setColor(color)
    QColor *color
    CODE:
    THIS->setColor(*color);

void
QPen::setStyle(style)
    PenStyle style

void
QPen::setWidth(width)
    uint width

PenStyle
QPen::style()

uint
QPen::width()
