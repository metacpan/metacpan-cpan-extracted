#ifndef PSIZE_H
#define PSIZE_H

/*
 * Declaration of the PSize class
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#undef bool
#include "qsize.h"
#include "pqt.h"

class PSize : public QSize {
public:
    PSize() {}
    PSize(int w, int h) : QSize(w, h) {}

    PSize(const QSize &size) { *(QSize *)this = size; }
};

#endif  // PSIZE_H
