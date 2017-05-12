/*
 * PerlQt interface to qmenubar.h
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#include "pmenubar.h"
#include "pqt.h"

MODULE = QMenuBar		PACKAGE = QMenuBar

PROTOTYPES: ENABLE

PMenuBar *
PMenuBar::new(parent = 0, name = 0)
    QWidget *parent
    char *name
