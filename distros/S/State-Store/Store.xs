#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* All this dist knows of HAMT: its public header, found through
 * ExtUtils::Depends. */
#include "hamt_abi.h"
#include "state_store_abi.h"

#include "store/store_alloc.h"
#include "store/store_hamt.h"
#include "store/store_call.h"
#include "store/store_core.h"
#include "store/store_history.h"
#include "store/store_watch.h"
#include "store/store_txn.h"
#include "store/store_checkpoint.h"
#include "store/store_abi_impl.h"
#include "store/store_abi_selftest.h"

MODULE = State::Store    PACKAGE = State::Store

PROTOTYPES: DISABLE

BOOT:
    store_hamt_boot(aTHX);

INCLUDE: xs/store.xs
INCLUDE: xs/history.xs
INCLUDE: xs/watch.xs
INCLUDE: xs/validator.xs
INCLUDE: xs/txn.xs
INCLUDE: xs/checkpoint.xs
INCLUDE: xs/abi.xs
INCLUDE: xs/test.xs
