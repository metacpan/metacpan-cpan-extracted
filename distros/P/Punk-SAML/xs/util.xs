MODULE = Punk::SAML  PACKAGE = Punk::SAML

# The private primitives, exposed so the suite can drive the bundled
# codecs against their core oracles. None of this is public API and none
# of it is documented in POD; the leading underscore says so.
#
# They exist because a bundled codec that is only reached through a
# finished AuthnRequest is a codec whose failures arrive as "the login
# did not work". Phase 9 tests the flows; these test the pieces.

SV *
_b64_encode(bytes)
        SV *bytes
    CODE:
        STRLEN n, out;
        const char *p = SvPVbyte(bytes, n);
        RETVAL = newSV(psaml_b64_encoded_len(n) + 1);
        SvPOK_on(RETVAL);
        out = psaml_b64_encode(SvPVX(RETVAL), (const unsigned char *)p, n);
        SvCUR_set(RETVAL, out);
        *SvEND(RETVAL) = '\0';
    OUTPUT:
        RETVAL

SV *
_b64_decode(str, allow_ws = 0)
        SV *str
        int allow_ws
    CODE:
        STRLEN n, out;
        const char *p = SvPVbyte(str, n);
        RETVAL = newSV(psaml_b64_decoded_max(n) + 1);
        SvPOK_on(RETVAL);
        out = psaml_b64_decode_ws((unsigned char *)SvPVX(RETVAL), p, n,
                                  allow_ws);
        if (out == (STRLEN)-1) {
            SvREFCNT_dec(RETVAL);
            XSRETURN_UNDEF;
        }
        SvCUR_set(RETVAL, out);
        *SvEND(RETVAL) = '\0';
    OUTPUT:
        RETVAL

SV *
_deflate(bytes)
        SV *bytes
    CODE:
        STRLEN n, out;
        const char *p = SvPVbyte(bytes, n);
        RETVAL = newSV(psaml_deflate_bound(n) + 1);
        SvPOK_on(RETVAL);
        out = psaml_deflate_stored((unsigned char *)SvPVX(RETVAL),
                                   (const unsigned char *)p, n);
        SvCUR_set(RETVAL, out);
        *SvEND(RETVAL) = '\0';
    OUTPUT:
        RETVAL

SV *
_xml_escape(str)
        SV *str
    CODE:
        STRLEN n, out;
        const char *p = SvPVbyte(str, n);
        RETVAL = newSV(psaml_xml_escaped_max(n) + 1);
        SvPOK_on(RETVAL);
        out = psaml_xml_escape(SvPVX(RETVAL), p, n);
        SvCUR_set(RETVAL, out);
        *SvEND(RETVAL) = '\0';
    OUTPUT:
        RETVAL

# Returns undef on any refusal, so the test can assert the refusals as
# a set rather than wrapping every case in an eval. (Do not begin this
# line with the word "undef" after the hash: a .xs comment starting
# "# undef" or "# if" is passed through as a preprocessor directive.)
SV *
_time_parse(str)
        SV *str
    CODE:
        STRLEN n;
        const char *p = SvPVbyte(str, n);
        IV t;
        if (!psaml_time_parse(p, n, &t))
            XSRETURN_UNDEF;
        RETVAL = newSViv(t);
    OUTPUT:
        RETVAL

SV *
_time_format(epoch)
        IV epoch
    CODE:
        char buf[64];
        STRLEN n = psaml_time_format(buf, sizeof buf, epoch);
        RETVAL = newSVpvn(buf, n);
    OUTPUT:
        RETVAL

# Throws a blessed Punk::SAML::Error. t/00-load.t calls this on purpose,
# so the croak_sv shim in psaml_compat.h is exercised on every perl the
# suite runs on rather than first being reached inside a phase-6 check
# on somebody else's smoker.
void
_throw(code, message = NULL)
        const char *code
        SV *message
    CODE:
        PERL_UNUSED_VAR(message);
        psaml_throw(aTHX_ code, NULL);

# The shim itself, called directly rather than through the #ifndef, so
# the body is compiled and run everywhere. Be honest about what this
# buys: it catches crashes, wrong types and ref-flattening on any perl,
# but it cannot catch the location-dropping half of the bug, because the
# wrong shim passes these assertions on a modern perl too. That half is
# only ever provable on a smoker.
void
_croak_sv_selftest(sv)
        SV *sv
    CODE:
        psaml_croak_sv(aTHX_ sv);

# Resolve each provider table and report its version, so a broken
# install fails in one named place rather than three frames into a
# login.
void
_abi_versions()
    PPCODE:
        int v_frx, v_jws, v_fetch;
        # A resolver runs Perl: eval_pv for the require, then call_pv for
        # _abi_ptr. Perl code reallocates the argument stack, so an SP
        # captured before the call is stale afterwards, and pushing
        # through it writes into freed memory. Resolve into locals first,
        # SPAGAIN to pick the stack back up, and only then push.
        v_frx   = psaml_frx(aTHX)->abi_version;
        v_jws   = psaml_jws(aTHX)->version;
        v_fetch = psaml_fetch(aTHX)->abi_version;
        SPAGAIN;
        EXTEND(SP, 3);
        mPUSHi(v_frx);
        mPUSHi(v_jws);
        mPUSHi(v_fetch);

void
_abi_needs()
    PPCODE:
        EXTEND(SP, 3);
        mPUSHi(PSAML_FRX_NEED);
        mPUSHi(PSAML_JWS_NEED);
        mPUSHi(PSAML_FETCH_NEED);
