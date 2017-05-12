#ifndef PRADIOBT_H
#define PRADIOBT_H

/*
 * Declaration of the PRadioButton class
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#undef bool
#include "qradiobt.h"

class PRadioButton : public QRadioButton {
public:
    PRadioButton(QWidget *parent = 0, const char *name = 0) :
	QRadioButton(parent, name) {}
    PRadioButton(const char *text, QWidget *parent = 0, const char *name = 0) :
	QRadioButton(text, parent, name) {}
};

#endif  // PRADIOBT_H
