/*
 * PerlQt interface to qfontinf.h
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#include "pfontinf.h"

MODULE = QFontInfo		PACKAGE = QFontInfo

PROTOTYPES: ENABLE

bool
QFontInfo::bold()

QFont::CharSet
QFontInfo::charSet()

bool
QFontInfo::exactMatch()

const char *
QFontInfo::family()

bool
QFontInfo::fixedPitch()

PFont *
QFontInfo::font()
    CODE:
    RETVAL = new PFont(THIS->font());
    OUTPUT:
    RETVAL

bool
QFontInfo::italic()

int
QFontInfo::pointSize()

bool
QFontInfo::rawMode()

bool
QFontInfo::strikeOut()

QFont::StyleHint
QFontInfo::styleHint()

bool
QFontInfo::underline()

int
QFontInfo::weight()