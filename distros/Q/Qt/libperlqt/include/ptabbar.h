#ifndef PTABBAR_H
#define PTABBAR_H

/*
 * Declaration of the PTabBar class
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#undef bool
#include "qtabbar.h"

// struct PTab : public QTab {};  // QTabBar::~QTabBar() runs delete, whoopie!

class PTabBar : public QTabBar {
public:
    PTabBar(QWidget *parent = 0, const char *name = 0) :
	QTabBar(parent, name) {}
};

#endif  // PTABBAR_H
