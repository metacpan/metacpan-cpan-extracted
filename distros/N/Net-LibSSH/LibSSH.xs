#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <libssh/libssh.h>
#include <libssh/sftp.h>

/* ====================================================
   Internal structs
   ==================================================== */

typedef struct {
    ssh_session session;
} NLSS_Session;

typedef struct {
    ssh_channel channel;
    SV         *session_sv;   /* holds a ref to the session SV — prevents GC */
} NLSS_Channel;

typedef struct {
    sftp_session sftp;
    SV          *session_sv;
} NLSS_SFTP;

/* Macros to unbox a blessed SV into the C struct pointer.
   No typemap needed — all XS params that are objects use SV*. */
#define SELF_SESSION(sv)  ((NLSS_Session *)SvIV(SvRV(sv)))
#define SELF_CHANNEL(sv)  ((NLSS_Channel *)SvIV(SvRV(sv)))
#define SELF_SFTP(sv)     ((NLSS_SFTP    *)SvIV(SvRV(sv)))

/* ====================================================
   Helper functions
   ==================================================== */

static void
nlss_croak_error(pTHX_ ssh_session session, const char *prefix)
{
    const char *msg = ssh_get_error(session);
    Perl_croak(aTHX_ "%s: %s", prefix, msg ? msg : "(unknown error)");
}

static SV *
nlss_channel_slurp(pTHX_ ssh_channel ch, int is_stderr)
{
    SV *buf = newSVpvs("");
    char tmp[4096];
    int n;
    while (1) {
        n = ssh_channel_read(ch, tmp, sizeof(tmp), is_stderr);
        if (n <= 0)
            break;
        sv_catpvn(buf, tmp, n);
    }
    return buf;
}

MODULE = Net::LibSSH    PACKAGE = Net::LibSSH

PROTOTYPES: DISABLE

SV *
new(class)
    SV *class
  PREINIT:
    NLSS_Session *s;
    SV *sv;
  CODE:
    Newxz(s, 1, NLSS_Session);
    s->session = ssh_new();
    if (!s->session) {
        Safefree(s);
        Perl_croak(aTHX_ "Net::LibSSH::new: ssh_new() returned NULL");
    }
    sv = newSV(0);
    sv_setiv(sv, (IV) s);
    RETVAL = sv_bless(newRV_noinc(sv), gv_stashpvs("Net::LibSSH", GV_ADD));
  OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
  PREINIT:
    NLSS_Session *s;
  CODE:
    s = SELF_SESSION(self);
    if (s->session) {
        ssh_disconnect(s->session);
        ssh_free(s->session);
        s->session = NULL;
    }
    Safefree(s);

void
option(self, key, value)
    SV         *self
    const char *key
    SV         *value
  PREINIT:
    NLSS_Session *s;
    int rc = SSH_OK;
  CODE:
    s = SELF_SESSION(self);
    if (strcmp(key, "host") == 0) {
        rc = ssh_options_set(s->session, SSH_OPTIONS_HOST, SvPV_nolen(value));
    } else if (strcmp(key, "user") == 0) {
        rc = ssh_options_set(s->session, SSH_OPTIONS_USER, SvPV_nolen(value));
    } else if (strcmp(key, "port") == 0) {
        unsigned int port = (unsigned int) SvUV(value);
        rc = ssh_options_set(s->session, SSH_OPTIONS_PORT, &port);
    } else if (strcmp(key, "knownhosts") == 0) {
        rc = ssh_options_set(s->session, SSH_OPTIONS_KNOWNHOSTS, SvPV_nolen(value));
    } else if (strcmp(key, "timeout") == 0) {
        long t = (long) SvIV(value);
        rc = ssh_options_set(s->session, SSH_OPTIONS_TIMEOUT, &t);
    } else if (strcmp(key, "compression") == 0) {
        rc = ssh_options_set(s->session, SSH_OPTIONS_COMPRESSION, SvPV_nolen(value));
    } else if (strcmp(key, "log_verbosity") == 0) {
        int v = SvIV(value);
        rc = ssh_options_set(s->session, SSH_OPTIONS_LOG_VERBOSITY, &v);
    } else if (strcmp(key, "strict_hostkeycheck") == 0) {
        int v = SvTRUE(value) ? 1 : 0;
        rc = ssh_options_set(s->session, SSH_OPTIONS_STRICTHOSTKEYCHECK, &v);
    } else {
        Perl_croak(aTHX_ "Net::LibSSH::option: unknown option '%s'", key);
    }
    if (rc != SSH_OK)
        nlss_croak_error(aTHX_ s->session, "Net::LibSSH::option");

int
connect(self)
    SV *self
  CODE:
    RETVAL = (ssh_connect(SELF_SESSION(self)->session) == SSH_OK) ? 1 : 0;
  OUTPUT:
    RETVAL

void
disconnect(self)
    SV *self
  CODE:
    ssh_disconnect(SELF_SESSION(self)->session);

SV *
error(self)
    SV *self
  PREINIT:
    const char *msg;
  CODE:
    msg = ssh_get_error(SELF_SESSION(self)->session);
    RETVAL = (msg && *msg) ? newSVpv(msg, 0) : &PL_sv_undef;
  OUTPUT:
    RETVAL

int
auth_password(self, password)
    SV         *self
    const char *password
  CODE:
    RETVAL = (ssh_userauth_password(SELF_SESSION(self)->session, NULL, password)
              == SSH_AUTH_SUCCESS) ? 1 : 0;
  OUTPUT:
    RETVAL

int
auth_agent(self)
    SV *self
  PREINIT:
    int rc;
    ssh_session sess;
  CODE:
    sess = SELF_SESSION(self)->session;
    rc = ssh_userauth_agent(sess, NULL);
    if (rc != SSH_AUTH_SUCCESS)
        rc = ssh_userauth_publickey_auto(sess, NULL, NULL);
    RETVAL = (rc == SSH_AUTH_SUCCESS) ? 1 : 0;
  OUTPUT:
    RETVAL

int
auth_publickey(self, privkey_path)
    SV         *self
    const char *privkey_path
  PREINIT:
    ssh_key key = NULL;
    int rc;
  CODE:
    rc = ssh_pki_import_privkey_file(privkey_path, NULL, NULL, NULL, &key);
    if (rc != SSH_OK) {
        RETVAL = 0;
    } else {
        rc = ssh_userauth_publickey(SELF_SESSION(self)->session, NULL, key);
        ssh_key_free(key);
        RETVAL = (rc == SSH_AUTH_SUCCESS) ? 1 : 0;
    }
  OUTPUT:
    RETVAL

SV *
channel(self)
    SV *self
  PREINIT:
    NLSS_Channel *c;
    ssh_channel   ch;
    SV           *sv;
  CODE:
    ch = ssh_channel_new(SELF_SESSION(self)->session);
    if (!ch)
        XSRETURN_UNDEF;
    if (ssh_channel_open_session(ch) != SSH_OK) {
        ssh_channel_free(ch);
        XSRETURN_UNDEF;
    }
    Newxz(c, 1, NLSS_Channel);
    c->channel    = ch;
    c->session_sv = SvREFCNT_inc(self);
    sv = newSV(0);
    sv_setiv(sv, (IV) c);
    RETVAL = sv_bless(newRV_noinc(sv), gv_stashpvs("Net::LibSSH::Channel", GV_ADD));
  OUTPUT:
    RETVAL

SV *
sftp(self)
    SV *self
  PREINIT:
    NLSS_SFTP    *s;
    sftp_session  sftp;
    SV           *sv;
  CODE:
    sftp = sftp_new(SELF_SESSION(self)->session);
    if (!sftp)
        XSRETURN_UNDEF;
    if (sftp_init(sftp) != SSH_OK) {
        sftp_free(sftp);
        XSRETURN_UNDEF;
    }
    Newxz(s, 1, NLSS_SFTP);
    s->sftp       = sftp;
    s->session_sv = SvREFCNT_inc(self);
    sv = newSV(0);
    sv_setiv(sv, (IV) s);
    RETVAL = sv_bless(newRV_noinc(sv), gv_stashpvs("Net::LibSSH::SFTP", GV_ADD));
  OUTPUT:
    RETVAL


MODULE = Net::LibSSH    PACKAGE = Net::LibSSH::Channel

PROTOTYPES: DISABLE

void
DESTROY(self)
    SV *self
  PREINIT:
    NLSS_Channel *c;
  CODE:
    c = SELF_CHANNEL(self);
    if (c->channel) {
        ssh_channel_send_eof(c->channel);
        ssh_channel_close(c->channel);
        ssh_channel_free(c->channel);
        c->channel = NULL;
    }
    SvREFCNT_dec(c->session_sv);
    Safefree(c);

int
exec(self, cmd)
    SV         *self
    const char *cmd
  CODE:
    RETVAL = (ssh_channel_request_exec(SELF_CHANNEL(self)->channel, cmd) == SSH_OK) ? 1 : 0;
  OUTPUT:
    RETVAL

SV *
read(self, ...)
    SV *self
  PREINIT:
    int is_stderr = 0;
    int len       = -1;
  CODE:
    if (items >= 2) len       = SvIV(ST(1));
    if (items >= 3) is_stderr = SvTRUE(ST(2));
    if (len < 0) {
        RETVAL = nlss_channel_slurp(aTHX_ SELF_CHANNEL(self)->channel, is_stderr);
    } else {
        char *buf;
        int   n;
        Newx(buf, len + 1, char);
        n = ssh_channel_read(SELF_CHANNEL(self)->channel, buf, len, is_stderr);
        if (n <= 0) {
            Safefree(buf);
            RETVAL = newSVpvs("");
        } else {
            RETVAL = newSVpvn(buf, n);
            Safefree(buf);
        }
    }
  OUTPUT:
    RETVAL

int
write(self, data)
    SV *self
    SV *data
  PREINIT:
    STRLEN      len;
    const char *ptr;
  CODE:
    ptr = SvPV(data, len);
    RETVAL = ssh_channel_write(SELF_CHANNEL(self)->channel, ptr, (uint32_t) len);
  OUTPUT:
    RETVAL

void
send_eof(self)
    SV *self
  CODE:
    ssh_channel_send_eof(SELF_CHANNEL(self)->channel);

int
eof(self)
    SV *self
  CODE:
    RETVAL = ssh_channel_is_eof(SELF_CHANNEL(self)->channel);
  OUTPUT:
    RETVAL

int
exit_status(self)
    SV *self
  CODE:
    RETVAL = ssh_channel_get_exit_status(SELF_CHANNEL(self)->channel);
  OUTPUT:
    RETVAL

void
close(self)
    SV *self
  PREINIT:
    NLSS_Channel *c;
  CODE:
    c = SELF_CHANNEL(self);
    if (c->channel) {
        ssh_channel_send_eof(c->channel);
        ssh_channel_close(c->channel);
        ssh_channel_free(c->channel);
        c->channel = NULL;
    }


MODULE = Net::LibSSH    PACKAGE = Net::LibSSH::SFTP

PROTOTYPES: DISABLE

void
DESTROY(self)
    SV *self
  PREINIT:
    NLSS_SFTP *s;
  CODE:
    s = SELF_SFTP(self);
    if (s->sftp) {
        sftp_free(s->sftp);
        s->sftp = NULL;
    }
    SvREFCNT_dec(s->session_sv);
    Safefree(s);

SV *
stat(self, path)
    SV         *self
    const char *path
  PREINIT:
    sftp_attributes attr;
    HV             *h;
  CODE:
    attr = sftp_stat(SELF_SFTP(self)->sftp, path);
    if (!attr)
        XSRETURN_UNDEF;
    h = newHV();
    hv_stores(h, "name",  newSVpv(attr->name ? attr->name : path, 0));
    hv_stores(h, "size",  newSVuv(attr->size));
    hv_stores(h, "uid",   newSVuv(attr->uid));
    hv_stores(h, "gid",   newSVuv(attr->gid));
    hv_stores(h, "mode",  newSVuv(attr->permissions));
    hv_stores(h, "atime", newSVuv(attr->atime64 ? attr->atime64 : attr->atime));
    hv_stores(h, "mtime", newSVuv(attr->mtime64 ? attr->mtime64 : attr->mtime));
    sftp_attributes_free(attr);
    RETVAL = newRV_noinc((SV *) h);
  OUTPUT:
    RETVAL
