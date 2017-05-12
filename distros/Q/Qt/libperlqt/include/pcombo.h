#ifndef PCOMBO_H
#define PCOMBO_H

/*
 * Declaration of the PComboBox class
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#undef bool
#include "qcombo.h"

typedef QComboBox::Policy QComboBox__Policy;

class PComboBox : public QComboBox {
public:
    PComboBox(QWidget *parent = 0, const char *name = 0) :
	QComboBox(parent, name) {}
    PComboBox(bool rw, QWidget *parent = 0, const char *name = 0) :
	QComboBox(rw, parent, name) {}
};

#endif  // PCOMBO_H
