/*
 * PerlQt interface to qpaintd.h
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#include "ppaintd.h"
#include "qwidget.h"
#include "enum.h"

#define STORE_PDT(key) enumIV(hv, MSTR(key), PDT_ ## key)
#define STORE_PDF(key) enumIV(hv, MSTR(key), PDF_ ## key)

inline void init_const() {
    HV *hv = perl_get_hv("QPaintDevice::PDT", TRUE | GV_ADDMULTI);

    STORE_PDT(UNDEF);
    STORE_PDT(WIDGET);
    STORE_PDT(PIXMAP);
    STORE_PDT(PRINTER);
    STORE_PDT(PICTURE);
    STORE_PDT(MASK);

    hv = perl_get_hv("QPaintDevice::PDF", TRUE | GV_ADDMULTI);

    STORE_PDF(EXTDEV);
    STORE_PDF(PAINTACTIVE);
}

MODULE = QPaintDevice		PACKAGE = QPaintDevice

PROTOTYPES: ENABLE

BOOT:
    init_const();

int
QPaintDevice::devType()

bool
QPaintDevice::isExtDev()

bool
QPaintDevice::paintingActive()

void
bitBlt(arg1, arg2, arg3, arg4 = 0, ...)
    CASE: sv_isobject(ST(1))
	QPaintDevice *arg1
	QPoint *arg2
	QPaintDevice *arg3
	PREINIT:
	QRect *sr = (items > 3) ? pextract(QRect, 3) : new QRect(0, 0, -1, -1);
	RasterOp rop = (items > 4) ? (RasterOp)SvIV(ST(4)) : CopyROP;
	bool ignoreMask = (items > 5) ? (SvTRUE(ST(5)) ? TRUE : FALSE) : FALSE;
	CODE:
	bitBlt(arg1, *arg2, arg3, *sr, rop, ignoreMask);
	if(items < 4) delete sr;
    CASE: items > 3
	QPaintDevice *arg1
	int arg2
	int arg3
	QPaintDevice *arg4
	PREINIT:
	int sx = (items > 4) ? SvIV(ST(4)) : 0;
	int sy = (items > 5) ? SvIV(ST(5)) : 0;
	int sw = (items > 6) ? SvIV(ST(6)) : -1;
	int sh = (items > 7) ? SvIV(ST(7)) : -1;
	RasterOp rop = (items > 8) ? (RasterOp)SvIV(ST(8)) : CopyROP;
	bool ignoreMask = (items > 9) ? (SvTRUE(ST(9)) ? TRUE : FALSE) : FALSE;
	CODE:
	bitBlt(arg1, arg2, arg3, arg4, sx, sy, sw, sh, rop, ignoreMask);
