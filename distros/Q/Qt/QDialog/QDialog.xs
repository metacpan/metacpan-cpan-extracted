/*
 * PerlQt interface to qdialog.h
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#include "pdialog.h"
#include "pqt.h"
#include "enum.h"

#define STORE_key(key) enumIV(hv, MSTR(key), QDialog::key)
inline void init_enum() {
    HV *hv = perl_get_hv("QDialog::DialogCode", TRUE | GV_ADDMULTI);

    STORE_key(Rejected);
    STORE_key(Accepted);
}

MODULE = QDialog		PACKAGE = QDialog

PROTOTYPES: ENABLE

BOOT:
     init_enum();

PDialog *
PDialog::new(parent = 0, name = 0, modal = FALSE, f = 0)
    QWidget *parent
    char *name
    bool modal
    WFlags f

int
QDialog::exec()

int
QDialog::result()
