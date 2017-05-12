#ifndef PLABEL_H
#define PLABEL_H

/*
 * Declaration of the PLabel class
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#undef bool
#include "qlabel.h"
#include "psize.h"
#include "pqt.h"
#include "virtual.h"

class PLabel : public QLabel, public virtualize {
public:
    PLabel(QWidget *parent = 0, const char *name = 0, WFlags f = 0) :
	QLabel(parent, name, f) {}
    PLabel(const char *text, QWidget *parent = 0, const char *name = 0,
	   WFlags f = 0) : QLabel(text, parent, name, f) {}

    QMetaObject *metaObject();
    const char *className() const;
protected:
    void initMetaObject();
};

#endif  // PLABEL_H
