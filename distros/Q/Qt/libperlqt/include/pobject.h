#ifndef POBJECT_H
#define POBJECT_H

class pObject;

/*
 * Declaration of the PObject class
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#undef bool
#include "qobject.h"
#include "pqt.h"
#include "virtual.h"
#include "sigslot.h"

class PObject : public QObject, public virtualize {
public:
    PObject(QObject *parent=0, const char *name=0) : QObject(parent, name) {}
    const char *className();
    void activateI(const char *, IV);
protected:
    void timerEvent(QTimerEvent *);
};

class pObject : public QObject {
public:
    QConnectionList *protected_receivers(const char *signal) const {
	return receivers(signal);
    }
    void protected_initMetaObject() { initMetaObject(); }
    void protected_timerEvent(QTimerEvent *);
};

extern char *getPerlSuperClass(char *clname);
extern QMetaObject *metaObjectSetup(char *clname);

extern HV *Signals;
extern HV *Slots;
extern HV *MetaObjects;

#endif  // POBJECT_H
