/*
 * PerlQt interface to qpalette.h
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#include "ppalette.h"

MODULE = QPalette		PACKAGE = QColorGroup

PROTOTYPES: ENABLE

PColorGroup *
PColorGroup::new(...)
    CASE: items == 1
	CODE:
	RETVAL = new PColorGroup();
	OUTPUT:
	RETVAL
    CASE: items > 7
	PREINIT:
	QColor *foreground = pextract(QColor, 1);
	QColor *background = pextract(QColor, 2);
	QColor *light = pextract(QColor, 3);
	QColor *dark = pextract(QColor, 4);
	QColor *mid = pextract(QColor, 5);
	QColor *text = pextract(QColor, 6);
	QColor *base = pextract(QColor, 7);
	CODE:
	RETVAL = new PColorGroup(*foreground, *background, *light, *dark,
				 *mid, *text, *base);
	OUTPUT:
	RETVAL

PColor *
QColorGroup::background()
    CODE:
    RETVAL = new PColor(THIS->background());
    OUTPUT:
    RETVAL

PColor *
QColorGroup::base()
    CODE:
    RETVAL = new PColor(THIS->base());
    OUTPUT:
    RETVAL

PColor *
QColorGroup::dark()
    CODE:
    RETVAL = new PColor(THIS->dark());
    OUTPUT:
    RETVAL

PColor *
QColorGroup::foreground()
    CODE:
    RETVAL = new PColor(THIS->foreground());
    OUTPUT:
    RETVAL

PColor *
QColorGroup::light()
    CODE:
    RETVAL = new PColor(THIS->light());
    OUTPUT:
    RETVAL

PColor *
QColorGroup::mid()
    CODE:
    RETVAL = new PColor(THIS->mid());
    OUTPUT:
    RETVAL

PColor *
QColorGroup::text()
    CODE:
    RETVAL = new PColor(THIS->text());
    OUTPUT:
    RETVAL

MODULE = QPalette		PACKAGE = QPalette

PPalette *
PPalette::new(...)
    CASE: items == 1
	CODE:
	RETVAL = new PPalette();
	OUTPUT:
	RETVAL
    CASE: items > 3
	PREINIT:
	QColorGroup *normal = pextract(QColorGroup, 1);
	QColorGroup *disabled = pextract(QColorGroup, 2);
	QColorGroup *active = pextract(QColorGroup, 3);
	CODE:
	RETVAL = new PPalette(*normal, *disabled, *active);
	OUTPUT:
	RETVAL

PColorGroup *
QPalette::active()
    CODE:
    RETVAL = new PColorGroup(THIS->active());
    OUTPUT:
    RETVAL

PPalette *
QPalette::copy()
    CODE:
    RETVAL = new PPalette(THIS->copy());
    OUTPUT:
    RETVAL

PColorGroup *
QPalette::disabled()
    CODE:
    RETVAL = new PColorGroup(THIS->disabled());
    OUTPUT:
    RETVAL

PColorGroup *
QPalette::normal()
    CODE:
    RETVAL = new PColorGroup(THIS->normal());
    OUTPUT:
    RETVAL

void
QPalette::setActive(colorgroup)
    QColorGroup *colorgroup
    CODE:
    THIS->setActive(*colorgroup);

void
QPalette::setDisabled(colorgroup)
    QColorGroup *colorgroup
    CODE:
    THIS->setDisabled(*colorgroup);

void
QPalette::setNormal(colorgroup)
    QColorGroup *colorgroup
    CODE:
    THIS->setNormal(*colorgroup);

int
QPalette::serialNumber()