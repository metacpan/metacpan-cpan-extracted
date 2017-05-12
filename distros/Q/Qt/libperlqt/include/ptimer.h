#ifndef PTIMER_H
#define PTIMER_H

/*
 * Declaration of the PTimer class
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#undef bool
#include "qtimer.h"

class PTimer : public QTimer {
public:
    PTimer(QObject *parent = 0, const char *name = 0) : QTimer(parent, name) {}
};

#endif  // PTIMER_H
