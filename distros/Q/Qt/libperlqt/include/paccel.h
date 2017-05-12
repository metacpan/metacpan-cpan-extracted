#ifndef PACCEL_H
#define PACCEL_H

/*
 * Declaration of the PAccel class
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#undef bool
#include "qaccel.h"
#include "pqt.h"

class PAccel : public QAccel {
public:
    PAccel(QWidget *parent, const char *name = 0) : QAccel(parent, name) {}
};

#endif  // PACCEL_H
