/*
 * PerlQt interface to qobject.h
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#undef bool
#include "qmetaobj.h"
#include "pobject.h"

#if !defined(Q_MOC_CONNECTIONLIST_DECLARED)
#define Q_MOC_CONNECTIONLIST_DECLARED
#include <qlist.h>
#if defined(Q_DECLARE)
Q_DECLARE(QListM,QConnection);
Q_DECLARE(QListIteratorM,QConnection);
#else
// for compatibility with old header files
declare(QListM,QConnection);
declare(QListIteratorM,QConnection);
#endif
#endif

void activate(QObject *self, const char *signal) {
    QConnectionList *clist = ((pObject *)self)->protected_receivers(signal);
    if(!clist || self->signalsBlocked()) return;
    typedef void (QObject::*RT)();
    typedef RT *PRT;
    RT r;

    QConnectionListIt it(*clist);
    QConnection *c;
    QSenderObject *object;
    while((c=it.current())) {
	++it;
	object = (QSenderObject*)c->object();
	object->setSender(self);
	r = *((PRT)(c->member()));
	(object->*r)();
    }
}

void activateI(QObject *self, const char *signal, IV param) {
    QConnectionList *clist = ((pObject *)self)->protected_receivers(signal);
    if(!clist || self->signalsBlocked()) return;
    typedef void (QObject::*RT0)();
    typedef RT0 *PRT0;
    typedef void (QObject::*RT1)(IV);
    typedef RT1 *PRT1;
    RT0 r0;
    RT1 r1;

    QConnectionListIt it(*clist);
    QConnection *c;
    QSenderObject *object;
    while((c=it.current())) {
	++it;
	object = (QSenderObject*)c->object();
	object->setSender(self);
	if(c->numArgs()) {
	    r1 = *((PRT1)(c->member()));
	    (object->*r1)(param);
	} else {
	    r0 = *((PRT0)(c->member()));
	    (object->*r0)();
	}
    }
}

XS(perl_emit_signal) {
    dXSARGS;
    char *sname = HvNAME(GvSTASH(CvGV(cv)));
    char *fname = GvNAME(CvGV(cv));
    char *proto;
    SV **svp = hv_fetch(Signals, sname, strlen(sname), 0);
    if(!svp) {
	warn("Not a signal!\n");
	return;
    }
    svp = hv_fetch((HV *)rv_check(*svp), fname, strlen(fname), 0);
    if(!svp) {
	warn("Not a signal!\n");
	return;
    }
    proto = SvPV(*svp, na);

    PObject *obj = (PObject *)extract_ptr(ST(0), "QObject");
    if(items == 1)
	activate(obj, proto);
    else if(items > 1) {
	if(SvIOK(ST(1)))
	    activateI(obj, proto, SvIV(ST(1)));
	else if(SvPOK(ST(1)))
	    activateI(obj, proto, (IV)SvPV(ST(1), na));
    }
}

MODULE = QObject		PACKAGE = signals

void
addSignal(name)
    char *name
    CODE:
    newXS(name, perl_emit_signal, __FILE__);

MODULE = QObject		PACKAGE = QObject

PROTOTYPES: ENABLE

BOOT:
    MetaObjects = newHV();
    Signals = perl_get_hv("signals::signals", TRUE);
    Slots = perl_get_hv("slots::slots", TRUE);
    SvREFCNT_inc((SV *)Signals);
    SvREFCNT_inc((SV *)Slots);

PObject *
PObject::new(parent=0, name=0)
    QObject *parent
    char *name

void
QObject::blockSignals(b)
    bool b

const char *
QObject::className()

bool
connect(...)
    PREINIT:
    if(items < 4)
        croak("Usage: QObject::connect(sender, signal, receiver, member);\nUsage: $receiver->connect(sender, signal, member);");
    bool virtual_call = sv_isobject(ST(1));
    QObject *receiver =
        (QObject *)extract_ptr(ST(virtual_call ? 0 : 2), "QObject");
    QObject *sender =
        (QObject *)extract_ptr(ST(virtual_call ? 1 : 0), "QObject");
    SV *si = parse_member(ST(virtual_call ? 2 : 1));
    SV *m = parse_member(ST(3));
    char *signal = SvPV(si, na);
    char *member = SvPV(m, na); // SvPV(ST(3), na);
    SV *sig = sv_2mortal(newSViv(SIGNAL_CODE));		// Emulate SIGNAL()
    SV *memb = sv_newmortal();
    char *s = find_signal(ST(virtual_call ? 0 : 2), member);
    sv_setiv(memb, s ? SIGNAL_CODE : SLOT_CODE);
    if(s) receiver = new pQtSigSlot(ST(virtual_call ? 0 : 2), s);
    else {
	s = find_slot(ST(virtual_call ? 0 : 2), member);
	if(s) receiver = new pQtSigSlot(ST(virtual_call ? 0 : 2), s);
    }
    CODE:
    sv_catpv(sig, signal);
    sv_catpv(memb, member);
    RETVAL = receiver->connect(sender, SvPV(sig, na), SvPV(memb, na));
    OUTPUT:
    RETVAL

bool
disconnect(...)
    CASE: items > 1 && sv_isobject(ST(1))
	PREINIT:
	QObject *sender   = (QObject *)extract_ptr(ST(0), "QObject");
	QObject *receiver = (QObject *)extract_ptr(ST(1), "QObject");
	char *member = (items > 2) ? SvPV(ST(2), na) : 0;
	SV *memb;
	CODE:
	if(member) {
	    memb = sv_2mortal(newSViv(find_signal(ST(1), member) ?
		SIGNAL_CODE : SLOT_CODE));
	    sv_catpv(memb, member);
	    member = SvPVX(memb);
	}
	RETVAL = sender->disconnect(receiver, member);
	OUTPUT:
	RETVAL
    CASE: items > 1
	PREINIT:
	QObject *sender   = (QObject *)extract_ptr(ST(0), "QObject");
	char *signal	  = (items > 1) ? SvPV(ST(1), na) : 0;
	QObject *receiver = (items > 2) ?
	    (QObject *)extract_ptr(ST(2), "QObject") : 0;
	char *member	  = (items > 3) ? SvPV(ST(3), na) : 0;
	SV *sv;
	CODE:
	if(signal) {
	    sv = sv_2mortal(newSViv(SIGNAL_CODE));
	    sv_catpv(sv, signal);
	    signal = SvPVX(sv);
	}
	if(member) {
	    sv = sv_2mortal(newSViv(find_signal(ST(2), member) ?
		SIGNAL_CODE : SLOT_CODE));
	    sv_catpv(sv, member);
	    member = SvPVX(sv);
	}
	RETVAL = sender->disconnect(signal, receiver, member);
	OUTPUT:
	RETVAL
    CASE:
	CODE:
	croak("Usage: $sender->disconnect(signal = undef, receiver = undef, member = undef);\nUsage: $sender->disconnect(receiver, member = undef);");

void
QObject::dumpObjectInfo()

void
QObject::dumpObjectTree()

bool
QObject::event(event)
    QEvent *event

bool
QObject::eventFilter(obj, event)
    QObject *obj
    QEvent *event

bool
QObject::highPriority()

bool
QObject::inherits(classname)
    char *classname

void
QObject::insertChild(obj)
    QObject *obj

void
QObject::installEventFilter(obj)
    QObject *obj

bool
QObject::isA(classname)
    char *classname

bool
QObject::isWidgetType()

void
QObject::killTimer(id)
    int id

void
QObject::killTimers()

QObject *
QObject::parent()

void
QObject::removeChild(obj)
    QObject *obj

void
QObject::removeEventFilter(obj)
    QObject *obj

void
QObject::setName(name)
    char *name

bool
QObject::signalsBlocked()

int
QObject::startTimer(interval)
    int interval

MODULE = QObject	PACKAGE = QObject	PREFIX = protected_

void
pObject::protected_timerEvent(event)
    QTimerEvent *event
