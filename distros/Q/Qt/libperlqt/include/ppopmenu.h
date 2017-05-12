#ifndef PPOPMENU_H
#define PPOPMENU_H

/*
 * Declaration of the PPopupMenu class
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#undef bool
#include "qpopmenu.h"

class PPopupMenu : public QPopupMenu {
public:
    PPopupMenu(QWidget *parent = 0, const char *name = 0) :
	QPopupMenu(parent, name) {}
};

#endif  // PPOPMENU_H
