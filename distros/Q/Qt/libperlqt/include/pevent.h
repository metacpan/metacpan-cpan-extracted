#ifndef PEVENT_H
#define PEVENT_H

/*
 * Declaration of the PEvent class
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#undef bool
#include "qevent.h"
#include "enum.h"
#include "prect.h"
#include "pqt.h"

class PEvent : public QEvent {
public:
    PEvent(int type) : QEvent(type) {}
};

class PCloseEvent : public QCloseEvent {
public:
    PCloseEvent() {}
};

class PFocusEvent : public QFocusEvent {
public:
    PFocusEvent(int type) : QFocusEvent(type) {}
};

class PKeyEvent : public QKeyEvent {
public:
    PKeyEvent(int type, int key, int ascii, int state) :
	QKeyEvent(type, key, ascii, state) {}
};

class PMouseEvent : public QMouseEvent {
public:
    PMouseEvent(int type, const QPoint &pos, int button, int state) :
	QMouseEvent(type, pos, button, state) {}
};

class PMoveEvent : public QMoveEvent {
public:
    PMoveEvent(const QPoint &pos, const QPoint &oldPos) :
	QMoveEvent(pos, oldPos) {}
};

class PPaintEvent : public QPaintEvent {
public:
    PPaintEvent(const QRect &paintRect) : QPaintEvent(paintRect) {}
};

class PResizeEvent : public QResizeEvent {
public:
    PResizeEvent(const QSize &size, const QSize &oldSize) :
	QResizeEvent(size, oldSize) {}
};

class PTimerEvent : public QTimerEvent {
public:
    PTimerEvent(int timerId) : QTimerEvent(timerId) {}
};

#endif  // PEVENT_H
