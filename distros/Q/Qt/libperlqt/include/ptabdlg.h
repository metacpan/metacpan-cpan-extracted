#ifndef PTABDLG_H
#define PTABDLG_H

/*
 * Declaration of the PTabDialog class
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#undef bool
#include "qtabdlg.h"

class PTabDialog : public QTabDialog {
public:
    PTabDialog(QWidget *parent = 0, const char *name = 0, bool modal = FALSE,
	       WFlags f = 0) : QTabDialog(parent, name, modal, f) {}
};

#endif  // PTABDLG_H
