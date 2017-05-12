/*
 * PerlQt interface to qregion.h
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#include "pregion.h"

MODULE = QRegion		PACKAGE = QRegion

PROTOTYPES: ENABLE

PRegion *
PRegion::new(...)
    CASE: items == 1
	CODE:
	RETVAL = new PRegion();
	OUTPUT:
	RETVAL
    CASE: sv_derived_from(ST(1), "QRect")
	PREINIT:
	QRect *rect = pextract(QRect, 1);
	QRegion::RegionType type = (items > 2) ?
	    (QRegion::RegionType)SvIV(ST(2)) : QRegion::Rectangle;
	CODE:
	RETVAL = new PRegion(*rect, type);
	OUTPUT:
	RETVAL
    CASE: items > 1
	PREINIT:
	QPointArray *parray = pextract(QPointArray, 1);
	bool winding = (items > 2) ? (SvIV(ST(2)) ? TRUE : FALSE) : FALSE;
	CODE:
	RETVAL = new PRegion(*parray, winding);
	OUTPUT:
	RETVAL

bool
QRegion::contains(thing)
    CASE: sv_derived_from(ST(1), "QPoint")
	QPoint *thing
	CODE:
	RETVAL = THIS->contains(*thing);
	OUTPUT:
	RETVAL
    CASE:
	QRect *thing
	CODE:
	RETVAL = THIS->contains(*thing);
	OUTPUT:
	RETVAL

PRegion *
QRegion::intersect(region)
    QRegion *region
    CODE:
    RETVAL = new PRegion(THIS->intersect(*region));
    OUTPUT:
    RETVAL

bool
QRegion::isEmpty()

bool
QRegion::isNull()

PRegion *
QRegion::subtract(region)
    QRegion *region
    CODE:
    RETVAL = new PRegion(THIS->subtract(*region));
    OUTPUT:
    RETVAL

void
QRegion::translate(dx, dy)
    int dx
    int dy

PRegion *
QRegion::unite(region)
    QRegion *region
    CODE:
    RETVAL = new PRegion(THIS->unite(*region));
    OUTPUT:
    RETVAL

PRegion *
QRegion::xor(region)
    QRegion *region
    CODE:
    RETVAL = new PRegion(THIS->xor(*region));
    OUTPUT:
    RETVAL
