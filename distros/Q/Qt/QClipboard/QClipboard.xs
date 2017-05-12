/*
 * PerlQt interface to qclipbrd.h
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#include "pclipbrd.h"

MODULE = QClipboard		PACKAGE = QClipboard

PROTOTYPES: ENABLE

void
QClipboard::clear()

QPixmap *
QClipboard::pixmap()
    CODE:
    RETVAL = THIS->pixmap();
    if(!RETVAL) XSRETURN_UNDEF;
    OUTPUT:
    RETVAL

void
QClipboard::setPixmap(pixmap)
    QPixmap *pixmap
    CODE:
    THIS->setPixmap(*pixmap);

void
QClipboard::setText(text)
    char *text

const char *
QClipboard::text()
    CODE:
    RETVAL = THIS->text();
    if(!RETVAL) XSRETURN_UNDEF;
    OUTPUT:
    RETVAL