/*
 * Arena.xs - root XS file for Shared::Arena.
 *
 * The perl headers, then the compat shim that puts back what PERL_IMPLICIT_SYS
 * takes away, then the C implementation headers from include/sa/ in dependency
 * order, then the per-package XS fragments from xs/ via INCLUDE:.
 *
 * This file sits at the TOP of the dist rather than under lib/. An XSMULTI
 * build from lib/Shared/Arena.xs writes its linker export list to
 * lib/Shared/Arena.def, while the import-library rule Strawberry adds for
 * MinGW reads $(EXPORT_LIST), which is always $(BASEEXT).def in the top
 * directory - the two names never meet and dlltool fails the build.
 *
 * The rules every header under include/sa/ follows:
 *
 *  1. Perl-free. A region is bytes and offsets; nothing below the XS layer
 *     needs an interpreter, which is what lets a harness with no perl drive it.
 *  2. NOTHING INSIDE A REGION IS EVER A POINTER. Offsets from the base, always,
 *     so a process that maps at a different address reads the same structure.
 *     t/03-relocatable.t is the test, and it maps one region twice in one
 *     process precisely so that a stray pointer fails deterministically.
 *  3. Errors are a return value, never a croak. Every function is ABI-shaped
 *     from the start, because the ABI is how the real consumer reaches it.
 *  4. Fail open. No atomics, no mapping, a name that will not open: a NULL
 *     handle and a caller that degrades. Never a crash.
 *  5. Every wait is bounded. A process that died holding something must not
 *     wedge the ones that did not.
 *  6. C89 declarations at block top. No VLAs, no designated initialisers,
 *     no %zu, no //.
 */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "sa/sa_compat.h"    /* puts back what XSUB.h took; must be first */

#include "sa/sa_atomic.h"    /* the probe and the operations (perl-free)  */
#include "sa/sa_format.h"    /* the layout: offsets only                  */
#include "sa/sa_map.h"       /* where the memory comes from               */
#include "sa/sa_arena.h"     /* the handle, the bump, the registry        */
#include "sa/sa_peer.h"      /* who is here, and how to prove one has died */
#include "sa/sa_ring.h"      /* the first tenant: a record ring           */
#include "sa/sa_hash.h"    /* the second tenant: a map                  */
#include "sa/sa_bloom.h"   /* the third tenant: a probabilistic set     */
#include "sa/sa_hist.h"    /* the fourth tenant: a distribution         */
#include "sa/sa_cache.h"   /* the fifth tenant: a cache that evicts     */
#include "sa/sa_rate.h"    /* the sixth tenant: a token bucket per key  */
#include "sa/sa_cms.h"     /* the seventh: how often, in fixed space    */
#include "sa/sa_frozen.h"  /* one structure, republished, read in place */
#include "sa/sa_xop.h"     /* the hot doors as opcodes                  */
#include "sa_abi.h"

/* ---- Frozen, a hard prerequisite ------------------------------------------
 *
 * Every other tenant stores bytes a caller flattened itself. This one stores a
 * structure that is READ WHERE IT LIES: no rebuilding on the way out, so a
 * worker looks up one key without materialising the rest. Frozen is the format
 * and the reader, reached through its ABI table so a read costs no Perl frame.
 *
 * The table is fetched once at BOOT through Frozen::_abi_ptr. The version is
 * checked against what THIS file was compiled against, with >= rather than ==:
 * the table is append-only, so a newer Frozen is fine and an older one is not.
 * Refusing at load is the point - the alternative is calling through a null
 * entry at the first publish, in production, in a worker. */
#include "fz_abi.h"

static const fz_abi *SA_FZ = NULL;

/* A borrowed view: the container, the tenant it came from, and which slot and
 * generation it was opened on, because a borrowed block can be republished
 * underneath it and `fresh` is how a reader finds out. The length is kept here
 * rather than read back off the container, which is opaque to a consumer. */
typedef struct {
    fz_container *c;
    sa_frozen    *f;
    uint64_t      len;
    uint64_t      gen;
    uint32_t      slot;
} sa_fzview;          /* the PUBLIC table a consumer resolves      */
#include "sa/sa_abi_impl.h"  /* and what it points at                     */

/* ---- THE INVOCANT IS AN ARGUMENT THAT ARRIVED FROM PERL --------------------
 *
 * Every object in this dist is a blessed SV carrying a C pointer as its IV, and
 * every entry used to reach it with INT2PTR(T *, SvIV(SvRV(self))) directly.
 * SvRV on something that is not a reference reads the union member a plain
 * string keeps its PV in, so `Shared::Arena->size` - a CLASS NAME invocant,
 * which is a typo away from every documented call - dereferenced a char buffer
 * as a struct. Measured: SIGBUS, not a croak.
 *
 * One guard, in one place, in front of every entry. It cannot tell a forged
 * integer from a real handle, and nothing with this representation can; what it
 * does is turn the two mistakes a caller actually makes - a class name, and an
 * object of the wrong kind - into an error message.
 *
 * This lives here rather than under include/sa/, because everything there is
 * perl-free and this is the opposite of that. */
static void *sa_self_ptr(pTHX_ SV *sv, const char *what) {
    if (!SvROK(sv) || !SvOBJECT(SvRV(sv)))
        croak("Shared::Arena: not a %s object", what);
    return INT2PTR(void *, SvIV(SvRV(sv)));
}
#define SA_SELF(type, sv) ((type *)sa_self_ptr(aTHX_ (sv), #type))

MODULE = Shared::Arena    PACKAGE = Shared::Arena

PROTOTYPES: DISABLE

INCLUDE: xs/region.xs
INCLUDE: xs/ring.xs
INCLUDE: xs/group.xs
INCLUDE: xs/map.xs
INCLUDE: xs/bloom.xs
INCLUDE: xs/hist.xs
INCLUDE: xs/cache.xs
INCLUDE: xs/rate.xs
INCLUDE: xs/cms.xs
INCLUDE: xs/frozen.xs
INCLUDE: xs/abi.xs
INCLUDE: xs/xop.xs
