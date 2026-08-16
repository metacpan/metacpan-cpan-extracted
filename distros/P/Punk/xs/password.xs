MODULE = Punk        PACKAGE = Punk::Auth::Password

PROTOTYPES: DISABLE

# Password hashing (punk_password.h): PBKDF2-HMAC-SHA256 over the dist's own
# SHA-256, in the MaatSite::Password stored format. Callable as functions or
# as class methods - a leading 'Punk::Auth::Password' invocant is skipped, so
# migrating code written against the class-method style keeps working.

# The iteration default: an explicit argument wins, then the localizable
# our $ITERATIONS in Punk/Auth/Password.pm, then the built-in 60_000.
SV *
hash(...)
    CODE:
    {
        int i = 0;
        SV *plain;
        U32 iterations = 0;
        STRLEN pl;
        const unsigned char *p;
        if (items > i && SvPOK(ST(i)) && sv_derived_from(ST(i), "Punk::Auth::Password"))
            i++;
        if (items <= i || !SvOK(ST(i)))
            croak("Punk::Auth::Password: hash needs a password");
        plain = ST(i);
        if (items > i + 1 && SvOK(ST(i + 1))) {
            IV want = SvIV(ST(i + 1));
            if (want <= 0)
                croak("Punk::Auth::Password: iterations must be positive");
            iterations = (U32)want;
        }
        else {
            SV *itsv = get_sv("Punk::Auth::Password::ITERATIONS", 0);
            if (itsv && SvOK(itsv) && SvIV(itsv) > 0)
                iterations = (U32)SvIV(itsv);
        }
        p = (const unsigned char *)SvPV(plain, pl);
        RETVAL = pwd_hash(aTHX_ p, pl, iterations);
    }
    OUTPUT:
        RETVAL

IV
verify(...)
    CODE:
    {
        int i = 0;
        STRLEN pl, sl;
        const unsigned char *p;
        const char *s;
        if (items > i && SvPOK(ST(i)) && sv_derived_from(ST(i), "Punk::Auth::Password"))
            i++;
        if (items <= i + 1 || !SvOK(ST(i)) || !SvOK(ST(i + 1)))
            RETVAL = 0;
        else {
            p = (const unsigned char *)SvPV(ST(i), pl);
            s = SvPV(ST(i + 1), sl);
            RETVAL = pwd_verify(aTHX_ p, pl, s, sl);
        }
    }
    OUTPUT:
        RETVAL

IV
needs_rehash(...)
    CODE:
    {
        int i = 0;
        U32 current = 0;
        STRLEN sl;
        const char *s;
        SV *itsv;
        if (items > i && SvPOK(ST(i)) && sv_derived_from(ST(i), "Punk::Auth::Password"))
            i++;
        itsv = get_sv("Punk::Auth::Password::ITERATIONS", 0);
        if (itsv && SvOK(itsv) && SvIV(itsv) > 0) current = (U32)SvIV(itsv);
        if (items > i + 1 && SvOK(ST(i + 1)) && SvIV(ST(i + 1)) > 0)
            current = (U32)SvIV(ST(i + 1));
        if (items <= i || !SvOK(ST(i)))
            RETVAL = 1;                       /* no hash at all: rehash */
        else {
            s = SvPV(ST(i), sl);
            RETVAL = pwd_needs_rehash(aTHX_ s, sl, current);
        }
    }
    OUTPUT:
        RETVAL

SV *
token(...)
    CODE:
        PERL_UNUSED_VAR(items);
        RETVAL = pwd_token(aTHX);
    OUTPUT:
        RETVAL

SV *
token_digest(...)
    CODE:
    {
        int i = 0;
        STRLEN tl;
        const unsigned char *t;
        if (items > i && SvPOK(ST(i)) && sv_derived_from(ST(i), "Punk::Auth::Password"))
            i++;
        if (items <= i || !SvOK(ST(i)))
            croak("Punk::Auth::Password: token_digest needs a token");
        t = (const unsigned char *)SvPV(ST(i), tl);
        RETVAL = pwd_token_digest(aTHX_ t, tl);
    }
    OUTPUT:
        RETVAL
