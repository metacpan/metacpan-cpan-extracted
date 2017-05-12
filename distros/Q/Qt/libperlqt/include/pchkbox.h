#ifndef PCHKBOX_H
#define PCHKBOX_H

/*
 * Declaration of the PCheckBox class
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#undef bool
#include "qchkbox.h"

class PCheckBox : public QCheckBox {
public:
    PCheckBox(QWidget *parent = 0, const char *name = 0) :
	QCheckBox(parent, name) {}
    PCheckBox(const char *text, QWidget *parent, const char *name = 0) :
	QCheckBox(text, parent, name) {}
};

#endif  // PCHKBOX_H
