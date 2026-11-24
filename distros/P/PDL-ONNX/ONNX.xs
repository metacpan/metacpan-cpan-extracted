#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "pdl.h"
#include "pdlcore.h"

#include <onnxruntime_c_api.h>

static Core* PDL;
static SV*   CoreSV;
static const OrtApi* g_ort = NULL;
static OrtEnv*       g_env = NULL;

static void check_ort(OrtStatus* status, const char* fn) {
    if (status != NULL) {
        const char* msg = g_ort->GetErrorMessage(status);
        char buf[512];
        snprintf(buf, sizeof(buf), "PDL::ONNX %s failed: %s", fn, msg ? msg : "unknown error");
        g_ort->ReleaseStatus(status);
        croak("%s", buf);
    }
}

static OrtSession* sv_to_session(pTHX_ SV* sv) {
    if (!sv_isobject(sv) || !sv_derived_from(sv, "PDL::ONNX::Session")) {
        croak("Expected a PDL::ONNX::Session object");
    }
    IV ptr = SvIV(SvRV(sv));
    if (!ptr) {
        croak("PDL::ONNX::Session has already been destroyed");
    }
    return INT2PTR(OrtSession*, ptr);
}

MODULE = PDL::ONNX    PACKAGE = PDL::ONNX

PROTOTYPES: DISABLE

BOOT:
{
    CoreSV = get_sv("PDL::SHARE", FALSE);
    if (!CoreSV) {
        croak("PDL::ONNX requires PDL::Core to be loaded first");
    }
    PDL = INT2PTR(Core*, SvIV(CoreSV));
    if (PDL->Version != PDL_CORE_VERSION) {
        croak("PDL::ONNX needs to be recompiled against the newly installed PDL");
    }
    g_ort = OrtGetApiBase()->GetApi(ORT_API_VERSION);
    if (!g_ort) {
        croak("Failed to initialize ONNX Runtime C API");
    }
    check_ort(g_ort->CreateEnv(ORT_LOGGING_LEVEL_WARNING, "PDL::ONNX", &g_env), "CreateEnv");
}

const char*
onnx_version()
CODE:
    RETVAL = OrtGetApiBase()->GetVersionString();
OUTPUT:
    RETVAL

void
available_providers()
PPCODE:
    char** providers = NULL;
    int count = 0;
    check_ort(g_ort->GetAvailableProviders(&providers, &count), "GetAvailableProviders");
    EXTEND(SP, count);
    for (int i = 0; i < count; ++i) {
        PUSHs(sv_2mortal(newSVpv(providers[i], 0)));
    }
    g_ort->ReleaseAvailableProviders(providers, count);

MODULE = PDL::ONNX    PACKAGE = PDL::ONNX::Session

SV*
_xs_create(const char* model_path)
CODE:
    OrtSessionOptions* opts = NULL;
    check_ort(g_ort->CreateSessionOptions(&opts), "CreateSessionOptions");
    OrtSession* sess = NULL;
    OrtStatus* st = g_ort->CreateSession(g_env, model_path, opts, &sess);
    g_ort->ReleaseSessionOptions(opts);
    check_ort(st, "CreateSession");

    SV* iv  = newSViv(PTR2IV(sess));
    SV* ref = newRV_noinc(iv);
    sv_bless(ref, gv_stashpv("PDL::ONNX::Session", GV_ADD));
    RETVAL = ref;
OUTPUT:
    RETVAL

void
input_names(SV* self)
PPCODE:
    OrtSession* sess = sv_to_session(aTHX_ self);
    OrtAllocator* alloc = NULL;
    check_ort(g_ort->GetAllocatorWithDefaultOptions(&alloc), "GetAllocator");
    size_t count = 0;
    check_ort(g_ort->SessionGetInputCount(sess, &count), "SessionGetInputCount");
    EXTEND(SP, (SSize_t)count);
    for (size_t i = 0; i < count; ++i) {
        char* name = NULL;
        check_ort(g_ort->SessionGetInputName(sess, i, alloc, &name), "SessionGetInputName");
        PUSHs(sv_2mortal(newSVpv(name, 0)));
        alloc->Free(alloc, name);
    }

void
output_names(SV* self)
PPCODE:
    OrtSession* sess = sv_to_session(aTHX_ self);
    OrtAllocator* alloc = NULL;
    check_ort(g_ort->GetAllocatorWithDefaultOptions(&alloc), "GetAllocator");
    size_t count = 0;
    check_ort(g_ort->SessionGetOutputCount(sess, &count), "SessionGetOutputCount");
    EXTEND(SP, (SSize_t)count);
    for (size_t i = 0; i < count; ++i) {
        char* name = NULL;
        check_ort(g_ort->SessionGetOutputName(sess, i, alloc, &name), "SessionGetOutputName");
        PUSHs(sv_2mortal(newSVpv(name, 0)));
        alloc->Free(alloc, name);
    }

void
DESTROY(SV* self)
CODE:
    if (SvROK(self)) {
        SV* iv = SvRV(self);
        IV ptr = SvIV(iv);
        if (ptr) {
            g_ort->ReleaseSession(INT2PTR(OrtSession*, ptr));
            sv_setiv(iv, 0);
        }
    }
