/*
 * PerlQt interface to qpixmap.h
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#include "ppixmap.h"
#include "enum.h"

#define STORE_key(key) enumIV(hv, MSTR(key), QPixmap::key)

inline void init_enum() {
    HV *hv = perl_get_hv("QPixmap::ColorMode", TRUE | GV_ADDMULTI);

    STORE_key(Auto);
    STORE_key(Color);
    STORE_key(Mono);
}

MODULE = QPixmap		PACKAGE = QPixmap

PROTOTYPES: ENABLE

BOOT:
    init_enum();

PPixmap *
PPixmap::new(...)
    CASE: items == 1
	CODE:
	RETVAL = new PPixmap();   // Memory leak, fix perhaps?
	OUTPUT:
	RETVAL
    CASE: items > 2 && (SvIOK(ST(1)) || SvNOK(ST(1)))
	PREINIT:
	int w = SvIV(ST(1));
	int h = SvIV(ST(2));
	int depth = (items > 3) ? SvIV(ST(3)) : -1;
	CODE:
	RETVAL = new PPixmap(w, h, depth);
	OUTPUT:
	RETVAL
    CASE: sv_isobject(ST(1))
	PREINIT:
	QSize *size = (QSize *)extract_ptr(ST(1), "QSize");
	int depth = (items > 2) ? SvIV(ST(2)) : -1;
	CODE:
	RETVAL = new PPixmap(*size, depth);
	OUTPUT:
	RETVAL
    CASE:
	PREINIT:
	char *filename = SvPV(ST(1), na);
	char *format = (items > 2) ? SvPV(ST(2), na) : 0;
	QPixmap::ColorMode mode = (items > 3) ?
	    (QPixmap::ColorMode)SvIV(ST(3)) : QPixmap::Auto;
	CODE:
	RETVAL = new PPixmap(filename, format, mode);
	OUTPUT:
	RETVAL

int
defaultDepth()
    CODE:
    RETVAL = QPixmap::defaultDepth();
    OUTPUT:
    RETVAL

int
QPixmap::depth()

void
QPixmap::detach()

void
QPixmap::fill(...)
    CASE: items > 3
	PREINIT:
	QWidget *widget = (QWidget *)extract_ptr(ST(1), "QWidget");
	int xofs = SvIV(ST(2));
	int yofs = SvIV(ST(3));
	CODE:
	THIS->fill(widget, xofs, yofs);
    CASE: items == 3
	PREINIT:
	QWidget *widget = (QWidget *)extract_ptr(ST(1), "QWidget");
	QPoint *ofs = (QPoint *)extract_ptr(ST(2), "QPoint");
	CODE:
	THIS->fill(widget, *ofs);
    CASE:
	PREINIT:
	const QColor *color = (items > 1) ?
	    (QColor *)extract_ptr(ST(1), "QColor") : &white;
	CODE:
	THIS->fill(*color);

int
QPixmap::height()

const char *
imageFormat(fileName)
    char *fileName
    CODE:
    RETVAL = QPixmap::imageFormat(fileName);
    OUTPUT:
    RETVAL

bool
QPixmap::isOptimized()

bool
QPixmap::isQBitmap()

bool
QPixmap::load(fileName, format = 0, mode = QPixmap::Auto)
    char *fileName
    char *format
    QPixmap::ColorMode mode

bool
QPixmap::loadFromData(buf, format = 0, mode = QPixmap::Auto)
    SV *buf
    char *format
    QPixmap::ColorMode mode
    CODE:
    uint len;
    uchar *nbuf = (uchar *)SvPV(buf, len);
    RETVAL = THIS->loadFromData(nbuf, len, format, mode);
    OUTPUT:
    RETVAL

bool
isGloballyOptimized()
    CODE:
    RETVAL = QPixmap::isGloballyOptimized();
    OUTPUT:
    RETVAL

bool
QPixmap::isNull()

void
QPixmap::optimize(b)
    bool b

void
optimizeGlobally(b)
    bool b
    CODE:
    QPixmap::optimizeGlobally(b);

PRect *
QPixmap::rect()
    CODE:
    RETVAL = new PRect(THIS->rect());
    OUTPUT:
    RETVAL

void
QPixmap::resize()
    CASE: items > 2
	PREINIT:
	int width = SvIV(ST(1));
	int height = SvIV(ST(2));
	CODE:
	THIS->resize(width, height);
    CASE: items > 1
	PREINIT:
	QSize *size = pextract(QSize, 1);
	CODE:
	THIS->resize(*size);

bool
QPixmap::save(fileName, format)
    char *fileName
    char *format

PSize *
QPixmap::size()
    CODE:
    RETVAL = new PSize(THIS->size());
    OUTPUT:
    RETVAL

PWMatrix *
QPixmap::trueMatrix(matrix, w, h)
    QWMatrix *matrix
    int w
    int h
    CODE:
    RETVAL = new PWMatrix(THIS->trueMatrix(*matrix, w, h));
    OUTPUT:
    RETVAL

int
QPixmap::width()

PPixmap *
QPixmap::xForm(matrix)
    QWMatrix *matrix
    CODE:
    RETVAL = new PPixmap(THIS->xForm(*matrix));
    OUTPUT:
    RETVAL
