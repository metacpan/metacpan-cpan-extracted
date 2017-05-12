#ifndef PPUSHBT_H
#define PPUSHBT_H

/*
 * Declaration of the PPushButton class
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#undef bool
#include "qpushbt.h"
#include "pqt.h"
#include "virtual.h"

class PPushButton : public QPushButton, public virtualize {
public:
    PPushButton(QWidget *parent = 0, const char *name = 0) :
	QPushButton(parent, name) {}
    PPushButton(const char *text, QWidget *parent = 0, const char *name = 0) :
	QPushButton(text, parent, name) {}
};

#endif  // PPUSHBT_H
