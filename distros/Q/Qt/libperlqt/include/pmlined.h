#ifndef PMLINED_H
#define PMLINED_H

/*
 * Declaration of the PMultiLineEdit class
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#undef bool
#include "qmlined.h"

class PMultiLineEdit : public QMultiLineEdit {
public:
    PMultiLineEdit(QWidget *parent = 0, const char *name = 0) :
	QMultiLineEdit(parent, name) {}
};

#endif  // PMLINED_H
