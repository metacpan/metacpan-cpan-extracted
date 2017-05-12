/*
 * PerlQt interface to qlined.h
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#include "plined.h"
#include "pqt.h"

MODULE = QLineEdit		PACKAGE = QLineEdit

PROTOTYPES: ENABLE

PLineEdit *
PLineEdit::new(parent, name)
    QWidget *parent
    char *name

void
QLineEdit::deselect()

int
QLineEdit::maxLength()

void
QLineEdit::selectAll()

void
QLineEdit::setMaxLength(length)
    int length

void
QLineEdit::setText(text)
    char *text

const char *
QLineEdit::text()
