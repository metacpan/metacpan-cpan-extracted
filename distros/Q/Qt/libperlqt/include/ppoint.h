#ifndef PPOINT_H
#define PPOINT_H

/*
 * Declaration of the PPoint class
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#undef bool
#include "qpoint.h"
#include "pqt.h"

class PPoint : public QPoint {
public:
    PPoint() {}
    PPoint(int xpos, int ypos) : QPoint(xpos, ypos) {}

    PPoint(const QPoint &point) { *(QPoint *)this = point; }
};

#endif  // PPOINT_H
