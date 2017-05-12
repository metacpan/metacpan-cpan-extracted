/*
 * PerlQt interface to qtimer.h
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#include "ptimer.h"
#include "pqt.h"
#include "sigslot.h"

MODULE = QTimer		PACKAGE = QTimer

PROTOTYPES: ENABLE

PTimer *
PTimer::new(parent = 0, name = 0)
    QObject *parent
    char *name

void
QTimer::changeInterval(msec)
    int msec

bool
QTimer::isActive()

void
singleShot(msec, receiver, member)
    int msec
    QObject *receiver
    char *member
    CODE:
    char *s = find_signal(ST(1), member);
    SV *memb = newSViv(s ? SIGNAL_CODE : SLOT_CODE);
    sv_catpv(memb, member);
    if(s) receiver = new pQtSigSlot(ST(1), s);
    else {
        s = find_slot(ST(1), member);
        if(s) receiver = new pQtSigSlot(ST(1), s);
    }
    QTimer::singleShot(msec, receiver, member);

int
QTimer::start(msec, sshot = FALSE)
    int msec
    bool sshot

void
QTimer::stop()
