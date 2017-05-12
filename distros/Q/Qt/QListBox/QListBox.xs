/*
 * PerlQt interface to qlistbox.h
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#include "plistbox.h"
#include "ppixmap.h"
#include "pqt.h"

MODULE = QListBox		PACKAGE = QListBoxItem

PROTOTYPES: ENABLE

int
QListBoxItem::height(listbox)
    QListBox *listbox

PPixmap *
QListBoxItem::pixmap()
    CODE:
    RETVAL = new PPixmap(*(THIS->pixmap()));
    OUTPUT:
    RETVAL

const char *
QListBoxItem::text()

int
QListBoxItem::width(listbox)
    QListBox *listbox


MODULE = QListBox		PACKAGE = QListBoxPixmap

PListBoxPixmap *
PListBoxPixmap::new(pixmap)
    QPixmap *pixmap
    CODE:
    RETVAL = new PListBoxPixmap(*pixmap);
    OUTPUT:
    RETVAL


MODULE = QListBox		PACKAGE = QListBoxText

PListBoxText *
PListBoxText::new(text)
    char *text


MODULE = QListBox		PACKAGE = QListBox

PListBox *
PListBox::new(parent = 0, name = 0, f = 0)
    QWidget *parent
    char *name
    WFlags f

bool
QListBox::autoBottomScrollBar()

bool
QListBox::autoScroll()

bool
QListBox::autoScrollBar()

bool
QListBox::autoUpdate()

bool
QListBox::bottomScrollBar()

void
QListBox::centerCurrentItem()

void
QListBox::changeItem(thing, index)
    CASE: !sv_isobject(ST(1))
	char *thing
	int index
    CASE: sv_derived_from(ST(1), "QPixmap")
	QPixmap *thing
	int index
	CODE:
	THIS->changeItem(*thing, index);
    CASE:
	QListBoxItem *thing
	int index

void
QListBox::clear()

uint
QListBox::count()

int
QListBox::currentItem()

bool
QListBox::dragSelect()

void
QListBox::insertItem(thing, index = -1)
    CASE: !sv_isobject(ST(1))
	char *thing
	int index
    CASE: sv_derived_from(ST(1), "QPixmap")
        QPixmap *thing
        int index
        CODE:
        THIS->insertItem(*thing, index);
    CASE:
	QListBoxItem *thing
	int index

void
QListBox::insertStrList(index, str1, ...)
    int index
    PREINIT:
    char **strings;
    CODE:
    New(123, strings, items-2, char *);
    for(int i = 2; i < items; i++)
        strings[i-2] = SvPV(ST(i), na);
    THIS->insertStrList((const char **)strings, (int)items-2, (int)index);
    Safefree(strings);

void
QListBox::inSort(thing)
    CASE: sv_isobject(ST(1))
	QListBoxItem *thing
    CASE:
	char *thing

int
QListBox::itemHeight(...)
    CASE: items > 1
	PREINIT:
	int index = SvIV(ST(1));
	CODE:
	RETVAL = THIS->itemHeight(index);
	OUTPUT:
	RETVAL
    CASE:

long
QListBox::maxItemWidth()
	
int
QListBox::numItemsVisible()

PPixmap *
QListBox::pixmap(index)
    int index
    PREINIT:
    const QPixmap *pixmap;
    CODE:
    pixmap = THIS->pixmap(index);
    if(!pixmap) XSRETURN_UNDEF;		// Fix the others that don't do this
    RETVAL = new PPixmap(*pixmap);
    OUTPUT:
    RETVAL

void
QListBox::removeItem(index)
    int index

bool
QListBox::scrollBar()

void
QListBox::setAutoBottomScrollBar(b)
    bool b

void
QListBox::setAutoScroll(b)
    bool b

void
QListBox::setAutoScrollBar(b)
    bool b

void
QListBox::setAutoUpdate(b)
    bool b

void
QListBox::setBottomScrollBar(b)
    bool b

void
QListBox::setCurrentItem(index)
    int index

void
QListBox::setDragSelect(b)
    bool b

void
QListBox::setScrollBar(b)
    bool b

void
QListBox::setSmoothScrolling(b)
    bool b

void
QListBox::setTopItem(index)
    int index

bool
QListBox::smoothScrolling()

const char *
QListBox::text(index)
    int index

int
QListBox::topItem()