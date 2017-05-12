/*
 * PerlQt interface to qtabdlg.h
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#include "ptabdlg.h"
#include "pqt.h"

MODULE = QTabDialog		PACKAGE = QTabDialog

PROTOTYPES: ENABLE

PTabDialog *
PTabDialog::new(parent = 0, name = 0, modal = FALSE, f = 0)
    QWidget *parent
    char *name
    bool modal
    WFlags f

void
QTabDialog::addTab(child, label)
    QWidget *child
    char *label

bool
QTabDialog::hasApplyButton()

bool
QTabDialog::hasCancelButton()

bool
QTabDialog::hasDefaultButton()

bool
QTabDialog::isTabEnabled(name)
    char *name

void
QTabDialog::setApplyButton(text = "Apply")
    char *text

void
QTabDialog::setCancelButton(text = "Cancel")
    char *text

void
QTabDialog::setDefaultButton(text = "Defaults")
    char *text

void
QTabDialog::setTabEnabled(name, enable)
    char *name
    bool enable
