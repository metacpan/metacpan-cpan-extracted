#ifndef PBUTTON_H
#define PBUTTON_H

/*
 * Declaration of the PButton class
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#undef bool
#include "qbutton.h"
#include "ppixmap.h"
#include "pqt.h"
#include "virtual.h"

class PButton : public QButton, public virtualize {
public:
    PButton(QWidget *parent = 0, const char *name = 0) :
	QButton(parent, name) {}
};

#endif  // PBUTTON_H
