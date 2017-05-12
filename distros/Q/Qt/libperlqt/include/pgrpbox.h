#ifndef PGRPBOX_H
#define PGRPBOX_H

/*
 * Declaration of the PGroupBox class
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#undef bool
#include "qgrpbox.h"

class PGroupBox : public QGroupBox {
public:
    PGroupBox(QWidget *parent = 0, const char *name = 0) :
	QGroupBox(parent, name) {}
    PGroupBox(const char *title, QWidget *parent = 0, const char *name = 0) :
	QGroupBox(title, parent, name) {}
};

#endif  // PGRPBOX_H
