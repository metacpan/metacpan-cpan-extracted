/*
 * PerlQt interface to qbutton.h
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#include "pbutton.h"

MODULE = QButton		PACKAGE = QButton

PROTOTYPES: ENABLE

PButton *
PButton::new(parent = 0, name = 0)
    QWidget *parent
    char *name

bool
QButton::autoResize()

bool
QButton::isDown()

bool
QButton::isOn()

bool
QButton::isToggleButton()

PPixmap *
QButton::pixmap()
    CODE:
    RETVAL = new PPixmap(*(THIS->pixmap()));
    OUTPUT:
    RETVAL

void
QButton::setAutoResize(b)
    bool b

void
QButton::setPixmap(pixmap)
    QPixmap *pixmap
    CODE:
    THIS->setPixmap(*pixmap);

void
QButton::setText(text)
    char *text

const char *
QButton::text()
