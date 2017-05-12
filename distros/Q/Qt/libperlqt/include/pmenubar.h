#ifndef PMENUBAR_H
#define PMENUBAR_H

/*
 * Declaration of the PMenuBar class
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#undef bool
#include "qmenubar.h"

class PMenuBar : public QMenuBar {
public:
    PMenuBar(QWidget *parent = 0, const char *name = 0) :
	QMenuBar(parent, name) {}
};

#endif  // PMENUBAR_H
