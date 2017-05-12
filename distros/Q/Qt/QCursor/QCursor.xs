/*
 * PerlQt interface to qcursor.h
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#include "pcursor.h"

#define STORE_cur(cursor) \
safe_hv_store(hv, MSTR(cursor), \
	      objectify_ptr((void *)&cursor ## Cursor, "QCursor"))

inline void init_const() {
    HV *hv = perl_get_hv("QCursor::Cursor", TRUE | GV_ADDMULTI);

    STORE_cur(arrow);
    STORE_cur(upArrow);
    STORE_cur(cross);
    STORE_cur(wait);
    STORE_cur(ibeam);
    STORE_cur(sizeVer);
    STORE_cur(sizeHor);
    STORE_cur(sizeBDiag);
    STORE_cur(sizeFDiag);
    STORE_cur(sizeAll);
}

MODULE = QCursor		PACKAGE = QCursor

PROTOTYPES: ENABLE

BOOT:
    init_const();

PCursor *
PCursor::new(...)
    CASE: items == 1
	CODE:
	RETVAL = new PCursor();
	OUTPUT:
	RETVAL
    CASE: sv_isobject(ST(1))
	PREINIT:
	QBitmap *bitmap = pextract(QBitmap, 1);
	QBitmap *mask = pextract(QBitmap, 2);
	int hotX = (items > 3) ? SvIV(ST(3)) : -1;
	int hotY = (items > 4) ? SvIV(ST(4)) : -1;
	CODE:
	RETVAL = new PCursor(*bitmap, *mask, hotX, hotY);
	OUTPUT:
	RETVAL
    CASE:
	PREINIT:
	int shape = SvIV(ST(1));
	CODE:
	RETVAL = new PCursor(shape);
	OUTPUT:
	RETVAL

PBitmap *
QCursor::bitmap()
    CODE:
    RETVAL = new PBitmap(*(THIS->bitmap()));
    OUTPUT:
    RETVAL

PPoint *
QCursor::hotSpot()
    CODE:
    RETVAL = new PPoint(THIS->hotSpot());
    OUTPUT:
    RETVAL

PBitmap *
QCursor::mask()
    CODE:
    RETVAL = new PBitmap(*(THIS->mask()));
    OUTPUT:
    RETVAL

PPoint *
pos()
    CODE:
    RETVAL = new PPoint(QCursor::pos());
    OUTPUT:
    RETVAL

void
setPos(arg1, ...)
    CASE: sv_isobject(ST(0))
	PREINIT:
	QPoint *point = pextract(QPoint, 0);
	CODE:
	QCursor::setPos(*point);
    CASE: items > 1
	PREINIT:
	int x = SvIV(ST(0));
	int y = SvIV(ST(1));
	CODE:
	QCursor::setPos(x, y);
