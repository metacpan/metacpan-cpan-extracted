MODULE = Punk::OAuth2  PACKAGE = Punk::OAuth2::Server::Store

# new(dbh => $dbh) or new(dsn => ..., user => ..., password => ...,
# auto_migrate => 1). Connecting a DSN uses DBI (loaded on demand).
SV *
new(class, ...)
        SV *class
    CODE:
        HV *self = newHV();
        HV *opts = newHV();
        int i;
        SV *obj, **dbh, **dsn;
        PERL_UNUSED_VAR(class);
        sv_2mortal((SV *)opts);
        if ((items - 1) % 2)
            croak("Punk::OAuth2::Server::Store->new: uneven options");
        for (i = 1; i < items; i += 2)
            (void)hv_store_ent(opts, ST(i), newSVsv(ST(i + 1)), 0);

        dbh = hv_fetchs(opts, "dbh", 0);
        dsn = hv_fetchs(opts, "dsn", 0);
        if (dbh && *dbh && SvOK(*dbh)) {
            (void)hv_stores(self, "dbh", newSVsv(*dbh));
            /* a caller-supplied handle: no fork reconnect (no dsn) */
        }
        else if (dsn && *dsn && SvOK(*dsn)) {
            SV **u = hv_fetchs(opts, "user", 0);
            SV **p = hv_fetchs(opts, "password", 0);
            SV *h = pox_dbi_connect(aTHX_ *dsn,
                                    u && *u ? *u : NULL, p && *p ? *p : NULL);
            if (!h) {
                SvREFCNT_dec((SV *)self);
                croak("Punk::OAuth2::Server::Store: DBI connect failed: %s",
                      SvPV_nolen(ERRSV));
            }
            (void)hv_stores(self, "dbh", h);
            /* remember how to reconnect after a fork */
            (void)hv_stores(self, "dsn", newSVsv(*dsn));
            if (u && *u && SvOK(*u)) (void)hv_stores(self, "user", newSVsv(*u));
            if (p && *p && SvOK(*p))
                (void)hv_stores(self, "password", newSVsv(*p));
            (void)hv_stores(self, "pid", newSViv((IV)PerlProc_getpid()));
        }
        else {
            SvREFCNT_dec((SV *)self);
            croak("Punk::OAuth2::Server::Store->new: dbh or dsn required");
        }

        obj = newRV_noinc((SV *)self);
        sv_bless(obj, gv_stashpvs("Punk::OAuth2::Server::Store", GV_ADD));
        {
            SV **am = hv_fetchs(opts, "auto_migrate", 0);
            if (!am || !*am || SvTRUE(*am))
                pox_store_migrate(aTHX_ obj);
        }
        RETVAL = obj;
    OUTPUT:
        RETVAL

void
migrate(self)
        SV *self
    CODE:
        pox_store_migrate(aTHX_ self);

SV *
dbh(self)
        SV *self
    CODE:
        RETVAL = SvREFCNT_inc(pox_store_dbh(aTHX_ self));
    OUTPUT:
        RETVAL

# --- clients ---------------------------------------------------------------

# client_put(\%client): client_id, secret (plaintext, digested here),
# name, redirect_uris (arrayref), grant_types, scopes, auth_method,
# public.
void
client_put(self, spec)
        SV *self
        SV *spec
    CODE:
        SV *dbh = pox_store_dbh(aTHX_ self);
        HV *c;
        SV *binds[9];
        SV *uris, *secret_digest;
        if (!SvROK(spec) || SvTYPE(SvRV(spec)) != SVt_PVHV)
            croak("client_put: expects a hashref");
        c = (HV *)SvRV(spec);
        {
            SV **u = hv_fetchs(c, "redirect_uris", 0);
            if (u && *u && SvROK(*u)) {
                dSP; int count; SV *j = NULL;
                ENTER; SAVETMPS; PUSHMARK(SP);
                XPUSHs(*u); PUTBACK;
                count = call_pv("File::Raw::JSON::file_json_encode",
                                G_SCALAR | G_EVAL);
                SPAGAIN;
                if (!SvTRUE(ERRSV) && count > 0) j = SvREFCNT_inc(POPs);
                else if (count > 0) (void)POPs;
                PUTBACK; FREETMPS; LEAVE;
                uris = j ? sv_2mortal(j) : sv_2mortal(newSVpvs("[]"));
            }
            else uris = sv_2mortal(newSVpvs("[]"));
        }
        {
            SV **s = hv_fetchs(c, "secret", 0);
            secret_digest = (s && *s && SvOK(*s) && SvCUR(*s))
                ? pox_digest(aTHX_ *s) : &PL_sv_undef;
        }
        binds[0] = hv_fetchs(c, "client_id", 0)
            ? *hv_fetchs(c, "client_id", 0) : &PL_sv_undef;
        binds[1] = secret_digest;
        binds[2] = hv_fetchs(c, "name", 0) ? *hv_fetchs(c, "name", 0)
            : &PL_sv_undef;
        binds[3] = uris;
        binds[4] = hv_fetchs(c, "grant_types", 0)
            ? *hv_fetchs(c, "grant_types", 0)
            : sv_2mortal(newSVpvs("authorization_code refresh_token"));
        binds[5] = hv_fetchs(c, "scopes", 0) ? *hv_fetchs(c, "scopes", 0)
            : &PL_sv_undef;
        binds[6] = hv_fetchs(c, "auth_method", 0)
            ? *hv_fetchs(c, "auth_method", 0) : sv_2mortal(newSVpvs("basic"));
        binds[7] = sv_2mortal(newSViv(
            hv_fetchs(c, "public", 0) && SvTRUE(*hv_fetchs(c, "public", 0))
              ? 1 : 0));
        binds[8] = sv_2mortal(newSViv((IV)time(NULL)));
        (void)pox_dbi_do(aTHX_ dbh,
            "INSERT OR REPLACE INTO oauth2_clients (client_id, "
            "secret_digest, name, redirect_uris, grant_types, scopes, "
            "auth_method, is_public, created) VALUES (?,?,?,?,?,?,?,?,?)",
            binds, 9);

SV *
client_get(self, client_id)
        SV *self
        SV *client_id
    CODE:
        SV *dbh = pox_store_dbh(aTHX_ self);
        SV *binds[1];
        HV *row;
        binds[0] = client_id;
        row = pox_dbi_row(aTHX_ dbh,
            "SELECT * FROM oauth2_clients WHERE client_id = ?", binds, 1);
        RETVAL = row ? newRV_inc((SV *)row) : &PL_sv_undef;
    OUTPUT:
        RETVAL

# --- codes -----------------------------------------------------------------

# code_put($code, \%rec): stores sha256(code) with the bound fields.
void
code_put(self, code, rec)
        SV *self
        SV *code
        SV *rec
    CODE:
        SV *dbh = pox_store_dbh(aTHX_ self);
        HV *r;
        SV *binds[7];
        if (!SvROK(rec) || SvTYPE(SvRV(rec)) != SVt_PVHV)
            croak("code_put: expects a hashref");
        r = (HV *)SvRV(rec);
        binds[0] = pox_digest(aTHX_ code);
        binds[1] = hv_fetchs(r, "client_id", 0) ? *hv_fetchs(r,"client_id",0) : &PL_sv_undef;
        binds[2] = hv_fetchs(r, "user_id", 0) ? *hv_fetchs(r,"user_id",0) : &PL_sv_undef;
        binds[3] = hv_fetchs(r, "redirect_uri", 0) ? *hv_fetchs(r,"redirect_uri",0) : &PL_sv_undef;
        binds[4] = hv_fetchs(r, "scope", 0) ? *hv_fetchs(r,"scope",0) : &PL_sv_undef;
        binds[5] = hv_fetchs(r, "nonce", 0) ? *hv_fetchs(r,"nonce",0) : &PL_sv_undef;
        binds[6] = hv_fetchs(r, "code_challenge", 0) ? *hv_fetchs(r,"code_challenge",0) : &PL_sv_undef;
        {
            SV *b2[8];
            SV **e = hv_fetchs(r, "expires", 0);
            int k;
            for (k = 0; k < 7; k++) b2[k] = binds[k];
            b2[7] = e && *e ? *e : sv_2mortal(newSViv((IV)time(NULL) + 300));
            (void)pox_dbi_do(aTHX_ dbh,
                "INSERT INTO oauth2_codes (code_digest, client_id, "
                "user_id, redirect_uri, scope, nonce, code_challenge, "
                "expires) VALUES (?,?,?,?,?,?,?,?)", b2, 8);
        }

# code_take($code) -> row hashref or undef, deleting it (single use).
SV *
code_take(self, code)
        SV *self
        SV *code
    CODE:
        SV *dbh = pox_store_dbh(aTHX_ self);
        SV *dig = pox_digest(aTHX_ code);
        SV *binds[1];
        HV *row;
        binds[0] = dig;
        row = pox_dbi_row(aTHX_ dbh,
            "SELECT * FROM oauth2_codes WHERE code_digest = ?", binds, 1);
        if (!row) { RETVAL = &PL_sv_undef; }
        else {
            IV deleted = pox_dbi_do(aTHX_ dbh,
                "DELETE FROM oauth2_codes WHERE code_digest = ?", binds, 1);
            if (deleted < 1) RETVAL = &PL_sv_undef;  /* lost the race */
            else RETVAL = newRV_inc((SV *)row);
        }
    OUTPUT:
        RETVAL

# --- refresh tokens --------------------------------------------------------

void
refresh_put(self, token, rec)
        SV *self
        SV *token
        SV *rec
    CODE:
        SV *dbh = pox_store_dbh(aTHX_ self);
        HV *r;
        SV *binds[6];
        if (!SvROK(rec) || SvTYPE(SvRV(rec)) != SVt_PVHV)
            croak("refresh_put: expects a hashref");
        r = (HV *)SvRV(rec);
        binds[0] = pox_digest(aTHX_ token);
        binds[1] = hv_fetchs(r, "family_id", 0) ? *hv_fetchs(r,"family_id",0) : &PL_sv_undef;
        binds[2] = hv_fetchs(r, "client_id", 0) ? *hv_fetchs(r,"client_id",0) : &PL_sv_undef;
        binds[3] = hv_fetchs(r, "user_id", 0) ? *hv_fetchs(r,"user_id",0) : &PL_sv_undef;
        binds[4] = hv_fetchs(r, "scope", 0) ? *hv_fetchs(r,"scope",0) : &PL_sv_undef;
        binds[5] = hv_fetchs(r, "expires", 0) ? *hv_fetchs(r,"expires",0)
            : sv_2mortal(newSViv((IV)time(NULL) + 30*86400));
        (void)pox_dbi_do(aTHX_ dbh,
            "INSERT INTO oauth2_refresh (token_digest, family_id, "
            "client_id, user_id, scope, expires) VALUES (?,?,?,?,?,?)",
            binds, 6);

SV *
refresh_take(self, token)
        SV *self
        SV *token
    CODE:
        SV *dbh = pox_store_dbh(aTHX_ self);
        SV *binds[1];
        HV *row;
        binds[0] = pox_digest(aTHX_ token);
        row = pox_dbi_row(aTHX_ dbh,
            "SELECT * FROM oauth2_refresh WHERE token_digest = ?", binds, 1);
        RETVAL = row ? newRV_inc((SV *)row) : &PL_sv_undef;
    OUTPUT:
        RETVAL

# mark a refresh token rotated (consumed) to a new one
void
refresh_rotate(self, token, new_digest)
        SV *self
        SV *token
        SV *new_digest
    CODE:
        SV *dbh = pox_store_dbh(aTHX_ self);
        SV *binds[2];
        binds[0] = new_digest;
        binds[1] = pox_digest(aTHX_ token);
        (void)pox_dbi_do(aTHX_ dbh,
            "UPDATE oauth2_refresh SET rotated_to = ? WHERE token_digest = ?",
            binds, 2);

void
refresh_revoke_family(self, family_id)
        SV *self
        SV *family_id
    CODE:
        SV *dbh = pox_store_dbh(aTHX_ self);
        SV *binds[1];
        binds[0] = family_id;
        (void)pox_dbi_do(aTHX_ dbh,
            "UPDATE oauth2_refresh SET revoked = 1 WHERE family_id = ?",
            binds, 1);

# --- consent ---------------------------------------------------------------

SV *
consent_get(self, user_id, client_id)
        SV *self
        SV *user_id
        SV *client_id
    CODE:
        SV *dbh = pox_store_dbh(aTHX_ self);
        SV *binds[2];
        HV *row;
        binds[0] = user_id;
        binds[1] = client_id;
        row = pox_dbi_row(aTHX_ dbh,
            "SELECT * FROM oauth2_consents WHERE user_id = ? AND "
            "client_id = ?", binds, 2);
        RETVAL = row ? newRV_inc((SV *)row) : &PL_sv_undef;
    OUTPUT:
        RETVAL

void
consent_put(self, user_id, client_id, scopes)
        SV *self
        SV *user_id
        SV *client_id
        SV *scopes
    CODE:
        SV *dbh = pox_store_dbh(aTHX_ self);
        SV *binds[4];
        binds[0] = user_id;
        binds[1] = client_id;
        binds[2] = scopes;
        binds[3] = sv_2mortal(newSViv((IV)time(NULL)));
        (void)pox_dbi_do(aTHX_ dbh,
            "INSERT OR REPLACE INTO oauth2_consents (user_id, client_id, "
            "scopes, created) VALUES (?,?,?,?)", binds, 4);

void
purge_expired(self)
        SV *self
    CODE:
        SV *dbh = pox_store_dbh(aTHX_ self);
        SV *binds[1];
        binds[0] = sv_2mortal(newSViv((IV)time(NULL)));
        (void)pox_dbi_do(aTHX_ dbh,
            "DELETE FROM oauth2_codes WHERE expires < ?", binds, 1);
        binds[0] = sv_2mortal(newSViv((IV)time(NULL)));
        (void)pox_dbi_do(aTHX_ dbh,
            "DELETE FROM oauth2_refresh WHERE expires < ?", binds, 1);
