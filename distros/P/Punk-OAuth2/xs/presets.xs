MODULE = Punk::OAuth2  PACKAGE = Punk::OAuth2::Presets

# preset(NAME) -> a fresh config hashref (google, github, oidc).
SV *
preset(name)
        SV *name
    CODE:
        RETVAL = newRV_noinc((SV *)pox_preset(aTHX_ SvPV_nolen(name)));
    OUTPUT:
        RETVAL

MODULE = Punk::OAuth2  PACKAGE = Punk::OAuth2

# _github_identity($user, $emails) -> normalized identity hashref. The
# github preset references this as its identity_map.
SV *
_github_identity(user, emails)
        SV *user
        SV *emails
    CODE:
        HV *u = (SvROK(user) && SvTYPE(SvRV(user)) == SVt_PVHV)
            ? (HV *)SvRV(user) : NULL;
        HV *out = newHV();
        SV **id, **login, **name, **avatar, **email;
        SV *primary_email = NULL;
        int primary_verified = -1;
        if (!u) croak("Punk::OAuth2::_github_identity: user must be a hashref");

        /* pick the primary (or first) verified email */
        if (SvROK(emails) && SvTYPE(SvRV(emails)) == SVt_PVAV) {
            AV *av = (AV *)SvRV(emails);
            SSize_t i, n = av_count(av);
            SV *first = NULL;
            int first_verified = -1;
            for (i = 0; i < n; i++) {
                SV **e = av_fetch(av, i, 0);
                HV *eh;
                SV **em, **pr, **ve;
                if (!e || !*e || !SvROK(*e)
                    || SvTYPE(SvRV(*e)) != SVt_PVHV) continue;
                eh = (HV *)SvRV(*e);
                em = hv_fetchs(eh, "email", 0);
                pr = hv_fetchs(eh, "primary", 0);
                ve = hv_fetchs(eh, "verified", 0);
                if (!em || !*em) continue;
                if (!first) {
                    first = *em;
                    first_verified = (ve && *ve) ? (SvTRUE(*ve) ? 1 : 0) : -1;
                }
                if (pr && *pr && SvTRUE(*pr)) {
                    primary_email = *em;
                    primary_verified = (ve && *ve) ? (SvTRUE(*ve) ? 1 : 0) : -1;
                    break;
                }
            }
            if (!primary_email && first) {
                primary_email = first;
                primary_verified = first_verified;
            }
        }

        id     = hv_fetchs(u, "id", 0);
        login  = hv_fetchs(u, "login", 0);
        name   = hv_fetchs(u, "name", 0);
        avatar = hv_fetchs(u, "avatar_url", 0);
        email  = hv_fetchs(u, "email", 0);

        if (id && *id && SvOK(*id)) {
            /* stringify the numeric id */
            SV *s = newSVsv(*id);
            sv_2pv_flags(s, &PL_na, SV_GMAGIC);
            (void)hv_stores(out, "sub", newSVpvf("%s", SvPV_nolen(*id)));
            SvREFCNT_dec(s);
        }
        else {
            (void)hv_stores(out, "sub", newSV(0));
        }
        (void)hv_stores(out, "email",
            primary_email ? newSVsv(primary_email)
                          : (email && *email ? newSVsv(*email) : newSV(0)));
        (void)hv_stores(out, "email_verified",
            primary_verified < 0 ? newSV(0) : newSViv(primary_verified));
        (void)hv_stores(out, "name",
            name && *name && SvOK(*name) ? newSVsv(*name)
            : (login && *login ? newSVsv(*login) : newSV(0)));
        (void)hv_stores(out, "picture",
            avatar && *avatar ? newSVsv(*avatar) : newSV(0));
        RETVAL = newRV_noinc((SV *)out);
    OUTPUT:
        RETVAL
