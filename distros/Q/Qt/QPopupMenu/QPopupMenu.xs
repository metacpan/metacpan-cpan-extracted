/*
 * PerlQt interface to qpopmenu.h
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#include "ppopmenu.h"
#include "pqt.h"

MODULE = QPopupMenu		PACKAGE = QPopupMenu

PROTOTYPES: ENABLE

PPopupMenu *
PPopupMenu::new(parent = 0, name = 0)
    QWidget *parent
    char *name

#if pQT_VERSION >= pQT_12

bool
QPopupMenu::isCheckable()

#endif

void
QPopupMenu::popup(pos, indexAtPoint = 0)
    QPoint *pos
    int indexAtPoint
    CODE:
    THIS->popup(*pos, indexAtPoint);

#if pQT_VERSION >= pQT_12

void
QPopupMenu::setCheckable(checkable)
    bool checkable

#endif