/*
 * Challenge.xs - root XS file
 *
 * Thin wrapper: the perl headers and the shims the 5.10 floor costs, then the
 * C implementation headers from include/pchal/ in dependency order, then the
 * per-package XS fragments from xs/ via INCLUDE: (the Punk-Feed layout).
 *
 * One bundle for every package in the distribution. Each .pm under
 * lib/Punk/Challenge/ and lib/Punk/Plugin/ loads the facade and nothing
 * else, so whichever module is loaded first bootstraps all of them.
 *
 * This distribution reaches Punk through its ordinary Perl surface. Punk
 * installs pk_abi.h and nothing else, and pk_abi.h is an observer table with
 * no install_kw, so the registrar is reached by method dispatch.
 */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <string.h>

/* The implementation headers, in dependency order. Each states its contract
 * at the top and names what must precede it. */

#include "pchal/pchal_compat.h"  /* what the 5.10 floor costs; must be first */
#include "pchal/pchal_rand.h"    /* entropy, for `punk challenge key` only   */
#include "pchal/pchal_clos.h"    /* predicates, the app hash, one-key reads   */
#include "pchal/pchal_reg.h"     /* the option-name check                     */
#include "pchal/pchal_sha256.h"  /* SHA-256, HMAC-SHA256, leading zero bits   */
#include "pchal/pchal_b64.h"     /* base64url, no padding                     */
#include "pchal/pchal_ct.h"      /* constant-time compare                     */
#include "pchal/pchal_boot.h"    /* the option table and its defaults         */
#include "pchal/pchal_subject.h" /* the /24, the /64, the exact address       */
#include "pchal/pchal_token.h"   /* the puzzle and the clearance              */
#include "pchal/pchal_solve.h"   /* the solver: tests and the CLI only        */
#include "pchal/pchal_gate.h"    /* cleared / issue / clear; demand declared  */
#include "pchal/pchal_page.h"    /* the interstitial and the escapers         */
#include "pchal/pchal_answer.h"  /* demand: the negotiated 503 page / 403 JSON */
#include "pchal/pchal_rules.h"   /* the `challenge` keyword, the hook, the boot check */
#include "pchal/pchal_guard.h"   /* `challenge_guard` and its body            */
#include "pchal/pchal_helpers.h" /* $c->challenge_cleared / _issue / _clear   */
#include "pchal/pchal_routes.h"  /* verify, the solver asset, the csrf exemption */
#include "pchal/pchal_install.h" /* what import and register install          */

MODULE = Punk::Challenge    PACKAGE = Punk::Plugin::Challenge

PROTOTYPES: DISABLE

BOOT:
    /* nothing to resolve: no C ABI table is consumed */
    ;

INCLUDE: xs/plugin.xs
INCLUDE: xs/token.xs
INCLUDE: xs/solver.xs
