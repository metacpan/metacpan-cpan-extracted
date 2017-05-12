/*
 * PerlQt interface to qwmatrix.h
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#include "pwmatrix.h"

MODULE = QWMatrix		PACKAGE = QWMatrix

PROTOTYPES: ENABLE

PWMatrix *
PWMatrix::new(...)
    CASE: items == 1
	CODE:
	RETVAL = new PWMatrix();
	OUTPUT:
	RETVAL
    CASE: items > 6
	PREINIT:
	float m11 = SvNV(ST(1));
	float m12 = SvNV(ST(2));
	float m21 = SvNV(ST(3));
	float m22 = SvNV(ST(4));
	float dx = SvNV(ST(5));
	float dy = SvNV(ST(6));
	CODE:
	RETVAL = new PWMatrix(m11, m12, m21, m22, dx, dy);
	OUTPUT:
	RETVAL
    CASE:
	CODE:
	croak("Usage: new %s(m11, m12, m21, m22, dx, dy);\nUsage: new %s;",
	      CLASS, CLASS);

float
QWMatrix::dx()

float
QWMatrix::dy()

#undef invert

PWMatrix *
QWMatrix::invert(invertable = 0)
    CASE: items == 1
	CODE:
	RETVAL = new PWMatrix(THIS->invert());
	OUTPUT:
	RETVAL
    CASE:
	bool invertable
	CODE:
	RETVAL = new PWMatrix(THIS->invert(&invertable));
	OUTPUT:
	invertable
	RETVAL

float
QWMatrix::m11()

float
QWMatrix::m12()

float
QWMatrix::m21()

float
QWMatrix::m22()

SV *
QWMatrix::map(thing, ...)
    CASE: items < 5 && !sv_isobject(ST(1))
	CODE:
	croak("Usage: $matrix->map(x, y, dx, dy);\nUsage: $matrix->map(point);\nUsage: $matrix->map(rect);");
    CASE: SvIOK(ST(1))
	PREINIT:
	int x = SvIV(ST(1));
	int y = SvIV(ST(2));
	int tx;
	int ty;
	CODE:
	THIS->map(x, y, &tx, &ty);
	RETVAL = &sv_undef;
	sv_setiv(ST(3), tx);
	sv_setiv(ST(4), ty);
	OUTPUT:
	RETVAL
    CASE: items > 4
	PREINIT:
	float x = SvNV(ST(1));
	float y = SvNV(ST(2));
	float tx;
	float ty;
	CODE:
	THIS->map(x, y, &tx, &ty);
	RETVAL = &sv_undef;
	sv_setnv(ST(3), tx);
	sv_setnv(ST(4), ty);
	OUTPUT:
	RETVAL
    CASE: sv_derived_from(ST(1), "QRect")
	PREINIT:
	QRect *rect = (QRect *)extract_ptr(ST(1), "QRect");
	CODE:
	RETVAL =
	    objectify_ptr((void *)new PRect(THIS->map(*rect)), "QRect", 1);
	OUTPUT:
	RETVAL
    CASE: sv_derived_from(ST(1), "QPoint")
	PREINIT:
	QPoint *point = (QPoint *)extract_ptr(ST(1), "QPoint");
	CODE:
	RETVAL =
	    objectify_ptr((void *)new PPoint(THIS->map(*point)), "QPoint", 1);
	OUTPUT:
	RETVAL
    CASE:
	PREINIT:
	QPointArray *parray = pextract(QPointArray, 1);
	CODE:
	RETVAL = objectify_ptr((void *)new PPointArray(THIS->map(*parray)),
			       "QPointArray", 1);
	OUTPUT:
	RETVAL

void
QWMatrix::reset()

PWMatrix *
QWMatrix::rotate(a)
    float a
    CODE:
    RETVAL = new PWMatrix(THIS->rotate(a));
    OUTPUT:
    RETVAL

PWMatrix *
QWMatrix::scale(sx, sy)
    float sx
    float sy
    CODE:
    RETVAL = new PWMatrix(THIS->scale(sx, sy));
    OUTPUT:
    RETVAL

PWMatrix *
QWMatrix::shear(sh, sv)
    float sh
    float sv
    CODE:
    RETVAL = new PWMatrix(THIS->shear(sh, sv));
    OUTPUT:
    RETVAL

void
QWMatrix::setMatrix(m11, m12, m21, m22, dx, dy)
    float m11
    float m12
    float m21
    float m22
    float dx
    float dy

PWMatrix *
QWMatrix::translate(dx, dy)
    float dx
    float dy
    CODE:
    RETVAL = new PWMatrix(THIS->translate(dx, dy));
    OUTPUT:
    RETVAL

