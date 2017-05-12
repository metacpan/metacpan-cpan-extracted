#ifndef PPIXMAP_H
#define PPIXMAP_H

/*
 * Declaration of the PPixmap class
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#undef bool
#include "qpixmap.h"
#include "prect.h"
#include "psize.h"
#include "pwmatrix.h"
#include "pqt.h"

typedef QPixmap::ColorMode QPixmap__ColorMode;

class PPixmap : public QPixmap {
public:
    PPixmap() {}
    PPixmap(int w, int h, int depth = -1) : QPixmap(w, h, depth) {}
    PPixmap(const QSize &s, int depth = -1) : QPixmap(s, depth) {}
    PPixmap(const char *fileName, const char *format = 0,
	    QPixmap::ColorMode mode = QPixmap::Auto) :
	QPixmap(fileName, format, mode) {}

    PPixmap(const QPixmap &pixmap) { *(QPixmap *)this = pixmap; }
};

#endif  // PPIXMAP_H
