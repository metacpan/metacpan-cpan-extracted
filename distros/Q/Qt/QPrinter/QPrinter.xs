/*
 * PerlQt interface to qprinter.h
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#include "pprinter.h"
#include "pqt.h"
#include "enum.h"

#define STORE_key(key) enumIV(hv, MSTR(key), QPrinter::key)

inline void init_enum() {
    HV *hv = perl_get_hv("QPrinter::Orientation", TRUE | GV_ADDMULTI);
    STORE_key(Portrait);
    STORE_key(Landscape);

    hv = perl_get_hv("QPrinter::PageSize", TRUE | GV_ADDMULTI);
    STORE_key(A4);
    STORE_key(B5);
    STORE_key(Letter);
    STORE_key(Legal);
    STORE_key(Executive);
}

MODULE = QPrinter		PACKAGE = QPrinter

PROTOTYPES: ENABLE

BOOT:
    init_enum();

PPrinter *
PPrinter::new()

bool
QPrinter::abort()

bool
QPrinter::aborted()

const char *
QPrinter::creator()

const char *
QPrinter::docName()

int
QPrinter::fromPage()

int
QPrinter::maxPage()

int
QPrinter::minPage()

int
QPrinter::numCopies()

bool
newPage(THIS)
    QPrinter *THIS
    CODE:
    RETVAL = THIS->newPage();   // Stupid xsubpp bug!
    OUTPUT:
    RETVAL

QPrinter::Orientation
QPrinter::orientation()

const char *
QPrinter::outputFileName()

bool
QPrinter::outputToFile()

QPrinter::PageSize
QPrinter::pageSize()

const char *
QPrinter::printerName()

const char *
QPrinter::printProgram()

bool
QPrinter::setup(parent = 0)
    QWidget *parent

void
QPrinter::setCreator(creator)
    char *creator

void
QPrinter::setDocName(name)
    char *name

void
QPrinter::setFromTo(fromPage, toPage)
    int fromPage
    int toPage

void
QPrinter::setMinMax(minPage, maxPage)
    int minPage
    int maxPage

void
QPrinter::setNumCopies(numCopies)
    int numCopies

void
QPrinter::setOrientation(orientation)
    QPrinter::Orientation orientation

void
QPrinter::setOutputFileName(fileName)
    char *fileName

void
QPrinter::setOutputToFile(b)
    bool b

void
QPrinter::setPageSize(pageSize)
    QPrinter::PageSize pageSize

void
QPrinter::setPrinterName(name)
    char *name

void
QPrinter::setPrintProgram(printProg)
    char *printProg

int
QPrinter::toPage()
