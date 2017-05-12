/*
 * PerlQt interface to qwindow.h
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#include "pwindow.h"
#include "pqt.h"

MODULE = QWindow		PACKAGE = QWindow

PROTOTYPES: ENABLE

PWindow *
PWindow::new(parent = 0, name = 0, f = 0)
    QWidget *parent
    char *name
    WFlags f
