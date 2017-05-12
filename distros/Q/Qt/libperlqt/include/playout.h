#ifndef PLAYOUT_H
#define PLAYOUT_H

/*
 * Declaration of the PBoxLayout and PGridLayout classes.
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#undef bool
#include "qlayout.h"

typedef QBoxLayout::Direction QBoxLayout__Direction;

class PBoxLayout : public QBoxLayout {
public:
    PBoxLayout(QWidget *parent, QBoxLayout::Direction direction,
	       int border = 0, int autoBorder = -1, const char *name = 0) :
	QBoxLayout(parent, direction, border, autoBorder, name) {}
    PBoxLayout(QBoxLayout::Direction direction, int autoBorder = -1,
	       const char *name = 0) :
	QBoxLayout(direction, autoBorder, name) {}
};

class PGridLayout : public QGridLayout {
public:
    PGridLayout(QWidget *parent, int nRows, int nCols, int border = 0,
		int autoBorder = -1, const char *name = 0) :
	QGridLayout(parent, nRows, nCols, border, autoBorder, name) {}
    PGridLayout(int nRows, int nCols, int autoBorder = -1,
		const char *name = 0) :
	QGridLayout(nRows, nCols, autoBorder, name) {}
};

#endif  // PLAYOUT_H
