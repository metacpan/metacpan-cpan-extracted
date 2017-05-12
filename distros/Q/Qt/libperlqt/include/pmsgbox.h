#ifndef PMSGBOX_H
#define PMSGBOX_H

/*
 * Declaration of the PMessageBox class
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#undef bool
#include "qmsgbox.h"

class PMessageBox : public QMessageBox {
public:
    PMessageBox(QWidget *parent = 0, const char *name = 0) :
	QMessageBox(parent, name) {}
};

#endif  // PMSGBOX_H
