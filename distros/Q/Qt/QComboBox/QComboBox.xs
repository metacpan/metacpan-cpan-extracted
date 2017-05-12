/*
 * PerlQt interface to qcombo.h
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#include "pcombo.h"
#include "ppixmap.h"
#include "pqt.h"
#include "enum.h"

#define STORE_key(key) enumIV(hv, MSTR(key), QComboBox::key)

inline void init_enum() {
    HV *hv = perl_get_hv("QComboBox::Policy", TRUE | GV_ADDMULTI);

    STORE_key(NoInsertion);
    STORE_key(AtTop);
    STORE_key(AtCurrent);
    STORE_key(AtBottom);
}

MODULE = QComboBox		PACKAGE = QComboBox

PROTOTYPES: ENABLE

BOOT:
    init_enum();

PComboBox *
PComboBox::new(...)
    CASE: items == 1
	CODE:
	RETVAL = new PComboBox();
	OUTPUT:
	RETVAL
    CASE: sv_isobject(ST(1))
	PREINIT:
	QWidget *parent = pextract(QWidget, 1);
	char *name = (items > 2) ? SvPV(ST(2), na) : 0;
	CODE:
	RETVAL = new PComboBox(parent, name);
	OUTPUT:
	RETVAL
    CASE:
	PREINIT:
	bool rw = SvTRUE(ST(1)) ? TRUE : FALSE;
	QWidget *parent = (items > 2) ? pextract(QWidget, 2) : 0;
	char *name = (items > 3) ? SvPV(ST(3), na) : 0;
	CODE:
	RETVAL = new PComboBox(rw, parent, name);
	OUTPUT:
	RETVAL

bool
QComboBox::autoResize()

void
QComboBox::changeItem(thing, index)
    CASE: sv_isobject(ST(1))
	QPixmap *thing
	int index
	CODE:
	THIS->changeItem(*thing, index);
    CASE:
	char *thing
	int index

int
QComboBox::count()

int
QComboBox::currentItem()

QComboBox::Policy
QComboBox::insertionPolicy()

void
QComboBox::insertItem(thing, index = -1)
    CASE: sv_isobject(ST(1))
	QPixmap *thing
	int index
	CODE:
	THIS->insertItem(*thing, index);
    CASE:
	char *thing
	int index

void
QComboBox::insertStrList(index, str1, ...)
    int index
    PREINIT:
    char **strings;
    CODE:
    New(123, strings, items-2, char *);
    for(int i = 2; i < items; i++)
	strings[i-2] = SvPV(ST(i), na);
    THIS->insertStrList((const char **)strings, (int)items-2, (int)index);
    Safefree(strings);

int
QComboBox::maxCount()

PPixmap *
QComboBox::pixmap(index)
    int index
    CODE:
    RETVAL = new PPixmap(*(THIS->pixmap(index)));
    OUTPUT:
    RETVAL

void
QComboBox::removeItem(index)
    int index

void
QComboBox::setAutoResize(b)
    bool b

void
QComboBox::setCurrentItem(index)
    int index

void
QComboBox::setInsertionPolicy(policy)
    QComboBox::Policy policy

void
QComboBox::setMaxCount(count)
    int count

void
QComboBox::setSizeLimit(limit)
    int limit

int
QComboBox::sizeLimit()

const char *
QComboBox::text(index)
    int index