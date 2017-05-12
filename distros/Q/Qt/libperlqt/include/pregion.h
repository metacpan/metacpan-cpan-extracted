#ifndef PREGION_H
#define PREGION_H

/*
 * Declaration of the PRegion class
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#undef bool
#include "qregion.h"
#include "pqt.h"

class PRegion : public QRegion {
public:
    PRegion() {}
    PRegion(const QRect &rect, QRegion::RegionType type = QRegion::Rectangle) :
	QRegion(rect, type) {}
    PRegion(const QPointArray &parray, bool winding=FALSE) :
	QRegion(parray, winding) {}

    PRegion(const QRegion &region) { *(QRegion *)this = region; }
};

#endif  // PREGION_H
