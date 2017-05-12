/*
 * PerlQt interface to qcolor.h
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#include "pcolor.h"
#include "enum.h"

#define STORE_enum(key) enumIV(hv, MSTR(key), QColor::key)

inline void init_Spec() {
    HV *hv = perl_get_hv("QColor::Spec", TRUE | GV_ADDMULTI);

    STORE_enum(Rgb);
    STORE_enum(Hsv);
}

#define ENUM_color(color) \
sv_setsv(perl_get_sv(MSTR(QColor::color), TRUE | GV_ADDMULTI), \
    sv_2mortal(objectify_ptr((void *)&color, "QColor")))

inline void load_enum() {
    ENUM_color(color0);
    ENUM_color(color1);
    ENUM_color(black);
    ENUM_color(white);
    ENUM_color(darkGray);
    ENUM_color(gray);
    ENUM_color(lightGray);
    ENUM_color(red);
    ENUM_color(green);
    ENUM_color(blue);
    ENUM_color(cyan);
    ENUM_color(magenta);
    ENUM_color(yellow);
    ENUM_color(darkRed);
    ENUM_color(darkGreen);
    ENUM_color(darkBlue);
    ENUM_color(darkCyan);
    ENUM_color(darkMagenta);
    ENUM_color(darkYellow);
}

#define STORE_const(const) \
sv_setiv(perl_get_sv(MSTR(QColor::const), TRUE | GV_ADDMULTI), const)

inline void load_const() {
    STORE_const(RGB_DIRTY);
    STORE_const(RGB_INVALID);
    STORE_const(RGB_DIRECT);
    STORE_const(RGB_MASK);
}

MODULE = QColor		PACKAGE = QColor

PROTOTYPES: ENABLE

BOOT:
    load_enum();
    load_const();
    init_Spec();

int
qBlue(rgb)
    QRgb rgb

int
qGray(arg1, ...)
    CASE: items == 1
	PREINIT:
	QRgb rgb = SvIV(ST(0));
	CODE:
	RETVAL = qGray(rgb);
	OUTPUT:
	RETVAL
    CASE: items > 2
	PREINIT:
	int r = SvIV(ST(0));
	int g = SvIV(ST(1));
	int b = SvIV(ST(2));
	CODE:
	RETVAL = qGray(r, g, b);
	OUTPUT:
	RETVAL

int
qGreen(rgb)
    QRgb rgb

int
qRed(rgb)
    QRgb rgb

QRgb
qRgb(r, g, b)
    int r
    int g
    int b


PColor *
PColor::new(...)
    CASE: items == 1
	CODE:
	RETVAL = new PColor();
	OUTPUT:
	RETVAL
    CASE: items == 4
	PREINIT:
	int r = SvIV(ST(1));
	int g = SvIV(ST(2));
	int b = SvIV(ST(3));
	CODE:
	RETVAL = new PColor(r, g, b);
	OUTPUT:
	RETVAL
    CASE: items > 4
	PREINIT:
	int x = SvIV(ST(1));
	int y = SvIV(ST(2));
	int z = SvIV(ST(3));
	QColor::Spec spec = (QColor::Spec)SvIV(ST(4));
	CODE:
	RETVAL = new PColor(x, y, z, spec);
	OUTPUT:
	RETVAL
    CASE: SvIOK(ST(1)) || SvNOK(ST(1))
	PREINIT:
	QRgb rgb = SvIV(ST(1));
	uint pixel = (items > 2) ? SvIV(ST(2)) : 0xffffffff;
	CODE:
	RETVAL = new PColor(rgb, pixel);
	OUTPUT:
	RETVAL
    CASE:
	PREINIT:
	char *name = SvPV(ST(1), na);
	CODE:
	RETVAL = new PColor(name);
	OUTPUT:
	RETVAL

uint
QColor::alloc()

int
QColor::blue()

void
cleanup()
    CODE:
    QColor::cleanup();

int
currentAllocContext()
    CODE:
    RETVAL = QColor::currentAllocContext();
    OUTPUT:
    RETVAL

PColor *
QColor::dark(f = 200)
    int f
    CODE:
    RETVAL = new PColor(THIS->dark(f));
    OUTPUT:
    RETVAL

void
destroyAllocContext(context)
    int context
    CODE:
    QColor::destroyAllocContext(context);

int
enterAllocContext()
    CODE:
    RETVAL = QColor::enterAllocContext();
    OUTPUT:
    RETVAL

int
QColor::green()

void
QColor::hsv(h, s, v)
    int h
    int s
    int v
    CODE:
    THIS->hsv(&h, &s, &v);
    OUTPUT:
    h
    s
    v

void
initialize()
    CODE:
    QColor::initialize();

bool
QColor::isDirty()

bool
QColor::isValid()

bool
lazyAlloc()
    CODE:
    RETVAL = QColor::lazyAlloc();
    OUTPUT:
    RETVAL

void
leaveAllocContext()
    CODE:
    QColor::leaveAllocContext();

PColor *
QColor::light(f = 112)
    int f
    CODE:
    RETVAL = new PColor(THIS->light(f));
    OUTPUT:
    RETVAL

int
maxColors()
    CODE:
    RETVAL = QColor::maxColors();
    OUTPUT:
    RETVAL

int
numBitPlanes()
    CODE:
    RETVAL = QColor::numBitPlanes();
    OUTPUT:
    RETVAL

uint
QColor::pixel()

void
QColor::red()

QRgb
QColor::rgb(...)
    CASE: items == 1
	CODE:
	RETVAL = THIS->rgb();
	OUTPUT:
	RETVAL
    CASE: items > 3
	PREINIT:
	int r, g, b;
	CODE:
	THIS->rgb(&r, &g, &b);
	sv_setiv(ST(1), r);
	sv_setiv(ST(2), g);
	sv_setiv(ST(3), b);
	XSRETURN_EMPTY;

void
QColor::setHsv(h, s, v)
    int h
    int s
    int v

void
setLazyAlloc(b)
    bool b
    CODE:
    QColor::setLazyAlloc(b);

void
QColor::setNamedColor(name)
    char *name

void
QColor::setRgb(...)
    CASE: items == 2
	PREINIT:
	QRgb rgb = SvIV(ST(1));
	CODE:
	THIS->setRgb(rgb);
    CASE: items > 3
	PREINIT:
	int r = SvIV(ST(1));
	int g = SvIV(ST(2));
	int b = SvIV(ST(3));
	CODE:
	THIS->setRgb(r, g, b);
