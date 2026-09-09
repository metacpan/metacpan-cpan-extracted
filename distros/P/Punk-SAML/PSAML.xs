#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

/* Punk::SAML is one shared object. Every module under lib/Punk/SAML and
 * lib/Punk/Plugin/SAML.pm does `use Punk::SAML ()` and nothing else, so
 * the bundle is bootstrapped once by whichever is loaded first, and each
 * package is declared below with its own MODULE = / PACKAGE = line.
 *
 * The rules this distribution is built under, recorded here where every
 * later phase sees them:
 *
 *   1. The include order below is a dependency order, not an alphabet.
 *      psaml_compat.h is first because every other header uses its
 *      shims; psaml_abi.h is second because the primitives above the
 *      resolvers are the only code that may run before they resolve.
 *
 *   2. Nothing in this dist matches an XML element by prefix. SAML
 *      documents choose their own prefixes and every finder goes
 *      through a namespace URI and a local name.
 *
 *   3. No structs on the application. Plugin state is keys on the
 *      application HV (psaml_reg.h). The only aggregates are the
 *      closure capture and the per-document frx_doc *.
 *
 *   4. Every frx_doc this dist parses is freed on every exit path
 *      including the croak path, through SAVEDESTRUCTOR_X. A leaked
 *      document per failed login is the slow leak nobody finds.
 *
 *      THE ONE EXCEPTION, and it is a double free rather than a leak if
 *      it is got wrong: frx_abi's doc_to_sv TAKES OWNERSHIP. It is the
 *      only entry in that table that does. A document handed to Perl
 *      through it belongs to the SV's magic from that moment, so the
 *      SAVEDESTRUCTOR_X must be cancelled or never installed on that
 *      path. Parse, verify, and only then hand it over.
 *
 *   5. Every refusal throws a blessed Punk::SAML::Error with a code.
 *      The code is the interface; the message is for the log and never
 *      reaches the browser.
 *
 *   6. The ABI resolvers compare >= against the version whose members
 *      this dist calls, never == and never against the installed
 *      header's constant. See psaml_abi.h.
 *
 *   7. Adding a header means re-running Makefile.PL: the depend glob
 *      that makes a header edit rebuild the object is evaluated at
 *      configure time.
 */

#include "psaml/psaml_compat.h"   /* what the 5.10 floor costs; first */
#include "psaml/psaml_abi.h"      /* the three resolvers: frx, jws, fetch */
#include "psaml/psaml_error.h"    /* the codes; throwing a blessed error */
#include "psaml/psaml_b64.h"      /* standard base64, strict decode */
#include "psaml/psaml_deflate.h"  /* raw DEFLATE, stored blocks */
#include "psaml/psaml_time.h"     /* xs:dateTime both ways */
#include "psaml/psaml_xml.h"      /* the escape; the finders over frx */
#include "psaml/psaml_clos.h"     /* the closure device; predicates */
#include "psaml/psaml_reg.h"      /* the registrar surface, through Perl */
#include "psaml/psaml_request.h"  /* the AuthnRequest and the redirect */
#include "psaml/psaml_signature.h"/* XML-DSig, verified */
#include "psaml/psaml_response.h" /* the checks in order; the parse guard */
#include "psaml/psaml_idp.h"      /* a provider, read from metadata bytes */
#include "psaml/psaml_metadata.h" /* the fetch, and SP metadata out */
#include "psaml/psaml_flow.h"     /* the flow cookie, SameSite=None */
#include "psaml/psaml_boot.h"     /* register, the keywords, the routes:
                                   * last, because it reads metadata,
                                   * mounts routes and writes the cookie */

MODULE = Punk::SAML  PACKAGE = Punk::SAML

PROTOTYPES: DISABLE

INCLUDE: xs/util.xs
INCLUDE: xs/plugin.xs
INCLUDE: xs/request.xs
INCLUDE: xs/response.xs
INCLUDE: xs/metadata.xs
