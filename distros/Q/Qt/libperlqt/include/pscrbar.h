#ifndef PSCRBAR_H
#define PSCRBAR_H

/*
 * Declaration of the PScrollBar class
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#undef bool
#include "qscrbar.h"
#include "enum.h"
#include "pqt.h"
#include "virtual.h"

typedef QScrollBar::Orientation QScrollBar__Orientation;

class PScrollBar : public QScrollBar, public virtualize {
public:
    PScrollBar(QWidget *parent = 0, const char *name = 0) :
	QScrollBar(parent, name) {}
    PScrollBar(QScrollBar::Orientation orientation, QWidget *parent = 0,
	       const char *name = 0) :
	QScrollBar(orientation, parent, name) {}
    PScrollBar(int minValue, int maxValue, int LineStep, int PageStep,
	       int value, QScrollBar::Orientation orientation,
	       QWidget *parent = 0, const char *name = 0) :
	QScrollBar(minValue, maxValue, LineStep, PageStep, value, orientation,
		   parent, name) {}
};

#endif  // PSCRBAR_H
