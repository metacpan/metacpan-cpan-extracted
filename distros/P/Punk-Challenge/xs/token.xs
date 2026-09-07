MODULE = Punk::Challenge    PACKAGE = Punk::Challenge::Token

# Issue and verify, without a plugin or an application: the module a test
# or the command line reaches for. `cfg` is the plugin's option hash and is
# validated exactly as the `plugin` line validates it, so what a test proves
# here is what the plugin does.
#
# Every method takes the configuration and the subject first. The subject
# is whatever the caller says it is - the plugin derives it from the
# request; a test or the CLI says it outright.

# The options a call may add after its positional arguments.

# ---- the configuration ------------------------------------------------------

# Validated and normalised per call, and mortal. Not cached: a test edits
# the hash between calls, and the cost is the CLI's, not the request's.
# (The plugin holds its own normalised copy and never comes through here.)

# ---- subject ------------------------------------------------------------------

# subject($addr, $bind = 'prefix'): the subject an address has under a
# binding, so a test can say what two addresses share.

SV *
subject(class, addr, bind = "prefix")
        SV *class
        SV *addr
        const char *bind
    CODE:
    {
        STRLEN al = 0, bl = strlen(bind);
        const char *ap = SvOK(addr) ? SvPV_const(addr, al) : "";
        PERL_UNUSED_VAR(class);
        if (!((bl == 6 && memEQ(bind, "prefix", 6))
              || (bl == 2 && memEQ(bind, "ip", 2))
              || (bl == 4 && memEQ(bind, "none", 4))))
            croak("%s: `bind` must be 'prefix', 'ip' or 'none', not '%s'",
                  PCHAL_WHO, bind);
        RETVAL = newSVpvs("");
        pchal_subject_cat(aTHX_ RETVAL, ap, al, bind, bl);
    }
    OUTPUT:
        RETVAL

# ---- a secret -----------------------------------------------------------------

# key(): 32 random bytes as base64url, for the configuration. What
# `punk challenge key` prints. Croaks when no entropy source answers,
# because a secret an attacker could predict is worse than none.

SV *
key(class)
        SV *class
    CODE:
    {
        unsigned char raw[32];
        PERL_UNUSED_VAR(class);
        if (pchal_random_bytes(raw, sizeof raw) != 0)
            croak("%s: no entropy source: getentropy is unavailable and "
                  "/dev/urandom could not be read", PCHAL_WHO);
        RETVAL = newSV(PCHAL_B64_LEN(32) + 1);
        SvPOK_on(RETVAL);
        SvCUR_set(RETVAL, pchal_b64url(raw, sizeof raw, SvPVX(RETVAL)));
        *SvEND(RETVAL) = '\0';
    }
    OUTPUT:
        RETVAL

# ---- the puzzle -----------------------------------------------------------------

# issue(\%cfg, $subject, %opts): a fresh puzzle. Options: bits, now.

SV *
issue(class, cfg, subject, ...)
        SV *class
        SV *cfg
        SV *subject
    CODE:
    {
        static const char *const known[] = { "bits", "now", NULL };
        HV *o = pchal_opts(aTHX_ cfg);
        HV *in = pchal_args(aTHX_ "issue", &ST(3), items - 3);
        SV *b;
        IV bits, now;
        PERL_UNUSED_VAR(class);
        (void)sv_2mortal((SV *)o);
        pchal_check_opts(aTHX_ "option", in, known);
        b = pchal_opt_str(aTHX_ in, "bits");
        bits = b ? pchal_opt_iv(aTHX_ in, "bits", 0, 1, PCHAL_MAX_BITS)
                 : pchal_bits_for(aTHX_ o, NULL);
        now = pchal_opt_iv(aTHX_ in, "now", 0, 0, IV_MAX);
        RETVAL = pchal_puzzle_issue(aTHX_ o, subject, bits, now);
    }
    OUTPUT:
        RETVAL

# verify(\%cfg, $subject, $puzzle, $nonce, %opts): the puzzle's bits when
# the solution is correct, else undef. In list context, the reason follows.
# $nonce undef means $puzzle already carries it. Options: bits (what this
# check demands; default the configuration's), now.

void
verify(class, cfg, subject, puzzle, nonce = &PL_sv_undef, ...)
        SV *class
        SV *cfg
        SV *subject
        SV *puzzle
        SV *nonce
    PPCODE:
    {
        static const char *const known[] = { "bits", "now", NULL };
        HV *o = pchal_opts(aTHX_ cfg);
        HV *in = pchal_args(aTHX_ "verify", &ST(5), items > 5 ? items - 5 : 0);
        SV *b, *sol;
        IV bits, now, got = 0;
        STRLEN sl;
        const char *solp;    /* not `sp`: that is the Perl stack pointer here */
        pchal_reason r;
        PERL_UNUSED_VAR(class);
        (void)sv_2mortal((SV *)o);
        pchal_check_opts(aTHX_ "option", in, known);
        b = pchal_opt_str(aTHX_ in, "bits");
        bits = b ? pchal_opt_iv(aTHX_ in, "bits", 0, 1, PCHAL_MAX_BITS)
                 : pchal_bits_for(aTHX_ o, NULL);
        now = pchal_opt_iv(aTHX_ in, "now", 0, 0, IV_MAX);

        sol = sv_2mortal(newSVsv(puzzle));
        if (SvOK(nonce)) {
            sv_catpvs(sol, ".");
            sv_catsv(sol, nonce);
        }
        solp = SvPV_const(sol, sl);
        r = pchal_puzzle_verify(aTHX_ o, subject, solp, sl, bits, now, &got);

        EXTEND(SP, 2);
        PUSHs(r == PCHAL_OK ? sv_2mortal(newSViv(got)) : &PL_sv_undef);
        if (GIMME_V == G_LIST)
            PUSHs(sv_2mortal(newSVpv(pchal_reason_str(r), 0)));
    }

# ---- the clearance ------------------------------------------------------------

# clear(\%cfg, $subject, %opts): a clearance value, as the cookie carries
# it. Options: bits (what was solved; default the configuration's), now.

SV *
clear(class, cfg, subject, ...)
        SV *class
        SV *cfg
        SV *subject
    CODE:
    {
        static const char *const known[] = { "bits", "now", NULL };
        HV *o = pchal_opts(aTHX_ cfg);
        HV *in = pchal_args(aTHX_ "clear", &ST(3), items - 3);
        SV *b;
        IV bits, now;
        PERL_UNUSED_VAR(class);
        (void)sv_2mortal((SV *)o);
        pchal_check_opts(aTHX_ "option", in, known);
        b = pchal_opt_str(aTHX_ in, "bits");
        bits = b ? pchal_opt_iv(aTHX_ in, "bits", 0, 1, PCHAL_MAX_BITS)
                 : pchal_bits_for(aTHX_ o, NULL);
        now = pchal_opt_iv(aTHX_ in, "now", 0, 0, IV_MAX);
        RETVAL = pchal_clearance_issue(aTHX_ o, subject, bits, now);
    }
    OUTPUT:
        RETVAL

# cleared(\%cfg, $subject, $value, %opts): the clearance's bits when it is
# valid for this subject at or above the demanded bits, else undef. In list
# context, the reason follows. Options: bits, now.

void
cleared(class, cfg, subject, value, ...)
        SV *class
        SV *cfg
        SV *subject
        SV *value
    PPCODE:
    {
        static const char *const known[] = { "bits", "now", NULL };
        HV *o = pchal_opts(aTHX_ cfg);
        HV *in = pchal_args(aTHX_ "cleared", &ST(4), items - 4);
        SV *b;
        IV bits, now, got = 0;
        STRLEN vl = 0;
        const char *vp = "";
        pchal_reason r;
        PERL_UNUSED_VAR(class);
        (void)sv_2mortal((SV *)o);
        pchal_check_opts(aTHX_ "option", in, known);
        b = pchal_opt_str(aTHX_ in, "bits");
        bits = b ? pchal_opt_iv(aTHX_ in, "bits", 0, 1, PCHAL_MAX_BITS)
                 : pchal_bits_for(aTHX_ o, NULL);
        now = pchal_opt_iv(aTHX_ in, "now", 0, 0, IV_MAX);
        if (SvOK(value)) vp = SvPV_const(value, vl);
        r = pchal_clearance_verify(aTHX_ o, subject, vp, vl, bits, now, &got);

        EXTEND(SP, 2);
        PUSHs(r == PCHAL_OK ? sv_2mortal(newSViv(got)) : &PL_sv_undef);
        if (GIMME_V == G_LIST)
            PUSHs(sv_2mortal(newSVpv(pchal_reason_str(r), 0)));
    }

# ---- private, for the tests -------------------------------------------------
#
# The primitives, reachable so they can be tested for what they are against
# Digest::SHA rather than only through a token. A hash with one wrong byte
# invalidates everything downstream of it, and testing it through a whole
# puzzle would report that as a refused solution rather than as a mis-hashed
# block boundary.
#
# Bytes in, bytes out. SvPVbyte croaks on a string that cannot be downgraded,
# which is the right answer for a key or a message holding wide characters.

SV *
_sha256(msg)
        SV *msg
    CODE:
    {
        STRLEN l;
        const unsigned char *p = (const unsigned char *)SvPVbyte(msg, l);
        unsigned char d[32];
        pchal_sha256(p, l, d);
        RETVAL = newSVpvn((const char *)d, 32);
    }
    OUTPUT:
        RETVAL

SV *
_hmac_sha256(key, msg)
        SV *key
        SV *msg
    CODE:
    {
        STRLEN kl, ml;
        const unsigned char *k = (const unsigned char *)SvPVbyte(key, kl);
        const unsigned char *m = (const unsigned char *)SvPVbyte(msg, ml);
        unsigned char d[32];
        pchal_hmac_sha256(k, kl, m, ml, d);
        RETVAL = newSVpvn((const char *)d, 32);
    }
    OUTPUT:
        RETVAL

SV *
_b64url(bytes)
        SV *bytes
    CODE:
    {
        STRLEN l, n;
        const unsigned char *p = (const unsigned char *)SvPVbyte(bytes, l);
        RETVAL = newSV(PCHAL_B64_LEN(l) + 1);
        SvPOK_on(RETVAL);
        n = pchal_b64url(p, l, SvPVX(RETVAL));
        SvCUR_set(RETVAL, n);
        *SvEND(RETVAL) = '\0';
    }
    OUTPUT:
        RETVAL

IV
_ct_eq(a, b)
        SV *a
        SV *b
    CODE:
    {
        STRLEN al, bl;
        const char *ap = SvPVbyte(a, al);
        const char *bp = SvPVbyte(b, bl);
        RETVAL = pchal_ct_eq(ap, al, bp, bl);
    }
    OUTPUT:
        RETVAL

IV
_zero_bits(digest)
        SV *digest
    CODE:
    {
        STRLEN l;
        const unsigned char *p = (const unsigned char *)SvPVbyte(digest, l);
        RETVAL = pchal_zero_bits(p, l);
    }
    OUTPUT:
        RETVAL
