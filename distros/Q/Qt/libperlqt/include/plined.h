#ifndef PLINED_H
#define PLINED_H

/*
 * Declaration of the PLineEdit class
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#undef bool
#include "qlined.h"

class PLineEdit : public QLineEdit {
public:
    PLineEdit(QWidget *parent = 0, const char *name = 0) :
	QLineEdit(parent, name) {}
};

#endif  // PLINED_H
