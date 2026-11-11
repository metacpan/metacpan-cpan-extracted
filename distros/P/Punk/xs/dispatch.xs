MODULE = Punk        PACKAGE = Punk

PROTOTYPES: DISABLE

# True when Open::API's C ABI (oa_abi.h) resolved at the compiled-against
# OA_ABI_VERSION. It always should - Open::API 0.04+ is a hard prerequisite -
# so this is really only for the guard test; punk_oa croaks on the request
# path if the table is missing. PUNK_FAKE_OA_BAD simulates a version mismatch.
int
_oa_available()
    CODE:
        RETVAL = punk_oa_try(aTHX) ? 1 : 0; /* # uncoverable condition left count:1 class:ignore_covered_err */
    OUTPUT:
        RETVAL

# The ABI version this was compiled against, for the guard test.
int
_oa_abi_version()
    CODE:
        RETVAL = OA_ABI_VERSION;
    OUTPUT:
        RETVAL

# Dispatch one matched API operation entirely in C: the before-dispatch hooks
# and the operation's guards (short-circuitable), the 413/501 checks, raw-input
# assembly and validation through the ABI, stashing the typed params, and the
# controller call. Returns ($ret, $err) for Punk::App's finish path - $ret the
# controller's value or an early PSGI triplet (400/413/501/guard short-circuit),
# $err a die message or undef. The hooks, guards and controller are the only
# Perl frames.
void
# uncoverable statement
# uncoverable subroutine
_oa_dispatch(c, before, rec, api, op_id, caps, max_body)
        SV *c
        SV *before
        SV *rec
        SV *api
        SV *op_id
        SV *caps
        IV max_body
    PPCODE:
    {
        AV *before_av;
        HV *rech;
        SV *ret, *err;
        # uncoverable statement
        # uncoverable branch true
        # uncoverable branch false
        # uncoverable condition left count:1
        # uncoverable condition right count:1
        # uncoverable condition left count:2
        # uncoverable condition right count:2
        if (!SvROK(rec) || SvTYPE(SvRV(rec)) != SVt_PVHV)
            croak("Punk::_oa_dispatch: rec must be a hashref"); /* # uncoverable statement */
        before_av = (SvROK(before) && SvTYPE(SvRV(before)) == SVt_PVAV) /* # uncoverable statement */
                    ? (AV *)SvRV(before) : NULL; /* # uncoverable statement */
        rech = (HV *)SvRV(rec); /* # uncoverable statement */
        punk_oa_dispatch(aTHX_ c, before_av, rech, api, op_id, caps, /* # uncoverable statement */
                         max_body, &ret, &err); /* # uncoverable statement */
        SP = PL_stack_base + ax - 1;      /* hooks and the controller ran */ /* # uncoverable statement */
        EXTEND(SP, 2); /* # uncoverable statement */
        # uncoverable statement
        # uncoverable condition left count:1
        # uncoverable condition right count:1
        PUSHs(ret == &PL_sv_undef ? ret : sv_2mortal(ret));
        # uncoverable statement
        # uncoverable condition left count:1
        # uncoverable condition right count:1
        PUSHs(err == &PL_sv_undef ? err : sv_2mortal(err));
    }

# Coerce a handler return into a PSGI triplet (triplet passthrough,
# Punk::Response, awaited Future, or JSON), folding in the context's pending
# status/headers. The response-finish path, in C.
SV *
# uncoverable statement
# uncoverable subroutine
_coerce(c, ret)
        SV *c
        SV *ret
    CODE:
        RETVAL = punk_coerce(aTHX_ c, ret); /* # uncoverable statement */
    OUTPUT:
        RETVAL

# Finish a response: coerce if needed, run the after-dispatch hooks (each may
# replace the triplet), blank the body on HEAD.
SV *
# uncoverable statement
# uncoverable subroutine
_deliver(c, resp, method, after)
        SV *c
        SV *resp
        SV *method
        SV *after
    CODE:
    {
        STRLEN ml;
        const char *m = SvPV_const(method, ml); /* # uncoverable statement */
        # uncoverable statement
        # uncoverable condition left count:1
        # uncoverable condition right count:1
        # uncoverable condition left count:2
        # uncoverable condition right count:2
        int is_head = (ml == 4 && memEQ(m, "HEAD", 4));
        AV *after_av = (SvROK(after) && SvTYPE(SvRV(after)) == SVt_PVAV) /* # uncoverable statement */
                       ? (AV *)SvRV(after) : NULL; /* # uncoverable statement */
        RETVAL = punk_deliver(aTHX_ c, resp, is_head, after_av); /* # uncoverable statement */
    }
    OUTPUT:
        RETVAL
