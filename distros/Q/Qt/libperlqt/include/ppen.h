#ifndef PPEN_H
#define PPEN_H

/*
 * Declaration of the PPen class
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#undef bool
#include "qpen.h"
#include "pcolor.h"
#include "pqt.h"
#include "enum.h"

class PPen : public QPen {
public:
    PPen() {}
    PPen(PenStyle style) : QPen(style) {}
    PPen(const QColor &color, uint width = 0, PenStyle style = SolidLine) :
	QPen(color, width, style) {}

    PPen(const QPen &pen) { *(QPen *)this = pen; }
};

#endif  // PPEN_H
