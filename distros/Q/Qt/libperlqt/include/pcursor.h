#ifndef PCURSOR_H
#define PCURSOR_H

/*
 * Declaration of the PCursor class
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#include "qcursor.h"
#include "pbitmap.h"
#include "ppoint.h"
#include "pqt.h"

class PCursor : public QCursor {
public:
    PCursor() {}
    PCursor(int shape) : QCursor(shape) {}
    PCursor(const QBitmap &bitmap, const QBitmap &mask, int hotX=-1,
	int hotY=-1) : QCursor(bitmap, mask, hotX, hotY) {}

    PCursor(const QCursor &cursor) { *(QCursor *)this = cursor; }
};

#endif  // PCURSOR_H
