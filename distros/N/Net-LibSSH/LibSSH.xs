#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define NEED_mg_findext
#include "ppport.h"

#include <libssh/libssh.h>
#include <libssh/sftp.h>

#define undef &PL_sv_undef

/* ====================================================
   Internal structs (named so Newxz has a type to size)
   ==================================================== */

typedef struct { ssh_session  session;                 } NLSS_Session;
typedef struct { ssh_channel  channel; SV *session_sv; } NLSS_Channel;
typedef struct { sftp_session sftp;    SV *session_sv; } NLSS_SFTP;

/* Pointer typedefs with the xsubpp __ → :: naming convention.
   Using pointer typedefs (not struct typedefs) means XS signatures
   need no *, and ${type} in typemap templates resolves cleanly to
   e.g. Net__LibSSH — making &${type}_magic valid C. */
typedef NLSS_Session *Net__LibSSH;
typedef NLSS_Channel *Net__LibSSH__Channel;
typedef NLSS_SFTP    *Net__LibSSH__SFTP;

/* ====================================================
   Magic vtables — svt_free replaces DESTROY in XS.
   Perl's GC calls svt_free automatically when the SV
   is collected; no explicit DESTROY method needed.
   ==================================================== */

static int
nlss_session_free(pTHX_ SV *sv, MAGIC *mg)
{
    NLSS_Session *self = (NLSS_Session *)(void *)mg->mg_ptr;
    if (self->session) {
        ssh_disconnect(self->session);
        ssh_free(self->session);
    }
    Safefree(self);
    return 0;
}
static const MGVTBL Net__LibSSH_magic = { .svt_free = nlss_session_free };

static int
nlss_channel_free(pTHX_ SV *sv, MAGIC *mg)
{
    NLSS_Channel *self = (NLSS_Channel *)(void *)mg->mg_ptr;
    if (self->channel) {
        ssh_channel_send_eof(self->channel);
        ssh_channel_close(self->channel);
        ssh_channel_free(self->channel);
    }
    SvREFCNT_dec(self->session_sv);
    Safefree(self);
    return 0;
}
static const MGVTBL Net__LibSSH__Channel_magic = { .svt_free = nlss_channel_free };

static int
nlss_sftp_free(pTHX_ SV *sv, MAGIC *mg)
{
    NLSS_SFTP *self = (NLSS_SFTP *)(void *)mg->mg_ptr;
    if (self->sftp)
        sftp_free(self->sftp);
    SvREFCNT_dec(self->session_sv);
    Safefree(self);
    return 0;
}
static const MGVTBL Net__LibSSH__SFTP_magic = { .svt_free = nlss_sftp_free };

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

Net::LibSSH
new(class)
    SV *class
  CODE:
    Newxz(RETVAL, 1, NLSS_Session);
    RETVAL->session = ssh_new();
    if (!RETVAL->session) {
        Safefree(RETVAL);
        Perl_croak(aTHX_ "Net::LibSSH::new: ssh_new() returned NULL");
    }
  OUTPUT:
    RETVAL

void
option(self, key, value)
    Net::LibSSH  self
    const char  *key
    SV          *value
  CODE:
    int rc = SSH_OK;
    if (strcmp(key, "host") == 0) {
        rc = ssh_options_set(self->session, SSH_OPTIONS_HOST, SvPV_nolen(value));
    } else if (strcmp(key, "user") == 0) {
        rc = ssh_options_set(self->session, SSH_OPTIONS_USER, SvPV_nolen(value));
    } else if (strcmp(key, "port") == 0) {
        unsigned int port = (unsigned int) SvUV(value);
        rc = ssh_options_set(self->session, SSH_OPTIONS_PORT, &port);
    } else if (strcmp(key, "knownhosts") == 0) {
        rc = ssh_options_set(self->session, SSH_OPTIONS_KNOWNHOSTS, SvPV_nolen(value));
    } else if (strcmp(key, "timeout") == 0) {
        long t = (long) SvIV(value);
        rc = ssh_options_set(self->session, SSH_OPTIONS_TIMEOUT, &t);
    } else if (strcmp(key, "compression") == 0) {
        rc = ssh_options_set(self->session, SSH_OPTIONS_COMPRESSION, SvPV_nolen(value));
    } else if (strcmp(key, "log_verbosity") == 0) {
        int v = SvIV(value);
        rc = ssh_options_set(self->session, SSH_OPTIONS_LOG_VERBOSITY, &v);
    } else if (strcmp(key, "strict_hostkeycheck") == 0) {
        int v = SvTRUE(value) ? 1 : 0;
        rc = ssh_options_set(self->session, SSH_OPTIONS_STRICTHOSTKEYCHECK, &v);
    } else {
        Perl_croak(aTHX_ "Net::LibSSH::option: unknown option '%s'", key);
    }
    if (rc != SSH_OK)
        nlss_croak_error(aTHX_ self->session, "Net::LibSSH::option");

int
connect(self)
    Net::LibSSH self
  CODE:
    RETVAL = (ssh_connect(self->session) == SSH_OK) ? 1 : 0;
  OUTPUT:
    RETVAL

void
disconnect(self)
    Net::LibSSH self
  CODE:
    ssh_disconnect(self->session);

SV *
error(self)
    Net::LibSSH self
  CODE:
    const char *msg = ssh_get_error(self->session);
    RETVAL = (msg && *msg) ? newSVpv(msg, 0) : undef;
  OUTPUT:
    RETVAL

int
auth_password(self, password)
    Net::LibSSH  self
    const char  *password
  CODE:
    RETVAL = (ssh_userauth_password(self->session, NULL, password)
              == SSH_AUTH_SUCCESS) ? 1 : 0;
  OUTPUT:
    RETVAL

int
auth_agent(self)
    Net::LibSSH self
  CODE:
    int rc = ssh_userauth_agent(self->session, NULL);
    if (rc != SSH_AUTH_SUCCESS)
        rc = ssh_userauth_publickey_auto(self->session, NULL, NULL);
    RETVAL = (rc == SSH_AUTH_SUCCESS) ? 1 : 0;
  OUTPUT:
    RETVAL

int
auth_publickey(self, privkey_path)
    Net::LibSSH  self
    const char  *privkey_path
  CODE:
    ssh_key key = NULL;
    int rc = ssh_pki_import_privkey_file(privkey_path, NULL, NULL, NULL, &key);
    if (rc != SSH_OK) {
        RETVAL = 0;
    } else {
        rc = ssh_userauth_publickey(self->session, NULL, key);
        ssh_key_free(key);
        RETVAL = (rc == SSH_AUTH_SUCCESS) ? 1 : 0;
    }
  OUTPUT:
    RETVAL

Net::LibSSH::Channel
channel(self)
    Net::LibSSH self
  CODE:
    ssh_channel ch = ssh_channel_new(self->session);
    if (!ch)
        XSRETURN_UNDEF;
    if (ssh_channel_open_session(ch) != SSH_OK) {
        ssh_channel_free(ch);
        XSRETURN_UNDEF;
    }
    Newxz(RETVAL, 1, NLSS_Channel);
    RETVAL->channel    = ch;
    RETVAL->session_sv = SvREFCNT_inc(ST(0));
  OUTPUT:
    RETVAL

Net::LibSSH::SFTP
sftp(self)
    Net::LibSSH self
  CODE:
    sftp_session sftp = sftp_new(self->session);
    if (!sftp)
        XSRETURN_UNDEF;
    if (sftp_init(sftp) != SSH_OK) {
        sftp_free(sftp);
        XSRETURN_UNDEF;
    }
    Newxz(RETVAL, 1, NLSS_SFTP);
    RETVAL->sftp       = sftp;
    RETVAL->session_sv = SvREFCNT_inc(ST(0));
  OUTPUT:
    RETVAL


MODULE = Net::LibSSH    PACKAGE = Net::LibSSH::Channel

int
exec(self, cmd)
    Net::LibSSH::Channel  self
    const char           *cmd
  CODE:
    RETVAL = (ssh_channel_request_exec(self->channel, cmd) == SSH_OK) ? 1 : 0;
  OUTPUT:
    RETVAL

SV *
read(self, ...)
    Net::LibSSH::Channel self
  CODE:
    int is_stderr = 0;
    int len       = -1;
    if (items >= 2) len       = SvIV(ST(1));
    if (items >= 3) is_stderr = SvTRUE(ST(2));
    if (len < 0) {
        RETVAL = nlss_channel_slurp(aTHX_ self->channel, is_stderr);
    } else {
        char *buf;
        int   n;
        Newx(buf, len + 1, char);
        n = ssh_channel_read(self->channel, buf, len, is_stderr);
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
    Net::LibSSH::Channel  self
    SV                   *data
  CODE:
    STRLEN      len;
    const char *ptr = SvPV(data, len);
    RETVAL = ssh_channel_write(self->channel, ptr, (uint32_t) len);
  OUTPUT:
    RETVAL

void
send_eof(self)
    Net::LibSSH::Channel self
  CODE:
    ssh_channel_send_eof(self->channel);

int
eof(self)
    Net::LibSSH::Channel self
  CODE:
    RETVAL = ssh_channel_is_eof(self->channel);
  OUTPUT:
    RETVAL

int
exit_status(self)
    Net::LibSSH::Channel self
  CODE:
    RETVAL = ssh_channel_get_exit_status(self->channel);
  OUTPUT:
    RETVAL

void
close(self)
    Net::LibSSH::Channel self
  CODE:
    /* Free the C channel now; svt_free will later release
       session_sv and Safefree the struct when the SV is GC'd. */
    if (self->channel) {
        ssh_channel_send_eof(self->channel);
        ssh_channel_close(self->channel);
        ssh_channel_free(self->channel);
        self->channel = NULL;
    }


MODULE = Net::LibSSH    PACKAGE = Net::LibSSH::SFTP

SV *
stat(self, path)
    Net::LibSSH::SFTP  self
    const char        *path
  CODE:
    sftp_attributes attr = sftp_stat(self->sftp, path);
    if (!attr)
        XSRETURN_UNDEF;
    HV *h = newHV();
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
