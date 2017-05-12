/*
 * PerlQt interface to qmlined.h
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#include "pmlined.h"
#include "pqt.h"

MODULE = QMultiLineEdit		PACKAGE = QMultiLineEdit

PROTOTYPES: ENABLE

PMultiLineEdit *
PMultiLineEdit::new(parent = 0, name = 0)
    QWidget *parent
    char *name

void
QMultiLineEdit::append(text)
    char *text

bool
QMultiLineEdit::atBeginning()

bool
QMultiLineEdit::atEnd()

bool
QMultiLineEdit::autoUpdate()

void
QMultiLineEdit::clear()

void
QMultiLineEdit::copyText()

void
QMultiLineEdit::cut()

void
QMultiLineEdit::deselect()

void
QMultiLineEdit::getCursorPosition(line, col)
    int &line
    int &col
    OUTPUT:
    line
    col

void
QMultiLineEdit::insertAt(s, line, col)
    char *s
    int line
    int col

void
QMultiLineEdit::insertLine(s, line = -1)
    char *s
    int line

bool
QMultiLineEdit::isOverwriteMode()

bool
QMultiLineEdit::isReadOnly()

int
QMultiLineEdit::numLines()

void
QMultiLineEdit::paste()

void
QMultiLineEdit::removeLine(line)
    int line

void
QMultiLineEdit::selectAll()

void
QMultiLineEdit::setAutoUpdate(b)
    bool b

void
QMultiLineEdit::setCursorPosition(line, col, mark = FALSE)
    int line
    int col
    bool mark

void
QMultiLineEdit::setOverwriteMode(b)
    bool b

void
QMultiLineEdit::setReadOnly(b)
    bool b

void
QMultiLineEdit::setText(text)
    char *text

const char *
QMultiLineEdit::text()

const char *
QMultiLineEdit::textLine(line)
    int line