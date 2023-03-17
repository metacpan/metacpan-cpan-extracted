#ifndef EASYXS_H
#define EASYXS_H 1

#include "init.h"

#define _EASYXS_CROAK_UNDEF(expected) \
    croak("undef given; " expected " expected")

#define _EASYXS_CROAK_STRINGIFY_REFERENCE(sv) \
    croak("%" SVf " given where string expected!", sv)

#include "easyxs_perlcall.h"
#include "easyxs_numeric.h"
#include "easyxs_scalar.h"
#include "easyxs_string.h"
#include "easyxs_structref.h"
#include "easyxs_debug.h"

#endif
