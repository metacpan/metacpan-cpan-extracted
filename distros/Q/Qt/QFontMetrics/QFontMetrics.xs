/*
 * PerlQt interface to qfontmet.h
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#include "pfontmet.h"

MODULE = QFontMetrics		PACKAGE = QFontMetrics

PROTOTYPES: ENABLE

int
QFontMetrics::ascent()

PRect *
QFontMetrics::boundingRect(str, len = -1)
    char *str
    int len
    CODE:
    RETVAL = new PRect(THIS->boundingRect(str, len));
    OUTPUT:
    RETVAL

int
QFontMetrics::descent()

PFont *
QFontMetrics::font()
    CODE:
    RETVAL = new PFont(THIS->font());
    OUTPUT:
    RETVAL

int
QFontMetrics::height()

int
QFontMetrics::leading()

int
QFontMetrics::lineSpacing()

int
QFontMetrics::lineWidth()

int
QFontMetrics::maxWidth()

int
QFontMetrics::strikeOutPos()

int
QFontMetrics::underlinePos()

int
QFontMetrics::width(str, len = -1)
    char *str
    int len
