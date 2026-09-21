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

/* Where the ssh_session is in its one-way life. libssh 0.10.6 cannot
   reconnect a session it has disconnected -- ssh_connect() sits out the whole
   timeout -- but measured on the same libssh, disconnect() on a session that
   was never connected leaves it fully connectable. Only the CONNECTED ->
   SPENT transition is therefore terminal, which is why this is three states
   and not a flag. Newxz gives FRESH for free.
   libssh has nothing to answer this with: ssh_get_status() reports SSH_CLOSED
   for both a spent session and a never-connected one that saw a disconnect(),
   and ssh_is_connected() is already 0 by the time connect() would ask. */
typedef enum {
    NLSS_SESSION_FRESH = 0,
    NLSS_SESSION_CONNECTED,
    NLSS_SESSION_SPENT
} NLSS_SessionState;

/* generation / session_generation: ssh_disconnect() frees every ssh_channel
   the session owns from inside libssh, so a channel or sftp session that
   outlives a disconnect() holds a non-NULL pointer into freed memory. The
   session counts its disconnects; each child copies the count it was born
   under and compares. See nlss_session_stale(). */
typedef struct {
    ssh_session        session;
    unsigned int       generation;
    NLSS_SessionState  state;
    /* The one message this binding raises itself; everything else in error()
       comes from libssh. Set when connect() refuses a spent session, where
       ssh_connect() is never called and ssh_get_error() would still hold what
       stood there before the disconnect (measured: nothing). A string
       literal, so there is nothing to free, and nothing clears it either --
       a spent session stays spent, and that is the reason every later call
       on it fails too. */
    const char        *own_error;
    /* Mirror of SSH_OPTIONS_STRICTHOSTKEYCHECK, kept here because libssh
       has no getter for it and connect() has to know. Inverted so that the
       zero Newxz leaves behind means strict -- the secure default, and
       libssh's own. Only option('strict_hostkeycheck') writes it. */
    int                hostkey_check_disabled;
} NLSS_Session;

typedef struct {
    ssh_channel  channel;
    SV          *session_sv;
    unsigned int session_generation;
} NLSS_Channel;

typedef struct {
    sftp_session sftp;
    SV          *session_sv;
    unsigned int session_generation;
} NLSS_SFTP;

/* Pointer typedefs with the xsubpp __ → :: naming convention.
   Using pointer typedefs (not struct typedefs) means XS signatures
   need no *. The typemap does not derive its vtable names from these:
   xsubpp maps :: → __ inside ${type} only from 3.60 on, so a generic
   T_MAGICEXT entry writing &${type}_magic expands to &Net::LibSSH_magic
   — not valid C — on the older xsubpp this distribution still supports.
   Every typemap entry therefore spells its vtable out literally. */
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
    /* No generation bump here: every channel and sftp session holds a
       reference on this very SV, so this runs only once the last of them is
       gone. There is nothing left to invalidate. */
    if (self->session) {
        ssh_disconnect(self->session);
        ssh_free(self->session);
    }
    Safefree(self);
    return 0;
}
static const MGVTBL Net__LibSSH_magic = { .svt_free = nlss_session_free };

/* Has libssh already freed the C object this child holds?
   The child reaches its session through session_sv -- the blessed,
   magic-bearing SV it took a reference on in channel()/sftp(). Since 0.003
   that is the referent, SvRV(ST(0)), not the reference scalar, so the magic
   sits on session_sv itself and mg_findext takes it directly; a further
   SvRV() here would walk off the object.
   Missing magic can only mean the session SV is not the one we stored, so it
   counts as stale: refusing is the safe answer for both the method guard and
   the free path. */
static int
nlss_session_stale(pTHX_ SV *session_sv, unsigned int generation)
{
    if (!session_sv || !SvMAGICAL(session_sv))
        return 1;
    MAGIC *mg = mg_findext(session_sv, PERL_MAGIC_ext, &Net__LibSSH_magic);
    if (!mg)
        return 1;
    return ((NLSS_Session *)(void *)mg->mg_ptr)->generation != generation;
}

static int
nlss_channel_free(pTHX_ SV *sv, MAGIC *mg)
{
    NLSS_Channel *self = (NLSS_Channel *)(void *)mg->mg_ptr;
    /* A stale channel was freed inside ssh_disconnect() already; sending eof
       on it is the crash the caller never asked for. Skip the C teardown
       only -- the session reference and the struct still have to go, or the
       crash is merely traded for a leak. The session struct is still there to
       ask: this child's reference on session_sv is released below, after the
       question, so nlss_session_free cannot have run yet. */
    if (self->channel
        && !nlss_session_stale(aTHX_ self->session_sv, self->session_generation)) {
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
    if (self->sftp) {
        /* Unlike a channel, an sftp_session is not freed by ssh_disconnect()
           -- only the channel inside it is. Skipping sftp_free() outright
           would trade the crash for a leak (measured: ~1.6 kB per
           disconnected-and-dropped sftp session), so cut the dangling channel
           loose first and let sftp_free() release everything else. libssh
           declares struct sftp_session_struct in its public sftp.h, and its
           ssh_channel_send_eof/close/free are all NULL-tolerant. */
        if (nlss_session_stale(aTHX_ self->session_sv, self->session_generation))
            self->sftp->channel = NULL;
        sftp_free(self->sftp);
    }
    SvREFCNT_dec(self->session_sv);
    Safefree(self);
    return 0;
}
static const MGVTBL Net__LibSSH__SFTP_magic = { .svt_free = nlss_sftp_free };

/* ====================================================
   Helper functions
   ==================================================== */

/* The one disconnect path, shared by disconnect() and the host-key refusal
   in connect(): both have to spend a connected session and bump the
   generation before libssh frees the channels, and having the invariant in
   one place is what keeps the two from drifting apart. */
static void
nlss_session_disconnect(NLSS_Session *self)
{
    /* Only a session that actually got connected is spent by this: measured
       on libssh 0.10.6, disconnect() on a never-connected session leaves it
       connectable, and marking it would refuse a call that works. */
    if (self->state == NLSS_SESSION_CONNECTED)
        self->state = NLSS_SESSION_SPENT;
    /* Bump before disconnecting: ssh_disconnect() frees every channel the
       session owns, so every channel and sftp session opened on it has to be
       stale by the time that memory goes away. */
    self->generation++;
    ssh_disconnect(self->session);
}

static void
nlss_croak_error(pTHX_ ssh_session session, const char *prefix)
{
    const char *msg = ssh_get_error(session);
    Perl_croak(aTHX_ "%s: %s", prefix, msg ? msg : "(unknown error)");
}

static void
nlss_channel_check_open(pTHX_ NLSS_Channel *self, const char *prefix)
{
    /* Two distinct states, two distinct messages: the caller closed this
       channel itself, or the session was disconnected out from under it.
       Collapsing them would leave a caller unable to tell its own teardown
       from libssh's. */
    if (!self->channel)
        Perl_croak(aTHX_ "%s: channel is closed", prefix);
    if (nlss_session_stale(aTHX_ self->session_sv, self->session_generation))
        Perl_croak(aTHX_ "%s: session was disconnected", prefix);
}

static void
nlss_sftp_check_open(pTHX_ NLSS_SFTP *self, const char *prefix)
{
    /* There is no SFTP close(), so self->sftp is set for the object's whole
       lifetime; disconnect() is the only thing that stops it being usable. */
    if (nlss_session_stale(aTHX_ self->session_sv, self->session_generation))
        Perl_croak(aTHX_ "%s: session was disconnected", prefix);
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
        if (rc == SSH_OK)
            self->hostkey_check_disabled = !v;
    } else {
        Perl_croak(aTHX_ "Net::LibSSH::option: unknown option '%s'", key);
    }
    if (rc != SSH_OK)
        nlss_croak_error(aTHX_ self->session, "Net::LibSSH::option");

int
connect(self)
    Net::LibSSH self
  CODE:
    if (self->state == NLSS_SESSION_SPENT) {
        /* Refuse without calling libssh: ssh_connect() on a disconnected
           session waits out the full timeout and then reports "Timeout
           connecting to <host>", which names the wrong problem. Still 0 and
           still no croak -- connect()'s contract is 1 or 0 with the message
           on error(), and Rex::LibSSH relies on it. */
        self->own_error = "session was disconnected and cannot be reconnected";
        RETVAL = 0;
    } else if (ssh_connect(self->session) == SSH_OK) {
        /* CONNECTED first: ssh_connect() has completed the key exchange, so
           a refusal below is a disconnect of a connected session and spends
           it exactly as disconnect() would. */
        self->state = NLSS_SESSION_CONNECTED;
        RETVAL = 1;
        /* ssh_connect() negotiates the host key but never checks it against
           known_hosts -- that is a separate call libssh leaves to the
           application, and without it SSH_OPTIONS_STRICTHOSTKEYCHECK is
           decoration. strict_hostkeycheck => 0 is documented as disabling
           verification outright, so it skips the question entirely: no
           refusal on CHANGED either, and nothing is written to known_hosts. */
        if (!self->hostkey_check_disabled) {
            const char *refusal = NULL;
            switch (ssh_session_is_known_server(self->session)) {
            case SSH_KNOWN_HOSTS_OK:
                break;
            case SSH_KNOWN_HOSTS_CHANGED:
                refusal = "host key has changed from the known_hosts entry"
                          " -- possible man-in-the-middle attack";
                break;
            case SSH_KNOWN_HOSTS_OTHER:
                refusal = "host key type differs from the known_hosts entry"
                          " -- possible man-in-the-middle attack";
                break;
            case SSH_KNOWN_HOSTS_ERROR:
                refusal = "could not verify host key against known_hosts";
                break;
            case SSH_KNOWN_HOSTS_NOT_FOUND:
            case SSH_KNOWN_HOSTS_UNKNOWN:
            default:
                refusal = "host key is not in known_hosts"
                          " and strict_hostkeycheck is on";
                break;
            }
            if (refusal) {
                /* Same 1/0 contract as every other connect() failure. The
                   session is spent from here on, so own_error being sticky
                   is right: the later "cannot be reconnected" overwrites it. */
                nlss_session_disconnect(self);
                self->own_error = refusal;
                RETVAL = 0;
            }
        }
    } else {
        RETVAL = 0;
    }
  OUTPUT:
    RETVAL

void
disconnect(self)
    Net::LibSSH self
  CODE:
    nlss_session_disconnect(self);

SV *
error(self)
    Net::LibSSH self
  CODE:
    const char *msg = self->own_error ? self->own_error
                                      : ssh_get_error(self->session);
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
    RETVAL->channel            = ch;
    RETVAL->session_sv         = SvREFCNT_inc(SvRV(ST(0)));
    RETVAL->session_generation = self->generation;
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
    RETVAL->sftp               = sftp;
    RETVAL->session_sv         = SvREFCNT_inc(SvRV(ST(0)));
    RETVAL->session_generation = self->generation;
  OUTPUT:
    RETVAL


MODULE = Net::LibSSH    PACKAGE = Net::LibSSH::Channel

int
exec(self, cmd)
    Net::LibSSH::Channel  self
    const char           *cmd
  CODE:
    nlss_channel_check_open(aTHX_ self, "Net::LibSSH::Channel::exec");
    RETVAL = (ssh_channel_request_exec(self->channel, cmd) == SSH_OK) ? 1 : 0;
  OUTPUT:
    RETVAL

SV *
read(self, ...)
    Net::LibSSH::Channel self
  CODE:
    nlss_channel_check_open(aTHX_ self, "Net::LibSSH::Channel::read");
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
    nlss_channel_check_open(aTHX_ self, "Net::LibSSH::Channel::write");
    STRLEN      len;
    const char *ptr = SvPV(data, len);
    RETVAL = ssh_channel_write(self->channel, ptr, (uint32_t) len);
  OUTPUT:
    RETVAL

void
send_eof(self)
    Net::LibSSH::Channel self
  CODE:
    nlss_channel_check_open(aTHX_ self, "Net::LibSSH::Channel::send_eof");
    ssh_channel_send_eof(self->channel);

int
eof(self)
    Net::LibSSH::Channel self
  CODE:
    nlss_channel_check_open(aTHX_ self, "Net::LibSSH::Channel::eof");
    RETVAL = ssh_channel_is_eof(self->channel);
  OUTPUT:
    RETVAL

int
exit_status(self)
    Net::LibSSH::Channel self
  CODE:
    nlss_channel_check_open(aTHX_ self, "Net::LibSSH::Channel::exit_status");
    RETVAL = ssh_channel_get_exit_status(self->channel);
  OUTPUT:
    RETVAL

void
close(self)
    Net::LibSSH::Channel self
  CODE:
    /* Free the C channel now; svt_free will later release
       session_sv and Safefree the struct when the SV is GC'd.
       Deliberately unguarded, so it stays idempotent for svt_free -- but a
       channel invalidated by disconnect() is only dropped, never freed twice.
       No croak either: `$ssh->disconnect; $ch->close` is teardown, and
       teardown that has already happened is not an error. */
    if (self->channel) {
        if (!nlss_session_stale(aTHX_ self->session_sv, self->session_generation)) {
            ssh_channel_send_eof(self->channel);
            ssh_channel_close(self->channel);
            ssh_channel_free(self->channel);
        }
        self->channel = NULL;
    }


MODULE = Net::LibSSH    PACKAGE = Net::LibSSH::SFTP

SV *
stat(self, path)
    Net::LibSSH::SFTP  self
    const char        *path
  CODE:
    nlss_sftp_check_open(aTHX_ self, "Net::LibSSH::SFTP::stat");
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
