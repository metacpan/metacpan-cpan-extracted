#ifndef POX_STORE_H
#define POX_STORE_H

#include "pox_abi.h"

/* Punk::OAuth2::Server::Store: a DBI-backed store for the authorization
 * server, in XS. Every credential is stored as a base64url SHA-256
 * digest, never in the clear. The blessed HV holds { dbh }. */

/* base64url(sha256(bytes)) as a mortal SV - the storage key for any
 * secret (client secret, code, refresh token). */
static SV *pox_digest(pTHX_ SV *token) {
  STRLEN tl;
  const char *tp = SvPVbyte(token, tl);
  SV *d = pox_sha256(aTHX_ (const unsigned char *)tp, tl);
  return pox_b64url(aTHX_ (const unsigned char *)SvPVX(d), SvCUR(d));
}

/* DBI->connect($dsn, $user, $pass, {RaiseError,AutoCommit,PrintError}).
 * Returns the dbh (owned) or NULL. */
static SV *pox_dbi_connect(pTHX_ SV *dsn, SV *user, SV *pass) {
  dSP; int count; SV *h = NULL;
  HV *attr;
  eval_pv("require DBI;", FALSE);
  SPAGAIN;   /* the require may have reallocated the stack */
  attr = newHV();
  (void)hv_stores(attr, "RaiseError", newSViv(1));
  (void)hv_stores(attr, "AutoCommit", newSViv(1));
  (void)hv_stores(attr, "PrintError", newSViv(0));
  ENTER; SAVETMPS; PUSHMARK(SP);
  XPUSHs(sv_2mortal(newSVpvs("DBI")));
  XPUSHs(dsn);
  XPUSHs(user && SvOK(user) ? user : &PL_sv_undef);
  XPUSHs(pass && SvOK(pass) ? pass : &PL_sv_undef);
  XPUSHs(sv_2mortal(newRV_noinc((SV *)attr)));
  PUTBACK;
  count = call_method("connect", G_SCALAR | G_EVAL);
  SPAGAIN;
  if (!SvTRUE(ERRSV) && count > 0) h = SvREFCNT_inc(POPs);
  else if (count > 0) (void)POPs;
  PUTBACK; FREETMPS; LEAVE;
  return (h && SvOK(h)) ? h : NULL;
}

static SV *pox_store_dbh(pTHX_ SV *self) {
  HV *h;
  SV **d, **dsn, **pidv;
  IV pid;
  if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
    croak("Punk::OAuth2::Server::Store: not a store");
  h = (HV *)SvRV(self);
  /* Fork safety: a DBI/DBD handle must not be shared across a fork.
   * When the store owns a dsn and the pid has changed since connect,
   * reconnect - so a prefork worker gets its own handle. */
  dsn = hv_fetchs(h, "dsn", 0);
  pidv = hv_fetchs(h, "pid", 0);
  pid = (IV)PerlProc_getpid();
  if (dsn && *dsn && SvOK(*dsn) && pidv && *pidv && SvIV(*pidv) != pid) {
    SV *nh = pox_dbi_connect(aTHX_ *dsn,
                             hv_fetchs(h, "user", 0) ? *hv_fetchs(h,"user",0) : NULL,
                             hv_fetchs(h, "password", 0) ? *hv_fetchs(h,"password",0) : NULL);
    if (nh) {
      (void)hv_stores(h, "dbh", nh);
      (void)hv_stores(h, "pid", newSViv(pid));
    }
  }
  d = hv_fetchs(h, "dbh", 0);
  if (!d || !*d || !SvOK(*d))
    croak("Punk::OAuth2::Server::Store: no database handle");
  return *d;
}

/* $dbh->do($sql, undef, @binds) -> rows affected (or -1 on error). */
static IV pox_dbi_do(pTHX_ SV *dbh, const char *sql, SV **binds, int n) {
  dSP; int count, i; IV rv = -1;
  ENTER; SAVETMPS; PUSHMARK(SP);
  EXTEND(SP, n + 3);
  PUSHs(dbh);
  PUSHs(sv_2mortal(newSVpv(sql, 0)));
  PUSHs(&PL_sv_undef);
  for (i = 0; i < n; i++) PUSHs(binds[i]);
  PUTBACK;
  count = call_method("do", G_SCALAR | G_EVAL);
  SPAGAIN;
  if (!SvTRUE(ERRSV) && count > 0) rv = SvIV(POPs);
  else if (count > 0) (void)POPs;
  PUTBACK; FREETMPS; LEAVE;
  if (SvTRUE(ERRSV))
    croak("Punk::OAuth2::Server::Store: %s", SvPV_nolen(ERRSV));
  return rv;
}

/* $dbh->selectrow_hashref($sql, undef, @binds) -> row HV (mortal) or NULL. */
static HV *pox_dbi_row(pTHX_ SV *dbh, const char *sql, SV **binds, int n) {
  dSP; int count, i; SV *row = NULL;
  ENTER; SAVETMPS; PUSHMARK(SP);
  EXTEND(SP, n + 3);
  PUSHs(dbh);
  PUSHs(sv_2mortal(newSVpv(sql, 0)));
  PUSHs(&PL_sv_undef);
  for (i = 0; i < n; i++) PUSHs(binds[i]);
  PUTBACK;
  count = call_method("selectrow_hashref", G_SCALAR | G_EVAL);
  SPAGAIN;
  if (!SvTRUE(ERRSV) && count > 0) row = SvREFCNT_inc(POPs);
  else if (count > 0) (void)POPs;
  PUTBACK; FREETMPS; LEAVE;
  if (!row || !SvROK(row) || SvTYPE(SvRV(row)) != SVt_PVHV) {
    SvREFCNT_dec(row);
    return NULL;
  }
  sv_2mortal(row);
  return (HV *)SvRV(row);
}

static const char *POX_SCHEMA[] = {
  "CREATE TABLE IF NOT EXISTS oauth2_clients ("
    "client_id TEXT PRIMARY KEY, secret_digest TEXT, name TEXT, "
    "redirect_uris TEXT, grant_types TEXT, scopes TEXT, "
    "auth_method TEXT, is_public INTEGER DEFAULT 0, created INTEGER)",
  "CREATE TABLE IF NOT EXISTS oauth2_codes ("
    "code_digest TEXT PRIMARY KEY, client_id TEXT, user_id TEXT, "
    "redirect_uri TEXT, scope TEXT, nonce TEXT, code_challenge TEXT, "
    "expires INTEGER)",
  "CREATE TABLE IF NOT EXISTS oauth2_refresh ("
    "token_digest TEXT PRIMARY KEY, family_id TEXT, client_id TEXT, "
    "user_id TEXT, scope TEXT, expires INTEGER, rotated_to TEXT, "
    "revoked INTEGER DEFAULT 0)",
  "CREATE TABLE IF NOT EXISTS oauth2_consents ("
    "user_id TEXT, client_id TEXT, scopes TEXT, created INTEGER, "
    "PRIMARY KEY (user_id, client_id))",
  NULL
};

static void pox_store_migrate(pTHX_ SV *self) {
  SV *dbh = pox_store_dbh(aTHX_ self);
  int i;
  for (i = 0; POX_SCHEMA[i]; i++)
    (void)pox_dbi_do(aTHX_ dbh, POX_SCHEMA[i], NULL, 0);
}

/* Row field as a mortal SV (borrowed from the row), or NULL. */
static SV *pox_row_get(pTHX_ HV *row, const char *k) {
  SV **v = hv_fetch(row, k, (I32)strlen(k), 0);
  return (v && *v && SvOK(*v)) ? *v : NULL;
}

#endif
