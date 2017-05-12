/*
 * PerlQt interface to qframe.h
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#include "pframe.h"
#include "enum.h"

#define STORE_key(key) enumIV(hv, MSTR(key), QFrame::key)

inline void init_enum() {
    HV *hv = perl_get_hv("QFrame::QFrame", TRUE | GV_ADDMULTI);

    STORE_key(NoFrame);
    STORE_key(Box);
    STORE_key(Panel);
    STORE_key(WinPanel);
    STORE_key(HLine);
    STORE_key(VLine);
    STORE_key(MShape);
    STORE_key(Plain);
    STORE_key(Raised);
    STORE_key(Sunken);
    STORE_key(MShadow);
}

MODULE = QFrame		PACKAGE = QFrame		

PROTOTYPES: ENABLE

BOOT:
    init_enum();

PFrame *
PFrame::new(parent = 0, name = 0, f = 0, allowLines = TRUE)
    QWidget *parent
    char *name
    WFlags f
    bool allowLines

PRect *
QFrame::contentsRect()
    CODE:
    RETVAL = new PRect(THIS->contentsRect());
    OUTPUT:
    RETVAL

PRect *
QFrame::frameRect()
    CODE:
    RETVAL = new PRect(THIS->frameRect());
    OUTPUT:
    RETVAL

int
QFrame::frameShadow()

int
QFrame::frameShape()

int
QFrame::frameStyle()

int
QFrame::frameWidth()

bool
QFrame::lineShapesOk()

int
QFrame::lineWidth()

int
QFrame::midLineWidth()

void
QFrame::setFrameStyle(style)
    int style

void
QFrame::setLineWidth(width)
    int width

void
QFrame::setMidLineWidth(width)
    int width