#ifndef PAPP_H
#define PAPP_H

/*
 * Declaration of the PApplication class
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#undef bool
#include "qapp.h"
#include "pfontmet.h"
#include "ppalette.h"
#include "pqt.h"
#include "virtual.h"

typedef QApplication::ColorMode QApplication__ColorMode;

class PApplication : public QApplication, public virtualize {
public:
    PApplication(int &argc, char **argv) : QApplication(argc, argv) {}
};

#endif  // PAPP_H
