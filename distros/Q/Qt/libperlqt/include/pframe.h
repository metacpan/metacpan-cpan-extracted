#ifndef PFRAME_H
#define PFRAME_H

/*
 * Declaration of the PFrame class
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#undef bool
#include "qframe.h"
#include "prect.h"
#include "pqt.h"
#include "virtual.h"

class PFrame : public QFrame, public virtualize {
public:
    PFrame(QWidget *parent = 0, const char *name = 0, WFlags f = 0,
	   bool allowLines = TRUE) : QFrame(parent, name, f, allowLines) {}
};

#endif  // PFRAME_H
