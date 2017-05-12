#ifndef PSLIDER_H
#define PSLIDER_H

/*
 * Declaration of the PSlider class
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#undef bool
#include <qslider.h>
#include "virtual.h"

typedef QSlider::Orientation QSlider__Orientation;
typedef QSlider::TickSetting QSlider__TickSetting;

class PSlider : public QSlider, public virtualize {
public:
    PSlider(QWidget *parent = 0, const char *name = 0) :
	QSlider(parent, name) {}
    PSlider(QSlider::Orientation orientation, QWidget *parent = 0,
	    const char *name = 0) :
	QSlider(orientation, parent, name) {}
    PSlider(int minValue, int maxValue, int step, int value,
	    QSlider::Orientation orientation, QWidget *parent = 0,
	    const char *name = 0) :
	QSlider(minValue, maxValue, step, value, orientation, parent, name) {}
};

#endif  // PSLIDER_H
