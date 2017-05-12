#ifndef PPNTARRY_H
#define PPNTARRY_H

/*
 * Declaration of the PPointArray class
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#undef bool
#include "qpntarry.h"
#include "ppoint.h"
#include "prect.h"
#include "pqt.h"

class PPointArray : public QPointArray {
public:
    PPointArray() {}
    PPointArray(int size) : QPointArray(size) {}
    PPointArray(const QRect &r, bool closed = FALSE) :
	QPointArray(r, closed) {}
    PPointArray(int nPoints, const QCOORD *points) :
	QPointArray(nPoints, points) {}

    PPointArray(const QPointArray &parray) { *(QPointArray *)this = parray; }
};

#endif  // PPNTARRY_H
