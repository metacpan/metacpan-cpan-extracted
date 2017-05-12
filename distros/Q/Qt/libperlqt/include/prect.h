#ifndef PRECT_H
#define PRECT_H

/*
 * Declaration of the PRect class
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#undef bool
#include "qrect.h"
#include "ppoint.h"
#include "psize.h"
#include "pqt.h"

class PRect : public QRect {
public:
    PRect() {}
    PRect(const QPoint &topleft, const QPoint &bottomright) :
	QRect(topleft, bottomright) {}
    PRect(const QPoint &topleft, const QSize &size) :
	QRect(topleft, size) {}
    PRect(int left, int top, int width, int height) :
	QRect(left, top, width, height) {}

    PRect(const QRect &rect) { *(QRect *)this = rect; }
};

#endif  // PRECT_H
