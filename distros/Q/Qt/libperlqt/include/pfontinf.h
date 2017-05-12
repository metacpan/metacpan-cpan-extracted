#ifndef PFONTINF_H
#define PFONTINF_H

/*
 * Declaration of the PFontInfo class
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#undef bool
#include "qfontinf.h"
#include "pfont.h"
#include "pqt.h"

class PFontInfo : public QFontInfo {
public:
    PFontInfo(const QFontInfo &fontinf) : QFontInfo(fontinf) {}
};

#endif  // PFONTINF_H
