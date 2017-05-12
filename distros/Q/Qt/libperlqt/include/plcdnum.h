#ifndef PLCDNUM_H
#define PLCDNUM_H

/*
 * Declaration of the PLCDNumber class
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#undef bool
#include "qlcdnum.h"
#include "pqt.h"
#include "virtual.h"

typedef QLCDNumber::Mode QLCDNumber__Mode;

class PLCDNumber : public QLCDNumber, public virtualize {
public:
    PLCDNumber(QWidget *parent = 0, const char *name = 0) :
	QLCDNumber(parent, name) {}
    PLCDNumber(uint numDigits, QWidget *parent = 0, const char *name = 0) :
	QLCDNumber(numDigits, parent, name) {}
};

#endif  // PLCDNUM_H
