/*
 * PWidget definitions.
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#include "pqt.h"
#include "pobject.h"
#include "pwidget.h"
#include "virtual.h"

void PWidget::initMetaObject() {
    char *clname = (char *)getQtClassName();
    SV **svp = hv_fetch(MetaObjects, clname, strlen(clname), 1);

    if(svp && SvTRUE(*svp)) return;
    if(!QWidget::metaObject()) QWidget::initMetaObject();
    safe_hv_store(MetaObjects, clname, newSViv(0));
}

QMetaObject *PWidget::metaObject() const {
    char *clname = (char *)getQtClassName();
    return metaObjectSetup(clname);
}

const char *PWidget::className() const {
    return getQtClassName();
}

void PWidget::mouseMoveEvent(QMouseEvent *event) {
    PWidget_mouseMoveEvent(event);
}

void PWidget::mousePressEvent(QMouseEvent *event) {
    PWidget_mousePressEvent(event);
}

void PWidget::mouseReleaseEvent(QMouseEvent *event) {
    PWidget_mouseReleaseEvent(event);
}

void PWidget::paintEvent(QPaintEvent *event) {
    PWidget_paintEvent(event);
}

void PWidget::resizeEvent(QResizeEvent *event) {
    PWidget_resizeEvent(event);
}

void PWidget::timerEvent(QTimerEvent *event) {
    PObject_timerEvent(event);
}

//void virtualize::magicalCallQtMethod(QEvent *event, const char *fname,
//				     const char *objtype) {
    
void virtualize::PWidget_mouseMoveEvent(QMouseEvent *event) {
    SV *obj = obj_check(getQtObject());
    GV *fglob = gv_fetchmethod(SvSTASH(obj), "mouseMoveEvent");
    CV *func = GvCV(fglob);
    if(CvXSUB(func)) {
	pQtTHIS(Widget)->protected_mouseMoveEvent(event);
	return;
    }
    SV *ptr = objectify_ptr(event, "QMouseEvent");
    callQtMethod(func, ptr);
    SvREFCNT_dec(ptr);
}

void virtualize::PWidget_mousePressEvent(QMouseEvent *event) {
    SV *obj = obj_check(getQtObject());
    GV *fglob = gv_fetchmethod(SvSTASH(obj), "mousePressEvent");
    CV *func = GvCV(fglob);
    if(CvXSUB(func)) {
	pQtTHIS(Widget)->protected_mousePressEvent(event);
	return;
    }
    SV *ptr = objectify_ptr(event, "QMouseEvent");
    callQtMethod(func, ptr);
    SvREFCNT_dec(ptr);
}

void virtualize::PWidget_mouseReleaseEvent(QMouseEvent *event) {
    SV *obj = obj_check(getQtObject());
    GV *fglob = gv_fetchmethod(SvSTASH(obj), "mouseReleaseEvent");
    CV *func = GvCV(fglob);
    if(CvXSUB(func)) {
	pQtTHIS(Widget)->protected_mouseReleaseEvent(event);
	return;
    }
    SV *ptr = objectify_ptr(event, "QMouseEvent");
    callQtMethod(func, ptr);
    SvREFCNT_dec(ptr);
}

void virtualize::PWidget_paintEvent(QPaintEvent *event) {
    SV *obj = obj_check(getQtObject());
    GV *fglob = gv_fetchmethod(SvSTASH(obj), "paintEvent");
    CV *func = GvCV(fglob);
    if(CvXSUB(func)) {
	pQtTHIS(Widget)->protected_paintEvent(event);
	return;
    }
    SV *ptr = objectify_ptr(event, "QPaintEvent");
    callQtMethod(func, ptr);
    SvREFCNT_dec(ptr);
}

void virtualize::PWidget_resizeEvent(QResizeEvent *event) {
    SV *obj = obj_check(getQtObject());
    GV *fglob = gv_fetchmethod(SvSTASH(obj), "resizeEvent");
    CV *func = GvCV(fglob);
    if(CvXSUB(func)) {                  // Shortcut, for speed
	pQtTHIS(Widget)->protected_resizeEvent(event);
	return;
    }
    SV *ptr = objectify_ptr(event, "QResizeEvent");
    callQtMethod(func, ptr);
    SvREFCNT_dec(ptr);
}

