/*
 * MCP.xs - root XS file
 *
 * Thin wrapper: the perl headers, then the C implementation headers from
 * include/pmcp/ in dependency order, then the per-module XS fragments from
 * xs/ via INCLUDE: (the Punk / Punk-Feed layout).
 */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* The two providers' public ABI headers, reached through ExtUtils::Depends
 * (or the sibling checkouts), never copied. */
#include "frj_abi.h"
#include "jsf_abi.h"

/* The implementation headers, in dependency order. Each states its contract at
 * the top and names what must precede it. */

#include "pmcp/pmcp.h"           /* the dist's name, for every message       */
#include "pmcp/pmcp_compat.h"    /* what the 5.10 floor costs                */
#include "pmcp/pmcp_clos.h"      /* closures, every call into Perl           */
#include "pmcp/pmcp_abi.h"       /* the frj and jsf tables, resolved at BOOT */
#include "pmcp/pmcp_rand.h"      /* random bytes, session ids                */
#include "pmcp/pmcp_rpc.h"       /* JSON-RPC: decode, classify, the envelope */
#include "pmcp/pmcp_proto.h"     /* versions, initialize, the dispatcher     */
#include "pmcp/pmcp_otel.h"      /* a span per request, under OpenTelemetry  */
#include "pmcp/pmcp_reg.h"       /* options, install_kw, on_compile          */
#include "pmcp/pmcp_decl.h"      /* tool declarations, frozen                */
#include "pmcp/pmcp_page.h"      /* cursors and pages                        */
#include "pmcp/pmcp_call.h"      /* tools/list, tools/call, the helpers      */
#include "pmcp/pmcp_uri.h"       /* URI templates, base64                    */
#include "pmcp/pmcp_res.h"       /* resources/list, templates, read          */
#include "pmcp/pmcp_prompt.h"    /* prompts/list, prompts/get                */
#include "pmcp/pmcp_state.h"     /* the keyword, the freeze, the guard check */
#include "pmcp/pmcp_http.h"      /* POST, the checks, the CORS probe         */
#include "pmcp/pmcp_sess.h"      /* Mcp-Session-Id, the record, DELETE       */
#include "pmcp/pmcp_sse.h"       /* SSE on POST, progress, logging, cancel   */
#include "pmcp/pmcp_bus.h"       /* GET stream, subscriptions, the bus       */
#include "pmcp/pmcp_auth.h"      /* auth, oauth, RFC 9728, principal         */
#include "pmcp/pmcp_oa.h"        /* tools from an Open::API mount            */
#include "pmcp/pmcp_stdio.h"     /* punk mcp: stdio, the command, doctor     */

/* Still to land: the live tests (14) and the gate (15) */

MODULE = Punk::Plugin::MCP    PACKAGE = Punk::Plugin::MCP

PROTOTYPES: DISABLE

BOOT:
    pmcp_abi_boot(aTHX);
    pmcp_rpc_boot(aTHX);

INCLUDE: xs/mcp.xs
