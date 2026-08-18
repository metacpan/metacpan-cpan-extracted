/*
 * Punk.xs - root XS file
 *
 * Thin wrapper: resolves the File::Raw::JSON C ABI, includes the C
 * implementation headers, then pulls in the per-module XS fragments
 * from xs/ via INCLUDE: (the Chandra / Open::API layout).
 */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "punk/punk_immortal_probe.h"  /* TEMP author probe (-DPUNK_IMMORTAL_PROBE) */

#include "punk/punk_compat.h"     /* pre-5.16 perl shims; must precede punk/ */

#include "frj_abi.h"

/* ---- the File::Raw::JSON C ABI (JSON response fast path) ------------------ *
 * Resolved lazily on first use from File::Raw::JSON::_abi_ptr, exactly the
 * consumer pattern Open::API uses. A mismatch croaks; the Perl caller only
 * reaches here when the XS tier is active, and File::Raw::JSON is a hard
 * PREREQ, so this is a startup-environment error, not a request-time one. */
static const frj_abi *PUNK_FRJ = NULL;
static int PUNK_FRJ_TRIED = 0;

static const frj_abi *punk_frj(pTHX) {
    if (!PUNK_FRJ && !PUNK_FRJ_TRIED) {
        dSP; int count; IV p = 0;
        PUNK_FRJ_TRIED = 1;
        eval_pv("require File::Raw::JSON;", FALSE);
        /* The require runs arbitrary Perl. If that grew the value stack it was
         * reallocated, and the SP captured above now points into the freed
         * block - which the PUTBACK below would publish as PL_stack_sp. */
        SPAGAIN;
        if (!SvTRUE(ERRSV)) {
            ENTER; SAVETMPS; PUSHMARK(SP); PUTBACK;
            count = call_pv("File::Raw::JSON::_abi_ptr", G_SCALAR | G_EVAL);
            SPAGAIN;
            if (!SvTRUE(ERRSV) && count > 0) p = POPi;
            else if (count > 0)             (void)POPs;
            PUTBACK; FREETMPS; LEAVE;
            if (p) {
                const frj_abi *a = INT2PTR(const frj_abi *, p);
                if (a && a->abi_version == FRJ_ABI_VERSION) PUNK_FRJ = a;
            }
        }
    }
    if (!PUNK_FRJ)
        croak("Punk: the XS JSON path needs File::Raw::JSON with a "
              "compatible C ABI (FRJ_ABI_VERSION %d)", FRJ_ABI_VERSION);
    return PUNK_FRJ;
}

#include "punk/punk_names.h"      /* fixed module/slot/key strings, named once */
#include "punk/punk_route.h"
#include "punk/punk_response.h"
#include "punk/punk_request.h"
#include "punk/punk_accept.h"    /* Accept negotiation for respond_to     */
#include "punk/punk_multipart.h" /* multipart/form-data + uploads      */
#include "punk/punk_context.h"    /* the per-request context object        */
#include "punk/punk_cookie.h"     /* build a Set-Cookie value              */
#include "punk/punk_session.h"    /* signed cookie sessions (SHA-256/HMAC) */
#include "punk/punk_flash.h"      /* one-request messages over the session */
#include "punk/punk_ua.h"        /* the shared outbound Fetch agent        */
#include "punk/punk_log.h"       /* the level-based logger               */
#include "punk/punk_dispatch.h"   /* the Open::API C ABI consumer (phase 6) */
#include "punk/punk_views.h"      /* the view-engine registry              */
#include "punk/punk_scope.h"      /* the `under` handle (needs context)     */
#include "punk/punk_app.h"        /* the Punk::App registrar (needs context) */
#include "punk/punk_proxy.h"      /* reverse-proxy trust (used by serve)    */
#include "punk/punk_serve.h"      /* the request dispatcher                 */
#include "punk/punk_ws.h"         /* the RFC 6455 frame codec (phase 8)    */
#include "punk/punk_config.h"      /* layered YAML config + resolved secrets */
#include "punk/punk_static.h"    /* the static-file app (a magic-CV closure) */
#include "punk/punk_sendfile.h"  /* $c->send_file: validators + ranges     */
#include "punk/punk_oamount.h"   /* the `api` mount, boot half (needs static) */
#include "punk/punk_dbi.h"       /* the shipped DBI model backend           */
#include "punk/punk_model.h"     /* the model tier: DSL, metadata, contract */
#include "punk/punk_csrf.h"      /* single-use tokens over the session */
#include "punk/punk_password.h"  /* PBKDF2 password hashing (needs session+csrf) */
#include "punk/punk_auth.h"      /* the auth battery's guard + denial path */
#include "punk/punk_validate.h"  /* collecting validation, on the jsf ABI */
#include "punk/punk_stencil.h"   /* the shipped view engine, on Stencil's ABI */
#include "punk/punk_markdown.h"  /* the `markdown` docs mount (needs static,
                                  * stencil and request) */
#include "hm_abi.h"              /* Hyperman's C ABI, via EU::Depends     */
#include "punk/punk_wsconn.h"     /* the live WebSocket connection         */
#include "punk/punk_wshandshake.h" /* the upgrade handshake (SHA-1 + base64) */
#include "punk/punk_sse.h"         /* Server-Sent Events streams            */
#include "punk/punk_ratelimit.h"  /* rate_limit: a C before_dispatch closure */
#include "punk/punk_wsroom.h"      /* per-worker pub/sub rooms              */
#include "punk/punk_future.h"      /* async result: loop when live, else block */
#include "punk/punk_dbil.h"        /* the async model backend, on DBIx::Loop's
                                      C ABI (needs punk_dbi.h + punk_future.h) */
#include "punk/punk_import.h"     /* `use Punk` and the DSL table */
#include "punk/punk_cors.h"       /* cross-origin: preflight + headers   */
#include "punk/punk_headers.h"    /* security headers on every response  */
#include "punk/punk_compile.h"    /* the boot compiler (needs static+serve) */

/* Every Punk::Router is an IV-ref to a pr_router (new through compile through
 * match); the whole class is XS. */
static pr_router *punk_router_of(pTHX_ SV *self) {
    if (!SvROK(self) || !SvIOK(SvRV(self)))
        croak("Punk::Router: not a compiled C router handle");
    return (pr_router *)INT2PTR(void *, SvIV(SvRV(self)));
}

MODULE = Punk        PACKAGE = Punk

PROTOTYPES: DISABLE

INCLUDE: xs/core.xs
INCLUDE: xs/router.xs
INCLUDE: xs/request.xs
INCLUDE: xs/upload.xs
INCLUDE: xs/response.xs
INCLUDE: xs/dispatch.xs
INCLUDE: xs/context.xs
INCLUDE: xs/session.xs
INCLUDE: xs/log.xs
INCLUDE: xs/scope.xs
INCLUDE: xs/app.xs
INCLUDE: xs/ratelimit.xs
INCLUDE: xs/serve.xs
INCLUDE: xs/views.xs
INCLUDE: xs/stencil.xs
INCLUDE: xs/csrf.xs
INCLUDE: xs/password.xs
INCLUDE: xs/auth.xs
INCLUDE: xs/validate.xs
INCLUDE: xs/cors.xs
INCLUDE: xs/headers.xs
INCLUDE: xs/websocket.xs
INCLUDE: xs/wshandshake.xs
INCLUDE: xs/sse.xs
INCLUDE: xs/wsroom.xs
INCLUDE: xs/future.xs
INCLUDE: xs/config.xs
INCLUDE: xs/static.xs
INCLUDE: xs/sendfile.xs
INCLUDE: xs/markdown.xs
INCLUDE: xs/model.xs
INCLUDE: xs/oamount.xs
INCLUDE: xs/dbi.xs
INCLUDE: xs/dbil.xs
INCLUDE: xs/compile.xs
