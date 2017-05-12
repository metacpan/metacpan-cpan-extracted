#ifndef PMENUDTA_H
#define PMENUDTA_H

/*
 * Declaration of the PMenuData class
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#undef bool
#include "qobject.h"		// Work-around for buglet
#include "qmenudta.h"
#include "qpopmenu.h"
#include "qmenubar.h"

class PMenuData : public QMenuData {
public:
    PMenuData() {}
};

#endif  // PMENUDTA_H
