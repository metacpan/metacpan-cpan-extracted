#ifndef PDIALOG_H
#define PDIALOG_H

/*
 * Declaration of the PDialog class
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#undef bool
#include "qdialog.h"

class PDialog : public QDialog {
public:
    PDialog(QWidget *parent = 0, const char *name = 0, bool modal = FALSE,
	    WFlags f=0) : QDialog(parent, name, modal, f) {}
};

#endif  // PDIALOG_H
