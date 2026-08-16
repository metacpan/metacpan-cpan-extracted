#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "pox/pox_abi.h"
#include "pox/pox_util.h"
#include "pox/pox_url.h"
#include "pox/pox_http.h"
#include "pox/pox_verify.h"
#include "pox/pox_tokens.h"
#include "pox/pox_presets.h"
#include "pox/pox_provider.h"
#include "pox/pox_jwks.h"
#include "pox/pox_checker.h"
#include "pox/pox_store.h"
#include "pox/pox_server.h"
#include "pox/pox_run.h"

MODULE = Punk::OAuth2  PACKAGE = Punk::OAuth2

PROTOTYPES: DISABLE

INCLUDE: xs/util.xs
INCLUDE: xs/flow.xs
INCLUDE: xs/http.xs
INCLUDE: xs/verify.xs
INCLUDE: xs/tokens.xs
INCLUDE: xs/presets.xs
INCLUDE: xs/provider.xs
INCLUDE: xs/jwks.xs
INCLUDE: xs/checker.xs
INCLUDE: xs/store.xs
INCLUDE: xs/server.xs
INCLUDE: xs/run.xs
