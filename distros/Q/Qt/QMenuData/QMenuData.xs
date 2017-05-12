/*
 * PerlQt interface to qmenudta.h
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#include "pmenudta.h"
#include "ppixmap.h"
#include "pqt.h"
#include "sigslot.h"

MODULE = QMenuData		PACKAGE = QMenuData

PROTOTYPES: ENABLE

PMenuData *
PMenuData::new()

int
QMenuData::accel(id)
    int id

void
QMenuData::changeItem(thing, id)
    CASE: sv_isobject(ST(1))
	QPixmap *thing
	int id
	CODE:
	THIS->changeItem(*thing, id);
    CASE:
	char *thing
	int id

void
QMenuData::clear()

bool
QMenuData::connectItem(id, receiver, member)
    int id
    QObject *receiver
    CODE:
    SV *m = parse_member(ST(3));
    char *member = SvPV(m, na);
    char *s = find_signal(ST(2), member);
    SV *memb = newSViv(s ? SIGNAL_CODE : SLOT_CODE);
    sv_catpv(memb, member);
    if(s) receiver = new pQtSigSlot(ST(2), s);
    else {
        s = find_slot(ST(2), member);
        if(s) receiver = new pQtSigSlot(ST(2), s);
    }
    RETVAL = THIS->connectItem(id, receiver, SvPVX(memb));
    OUTPUT:
    RETVAL

uint
QMenuData::count()

bool
QMenuData::disconnectItem(id, reciever, member)
    int id
    QObject *reciever
    CODE:
    SV *m = parse_member(ST(3));
    char *member = SvPV(m, na);
    char *s = find_signal(ST(2), member);
    SV *memb = newSViv(s ? SIGNAL_CODE : SLOT_CODE);
    sv_catpv(memb, member);
    RETVAL = THIS->disconnectItem(id, reciever, SvPVX(memb));
    OUTPUT:
    RETVAL

int
QMenuData::idAt(index)
    int index

int
QMenuData::indexOf(id)
    int id

int
QMenuData::insertItem(arg1, ...)
    CASE: (items == 2 || !sv_isobject(ST(2))) && !sv_isobject(ST(1))
	PREINIT:
	char *text = SvPV(ST(1), na);
	int id = (items > 2) ? SvIV(ST(2)) : -1;
	int index = (items > 3) ? SvIV(ST(3)) : -1;
	CODE:
	RETVAL = THIS->insertItem(text, id, index);
	OUTPUT:
	RETVAL
    CASE: items > 2 && !sv_isobject(ST(1)) && sv_isobject(ST(2)) && sv_derived_from(ST(2), "QPopupMenu")
	PREINIT:
	char *text = SvPV(ST(1), na);
	QPopupMenu *popup = pextract(QPopupMenu, 2);
	int id = (items > 3) ? SvIV(ST(3)) : -1;
	int index = (items > 4) ? SvIV(ST(4)) : -1;
	CODE:
	RETVAL = THIS->insertItem(text, popup, id, index);
	OUTPUT:
	RETVAL
    CASE: items > 3 && !sv_isobject(ST(1))
	PREINIT:
	char *text = SvPV(ST(1), na);
	QObject *receiver = pextract(QObject, 2);
//	char *member = SvPV(ST(3), na);
	SV *m = parse_member(ST(3));
	char *member = SvPV(m, na);
	int accel = (items > 4) ? SvIV(ST(4)) : 0;
	CODE:
	char *s = find_signal(ST(2), member);
	SV *memb = newSViv(s ? SIGNAL_CODE : SLOT_CODE);
	sv_catpv(memb, member);
	if(s) receiver = new pQtSigSlot(ST(2), s);
	else {
	    s = find_slot(ST(2), member);
	    if(s) receiver = new pQtSigSlot(ST(2), s);
	}

	RETVAL = THIS->insertItem(text, receiver, SvPVX(memb), accel);
	OUTPUT:
	RETVAL
    CASE: items > 2 && !sv_isobject(ST(1)) 
	PREINIT:
	char *text = SvPV(ST(1), na);
	QPopupMenu *popup = pextract(QPopupMenu, 2);
	int id = (items > 3) ? SvIV(ST(3)) : -1;
	int index = (items > 4) ? SvIV(ST(4)) : -1;
	CODE:
	RETVAL = THIS->insertItem(text, popup, id, index);
	OUTPUT:
	RETVAL
    CASE: items == 2 || !sv_isobject(ST(2))
	PREINIT:
	QPixmap *pixmap = pextract(QPixmap, 1);
	int id = (items > 2) ? SvIV(ST(2)) : -1;
	int index = (items > 3) ? SvIV(ST(3)) : -1;
	CODE:
	RETVAL = THIS->insertItem(*pixmap, id, index);
	OUTPUT:
	RETVAL
    CASE: sv_derived_from(ST(2), "QPopupMenu")
	PREINIT:
	QPixmap *pixmap = pextract(QPixmap, 1);
	QPopupMenu *popup = pextract(QPopupMenu, 2);
	int id = (items > 3) ? SvIV(ST(3)) : -1;
	int index = (items > 4) ? SvIV(ST(4)) : -1;
	CODE:
	RETVAL = THIS->insertItem(*pixmap, popup, id, index);
	OUTPUT:
	RETVAL
    CASE: items > 3
	PREINIT:
	QPixmap *pixmap = pextract(QPixmap, 1);
	QObject *receiver = pextract(QObject, 2);
//	char *member = SvPV(ST(3), na);
	SV *m = parse_member(ST(3));
	char *member = SvPV(m, na);
	int accel = (items > 4) ? SvIV(ST(4)) : 0;
	CODE:
	char *s = find_signal(ST(2), member);
	SV *memb = newSViv(s ? SIGNAL_CODE : SLOT_CODE);
	sv_catpv(memb, member);
	if(s) receiver = new pQtSigSlot(ST(2), s);
	else {
	    s = find_slot(ST(2), member);
	    if(s) receiver = new pQtSigSlot(ST(2), s);
	}

	RETVAL = THIS->insertItem(*pixmap, receiver, SvPVX(memb), accel);
	OUTPUT:
	RETVAL

void
QMenuData::insertSeparator(index = -1)
    int index

bool
QMenuData::isItemChecked(id)
    int id

bool
QMenuData::isItemEnabled(id)
    int id

QPixmap *
QMenuData::pixmap(id)
    int id
    
void
QMenuData::removeItem(id)
    int id

void
QMenuData::removeItemAt(index)
    int index

void
QMenuData::setAccel(key, id)
    int key
    int id

void
QMenuData::setId(index, id)
    int index
    int id

void
QMenuData::setItemChecked(id, check)
    int id
    bool check

void
QMenuData::setItemEnabled(id, enable)
    int id
    bool enable

const char *
QMenuData::text(id)
    int id

void
QMenuData::updateItem(id)
    int id
