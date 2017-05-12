#ifndef PLISTBOX_H
#define PLISTBOX_H

/*
 * Declaration of the PListBox, PListBoxText and PListBoxPixmap classes
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#undef bool
#include "qlistbox.h"

class PListBox : public QListBox {
public:
    PListBox(QWidget *parent = 0, const char *name = 0, WFlags f = 0) :
	QListBox(parent, name, f) {}
};

class PListBoxPixmap : public QListBoxPixmap {
public:
    PListBoxPixmap(const QPixmap &pixmap) : QListBoxPixmap(pixmap) {}
};

class PListBoxText : public QListBoxText {
public:
    PListBoxText(const char *text) : QListBoxText(text) {}
};

#endif  // PLISTBOX_H
