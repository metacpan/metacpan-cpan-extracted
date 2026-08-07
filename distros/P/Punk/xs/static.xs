MODULE = Punk        PACKAGE = Punk::Static

PROTOTYPES: DISABLE

# Punk::Static->app($dir) - the PSGI coderef serving that directory. The
# request path itself is punk_static_cb in include/punk/punk_static.h: a
# magic CV carrying [ $dir ], so a request for a file crosses no Perl
# frame at all.
SV *
app(class, dir)
        SV *class
        SV *dir
    CODE:
    {
        AV *cap;
        Stat_t st;
        const char *d = SvPV_nolen(dir);
        PERL_UNUSED_VAR(class);
        if (PerlLIO_stat(d, &st) < 0 || !S_ISDIR(st.st_mode))
            croak("Punk::Static: '%s' is not a directory", d);
        cap = newAV();
        {   /* keep the directory without a trailing slash, so joining a
             * PATH_INFO (which always starts with one) cannot double it */
            STRLEN dlen;
            const char *p = SvPV_const(dir, dlen);
            while (dlen > 1 && p[dlen - 1] == '/') dlen--;
            av_push(cap, newSVpvn(p, dlen));
        }
        RETVAL = punk_closure(aTHX_ punk_static_cb, cap);
    }
    OUTPUT:
        RETVAL
