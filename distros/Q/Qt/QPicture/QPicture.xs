/*
 * PerlQt interface to qpicture.h
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#include "ppicture.h"

MODULE = QPicture		PACKAGE = QPicture

PROTOTYPES: ENABLE

PPicture *
PPicture::new()

bool
QPicture::load(fileName)
    char *fileName

bool
QPicture::play(painter)
    QPainter *painter

bool
QPicture::save(fileName)
    char *fileName