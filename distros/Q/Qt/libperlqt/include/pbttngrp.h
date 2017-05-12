#ifndef PBTTNGRP_H
#define PBTTNGRP_H

/*
 * Declaration of the PButtonGroup class
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#undef bool
#include "qbttngrp.h"

class PButtonGroup : public QButtonGroup {
public:
    PButtonGroup(QWidget *parent = 0, const char *name = 0) :
	QButtonGroup(parent, name) {}
    PButtonGroup(const char *title, QWidget *parent = 0,
		 const char *name = 0) :
	QButtonGroup(title, parent, name) {}
};

#endif  // PBTTNGRP_H