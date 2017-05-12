#ifndef PCOLOR_H
#define PCOLOR_H

/*
 * Declaration of the PColor class
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#undef bool
#include "qcolor.h"
#include "pqt.h"

class PColor : public QColor {
public:
    PColor() {}
    PColor(int r, int g, int b) : QColor(r, g, b) {}
    PColor(int x, int y, int z, QColor::Spec spec) : QColor(x, y, z, spec) {}
    PColor(QRgb rgb, uint pixel = 0xffffffff) : QColor(rgb, pixel) {}
    PColor(const char *name) : QColor(name) {}

    PColor(const QColor &color) { *(QColor *)this = color; }
};

#endif  // PCOLOR_H
