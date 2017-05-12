/*
 * PerlQt interface to qmsgbox.h
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#include "pmsgbox.h"
#include "pqt.h"

MODULE = QMessageBox		PACKAGE = QMessageBox

PROTOTYPES: ENABLE

PMessageBox *
PMessageBox::new(parent = 0, name = 0)
    QWidget *parent
    char *name

void
QMessageBox::adjustSize()

const char *
QMessageBox::buttonText()

int
message(caption, text, buttonText = 0, parent = 0, name = 0)
    char *caption
    char *text
    char *buttonText
    QWidget *parent
    char *name
    CODE:
    RETVAL = QMessageBox::message(caption, text, buttonText, parent, name);
    OUTPUT:
    RETVAL

bool
query(caption, text, yesButtonText = 0, noButtonText = 0, parent = 0, name = 0)
    char *caption
    char *text
    char *yesButtonText
    char *noButtonText
    QWidget *parent
    char *name
    CODE:
    RETVAL = QMessageBox::query(caption, text, yesButtonText, noButtonText,
				parent, name);
    OUTPUT:
    RETVAL

void
QMessageBox::setButtonText(text)
    char *text

void
QMessageBox::setText(text)
    char *text

const char *
QMessageBox::text()