#ifndef PQT_H
#define PQT_H

/*
 * Header of general use to libperlqt and PerlQt
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */


// This header is needed by every Qt source file. It needs to be
// #included *AFTER* any real qt headers, because there are serious
// name-space conflicts between qt and Perl! Any and all name-space
// conflicts are to be solved in this header, one time.

#undef bool

#include "qglobal.h"
#include "qwindefs.h"

#define pQT_11 10100
#define pQT_12 10200

#include <qslider.h>    /* Used for version identification purposes */

#ifndef pQT_VERSION     /* if it's defined, it's pQT_11 (1.1) */
#define pQT_VERSION pQT_12
#endif  // pQT_VERSION

#if defined(DEBUG)
/*
 * Perl has an extensive set of DEBUG* macros, it's better to cut off the
 * single Qt DEBUG definition than to fiddle with all of Perl's macros. We
 * keep a copy of it in QtDEBUG if it exists. Qt is very conservative with
 * it's use of defines, Perl is just plain reckless. Lets cross our
 * fingers and hope everything works out alright.
 */
#define QtDEBUG
#undef DEBUG
#endif  // defined(DEBUG)

extern "C" {
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
}

#define MSTR(str) # str

#define pextract(type, elem) (type *)extract_ptr(ST(elem), MSTR(elem))

extern SV *objectify_ptr(void *ptr, char *clname, int delete_on_destroy = 0);
extern void *extract_ptr(SV *obj, char *clname);
extern SV *rv_check(SV *rv, char *errmsg = "Not a reference");
extern SV *obj_check(SV *rv, char *errmsg = "Invalid object");
extern SV *safe_hv_store(HV *hash, char *key, SV *value);
extern SV *safe_hv_fetch(HV *hash, char *key, char *message);

extern char *find_signal(SV *obj, char *signal);
extern char *find_slot(SV *obj, char *slot);

extern SV *parse_member(SV *member);

#endif  // PQT_H
