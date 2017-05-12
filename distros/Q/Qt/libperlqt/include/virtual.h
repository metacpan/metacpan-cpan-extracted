#ifndef VIRTUAL_H
#define VIRTUAL_H

/*
 * Declaration of the virtualize class
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#undef bool
#include "qevent.h"
#include "pqt.h"

class virtualize {
    SV *qtObject;
    char *qtClassName;
public:
    virtualize() { qtObject = NULL; }
    virtual ~virtualize();
    void setQtObject(SV *obj) { qtObject = obj; SvREFCNT_inc(obj); }
    SV *getQtObject() const { return qtObject; }
    char *setQtClassName(char *cname);
    char *getQtClassName() const { return qtClassName; }
    void callQtMethod(CV *method, SV *arg1 = Nullsv, SV *arg2 = Nullsv);

protected:
    void PObject_timerEvent(QTimerEvent *);

    void PWidget_mouseMoveEvent(QMouseEvent *);
    void PWidget_mousePressEvent(QMouseEvent *);
    void PWidget_mouseReleaseEvent(QMouseEvent *);
    void PWidget_paintEvent(QPaintEvent *);
    void PWidget_resizeEvent(QResizeEvent *);
};

#define pQtTHIS(type) ((p ## type *)(Q ## type *)(P ## type *)this)

#endif  // VIRTUAL_H
