#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "includes.h"
#include "dbutil.h"
#include "session.h"
#include "buffer.h"
#include "signkey.h"
#include "runopts.h"
#include "dbrandom.h"
#include "crypto_desc.h"
#include "libdropbear.h"

typedef struct dropbear_chansess_accept * Net__Dropbear__XS__SessionAccept;
typedef struct AuthState * Net__Dropbear__XS__AuthState;

int _get_bool(SV *self, char *method)
{
        int count;
        int result;
        SV *option;

        dTHX;
        dSP;

        ENTER;
        SAVETMPS;

        PUSHMARK(SP);
        XPUSHs(self);
        PUTBACK;
        count = call_method(method, G_SCALAR);
        SPAGAIN;

        if (count != 1)
          croak("Too much result from %s\n", method);

        option = POPs;
        result = SvTRUE(option);

        PUTBACK;
        FREETMPS;
        LEAVE;

        return result;
}

SV* hooks_self;
int hooks_on(const char *hook, AV* args)
{
    int RETVAL;
    int len, i;

    dTHX;
    dSP;

    ENTER;
    SAVETMPS;

    if (hooks_self == NULL)
        hooks_self = &PL_sv_undef;

    PUSHMARK(SP);
    XPUSHs(hooks_self);
    XPUSHs(sv_2mortal(newSVpv(hook, 0)));

    len = av_len(args) + 1;

    for(i = 0; i < len; i++)
    {
        SV ** elem = av_fetch(args, i, 0);
        if ( elem != NULL )
          XPUSHs(*elem);
        else
          XPUSHs(&PL_sv_undef);
    }

    PUTBACK;
    int count = call_method("auto_hook", G_EVAL | G_SCALAR);
    SPAGAIN;

    if (SvTRUE(ERRSV))
    {
        dropbear_log(LOG_DEBUG, "Error calling %s: %s\n", hook, SvPV_nolen(ERRSV));
        RETVAL = LIBDROPBEAR_HOOK_FAILURE;
    }
    else
    {
        RETVAL = POPi;
    }

    PUTBACK;
    FREETMPS;
    LEAVE;

    return RETVAL;
}

int hooks_on_log(int priority, const char *message)
{
    dTHX;
    ENTER;
    SAVETMPS;

    AV* args = newAV();

    av_push(args, sv_2mortal(newSViv(priority)));
    av_push(args, sv_2mortal(newSVpv(message, 0)));
    int RETVAL = hooks_on("on_log", args);

    FREETMPS;
    LEAVE;

    return RETVAL;
}

int hooks_on_start()
{
    dTHX;
    ENTER;
    SAVETMPS;

    AV* args = newAV();

    int RETVAL = hooks_on("on_start", args);

    FREETMPS;
    LEAVE;

    return RETVAL;
}

int hooks_on_username(const char* username)
{
    dTHX;
    ENTER;
    SAVETMPS;

    AV* args = newAV();

    av_push(args, sv_2mortal(newSVpv(username, 0)));
    int RETVAL = hooks_on("on_username", args);

    FREETMPS;
    LEAVE;

    return RETVAL;
}

int hooks_on_passwd_fill(struct AuthState *auth, const char *username)
{
    dTHX;
    ENTER;
    SAVETMPS;

    AV* args = newAV();

    SV *auth_obj = newSV(0);
    auth_obj = sv_setref_pv(auth_obj, "Net::Dropbear::XS::AuthState", auth);
    av_push(args, sv_2mortal(auth_obj));
    av_push(args, sv_2mortal(newSVpv(username, 0)));
    int RETVAL = hooks_on("on_passwd_fill", args);

    FREETMPS;
    LEAVE;

    return RETVAL;
}

int hooks_on_shadow_fill(char** crypt_password, const char *pw_name)
{
    dTHX;
    ENTER;
    SAVETMPS;

    AV* args = newAV();

    av_push(args, sv_2mortal(newSVpv("", 0)));
    av_push(args, sv_2mortal(newSVpv(pw_name, 0)));
    int RETVAL = hooks_on("on_shadow_fill", args);

    SV** arg = av_fetch(args, 0, 0);
    if ( arg != NULL )
    {
      *crypt_password = m_strdup(SvPV_nolen(*arg));
    }

    FREETMPS;
    LEAVE;

    return RETVAL;
}

int hooks_on_crypt_passwd(char** input_passwd, const char *salt, const char *pw_name)
{
    dTHX;
    ENTER;
    SAVETMPS;

    AV* args = newAV();

    av_push(args, sv_2mortal(newSVpv(m_strdup(*input_passwd), 0)));
    av_push(args, sv_2mortal(newSVpv(salt, 0)));
    av_push(args, sv_2mortal(newSVpv(pw_name, 0)));
    int RETVAL = hooks_on("on_crypt_passwd", args);

    SV** arg = av_fetch(args, 0, 0);
    if ( arg != NULL )
    {
      *input_passwd = m_strdup(SvPV_nolen(*arg));
    }

    FREETMPS;
    LEAVE;

    return RETVAL;
}

int hooks_on_check_pubkey(char** authkeys, const char *pw_name)
{
    dTHX;
    ENTER;
    SAVETMPS;

    AV* args = newAV();

    av_push(args, sv_2mortal(newSVpv("", 0)));
    av_push(args, sv_2mortal(newSVpv(pw_name, 0)));
    int RETVAL = hooks_on("on_check_pubkey", args);

    SV** arg = av_fetch(args, 0, 0);
    if ( arg != NULL )
    {
      *authkeys = m_strdup(SvPV_nolen(*arg));
    }

    FREETMPS;
    LEAVE;

    return RETVAL;
}

int hooks_on_new_channel(const char* type)
{
    dTHX;
    ENTER;
    SAVETMPS;

    AV* args = newAV();

    av_push(args, sv_2mortal(newSVpv(type, 0)));
    int RETVAL = hooks_on("on_new_channel", args);

    FREETMPS;
    LEAVE;

    return RETVAL;
}

int hooks_on_chansess_command(struct dropbear_chansess_accept *chansess)
{
    dTHX;
    ENTER;
    SAVETMPS;

    AV* args = newAV();

    SV *session_accept = newSV(0);
    session_accept = sv_setref_pv(session_accept, "Net::Dropbear::XS::SessionAccept", chansess);
    av_push(args, sv_2mortal(session_accept));
    int RETVAL = hooks_on("on_chansess_command", args);

    FREETMPS;
    LEAVE;

    return RETVAL;
}

MODULE = Net::Dropbear  PACKAGE = Net::Dropbear::XS

BOOT:
{
    HV *stash = gv_stashpv("Net::Dropbear::XS", 0);

    newCONSTSUB(stash, "HOOK_COMPLETE", newSViv (LIBDROPBEAR_HOOK_COMPLETE));
    newCONSTSUB(stash, "HOOK_CONTINUE", newSViv (LIBDROPBEAR_HOOK_CONTINUE));
    newCONSTSUB(stash, "HOOK_FAILURE",  newSViv (LIBDROPBEAR_HOOK_FAILURE));
}

void
gen_key(const char* filename, enum signkey_type keytype=DROPBEAR_SIGNKEY_RSA, int bits=2048)
    CODE:
        dropbear_gen_key(keytype, bits, filename);

void
svr_main(CLASS)
        SV *CLASS = NO_INIT
    PROTOTYPE: $
    CODE:
        dropbear_run();
        /* Never Returns */

void
setup_svr_opts(CLASS, options)
        SV *CLASS = NO_INIT
        SV * options
    PROTOTYPE: $$
    CODE:
        dropbear_init();
#ifdef DEBUG_TRACE
        debug_trace             = _get_bool(options, "debug");
#endif
        svr_opts.forkbg         = _get_bool(options, "forkbg");
        opts.usingsyslog        = _get_bool(options, "usingsyslog");
        svr_opts.inetdmode      = _get_bool(options, "inetdmode");
        svr_opts.norootlogin    = _get_bool(options, "norootlogin");
        svr_opts.noauthpass     = _get_bool(options, "noauthpass");
        svr_opts.norootpass     = _get_bool(options, "norootpass");
        svr_opts.allowblankpass = _get_bool(options, "allowblankpass");
        svr_opts.delay_hostkey  = _get_bool(options, "delay_hostkey");
#ifdef DO_MOTD
        svr_opts.domotd = _get_bool(options, "domotd");
#endif
#ifdef ENABLE_SVR_REMOTETCPFWD
        svr_opts.noremotetcp = _get_bool(options, "noremotetcp");
#endif
#ifdef ENABLE_SVR_LOCALTCPFWD
        svr_opts.nolocaltcp = _get_bool(options, "nolocaltcp");
#endif

        hooks_self = options;
        hooks.on_log = hooks_on_log;
        hooks.on_start = hooks_on_start;
        hooks.on_username = hooks_on_username;
        hooks.on_passwd_fill = hooks_on_passwd_fill;
        hooks.on_shadow_fill = hooks_on_shadow_fill;
        hooks.on_crypt_passwd = hooks_on_crypt_passwd;
        hooks.on_check_pubkey = hooks_on_check_pubkey;
        hooks.on_new_channel = hooks_on_new_channel;
        hooks.on_chansess_command = hooks_on_chansess_command;

        int count, i;
        SSize_t len;
        SV * ref_result;

        ENTER;
        SAVETMPS;

        PUSHMARK(SP);
        XPUSHs(options);
        PUTBACK;
        count = call_method("addrs", G_SCALAR);
        SPAGAIN;

        if (count != 1)
          croak("Too much result from %s\n", "addr");

        ref_result = POPs;

        if (!SvROK(ref_result) || SvTYPE(SvRV(ref_result)) != SVt_PVAV)
          croak("$self->addrs did not return an array");

        PUTBACK;

        AV* addrs = (AV*)SvRV(ref_result);
        len = av_len(addrs);

        for (i = 0; i <= len; i++)
        {
          SV** addr = av_fetch(addrs, i, 0);
          if ( addr != NULL )
          {
            dropbear_add_svr_addr(SvPV_nolen(*addr));
          }
        }

        PUSHMARK(SP);
        XPUSHs(options);
        PUTBACK;
        count = call_method("keys", G_SCALAR);
        SPAGAIN;

        if (count != 1)
          croak("Too much result from %s\n", "keys");

        ref_result = POPs;

        if (!SvROK(ref_result) || SvTYPE(SvRV(ref_result)) != SVt_PVAV)
          croak("$self->addr did not return an array");

        PUTBACK;

        AV* svr_keys = (AV*)SvRV(ref_result);
        len = av_len(svr_keys);

        for (i = 0; i <= len; i++)
        {
          SV** key = av_fetch(svr_keys, i, 0);
          if ( key != NULL )
          {
            dropbear_add_svr_key(SvPV_nolen(*key));
          }
        }

        FREETMPS;
        LEAVE;

MODULE = Net::Dropbear  PACKAGE = Net::Dropbear::XS::AuthState

BOOT:
{
    HV *stash = gv_stashpv("Net::Dropbear::XS::AuthState", 0);

    newCONSTSUB(stash, "AUTH_TYPE_NONE",      newSViv (AUTH_TYPE_NONE));
    newCONSTSUB(stash, "AUTH_TYPE_PUBKEY",    newSViv (AUTH_TYPE_PUBKEY));
    newCONSTSUB(stash, "AUTH_TYPE_PASSWORD",  newSViv (AUTH_TYPE_PASSWORD));
    newCONSTSUB(stash, "AUTH_TYPE_INTERACT",  newSViv (AUTH_TYPE_INTERACT));
}

uid_t
pw_uid(THIS, __value = NO_INIT)
        Net::Dropbear::XS::AuthState THIS
        uid_t __value
    PROTOTYPE: $;$
    CODE:
        if (items > 1)
            THIS->pw_uid = __value;
        RETVAL = THIS->pw_uid;
    OUTPUT:
        RETVAL
 
gid_t
pw_gid(THIS, __value = NO_INIT)
        Net::Dropbear::XS::AuthState THIS
        gid_t __value
    PROTOTYPE: $;$
    CODE:
        if (items > 1)
            THIS->pw_gid = __value;
        RETVAL = THIS->pw_gid;
    OUTPUT:
        RETVAL
 
char *
pw_dir(THIS, __value = NO_INIT)
        Net::Dropbear::XS::AuthState THIS
        char * __value
    PROTOTYPE: $;$
    CODE:
        if (items > 1)
            THIS->pw_dir = m_strdup(__value);
        RETVAL = THIS->pw_dir;
    OUTPUT:
        RETVAL
 
char *
pw_shell(THIS, __value = NO_INIT)
        Net::Dropbear::XS::AuthState THIS
        char * __value
    PROTOTYPE: $;$
    CODE:
        if (items > 1)
            THIS->pw_shell = m_strdup(__value);
        RETVAL = THIS->pw_shell;
    OUTPUT:
        RETVAL
 
char *
pw_name(THIS, __value = NO_INIT)
        Net::Dropbear::XS::AuthState THIS
        char * __value
    PROTOTYPE: $;$
    CODE:
        if (items > 1)
            THIS->pw_name = m_strdup(__value);
        RETVAL = THIS->pw_name;
    OUTPUT:
        RETVAL
 
char *
pw_passwd(THIS, __value = NO_INIT)
        Net::Dropbear::XS::AuthState THIS
        char * __value
    PROTOTYPE: $;$
    CODE:
        if (items > 1)
            THIS->pw_passwd = m_strdup(__value);
        RETVAL = THIS->pw_passwd;
    OUTPUT:
        RETVAL
 
MODULE = Net::Dropbear  PACKAGE = Net::Dropbear::XS::SessionAccept

int
channel_index(THIS, __value = NO_INIT)
        Net::Dropbear::XS::SessionAccept THIS
        int __value
    PROTOTYPE: $;$
    CODE:
        RETVAL = THIS->channel_index;
    OUTPUT:
        RETVAL
 
char *
cmd(THIS, __value = NO_INIT)
        Net::Dropbear::XS::SessionAccept THIS
        char * __value
    PROTOTYPE: $;$
    CODE:
        if (items > 1)
            THIS->cmd = m_strdup(__value);
        RETVAL = (char *)THIS->cmd;
    OUTPUT:
        RETVAL
 
pid_t
pid(THIS, __value = NO_INIT)
        Net::Dropbear::XS::SessionAccept THIS
        pid_t __value
    PROTOTYPE: $;$
    CODE:
        if (items > 1)
            THIS->pid = __value;
        RETVAL = THIS->pid;
    OUTPUT:
        RETVAL
 
int
iscmd(THIS, __value = NO_INIT)
        Net::Dropbear::XS::SessionAccept THIS
        int __value
    PROTOTYPE: $;$
    CODE:
        if (items > 1)
            THIS->iscmd = __value;
        RETVAL = THIS->iscmd;
    OUTPUT:
        RETVAL
 
int
issubsys(THIS, __value = NO_INIT)
        Net::Dropbear::XS::SessionAccept THIS
        int __value
    PROTOTYPE: $;$
    CODE:
        if (items > 1)
            THIS->issubsys = __value;
        RETVAL = THIS->issubsys;
    OUTPUT:
        RETVAL
 
int
writefd(THIS, __value = NO_INIT)
        Net::Dropbear::XS::SessionAccept THIS
        int __value
    PROTOTYPE: $;$
    CODE:
        if (items > 1)
            THIS->writefd = __value;
        RETVAL = THIS->writefd;
    OUTPUT:
        RETVAL
 
int
readfd(THIS, __value = NO_INIT)
        Net::Dropbear::XS::SessionAccept THIS
        int __value
    PROTOTYPE: $;$
    CODE:
        if (items > 1)
            THIS->readfd = __value;
        RETVAL = THIS->readfd;
    OUTPUT:
        RETVAL
 
int
errfd(THIS, __value = NO_INIT)
        Net::Dropbear::XS::SessionAccept THIS
        int __value
    PROTOTYPE: $;$
    CODE:
        if (items > 1)
            THIS->errfd = __value;
        RETVAL = THIS->errfd;
    OUTPUT:
        RETVAL
