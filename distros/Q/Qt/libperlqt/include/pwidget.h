#ifndef PWIDGET_H
#define PWIDGET_H

/*
 * Declaration of the PWidget class
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#undef bool
#include "qwidget.h"
#include "pcolor.h"
#include "pfont.h"
#include "ppixmap.h"
#include "prect.h"
#include "pqt.h"
#include "virtual.h"

typedef QWidget::FocusPolicy QWidget__FocusPolicy;

class PWidget : public QWidget, public virtualize {
public:
    PWidget(QWidget *parent = 0, const char *name = 0, WFlags f = 0) :
	QWidget(parent, name, f) {}
    QMetaObject *metaObject() const;
    const char *className() const;
protected:
    void initMetaObject();
    void mouseMoveEvent(QMouseEvent *);
    void mousePressEvent(QMouseEvent *);
    void mouseReleaseEvent(QMouseEvent *);
    void paintEvent(QPaintEvent *);
    void resizeEvent(QResizeEvent *);
    void timerEvent(QTimerEvent *);
};

class pWidget : public QWidget {
public:
    void protected_mouseMoveEvent(QMouseEvent *event) {
	QWidget::mouseMoveEvent(event);
    }
    void protected_mousePressEvent(QMouseEvent *event) {
	QWidget::mousePressEvent(event);
    }
    void protected_mouseReleaseEvent(QMouseEvent *event) {
	QWidget::mouseReleaseEvent(event);
    }
    void protected_paintEvent(QPaintEvent *event) {
	QWidget::paintEvent(event);
    }
    void protected_resizeEvent(QResizeEvent *event) {
	QWidget::resizeEvent(event);
    }
};

#endif  // PWIDGET_H
