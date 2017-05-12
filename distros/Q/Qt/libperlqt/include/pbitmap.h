#ifndef PBITMAP_H
#define PBITMAP_H

/*
 * Declaration of the PCursor class
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#undef bool
#include "qbitmap.h"
#include "psize.h"
#include "pwmatrix.h"
#include "pqt.h"

class PBitmap : public QBitmap {
public:
    PBitmap() {}
    PBitmap(int w, int h, bool clear = FALSE) : QBitmap(w, h, clear) {}
    PBitmap(const QSize &size, bool clear = FALSE) : QBitmap(size, clear) {}
    PBitmap(int w, int h, const uchar *bits, bool isXbitmap = FALSE) :
	QBitmap(w, h, bits, isXbitmap) {}
    PBitmap(const QSize &size, const uchar *bits, bool isXbitmap = FALSE) :
	QBitmap(size, bits, isXbitmap) {}
    PBitmap(const char *fileName, const char *format = 0) :
	QBitmap(fileName, format) {}

    PBitmap(const QBitmap &bitmap) { *(QBitmap *)this = bitmap; }
};

#endif  // PBITMAP_H
