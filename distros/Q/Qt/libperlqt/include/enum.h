#ifndef ENUM_H
#define ENUM_H

/*
 * Utility functions for making enum constants available in Perl
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#include "pqt.h"

#define enumSV(hash, key, value) safe_hv_store(hash, key, value)
#define enumIV(hash, key, value) safe_hv_store(hash, key, newSViv(value))
#define enum2IV(hash, key, copy, value) \
safe_hv_store(hash, copy, safe_hv_store(hash, key, newSViv(value)));

#endif  // ENUM_H
