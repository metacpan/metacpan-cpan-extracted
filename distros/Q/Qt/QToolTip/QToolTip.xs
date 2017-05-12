/*
 * PerlQt interface to qtooltip.h
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#include "ptooltip.h"
#include "pqt.h"

MODULE = QToolTip		PACKAGE = QToolTipGroup

PROTOTYPES: ENABLE

PToolTipGroup *
PToolTipGroup::new(parent, name)
    QObject *parent
    char *name

MODULE = QToolTip		PACKAGE = QToolTip

void
add(...)
    CASE: items == 2
	PREINIT:
	QWidget *widget = pextract(QWidget, 0);
	char *text = SvPV(ST(1), na);
	CODE:
	QToolTip::add(widget, text);
    CASE: items == 3
	PREINIT:
	QWidget *widget = pextract(QWidget, 0);
	QRect *rect = pextract(QRect, 1);
	char *text = SvPV(ST(2), na);
	CODE:
	QToolTip::add(widget, *rect, text);
    CASE: items == 4
	PREINIT:
	QWidget *widget = pextract(QWidget, 0);
	char *text = SvPV(ST(1), na);
	QToolTipGroup *group = pextract(QToolTipGroup, 2);
	char *longText = SvPV(ST(3), na);
	CODE:
	QToolTip::add(widget, text, group, longText);
    CASE: items == 5
	PREINIT:
	QWidget *widget = pextract(QWidget, 0);
	QRect *rect = pextract(QRect, 1);
	char *text = SvPV(ST(2), na);
	QToolTipGroup *group = pextract(QToolTipGroup, 3);
	char *longText = SvPV(ST(4), na);
	CODE:
	QToolTip::add(widget, *rect, text, group, longText);

void
remove(...)
    CASE: items == 1
	PREINIT:
	QWidget *widget = pextract(QWidget, 0);
	CODE:
	QToolTip::remove(widget);
    CASE: items == 2
	PREINIT:
	QWidget *widget = pextract(QWidget, 0);
	QRect *rect = pextract(QRect, 1);
	CODE:
	QToolTip::remove(widget, *rect);
