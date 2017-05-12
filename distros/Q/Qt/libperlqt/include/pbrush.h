#ifndef PBRUSH_H
#define PBRUSH_H

/*
 * Declaration of the PBrush class
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#undef bool
#include "qbrush.h"
#include "pcolor.h"
#include "pqt.h"

class PBrush : public QBrush {
public:
    PBrush() {}
    PBrush(BrushStyle style) : QBrush(style) {}
    PBrush(const QColor &color, BrushStyle style = SolidPattern) :
	QBrush(color, style) {}
    PBrush(const QColor &color, const QPixmap &pixmap) :
	QBrush(color, pixmap) {}
//    PBrush(const QBrush &brush) : QBrush(brush) {}
};

#endif  // PBRUSH_H
