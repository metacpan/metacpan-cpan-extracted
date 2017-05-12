#ifndef PPAINTER_H
#define PPAINTER_H

/*
 * Declaration of the PPainter class
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#undef bool
#include "qpainter.h"
#include "qwidget.h"
#include "pcolor.h"
#include "pfont.h"
#include "pfontinf.h"
#include "pfontmet.h"
#include "ppen.h"
#include "ppoint.h"
#include "pregion.h"
#include "pwmatrix.h"
#include "pqt.h"

class PPainter : public QPainter {
public:
    PPainter() {}
};

#endif  // PPAINTER_H
