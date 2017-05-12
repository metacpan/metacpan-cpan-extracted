#ifndef PFONTMET_H
#define PFONTMET_H

/*
 * Declaration of the PFontMetrics class
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#undef bool
#include "qfontmet.h"
#include "pfont.h"
#include "prect.h"
#include "pqt.h"

class PFontMetrics : public QFontMetrics {
public:
    PFontMetrics(const QFontMetrics &fontMet) : QFontMetrics(fontMet) {
	*(QFontMetrics *)this = fontMet;
    }
};
#endif  // PFONTMET_H
