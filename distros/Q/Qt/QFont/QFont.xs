/*
 * PerlQt interface to qfont.h
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#include "pfont.h"

#define STORE_key(key) enumIV(hv, MSTR(key), QFont::key)
#define STORE_keys(key, copy) enum2IV(hv, MSTR(key), MSTR(copy), QFont::copy)

inline HV *init_StyleHint(HV *hv) {
    register SV **svp = NULL;

    STORE_keys(Helvetica, SansSerif);
    STORE_keys(Times, Serif);
    STORE_keys(Courier, TypeWriter);
    STORE_keys(OldEnglish, Decorative);
    STORE_key(System);
    STORE_key(AnyStyle);

    return hv;
};

inline HV *init_Weight(HV *hv) {
    register SV **svp = NULL;

    STORE_key(Light);
    STORE_key(Normal);
    STORE_key(DemiBold);
    STORE_key(Bold);
    STORE_key(Black);

    return hv;
}

inline HV *init_CharSet(HV *hv) {
    register SV **svp = NULL;

    STORE_keys(Latin1, ISO_8859_1);
    STORE_key(AnyCharSet);

    return hv;
}

inline void load_enum() {
    SvREADONLY_on(
	init_StyleHint(perl_get_hv("QFont::StyleHint", TRUE | GV_ADDMULTI)));
    SvREADONLY_on(
	init_Weight(perl_get_hv("QFont::Weight", TRUE | GV_ADDMULTI)));
    SvREADONLY_on(
	init_CharSet(perl_get_hv("QFont::CharSet", TRUE | GV_ADDMULTI)));
}

MODULE = QFont		PACKAGE = QFont

PROTOTYPES: ENABLE

BOOT:
    load_enum();

PFont *
PFont::new(family = 0, pointSize = 12, weight = QFont::Normal, italic = FALSE)
    char *family
    int pointSize
    int weight
    bool italic

bool
QFont::bold()

QFont::CharSet
QFont::charSet()

PFont *
defaultFont()
    CODE:
    RETVAL = new PFont(QFont::defaultFont());
    OUTPUT:
    RETVAL

bool
QFont::exactMatch()

const char *
QFont::family()

bool
QFont::fixedPitch()

void
insertSubstitution(familyName, replacementName)
    char *familyName
    char *replacementName
    CODE:
    QFont::insertSubstitution(familyName, replacementName);

bool
QFont::italic()

int
QFont::pointSize()

bool
QFont::rawMode()

void
removeSubstitution(familyName)
    char *familyName
    CODE:
    QFont::removeSubstitution(familyName);

void
QFont::setBold(b)
    bool b

void
QFont::setCharSet(charSet)
    QFont::CharSet charSet

void
setDefaultFont(font)
    QFont *font
    CODE:
    QFont::setDefaultFont(*font);

void
QFont::setFamily(family)
    char *family

void
QFont::setFixedPitch(b)
    bool b

void
QFont::setItalic(b)
    bool b

void
QFont::setPointSize(size)
    int size

void
QFont::setRawMode(b)
    bool b

void
QFont::setStrikeOut(b)
    bool b

void
QFont::setStyleHint(hint)
    QFont::StyleHint hint

void
QFont::setUnderline(b)
    bool b

void
QFont::setWeight(weight)
    int weight

bool
QFont::strikeOut()

QFont::StyleHint
QFont::styleHint()

const char *
substitute(familyName)
    char *familyName
    CODE:
    RETVAL = QFont::substitute(familyName);
    OUTPUT:
    RETVAL

bool
QFont::underline()

int
QFont::weight()