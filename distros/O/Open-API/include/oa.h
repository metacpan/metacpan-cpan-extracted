#ifndef OA_H
#define OA_H

/* Open::API C core - umbrella header.
 *
 * The .xs includes EXTERN.h / perl.h / XSUB.h BEFORE this file (so SV/HV/AV/
 * pTHX are defined). Everything is `static` in one translation unit (API.c).
 *
 * The heavy lifting is delegated through two runtime-resolved C ABIs:
 *   jsf_abi.h   - JSON::Schema::Fast: compile a schema once, validate per
 *                 request in C (REQUIRED; resolved and version-checked in
 *                 BOOT, Open/API.pm croaks at load without it).
 *   fetch_abi.h - Fetch: the HTTP client used by Open::API::Client
 *                 (resolved lazily on first client use).
 *   frj_abi.h   - File::Raw::JSON: decode spec + request/response JSON bodies
 *                 in C (REQUIRED; resolved lazily on first decode).
 *
 * All three headers are reached through ExtUtils::Depends (no vendored copy). */

#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include "oa_compat.h"   /* pre-5.16 perl shims (XS_INTERNAL, mg_findext) */
#include "jsf_abi.h"     /* via ExtUtils::Depends (JSON::Schema::Fast) */
#include "fetch_abi.h"   /* via ExtUtils::Depends (Fetch) */
#include "frj_abi.h"     /* via ExtUtils::Depends (File::Raw::JSON) */

#include "oa_types.h"
/* oa_compile.h is included by API.xs after its JSF pointer is declared */

#endif /* OA_H */
