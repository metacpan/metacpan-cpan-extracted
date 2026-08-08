/* punk_names.h - the fixed strings the registrar and compiler use, named once.
 *
 * These are string-literal macros (not const char[]) on purpose: hv_fetchs,
 * hv_stores and newSVpvs bake the length from a literal at compile time, and a
 * macro that expands to a literal keeps that. So `hv_fetchs(h, K_PREFIX, 0)`
 * and `newSVpvs(K_PREFIX)` still see a literal, and a require of a fixed module
 * is a single compile-time-concatenated string ("require " PK_CONFIG ";") with
 * nothing built at run time.
 */

#ifndef PUNK_NAMES_H
#define PUNK_NAMES_H

/* ---- modules and classes -------------------------------------------------- */
#define PK_ROUTER    "Punk::Router"
#define PK_SCOPE     "Punk::Router::Scope"
#define PK_CONTEXT   "Punk::Context"
#define PK_STATIC    "Punk::Static"
#define PK_CONFIG    "Punk::Config"
#define PK_MODEL     "Punk::Model"
#define PK_VIEWS     "Punk::Views"
#define PK_WEBSOCKET "Punk::WebSocket"
#define PK_MOUNT_OA  "Punk::Mount::OpenAPI"
#define PK_MOUNT_MD  "Punk::Mount::Markdown"
#define PK_OA_UI     "Open::API::UI"

/* the require of a fixed module, as one compile-time literal */
#define PK_REQUIRE(mod) ("require " mod ";")

/* ---- caller-relative namespace pieces ------------------------------------- */
#define PK_NS_CONTROLLER "::Controller::"
#define PK_NS_MODEL      "::Model::"
#define PK_SFX_CONTEXT   "::_Context"

/* ---- app-object slots ----------------------------------------------------- */
#define K_CALLER     "caller"
#define K_ROUTER     "router"
#define K_MOUNTS     "mounts"
#define K_VIEWS      "views"
#define K_DATABASES  "databases"
#define K_MODELS     "models"
#define K_HOOKS      "hooks"
#define K_BEFORE_D   "before_dispatch"
#define K_AFTER_D    "after_dispatch"
#define K_MIDDLEWARE "middleware"
#define K_HELPERS    "helpers"
#define K_ON_ERROR   "on_error"
#define K_COMPILED   "compiled"
#define K_CONFIG     "config"
#define K_API_MOUNTS "api_mounts"
#define K_WS_ROUTES  "ws_routes"
#define K_SSE_ROUTES "sse_routes"
#define K_SSE        "sse"
#define K_DOCS       "docs"
#define K_MODEL_AUTO "model_auto"
#define K_MODELS_C   "models_compiled"
#define K_MODEL_CACHE "model_cache"
#define K_VIEWS_C    "views_compiled"
#define K_CTX_DEFINED "ctx_defined"
#define K_UA         "ua"          /* the `ua` keyword's frozen config */
#define K_UA_AGENT   "ua_agent"    /* { agent => $fetch, pid => $$ } */

/* ---- record / state / option keys ----------------------------------------- */
#define K_PREFIX   "prefix"
#define K_LEN      "len"
#define K_MOUNT    "mount"
#define K_DIR      "dir"
#define K_MD_DIR   "md_dir"
#define K_APP      "app"
#define K_PATH     "path"
#define K_METHOD   "method"
#define K_TARGET   "target"
#define K_GUARDS   "guards"
#define K_OPTS     "opts"
#define K_API      "api"
#define K_OPS      "ops"
#define K_MAX_BODY "max_body"
#define K_RECS     "recs"
#define K_CTX      "ctx"
#define K_BEFORE   "before"
#define K_AFTER    "after"
#define K_CODE     "code"
#define K_OWNER    "owner"
#define K_WS       "ws"
#define K_PID      "pid"
#define K_DEFAULT  "default"
#define K_AUTO     "auto"
#define K_ONLY     "only"
#define K_BLOCKING "blocking"
#define K_RESPONSE "response"
#define K_CSRF     "csrf"
#define K_CORS     "cors"

#endif /* PUNK_NAMES_H */
