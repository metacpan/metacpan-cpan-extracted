/*
 * PerlQt interface to qlayout.h
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#include "playout.h"
#include "pqt.h"
#include "enum.h"

#define STORE_key(key) enumIV(hv, MSTR(key), QBoxLayout::key)
#define STORE_keys(key, copy) \
enum2IV(hv, MSTR(key), MSTR(copy), QBoxLayout::copy)

inline void init_enum() {
    HV *hv = perl_get_hv("QLayout::Direction", TRUE | GV_ADDMULTI);

    STORE_key(LeftToRight);
    STORE_key(RightToLeft);
    STORE_keys(TopToBottom, Down);
    STORE_keys(BottomToTop, Up);
}

MODULE = QLayout		PACKAGE = QLayout

PROTOTYPES: ENABLE

BOOT:
    init_enum();

bool
QLayout::activate()

int
QLayout::defaultBorder()

void
QLayout::freeze(...)
    CASE: items == 1
	CODE:
	THIS->freeze();
    CASE: items > 2
	PREINIT:
	int w = SvIV(ST(1));
	int h = SvIV(ST(2));
	CODE:
	THIS->freeze(w, h);

void
QLayout::setMenuBar(w)
    QMenuBar *w


MODULE = QLayout		PACKAGE = QBoxLayout

PBoxLayout *
PBoxLayout::new(...)
    CASE: items == 1
	CODE:
    CASE: !sv_isobject(ST(1))
	PREINIT:
	QBoxLayout::Direction direction = (QBoxLayout::Direction)SvIV(ST(1));
	int autoBorder = (items > 2) ? SvIV(ST(2)) : -1;
	char *name = (items > 3) ? SvPV(ST(3), na) : 0;
	CODE:
	RETVAL = new PBoxLayout(direction, autoBorder, name);
	OUTPUT:
	RETVAL
    CASE: items > 2
	PREINIT:
	QWidget *parent = pextract(QWidget, 1);
	QBoxLayout::Direction direction = (QBoxLayout::Direction)SvIV(ST(2));
	int border = (items > 3) ? SvIV(ST(3)) : 0;
	int autoBorder = (items > 4) ? SvIV(ST(4)) : -1;
	char *name = (items > 5) ? SvPV(ST(5), na) : 0;
	CODE:
	RETVAL = new PBoxLayout(parent, direction, border, autoBorder, name);
	OUTPUT:
	RETVAL

void
QBoxLayout::addLayout(layout, stretch = 0)
    QLayout *layout
    int stretch

void
QBoxLayout::addSpacing(size)
    int size

void
QBoxLayout::addStretch(stretch = 0)
    int stretch

void
QBoxLayout::addStrut(size)
    int size

void
QBoxLayout::addWidget(widget, stretch = 0, alignment = AlignCenter)
    QWidget *widget
    int stretch
    int alignment

QBoxLayout::Direction
QBoxLayout::direction()


MODULE = QLayout		PACKAGE = QGridLayout

PGridLayout *
PGridLayout::new(...)
    CASE: items < 3
	CODE:
    CASE: !sv_isobject(ST(1))
	PREINIT:
	int nRows = SvIV(ST(1));
	int nCols = SvIV(ST(2));
	int autoBorder = (items > 3) ? SvIV(ST(3)) : -1;
	char *name = (items > 4) ? SvPV(ST(4), na) : 0;
	CODE:
	RETVAL = new PGridLayout(nRows, nCols, autoBorder, name);
	OUTPUT:
	RETVAL
    CASE: items > 3
	PREINIT:
	QWidget *parent = pextract(QWidget, 1);
	int nRows = SvIV(ST(2));
	int nCols = SvIV(ST(3));
	int border = (items > 4) ? SvIV(ST(4)) : 0;
	int autoBorder = (items > 5) ? SvIV(ST(5)) : -1;
	char *name = (items > 6) ? SvPV(ST(6), na) : 0;
	CODE:
	RETVAL = new PGridLayout(parent, nRows, nCols, border, autoBorder,
				 name);
        OUTPUT:
	RETVAL

void
QGridLayout::addLayout(layout, row, col)
    QLayout *layout
    int row
    int col

void
QGridLayout::addMultiCellWidget(widget, fromRow, toRow, fromCol, toCol, align = 0)
    QWidget *widget
    int fromRow
    int toRow
    int fromCol
    int toCol
    int align

void
QGridLayout::addWidget(widget, row, col, align = 0)
    QWidget *widget
    int row
    int col
    int align

void
QGridLayout::setColStretch(col, stretch)
    int col
    int stretch

void
QGridLayout::setRowStretch(row, stretch)
    int row
    int stretch

