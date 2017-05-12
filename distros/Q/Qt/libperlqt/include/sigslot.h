#ifndef SIGSLOT_H
#define SIGSLOT_H

/*
 * Declaration of the pQtSigSlot class
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#undef bool
#include "qmetaobj.h"
#include "qobject.h"
#include "pobject.h"
#include "pqt.h"

class pQtSigSlot : public QObject {
    SV *object;
    pObject *qobj;
    char *sname;
protected:
    void initMetaObject();
public:
    pQtSigSlot(SV *obj, char *name) {
        object = newSVsv(obj);
//	warn("OBJECT = %p\n", object);
	qobj = (pObject *)extract_ptr(object, "QObject");
	sname = new char[strlen(name)+1];
	strcpy(sname, name);
    }
    ~pQtSigSlot() { delete [] sname; SvREFCNT_dec(object); }
    QMetaObject *metaObject() const;
    const char *className() const;
    void slot1(SV *);
    void slot2(SV *, SV *);
    void s();
    void sI(IV);
    void sII(IV, IV);
};

QMember stub_func(char *member);

#endif  // SIGSLOT_H
