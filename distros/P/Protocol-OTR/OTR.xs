
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "patchlevel.h"
#include "ppport.h"

#define HASHGET(rv, k, l) (SV*)*hv_fetch((HV*)SvRV(rv), k, l, 0) 
#define ACCOUNT2OTR(rv) HASHGET(rv, "otr", 3)
#define CONTACT2ACCOUNT(rv) HASHGET(rv, "act", 3)
#define CHANNEL2ACCOUNT(rv) CONTACT2ACCOUNT(HASHGET(rv, "cnt", 3))
#define CHANNEL2CONTACT(rv) HASHGET(rv, "cnt", 3)
#define ACCOUNT2CTX(rv) INT2PTR(Protocol__OTR,SvIV((SV*)SvRV(ACCOUNT2OTR(rv))))
#define CHANNEL2CTX(rv) ACCOUNT2CTX(CHANNEL2ACCOUNT(rv))


/* There is a struct name conflict with perl.h */
#define context otr_context
#include <libotr/context.h>
#undef context


/* libotr */
#include <libotr/proto.h>
#include <libotr/privkey.h>
#include <libotr/message.h>


static const struct mmsByProto {
    char *protocol;
    int mms;
} mmsTable[8] = {
    {"prpl-msn", 1409},
    {"prpl-icq", 2346},
	{"prpl-aim", 2343},
    {"prpl-yahoo", 799},
    {"prpl-gg", 1999},
	{"prpl-irc", 417},
    {"prpl-oscar", 2343},
    {NULL, 0}
};

static const char *TrustStates[] = {
    "Not private",
    "Unverified",
    "Private",
    "Finished"
};

typedef enum {
    TRUST_NOT_PRIVATE,
    TRUST_UNVERIFIED,
    TRUST_PRIVATE,
    TRUST_FINISHED
} TrustLevel;

typedef struct {
    OtrlUserState userstate;
    char * privkeys_file;
    char * contacts_file;
    char * instance_tags_file;
} OTRctx;

typedef OTRctx * Protocol__OTR;

static void write_fingerprints(OTRctx *ctx);

/* privkey.c -  Convert a hex character to a value */
static unsigned int ctoh(unsigned char c)
{
    if (c >= '0' && c <= '9') return c-'0';
    if (c >= 'a' && c <= 'f') return c-'a'+10;
    if (c >= 'A' && c <= 'F') return c-'A'+10;
    return 0;  /* Unknown hex char */
}


static OtrlPolicy policy_cb(void *opdata, ConnContext *context)
{
    OtrlPolicy policy = OTRL_POLICY_DEFAULT;

    if (!context) return policy;

    SV *channel = (SV *)opdata;

    policy = SvUV(HASHGET(channel, "policy", 6));

    return policy;
}

static int is_logged_in_cb(void *opdata, const char *accountname,
    const char *protocol, const char *recipient)
{
    int count;
    int is_logged_in = 0;
    dSP;
    SV *channel = (SV *)opdata;

    if ( ! hv_exists((HV*)SvRV(channel), "on_is_contact_logged_in", 23) ) return -1;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs( channel );
    XPUSHs( sv_2mortal( newSVpvn( "on_is_contact_logged_in", 23 )));
    PUTBACK;

    count = call_method( "_ev", G_SCALAR );

    if ( count != 1 ) {
        croak("on_is_contact_logged_in() callback did not return scalar value");
    }

    SPAGAIN;

    is_logged_in = POPi;

    if ( is_logged_in < -1 || is_logged_in > 1 ) {
        croak("on_is_contact_logged_in() callback must return: -1, 0 or 1");
    }

    PUTBACK;
    FREETMPS;
    LEAVE;

    return is_logged_in;
}

static void inject_message_cb(void *opdata, const char *accountname,
	const char *protocol, const char *recipient, const char *message)
{
    dSP;

    SV *channel = (SV *)opdata;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs( channel );
    XPUSHs( sv_2mortal( newSVpvn( "on_write", 8 )));
    XPUSHs( sv_2mortal( newSVpv( message, 0 )));
    PUTBACK;

    call_method( "_ev", G_DISCARD | G_VOID );

    FREETMPS;
    LEAVE;
}

static void send_default_query_msg(SV *channel)
{
    char * init_msg;
    HV * contact = (HV*)CHANNEL2CONTACT(channel);
    HV * account = (HV*)CONTACT2ACCOUNT(contact);
    unsigned int channel_policy = SvUV(HASHGET(channel, "policy", 6));
    char * contact_name = SvPV_nolen(HASHGET(contact, "name", 4)); 
    char * account_name = SvPV_nolen(HASHGET(account, "name", 4)); 
    char * account_protocol = SvPV_nolen(HASHGET(account, "protocol", 8)); 

    init_msg = otrl_proto_default_query_msg( account_name, channel_policy);

    inject_message_cb(
        (void*) channel,
        account_name,
        account_protocol,
        contact_name,
        init_msg
    );

    free(init_msg);
}

static void write_fingerprints(OTRctx *ctx)
{
    FILE * fs;
    gcry_error_t err;

    /* contacts_file */
    fs = fopen(ctx->contacts_file,"wb");
    if ( ! fs ) return;
    err = otrl_privkey_write_fingerprints_FILEp(ctx->userstate, fs);
    if (fs) fclose(fs);

    if ( err ) {
        croak("Cannot update contacts files: %s\n", gcry_strerror(err));
    }
}

static void write_fingerprints_cb(void *opdata)
{
    SV *channel = (SV *)opdata;
    OTRctx * ctx = CHANNEL2CTX(channel);

    write_fingerprints(ctx);
}

static void update_context_list_cb(void *opdata)
{
    SV *channel = (SV *)opdata;
    OTRctx * ctx = CHANNEL2CTX(channel);

    write_fingerprints(ctx);
}

static void gone_secure_mark_only_cb(void *opdata, ConnContext *context)
{
    SV *channel = (SV *)opdata;

    (void)hv_store((HV*)SvRV(channel), "gone_secure", 11, &PL_sv_yes, 0);
}

static void update_channel_sessions(SV *channel, ConnContext *context)
{
    if ( context->their_instance ) {
        char itoa[20] = {0};

        HV *sessions = (HV*)SvRV(HASHGET(channel, "known_sessions", 14));
        snprintf(itoa, 20, "%u", context->their_instance);
        (void)hv_store(sessions, itoa, strlen(itoa), newSViv(1), 0);
    }
}

static void gone_secure_cb(void *opdata, ConnContext *context)
{
    dSP;
    SV *channel = (SV *)opdata;

    update_channel_sessions(channel, context);

    if ( ! hv_exists((HV*)SvRV(channel), "on_gone_secure", 14) ) return;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);

    XPUSHs( channel );
    XPUSHs( sv_2mortal( newSVpvn( "on_gone_secure", 14 )));

    PUTBACK;

    call_method( "_ev", G_DISCARD | G_VOID );

    FREETMPS;
    LEAVE;
}

static void gone_insecure_cb(void *opdata, ConnContext *context)
{
    dSP;
    SV *channel = (SV *)opdata;

    update_channel_sessions(channel, context);

    if ( ! hv_exists((HV*)SvRV(channel), "on_gone_insecure", 16) ) return;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);

    XPUSHs( channel );
    XPUSHs( sv_2mortal( newSVpvn( "on_gone_insecure", 16 )));

    PUTBACK;

    call_method( "_ev", G_DISCARD | G_VOID );

    FREETMPS;
    LEAVE;
}

static void still_secure_cb(void *opdata, ConnContext *context, int is_reply)
{
    dSP;
    SV *channel = (SV *)opdata;

    if ( is_reply != 0 ) return;

    update_channel_sessions(channel, context);

    if ( ! hv_exists((HV*)SvRV(channel), "on_still_secure", 15) ) return;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);

    XPUSHs( channel );
    XPUSHs( sv_2mortal( newSVpvn( "on_still_secure", 15 )));

    PUTBACK;

    call_method( "_ev", G_DISCARD | G_VOID );

    FREETMPS;
    LEAVE;
}

static void new_fingerprint_cb(void *opdata, OtrlUserState us,
	const char *accountname, const char *protocol, const char *username,
	unsigned char fingerprint[20])
{
    ConnContext *context;
    int seenbefore = 0;
    char *hex_fingerprint;
    dSP;
    SV *channel = (SV *)opdata;

    /* just skip */
    if ( ! hv_exists((HV*)SvRV(channel), "on_unverified_fingerprint", 25) ) return;

    /* Figure out if this is the first fingerprint we've seen for this
     * user. */
    context = otrl_context_find(us, username, accountname, protocol,
        OTRL_INSTAG_MASTER, 0, NULL, NULL, NULL);

    if (context) {
        Fingerprint *fp;
        for ( fp = context->fingerprint_root.next; fp; fp = fp->next ) {
            if (memcmp(fingerprint, fp->fingerprint, 20)) {
                /* This is a previously seen fingerprint for this user,
                 * different from the one we were passed. */
                seenbefore = 1;
                break;
            }
        }
    }

    Newx(hex_fingerprint, OTRL_PRIVKEY_FPRINT_HUMAN_LEN, char);

    otrl_privkey_hash_to_human(hex_fingerprint, fingerprint);

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs( channel );
    XPUSHs( sv_2mortal( newSVpvn( "on_unverified_fingerprint", 25 )));
    XPUSHs( sv_2mortal( newSVpvn( hex_fingerprint, OTRL_PRIVKEY_FPRINT_HUMAN_LEN - 1)));

    Safefree(hex_fingerprint);

    if (seenbefore) {
        XPUSHs( sv_2mortal( &PL_sv_yes ) );
    } else {
        XPUSHs( sv_2mortal( &PL_sv_no ) );
    }

    PUTBACK;

    call_method( "_ev", G_DISCARD | G_VOID );

    FREETMPS;
    LEAVE;
}

static int max_message_size_cb(void *opdata, ConnContext *context)
{
    SV *channel = (SV *)opdata;
    int max_message_size = SvIV(HASHGET(channel, "max_message_size", 16));

    if ( max_message_size > 0 ) {
        return max_message_size;
    } else {
        int i;
        HV * account = (HV*)CHANNEL2ACCOUNT(channel);
        char *account_protocol;
        account_protocol = SvPV_nolen(HASHGET(account, "protocol", 8));

        for ( i = 0;  mmsTable[i].protocol != NULL; i++ ) {
            if ( strEQ(mmsTable[i].protocol, account_protocol) ) {
                return mmsTable[i].mms;
            }
        }
    }

    /* unlimited */
    return 0;
}

static void received_symkey_cb(void *opdata, ConnContext *context,
	unsigned int use, const unsigned  char *usedata,
	size_t usedatalen, const unsigned char *symkey)
{
    dSP;
    SV *channel = (SV *)opdata;

    if ( ! hv_exists((HV*)SvRV(channel), "on_symkey", 9) ) return;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs( channel );
    XPUSHs( sv_2mortal( newSVpvn( "on_symkey", 9 )));
    XPUSHs( sv_2mortal( newSVpvn( (char*)symkey, OTRL_EXTRAKEY_BYTES )));
    XPUSHs( sv_2mortal( newSVuv( use )));
    if ( usedata ) {
        XPUSHs( sv_2mortal( newSVpvn( (char *)usedata, usedatalen )));
    }
    PUTBACK;

    call_method( "_ev", G_DISCARD | G_VOID );

    FREETMPS;
    LEAVE;
}

static const char* error_message_cb(void *opdata, ConnContext *context,
	OtrlErrorCode err_code)
{
    char * err_msg;
    int count;
    dSP;
    SV *channel = (SV *)opdata;

    if ( ! hv_exists((HV*)SvRV(channel), "on_error", 8) ) return NULL;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs( channel );
    XPUSHs( sv_2mortal( newSVpvn( "on_error", 8 )));
    XPUSHs( sv_2mortal( newSViv( err_code )));
    PUTBACK;

    count = call_method( "_ev", G_SCALAR );

    if ( count != 1 ) {
        croak("on_error() callback did not return message string");
    }

    SPAGAIN;

    err_msg = savepv( POPp );

    PUTBACK;
    FREETMPS;
    LEAVE;

    return err_msg;
}

static void error_message_free_cb(void *opdata, const char *err_msg)
{
    if (err_msg) Safefree((char *)err_msg);
}

static void smp_event_cb(SV *channel, OtrlSMPEvent smp_event, unsigned short progress_percent)
{
    dSP;

    if ( ! hv_exists((HV*)SvRV(channel), "on_smp_event", 12) ) return;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);

    XPUSHs( channel );
    XPUSHs( sv_2mortal( newSVpvn( "on_smp_event", 12 )));
    XPUSHs( sv_2mortal( newSViv( smp_event )));
    XPUSHs( sv_2mortal( newSViv( progress_percent )));
    PUTBACK;

    call_method( "_ev", G_DISCARD | G_VOID );

    FREETMPS;
    LEAVE;
}

static void handle_smp_event_cb(void *, OtrlSMPEvent , ConnContext *, unsigned short , char *);

static void handle_msg_event_cb(void *opdata, OtrlMessageEvent msg_event, ConnContext *context,
	const char* message, gcry_error_t err)
{
    dSP;
    SV *channel = (SV *)opdata;

    if ( ! hv_exists((HV*)SvRV(channel), "on_event", 8) ) return;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);

    XPUSHs( channel );
    XPUSHs( sv_2mortal( newSVpvn( "on_event", 8 )));

    XPUSHs( sv_2mortal( newSViv( msg_event )));
    switch ( msg_event ) {
        case OTRL_MSGEVENT_SETUP_ERROR:
            XPUSHs( sv_2mortal( newSVpv( gcry_strerror(err), 0 )));
            break;
        case OTRL_MSGEVENT_RCVDMSG_GENERAL_ERR:
        case OTRL_MSGEVENT_RCVDMSG_UNENCRYPTED:
            XPUSHs( sv_2mortal( newSVpv( message, 0 )));
            break;
        default:
            break;
    }
    PUTBACK;

    call_method( "_ev", G_DISCARD | G_VOID );

    FREETMPS;
    LEAVE;
}

static void create_instag_cb(void *opdata, const char *accountname,
	const char *protocol)
{
    FILE * fs;

    SV *channel = (SV *)opdata;
    OTRctx * ctx = CHANNEL2CTX(channel);

    /* contacts_file */
    fs = fopen(ctx->instance_tags_file,"w+b");
    if ( ! fs ) return;
    otrl_instag_generate_FILEp(ctx->userstate, fs, accountname, protocol);
    fclose(fs);
}

static void timer_control_cb(void *, unsigned int);

static void convert_data_cb(void *opdata, ConnContext *context,
    OtrlConvertType convert_type, char ** dest, const char *src)
{
    char *cb_name;
    int count;
    dSP;
    SV *channel = (SV *)opdata;

    if ( convert_type == OTRL_CONVERT_SENDING ) {
        if ( hv_exists((HV*)SvRV(channel), "on_before_encrypt", 17) ) {
            cb_name = "on_before_encrypt";
        } else {
            *dest = NULL;
            return;
        }
    } else { /* OTRL_CONVERT_RECEIVING */
        if ( hv_exists((HV*)SvRV(channel), "on_after_decrypt", 16) ) {
            cb_name = "on_after_decrypt";
        } else {
            *dest = NULL;
            return;
        }
    }

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);

    XPUSHs( channel );
    XPUSHs( sv_2mortal( newSVpvn( cb_name, strlen(cb_name) )));
    XPUSHs( sv_2mortal( newSVpv( src, 0 )));
    PUTBACK;

    count = call_method( "_ev", G_SCALAR );

    if ( count != 1 ) {
        croak("%s() callback did not return message string", cb_name);
    }

    SPAGAIN;

    *dest = savepv( POPp );

    PUTBACK;
    FREETMPS;
    LEAVE;
}


static void convert_data_free_cb(void *opdata, ConnContext *context, char *dest)
{
    if (dest) Safefree(dest);
}

static OtrlMessageAppOps callbacks = {
    policy_cb,
    NULL,  /* missing privkey is generated when creating account obj */
    is_logged_in_cb,
    inject_message_cb,
    update_context_list_cb,
    new_fingerprint_cb,
    write_fingerprints_cb,
    gone_secure_mark_only_cb /* gone_secure_cb */,
    gone_insecure_cb,
    still_secure_cb,
    max_message_size_cb,
    NULL,                   /* account_name */
    NULL,                   /* account_name_free */
    received_symkey_cb,
    error_message_cb,
    error_message_free_cb,
    NULL /* resent_msg_prefix_cb */,
    NULL /* resent_msg_prefix_free_cb */,
    handle_smp_event_cb,
    handle_msg_event_cb,
    create_instag_cb,
    convert_data_cb,
    convert_data_free_cb,
    timer_control_cb 
};

static void smp_event_popup(SV *channel, ConnContext *context, char *question)
{
    int count;
    OTRctx * ctx = CHANNEL2CTX(channel);
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);

    XPUSHs( channel );
    XPUSHs( sv_2mortal( newSVpvn( "on_smp", 6 )));
    if ( question != NULL ) {
        XPUSHs( sv_2mortal( newSVpv( question, 0 )));
    }
    PUTBACK;

    call_method( "_ev", G_DISCARD | G_VOID );

    FREETMPS;
    LEAVE;
}

static void handle_smp_event_cb(void *opdata, OtrlSMPEvent smp_event, ConnContext *context,
	unsigned short progress_percent, char *question)
{
    SV *channel = (SV *)opdata;
    OTRctx * ctx;

    if ( ! context ) return;

    if ( ! hv_exists((HV*)SvRV(channel), "on_smp", 6) ) return;

    ctx = CHANNEL2CTX(channel);

    switch (smp_event)
    {
        case OTRL_SMPEVENT_NONE :
            smp_event_cb(channel, smp_event, progress_percent);
            break;
        case OTRL_SMPEVENT_ASK_FOR_SECRET :
            smp_event_popup( channel, context, NULL);
            break;
        case OTRL_SMPEVENT_ASK_FOR_ANSWER :
            smp_event_popup( channel, context, question);
            break;
        case OTRL_SMPEVENT_CHEATED :
            otrl_message_abort_smp(
                ctx->userstate,
                &callbacks,
                channel,
                context
            );

            /* FALLTHROUGH */
        case OTRL_SMPEVENT_IN_PROGRESS :
        case OTRL_SMPEVENT_SUCCESS :
        case OTRL_SMPEVENT_FAILURE :
        case OTRL_SMPEVENT_ABORT :
            smp_event_cb(channel, smp_event, progress_percent);
            break;
        case OTRL_SMPEVENT_ERROR :
            otrl_message_abort_smp(
                ctx->userstate,
                &callbacks,
                channel,
                context
            );
            smp_event_cb(channel, smp_event, progress_percent);
            break;
    }
}


static void timer_control_cb(void *opdata, unsigned int interval)
{
    SV *channel = (SV *)opdata;

    /* user provided timer function */
    if ( hv_exists((HV*)SvRV(channel), "on_timer", 8) ) {
        dSP;

        ENTER;
        SAVETMPS;

        PUSHMARK(SP);

        XPUSHs( channel );
        XPUSHs( sv_2mortal( newSVpvn( "on_timer", 8 )));
        XPUSHs( sv_2mortal( newSVuv( interval )));

        PUTBACK;

        call_method( "_ev", G_DISCARD | G_VOID );

        FREETMPS;
        LEAVE;
    } else if ( interval > 0 ) {
        OTRctx * ctx = CHANNEL2CTX(channel);
        
        otrl_message_poll(ctx->userstate, &callbacks, channel);
    }
}

/* (From otr-plugin.c) What level of trust do we have in the privacy of this ConnContext? */
TrustLevel otrp_plugin_context_to_trust(ConnContext *context)
{
    TrustLevel level = TRUST_NOT_PRIVATE;

    if (context && context->msgstate == OTRL_MSGSTATE_ENCRYPTED) {
        if (context->active_fingerprint &&
            context->active_fingerprint->trust &&
            context->active_fingerprint->trust[0] != '\0') {
            level = TRUST_PRIVATE;
        } else {
            level = TRUST_UNVERIFIED;
        }
    } else if (context && context->msgstate == OTRL_MSGSTATE_FINISHED) {
        level = TRUST_FINISHED;
    }

    return level;
}

MODULE = Protocol::OTR        PACKAGE = Protocol::OTR

BOOT:
{
#if (PATCHLEVEL > 4) || ((PATCHLEVEL == 4) && (SUBVERSION >= 70))
    HV *pstash = gv_stashpv("Protocol::OTR", 0);

    newCONSTSUB(pstash, "POLICY_OPPORTUNISTIC", newSVuv(OTRL_POLICY_OPPORTUNISTIC) );
    newCONSTSUB(pstash, "POLICY_ALWAYS", newSVuv(OTRL_POLICY_ALWAYS) );
    newCONSTSUB(pstash, "ERRCODE_NONE", newSVuv(OTRL_ERRCODE_NONE) );
    newCONSTSUB(pstash, "ERRCODE_ENCRYPTION_ERROR", newSVuv(OTRL_ERRCODE_ENCRYPTION_ERROR) );
    newCONSTSUB(pstash, "ERRCODE_MSG_NOT_IN_PRIVATE", newSVuv(OTRL_ERRCODE_MSG_NOT_IN_PRIVATE) );
    newCONSTSUB(pstash, "ERRCODE_MSG_UNREADABLE", newSVuv(OTRL_ERRCODE_MSG_UNREADABLE) );
    newCONSTSUB(pstash, "ERRCODE_MSG_MALFORMED", newSVuv(OTRL_ERRCODE_MSG_MALFORMED) );
    newCONSTSUB(pstash, "MSGEVENT_NONE", newSVuv(OTRL_MSGEVENT_NONE) );
    newCONSTSUB(pstash, "MSGEVENT_ENCRYPTION_REQUIRED", newSVuv(OTRL_MSGEVENT_ENCRYPTION_REQUIRED) );
    newCONSTSUB(pstash, "MSGEVENT_ENCRYPTION_ERROR", newSVuv(OTRL_MSGEVENT_ENCRYPTION_ERROR) );
    newCONSTSUB(pstash, "MSGEVENT_CONNECTION_ENDED", newSVuv(OTRL_MSGEVENT_CONNECTION_ENDED) );
    newCONSTSUB(pstash, "MSGEVENT_SETUP_ERROR", newSVuv(OTRL_MSGEVENT_SETUP_ERROR) );
    newCONSTSUB(pstash, "MSGEVENT_MSG_REFLECTED", newSVuv(OTRL_MSGEVENT_MSG_REFLECTED) );
    newCONSTSUB(pstash, "MSGEVENT_MSG_RESENT", newSVuv(OTRL_MSGEVENT_MSG_RESENT) );
    newCONSTSUB(pstash, "MSGEVENT_RCVDMSG_NOT_IN_PRIVATE", newSVuv(OTRL_MSGEVENT_RCVDMSG_NOT_IN_PRIVATE) );
    newCONSTSUB(pstash, "MSGEVENT_RCVDMSG_UNREADABLE", newSVuv(OTRL_MSGEVENT_RCVDMSG_UNREADABLE) );
    newCONSTSUB(pstash, "MSGEVENT_RCVDMSG_MALFORMED", newSVuv(OTRL_MSGEVENT_RCVDMSG_MALFORMED) );
    newCONSTSUB(pstash, "MSGEVENT_LOG_HEARTBEAT_RCVD", newSVuv(OTRL_MSGEVENT_LOG_HEARTBEAT_RCVD) );
    newCONSTSUB(pstash, "MSGEVENT_LOG_HEARTBEAT_SENT", newSVuv(OTRL_MSGEVENT_LOG_HEARTBEAT_SENT) );
    newCONSTSUB(pstash, "MSGEVENT_RCVDMSG_GENERAL_ERR", newSVuv(OTRL_MSGEVENT_RCVDMSG_GENERAL_ERR) );
    newCONSTSUB(pstash, "MSGEVENT_RCVDMSG_UNENCRYPTED", newSVuv(OTRL_MSGEVENT_RCVDMSG_UNENCRYPTED) );
    newCONSTSUB(pstash, "MSGEVENT_RCVDMSG_UNRECOGNIZED", newSVuv(OTRL_MSGEVENT_RCVDMSG_UNRECOGNIZED) );
    newCONSTSUB(pstash, "MSGEVENT_RCVDMSG_FOR_OTHER_INSTANCE", newSVuv(OTRL_MSGEVENT_RCVDMSG_FOR_OTHER_INSTANCE) );
    newCONSTSUB(pstash, "SMPEVENT_NONE", newSVuv(OTRL_SMPEVENT_NONE) );
    newCONSTSUB(pstash, "SMPEVENT_CHEATED", newSVuv(OTRL_SMPEVENT_CHEATED) );
    newCONSTSUB(pstash, "SMPEVENT_IN_PROGRESS", newSVuv(OTRL_SMPEVENT_IN_PROGRESS) );
    newCONSTSUB(pstash, "SMPEVENT_SUCCESS", newSVuv(OTRL_SMPEVENT_SUCCESS) );
    newCONSTSUB(pstash, "SMPEVENT_FAILURE", newSVuv(OTRL_SMPEVENT_FAILURE) );
    newCONSTSUB(pstash, "SMPEVENT_ABORT", newSVuv(OTRL_SMPEVENT_ABORT) );
    newCONSTSUB(pstash, "SMPEVENT_ERROR", newSVuv(OTRL_SMPEVENT_ERROR) );
    newCONSTSUB(pstash, "INSTAG_BEST", newSVuv(OTRL_INSTAG_BEST) );
    newCONSTSUB(pstash, "INSTAG_RECENT", newSVuv(OTRL_INSTAG_RECENT) );
    newCONSTSUB(pstash, "INSTAG_RECENT_RECEIVED", newSVuv(OTRL_INSTAG_RECENT_RECEIVED) );
    newCONSTSUB(pstash, "INSTAG_RECENT_SENT", newSVuv(OTRL_INSTAG_RECENT_SENT) );
#endif

    /* Version check should be the very first call because it
    makes sure that important subsystems are intialized. */
    if (!gcry_check_version (GCRYPT_VERSION))
    {
        croak("libgcrypt version mismatch\n");
    }

    /* We don't want to see any warnings, e.g. because we have not yet
    parsed program options which might be used to suppress such
    warnings. */
    gcry_control (GCRYCTL_SUSPEND_SECMEM_WARN);

    /* Allocate a pool of 16k secure memory.  This make the secure memory
    available and also drops privileges where needed.  */
    gcry_control (GCRYCTL_INIT_SECMEM, 16384, 0);

    /* It is now okay to let Libgcrypt complain when there was/is
    a problem with the secure memory. */
    gcry_control (GCRYCTL_RESUME_SECMEM_WARN);


    if ( PerlEnv_getenv("PROTOCOL_OTR_ENABLE_QUICK_RANDOM") ) {
        gcry_control(GCRYCTL_ENABLE_QUICK_RANDOM, 0);
    }

    /* Tell Libgcrypt that initialization has completed. */
    gcry_control (GCRYCTL_INITIALIZATION_FINISHED, 0);

    OTRL_INIT;
}

#if (PATCHLEVEL < 4) || ((PATCHLEVEL == 4) && (SUBVERSION < 70))
PROTOTYPES: ENABLE

unsigned int
POLICY_OPPORTUNISTIC()
    CODE:
        RETVAL = OTRL_POLICY_OPPORTUNISTIC;
    OUTPUT:
        RETVAL

unsigned int
POLICY_ALWAYS()
    CODE:
        RETVAL = OTRL_POLICY_ALWAYS;
    OUTPUT:
        RETVAL

unsigned int
ERRCODE_NONE()
    CODE:
        RETVAL = OTRL_ERRCODE_NONE;
    OUTPUT:
        RETVAL

unsigned int
ERRCODE_ENCRYPTION_ERROR()
    CODE:
        RETVAL = OTRL_ERRCODE_ENCRYPTION_ERROR;
    OUTPUT:
        RETVAL

unsigned int
ERRCODE_MSG_NOT_IN_PRIVATE()
    CODE:
        RETVAL = OTRL_ERRCODE_MSG_NOT_IN_PRIVATE;
    OUTPUT:
        RETVAL

unsigned int
ERRCODE_MSG_UNREADABLE()
    CODE:
        RETVAL = OTRL_ERRCODE_MSG_UNREADABLE;
    OUTPUT:
        RETVAL

unsigned int
ERRCODE_MSG_MALFORMED()
    CODE:
        RETVAL = OTRL_ERRCODE_MSG_MALFORMED;
    OUTPUT:
        RETVAL

unsigned int
MSGEVENT_NONE()
    CODE:
        RETVAL = OTRL_MSGEVENT_NONE;
    OUTPUT:
        RETVAL

unsigned int
MSGEVENT_ENCRYPTION_REQUIRED()
    CODE:
        RETVAL = OTRL_MSGEVENT_ENCRYPTION_REQUIRED;
    OUTPUT:
        RETVAL

unsigned int
MSGEVENT_ENCRYPTION_ERROR()
    CODE:
        RETVAL = OTRL_MSGEVENT_ENCRYPTION_ERROR;
    OUTPUT:
        RETVAL

unsigned int
MSGEVENT_CONNECTION_ENDED()
    CODE:
        RETVAL = OTRL_MSGEVENT_CONNECTION_ENDED;
    OUTPUT:
        RETVAL

unsigned int
MSGEVENT_SETUP_ERROR()
    CODE:
        RETVAL = OTRL_MSGEVENT_SETUP_ERROR;
    OUTPUT:
        RETVAL

unsigned int
MSGEVENT_MSG_REFLECTED()
    CODE:
        RETVAL = OTRL_MSGEVENT_MSG_REFLECTED;
    OUTPUT:
        RETVAL

unsigned int
MSGEVENT_MSG_RESENT()
    CODE:
        RETVAL = OTRL_MSGEVENT_MSG_RESENT;
    OUTPUT:
        RETVAL

unsigned int
MSGEVENT_RCVDMSG_NOT_IN_PRIVATE()
    CODE:
        RETVAL = OTRL_MSGEVENT_RCVDMSG_NOT_IN_PRIVATE;
    OUTPUT:
        RETVAL

unsigned int
MSGEVENT_RCVDMSG_UNREADABLE()
    CODE:
        RETVAL = OTRL_MSGEVENT_RCVDMSG_UNREADABLE;
    OUTPUT:
        RETVAL

unsigned int
MSGEVENT_RCVDMSG_MALFORMED()
    CODE:
        RETVAL = OTRL_MSGEVENT_RCVDMSG_MALFORMED;
    OUTPUT:
        RETVAL

unsigned int
MSGEVENT_LOG_HEARTBEAT_RCVD()
    CODE:
        RETVAL = OTRL_MSGEVENT_LOG_HEARTBEAT_RCVD;
    OUTPUT:
        RETVAL

unsigned int
MSGEVENT_LOG_HEARTBEAT_SENT()
    CODE:
        RETVAL = OTRL_MSGEVENT_LOG_HEARTBEAT_SENT;
    OUTPUT:
        RETVAL

unsigned int
MSGEVENT_RCVDMSG_GENERAL_ERR()
    CODE:
        RETVAL = OTRL_MSGEVENT_RCVDMSG_GENERAL_ERR;
    OUTPUT:
        RETVAL

unsigned int
MSGEVENT_RCVDMSG_UNENCRYPTED()
    CODE:
        RETVAL = OTRL_MSGEVENT_RCVDMSG_UNENCRYPTED;
    OUTPUT:
        RETVAL

unsigned int
MSGEVENT_RCVDMSG_UNRECOGNIZED()
    CODE:
        RETVAL = OTRL_MSGEVENT_RCVDMSG_UNRECOGNIZED;
    OUTPUT:
        RETVAL

unsigned int
MSGEVENT_RCVDMSG_FOR_OTHER_INSTANCE()
    CODE:
        RETVAL = OTRL_MSGEVENT_RCVDMSG_FOR_OTHER_INSTANCE;
    OUTPUT:
        RETVAL

unsigned int
SMPEVENT_NONE()
    CODE:
        RETVAL = OTRL_SMPEVENT_NONE;
    OUTPUT:
        RETVAL

unsigned int
SMPEVENT_CHEATED()
    CODE:
        RETVAL = OTRL_SMPEVENT_CHEATED;
    OUTPUT:
        RETVAL

unsigned int
SMPEVENT_IN_PROGRESS()
    CODE:
        RETVAL = OTRL_SMPEVENT_IN_PROGRESS;
    OUTPUT:
        RETVAL

unsigned int
SMPEVENT_SUCCESS()
    CODE:
        RETVAL = OTRL_SMPEVENT_SUCCESS;
    OUTPUT:
        RETVAL

unsigned int
SMPEVENT_FAILURE()
    CODE:
        RETVAL = OTRL_SMPEVENT_FAILURE;
    OUTPUT:
        RETVAL

unsigned int
SMPEVENT_ABORT()
    CODE:
        RETVAL = OTRL_SMPEVENT_ABORT;
    OUTPUT:
        RETVAL

unsigned int
SMPEVENT_ERROR()
    CODE:
        RETVAL = OTRL_SMPEVENT_ERROR;
    OUTPUT:
        RETVAL

unsigned int
INSTAG_BEST()
    CODE:
        RETVAL = OTRL_INSTAG_BEST;
    OUTPUT:
        RETVAL

unsigned int
INSTAG_RECENT()
    CODE:
        RETVAL = OTRL_INSTAG_RECENT;
    OUTPUT:
        RETVAL

unsigned int
INSTAG_RECENT_RECEIVED()
    CODE:
        RETVAL = OTRL_INSTAG_RECENT_RECEIVED;
    OUTPUT:
        RETVAL

unsigned int
INSTAG_RECENT_SENT()
    CODE:
        RETVAL = OTRL_INSTAG_RECENT_SENT;
    OUTPUT:
        RETVAL

PROTOTYPES: DISABLE

#endif

Protocol::OTR
_new(privkeys_file, contacts_file, instance_tags_file)
    char * privkeys_file
    char * contacts_file
    char * instance_tags_file
    PROTOTYPE: $$$
    PREINIT:
        FILE *fs;
        gcry_error_t err;
        OTRctx * ctx;
        SV *obj;
    CODE:
    {
        Newx(ctx, 1, OTRctx);

        ctx->privkeys_file = savepv(privkeys_file);
        ctx->contacts_file = savepv(contacts_file);
        ctx->instance_tags_file = savepv(instance_tags_file);
        ctx->userstate = otrl_userstate_create();

        /* privkeys_file */
        fs = fopen(ctx->privkeys_file,"rb");
        err = otrl_privkey_read_FILEp(ctx->userstate, fs);
        if (fs) fclose(fs);
        if ( err ) {
            croak("Cannot read/write privkeys_file: %s", gcry_strerror(err));
        }

        /* contacts_file */
        fs = fopen(ctx->contacts_file,"rb");
        err = otrl_privkey_read_fingerprints_FILEp(ctx->userstate, fs, NULL, NULL);
        if (fs) fclose(fs);
        if ( err ) {
            croak("Cannot read/write contacts_file: %s", gcry_strerror(err));
        }

        /* instance_tags_file */
        fs = fopen(ctx->instance_tags_file,"rb");
        err = otrl_instag_read_FILEp(ctx->userstate, fs);
        if (fs) fclose(fs);
        if ( err ) {
            croak("Cannot read/write instance_tags_file: %s", gcry_strerror(err));
        }

        RETVAL = ctx;
    }
    OUTPUT:
        RETVAL

SV *
_accounts(ctx)
    Protocol::OTR ctx
    PROTOTYPE: $
    PREINIT:
        OtrlPrivKey *p;
        AV * list;
        char *fingerprint;
    CODE:
    {
        list = (AV *)sv_2mortal( (SV *)newAV() );
        for(p=ctx->userstate->privkey_root; p; p=p->next) {
            HV *ac = (HV*)sv_2mortal((SV*)newHV());
           
            (void)hv_store(ac, "name", 4, newSVpv( p->accountname, 0 ), 0);
            (void)hv_store(ac, "protocol", 8, newSVpv( p->protocol, 0 ), 0);

            Newx(fingerprint, OTRL_PRIVKEY_FPRINT_HUMAN_LEN, char);

            fingerprint = otrl_privkey_fingerprint(ctx->userstate, fingerprint, p->accountname, p->protocol);

            (void)hv_store(ac, "fingerprint", 11, newSVpv( fingerprint, 0 ), 0);

            Safefree(fingerprint);

            av_push(list, newRV((SV*)ac));
        }
        RETVAL = newRV_inc((SV*) list);
    }
    OUTPUT:
        RETVAL

SV *
_account(ctx, accountname, protocol)
    Protocol::OTR ctx
    char * accountname
    char * protocol
    ALIAS:
        _find_account = 1
    PROTOTYPE: $$$
    PREINIT:
        OtrlPrivKey *p;
        char *fingerprint;
    CODE:
    {
        p = otrl_privkey_find(ctx->userstate, accountname, protocol);

        if ( ! p ) {
            if ( ix == 1 ) XSRETURN_UNDEF;

            FILE * fs;
            gcry_error_t err;

            /* privkeys_file */
            fs = fopen(ctx->privkeys_file,"w+b");
            if ( ! fs ) croak("Could not open %s for updating: %s", ctx->privkeys_file, Strerror(errno));
            err = otrl_privkey_generate_FILEp(ctx->userstate, fs, accountname, protocol);
            if (fs) fclose(fs);

            if (err) {
                croak("Cannot generate: %s", gcry_strerror(err));
            }
        }

        Newx(fingerprint, OTRL_PRIVKEY_FPRINT_HUMAN_LEN, char);

        fingerprint = otrl_privkey_fingerprint(ctx->userstate, fingerprint, accountname, protocol);

        RETVAL = newSVpvn(fingerprint, OTRL_PRIVKEY_FPRINT_HUMAN_LEN - 1);

        Safefree(fingerprint);
    }
    OUTPUT:
        RETVAL

void
DESTROY(self)
    Protocol::OTR self
    CODE:
    {
        if ( self->userstate ) {
            otrl_userstate_free(self->userstate);
            self->userstate = NULL;
        }
        Safefree(self->privkeys_file);
        Safefree(self->contacts_file);
        Safefree(self->instance_tags_file);

        Safefree(self);
    }


MODULE = Protocol::OTR        PACKAGE = Protocol::OTR::Account

void
_contact(account, username, sv_fprint, verified)
    SV * account
    char * username
    SV * sv_fprint
    SV * verified
    PROTOTYPE: $$;$$
    PREINIT:
        OTRctx *ctx;
        unsigned char fingerprint[20] = {0};
        int with_fingerprint = 0;
        int is_verified = 0;

        ConnContext *context;
        Fingerprint *fprint;
        int context_created = 0;
        int fprint_added = 0;
        char * account_name;
        char * account_protocol;
    PPCODE:
    {
        ctx = ACCOUNT2CTX(account);

        if ( SvOK(sv_fprint) ) {
            STRLEN flen;
            unsigned char *fingerprint_hex = (unsigned char*)SvPV(sv_fprint, flen);

            if (
                ( /* human readable string */
                    flen == 44
                    && fingerprint_hex[8] == ' '
                    && fingerprint_hex[17] == ' '
                    && fingerprint_hex[26] == ' '
                    && fingerprint_hex[35] == ' '
                )
                ||
                ( /* hex encoded string */
                    flen == 40
                    &&
                    strchr((char*)fingerprint_hex, ' ') == NULL
                )
            ) {
                int j, i;
                for(j=0, i=0; j<=20; i+=2) {
                    fingerprint[j++] = (ctoh(fingerprint_hex[i]) << 4) + (ctoh(fingerprint_hex[i+1]));
                    if (flen == 44 && j % 4 == 0 ) { /* skip spaces */
                        i++;
                    }
                }

                with_fingerprint = 1;
            }
            else {
                croak("Fingerprint has invalid format: %s", fingerprint_hex);
            }

            if ( SvOK(verified) && SvTRUE(verified) ) {
                is_verified = 1;
            }
        }

        account_name = SvPV_nolen(HASHGET(account, "name", 4)); 
        account_protocol = SvPV_nolen(HASHGET(account, "protocol", 8)); 

        context = otrl_context_find(
            ctx->userstate, username, account_name, account_protocol,
            OTRL_INSTAG_BEST, 1, &context_created, NULL, NULL );

        if ( context ) {
            if ( context_created && ! with_fingerprint ) {
                //croak("New contact requires fingerprint");
            }

            if ( with_fingerprint ) {
                fprint = otrl_context_find_fingerprint(context, fingerprint, 1, &fprint_added);
                otrl_context_set_trust(fprint, is_verified ? "verified" : NULL);
            }

            if ( context_created || fprint_added ) {
                write_fingerprints(ctx);
            }

            XSRETURN_YES;
        }
        croak("Could not find or create contact");
    }

SV *
_contacts(account)
    SV * account
    PROTOTYPE: $
    PREINIT:
        AV * list;
        ConnContext *context;
        OTRctx *ctx;
        char * account_name;
        char * account_protocol;
    CODE:
    {
        ctx = ACCOUNT2CTX(account);

        list = (AV *)sv_2mortal( (SV *)newAV() );

        account_name = SvPV_nolen(HASHGET(account, "name", 4)); 
        account_protocol = SvPV_nolen(HASHGET(account, "protocol", 8)); 

        for(context = ctx->userstate->context_root; context; context = context->next) {

            /* Fingerprints are only stored in the master contexts */
            if (context->their_instance != OTRL_INSTAG_MASTER) continue;

            /* Found matching account */
            if ( ! strEQ(context->accountname, account_name) ) continue;
            if ( ! strEQ(context->protocol, account_protocol) ) continue;

            av_push(list, newSVpv( context->username, 0 ));
        }
        RETVAL = newRV_inc((SV*) list);
    }
    OUTPUT:
        RETVAL



MODULE = Protocol::OTR        PACKAGE = Protocol::OTR::Contact

SV *
_fingerprints(contact)
    SV * contact
    PROTOTYPE: \% 
    PREINIT:
        AV * list;
        ConnContext *context;
        Fingerprint *fingerprint;
        OTRctx *ctx;
        char *contact_name;
        char *account_name;
        char *account_protocol;
    CODE:
    {
        HV *account = (HV*)HASHGET(contact, "act", 3);
        ctx = ACCOUNT2CTX(account);

        list = (AV *)sv_2mortal( (SV *)newAV() );

        contact_name = SvPV_nolen(HASHGET(contact, "name", 4));
        account_name = SvPV_nolen(HASHGET(account, "name", 4));
        account_protocol = SvPV_nolen(HASHGET(account, "protocol", 8));

        for(context = ctx->userstate->context_root; context; context = context->next) {

            /* Fingerprints are only stored in the master contexts */
            if (context->their_instance != OTRL_INSTAG_MASTER) continue;

            /* Found matching account */
            if ( ! strEQ(context->accountname, account_name) ) continue;
            if ( ! strEQ(context->protocol, account_protocol) ) continue;
            if ( ! strEQ(context->username, contact_name) ) continue;

            /* Don't bother with the first (fingerprintless) entry. */
            for (fingerprint = context->fingerprint_root.next; fingerprint; fingerprint = fingerprint->next) {
                ConnContext *context_iter;
                TrustLevel best_level = TRUST_NOT_PRIVATE;
                int used = 0;
                HV *fprint = (HV*)sv_2mortal((SV*)newHV());

                for (context_iter = context->m_context;
                    context_iter && context_iter->m_context == context->m_context;
                    context_iter = context_iter->next) {

                    TrustLevel this_level = TRUST_NOT_PRIVATE;

                    if (context_iter->active_fingerprint == fingerprint) {
                        this_level = otrp_plugin_context_to_trust(context_iter);
                        used = 1;

                        if (this_level == TRUST_PRIVATE) {
                            best_level = TRUST_PRIVATE;
                        } else if (this_level == TRUST_UNVERIFIED
                            && best_level != TRUST_PRIVATE) {
                            best_level = TRUST_UNVERIFIED;
                        } else if (this_level == TRUST_FINISHED
                            && best_level == TRUST_NOT_PRIVATE) {
                            best_level = TRUST_FINISHED;
                        }
                    }
                }

                (void)hv_store(fprint, "fingerprint", 11, newSVpvn( (char*)fingerprint->fingerprint, 20), 0);

                (void)hv_store(fprint, "is_verified", 11, otrl_context_is_fingerprint_trusted(fingerprint) ? &PL_sv_yes : &PL_sv_no , 0);

                (void)hv_store(fprint, "status", 6, newSVpv( used ? TrustStates[best_level] : "Unused", 0 ), 0);

                av_push(list, newRV((SV*)fprint));
            }
        }
        RETVAL = newRV_inc((SV*) list);
    }
    OUTPUT:
        RETVAL

void
_active_fingerprint(contact)
    SV * contact
    PROTOTYPE: \%
    PREINIT:
        ConnContext *context;
        Fingerprint *fingerprint;
        OTRctx *ctx;
        char *contact_name;
        char *account_name;
        char *account_protocol;
    PPCODE:
    {
        HV *account = (HV*)HASHGET(contact, "act", 3);

        ctx = ACCOUNT2CTX(account);

        contact_name = SvPV_nolen(HASHGET(contact, "name", 4));
        account_name = SvPV_nolen(HASHGET(account, "name", 4));
        account_protocol = SvPV_nolen(HASHGET(account, "protocol", 8));

        context = otrl_context_find(
            ctx->userstate, contact_name, account_name, account_protocol,
            OTRL_INSTAG_MASTER, 0, NULL, NULL, NULL );

        if (context) {
            /* Don't bother with the first (fingerprintless) entry. */
            for (fingerprint = context->fingerprint_root.next; fingerprint; fingerprint = fingerprint->next) {
                ConnContext *context_iter;

                for (context_iter = context->m_context;
                    context_iter && context_iter->m_context == context->m_context;
                    context_iter = context_iter->next) {

                    if (context_iter->active_fingerprint == fingerprint) {
                        HV *fprint = (HV*)sv_2mortal((SV*)newHV());
                        TrustLevel this_level = otrp_plugin_context_to_trust(context_iter);

                        (void)hv_store(fprint, "fingerprint", 11, newSVpvn( (char *)fingerprint->fingerprint, 20), 0);

                        (void)hv_store(fprint, "is_verified", 11, otrl_context_is_fingerprint_trusted(fingerprint) ? &PL_sv_yes : &PL_sv_no , 0);

                        (void)hv_store(fprint, "status", 6, newSVpv( TrustStates[this_level], 0 ), 0);

                        XPUSHs(newRV_inc((SV*) fprint));

                        XSRETURN(1);
                    }
                }
            }
        }
        XSRETURN_UNDEF;
    }


MODULE = Protocol::OTR        PACKAGE = Protocol::OTR::Fingerprint

void
hash(fprint)
    SV *fprint
    PROTOTYPE: $
    PREINIT:
        char *hex_fingerprint;
        unsigned char *fprint_bytes;
    PPCODE:
    {
        fprint_bytes = (unsigned char*)SvPVbyte_nolen(HASHGET(fprint, "fingerprint", 11));

        Newx(hex_fingerprint, OTRL_PRIVKEY_FPRINT_HUMAN_LEN, char);

        otrl_privkey_hash_to_human(hex_fingerprint, fprint_bytes);

        XPUSHs( sv_2mortal( newSVpvn( hex_fingerprint, OTRL_PRIVKEY_FPRINT_HUMAN_LEN - 1)));

        Safefree(hex_fingerprint);

        XSRETURN(1);
    }

void
set_verified(fprint, verified)
    SV *fprint
    SV * verified
    PROTOTYPE: $$
    PREINIT:
        OTRctx * ctx;
        ConnContext * context;
        Fingerprint * fingerprint;
        int is_verified;
        char *contact_name;
        char *account_name;
        char *account_protocol;
    PPCODE:
    {
        HV *contact = (HV*)HASHGET(fprint, "cnt", 3);
        HV *account = (HV*)HASHGET(contact, "act", 3);
        ctx = ACCOUNT2CTX(account);

        is_verified = SvOK(verified) && SvTRUE(verified) ? 1 : 0;

        contact_name = SvPV_nolen(HASHGET(contact, "name", 4));
        account_name = SvPV_nolen(HASHGET(account, "name", 4));
        account_protocol = SvPV_nolen(HASHGET(account, "protocol", 8));

        context = otrl_context_find(ctx->userstate, contact_name, account_name, account_protocol,
            OTRL_INSTAG_MASTER, 0, NULL, NULL, NULL);

        if ( context ) {
            unsigned char *fprint_bytes = (unsigned char*)SvPV_nolen(HASHGET(fprint, "fingerprint", 11));
            fingerprint = otrl_context_find_fingerprint(context, fprint_bytes, 0, NULL);

            if ( fingerprint ) {
                otrl_context_set_trust(fingerprint, verified ? "verified" : "");
                (void)hv_store((HV*)SvRV(fprint), "is_verified", 11, is_verified ? &PL_sv_yes : &PL_sv_no , 0);

                write_fingerprints(ctx);

                is_verified ? XSRETURN_YES : XSRETURN_NO;
            }
        }

        XSRETURN_UNDEF;
    }


MODULE = Protocol::OTR        PACKAGE = Protocol::OTR::Channel

void
init(channel)
    SV * channel
    ALIAS:
        refresh = 1
    PROTOTYPE: $
    PPCODE:
    {
        send_default_query_msg(channel);

        XSRETURN_YES;
    }

void
create_symkey(channel, use, use_for)
    SV * channel
    unsigned int use
    SV * use_for
    PROTOTYPE: $$$
    PREINIT:
        ConnContext *context;
        int context_created = 0;
        OTRctx * ctx;
        char *contact_name;
        char * account_name;
        char * account_protocol;
    PPCODE:
    {
        HV * contact = (HV*)CHANNEL2CONTACT(channel);
        HV * account = (HV*)CONTACT2ACCOUNT(contact);

        ctx = CHANNEL2CTX(channel);

        contact_name = SvPV_nolen(HASHGET(contact, "name", 4));
        account_name = SvPV_nolen(HASHGET(account, "name", 4)); 
        account_protocol = SvPV_nolen(HASHGET(account, "protocol", 8)); 

        context = otrl_context_find(
            ctx->userstate, contact_name, account_name, account_protocol,
            SvUV(HASHGET(channel, "selected_instag", 15)), 0, &context_created, NULL, NULL );

        if ( context && ! context_created && context->msgstate == OTRL_MSGSTATE_ENCRYPTED ) {
            unsigned char *symkey;
            unsigned char *usedata;
            STRLEN usedatalen;
            gcry_error_t err;

            usedata = (unsigned char*)SvPVbyte(use_for, usedatalen);

            Newx(symkey, OTRL_EXTRAKEY_BYTES, unsigned char);

            err = otrl_message_symkey(ctx->userstate,
                &callbacks,
                channel /* opdata */,
                context,
                use,
                usedata,
                (size_t)usedatalen,
                symkey);

            XPUSHs( sv_2mortal( newSVpvn( (char*)symkey, OTRL_EXTRAKEY_BYTES )));

            Safefree(symkey);
        
            XSRETURN( 1 );
        }

        XSRETURN_UNDEF;
    }

void
finish(channel)
    SV * channel
    PROTOTYPE: $
    PREINIT:
        OTRctx * ctx;
        char *contact_name;
        char *account_name;
        char *account_protocol;
    PPCODE:
    {
        HV * contact = (HV*)CHANNEL2CONTACT(channel);
        HV * account = (HV*)CONTACT2ACCOUNT(contact);
        ctx = ACCOUNT2CTX(account);

        contact_name = SvPV_nolen(HASHGET(contact, "name", 4));
        account_name = SvPV_nolen(HASHGET(account, "name", 4));
        account_protocol = SvPV_nolen(HASHGET(account, "protocol", 8));

        (void)hv_store((HV*)SvRV(channel), "gone_secure", 11, &PL_sv_no, 0);

        otrl_message_disconnect_all_instances(
            ctx->userstate,
            &callbacks,
            channel,
	        account_name,
            account_protocol,
            contact_name
        );

        XSRETURN_YES;
    }


void
write(channel, plain_text)
    SV * channel
    char * plain_text
    PROTOTYPE: $$
    PREINIT:
        OTRctx * ctx;
        char *contact_name;
        char *account_name;
        char *account_protocol;
    PPCODE:
    {
        ConnContext *context;
        int context_created = 0;
        gcry_error_t err;
        char *newmessage = NULL;
        unsigned int selected_instag;
        HV * contact = (HV*)CHANNEL2CONTACT(channel);
        HV * account = (HV*)CONTACT2ACCOUNT(contact);
        ctx = ACCOUNT2CTX(account);

        contact_name = SvPV_nolen(HASHGET(contact, "name", 4));
        account_name = SvPV_nolen(HASHGET(account, "name", 4));
        account_protocol = SvPV_nolen(HASHGET(account, "protocol", 8));

        selected_instag = SvUV(HASHGET(channel, "selected_instag", 15));

        context = otrl_context_find(
            ctx->userstate, contact_name, account_name, account_protocol,
            selected_instag, 0, &context_created, NULL, NULL );

        if ( context && context->msgstate == OTRL_MSGSTATE_FINISHED ) {

            handle_msg_event_cb(
                (void*) channel,
                OTRL_MSGEVENT_CONNECTION_ENDED,
                context,
                NULL,
                err
            );
            XSRETURN_NO;
        }

        err = otrl_message_sending(ctx->userstate,
            &callbacks,
            channel /* opdata */,
            account_name, account_protocol, contact_name,
            selected_instag,
            plain_text,
            NULL /* tlvs */,
            &newmessage,
            OTRL_FRAGMENT_SEND_ALL,
            &context,
            NULL /* add_app_info */,
            NULL /* add_app_info_data */);

        if ( err ) {
            otrl_message_free(newmessage);
            croak("Cannot send: %s", gcry_strerror(err));
        }

        otrl_message_free(newmessage);

        XSRETURN_YES;
    }

void
ping(channel)
    SV * channel
    PROTOTYPE: $
    PPCODE:
    {
        OTRctx * ctx = CHANNEL2CTX(channel);

        otrl_message_poll(ctx->userstate, &callbacks, channel);
        XSRETURN_YES;
    }

void
smp_verify(channel, answer, ...)
    SV * channel
    SV * answer
    PROTOTYPE: $$;$
    PPCODE:
    {
        ConnContext *context;
        int context_created = 0;
        char * question = NULL;
        STRLEN slen;
        unsigned char * secret;
        OTRctx * ctx;
        char *contact_name;
        char * account_name;
        char * account_protocol;

        HV * contact = (HV*)CHANNEL2CONTACT(channel);
        HV * account = (HV*)CONTACT2ACCOUNT(contact);

        ctx = CHANNEL2CTX(channel);

        contact_name = SvPV_nolen(HASHGET(contact, "name", 4));
        account_name = SvPV_nolen(HASHGET(account, "name", 4));
        account_protocol = SvPV_nolen(HASHGET(account, "protocol", 8));

        context = otrl_context_find(
            ctx->userstate, contact_name, account_name, account_protocol,
            SvUV(HASHGET(channel, "selected_instag", 15)), 0, &context_created, NULL, NULL );

        if ( ! context ) XSRETURN_NO;

        secret = (unsigned char*)SvPVbyte(answer, slen);

        if ( items == 3 && SvOK(ST(2)) ) {
            STRLEN qlen;
            question = SvPVbyte(ST(2), qlen);
        
            otrl_message_initiate_smp_q(
                ctx->userstate,
                &callbacks,
                channel,
                context,
                question,
                secret,
                slen
            );
        } else {
            otrl_message_initiate_smp(
                ctx->userstate,
                &callbacks,
                channel,
                context,
                secret,
                slen
            );
        }

        XSRETURN_YES;
    }

void
smp_respond(channel, response)
    SV * channel
    unsigned char *response
    PROTOTYPE: $$
    PPCODE:
    {
        ConnContext *context;
        int context_created = 0;
        OTRctx * ctx;
        char *contact_name;
        char * account_name;
        char * account_protocol;

        HV * contact = (HV*)CHANNEL2CONTACT(channel);
        HV * account = (HV*)CONTACT2ACCOUNT(contact);

        ctx = CHANNEL2CTX(channel);

        contact_name = SvPV_nolen(HASHGET(contact, "name", 4));
        account_name = SvPV_nolen(HASHGET(account, "name", 4));
        account_protocol = SvPV_nolen(HASHGET(account, "protocol", 8));

        context = otrl_context_find(
            ctx->userstate, contact_name, account_name, account_protocol,
            SvUV(HASHGET(channel, "selected_instag", 15)), 0, &context_created, NULL, NULL );


        if ( ! context ) XSRETURN_NO;

        otrl_message_respond_smp(ctx->userstate, &callbacks, channel,
            context, response, strlen((char*)response));

        XSRETURN_YES;
    }


void
smp_abort(channel)
    SV * channel
    PROTOTYPE: $
    PPCODE:
    {
        ConnContext *context;
        int context_created = 0;
        OTRctx * ctx;
        char *contact_name;
        char * account_name;
        char * account_protocol;

        HV * contact = (HV*)CHANNEL2CONTACT(channel);
        HV * account = (HV*)CONTACT2ACCOUNT(contact);

        ctx = CHANNEL2CTX(channel);

        contact_name = SvPV_nolen(HASHGET(contact, "name", 4));
        account_name = SvPV_nolen(HASHGET(account, "name", 4)); 
        account_protocol = SvPV_nolen(HASHGET(account, "protocol", 8)); 

        context = otrl_context_find(
            ctx->userstate, contact_name, account_name, account_protocol,
            SvUV(HASHGET(channel, "selected_instag", 15)), 0, &context_created, NULL, NULL );


        if ( ! context ) XSRETURN_NO;

        otrl_message_abort_smp(
            ctx->userstate,
            &callbacks,
            channel,
            context
        );

        XSRETURN_YES;
    }


void
read(channel, input)
    SV * channel
    char * input
    PROTOTYPE: $$
    PPCODE:
    {
        int res;
        char *newmessage = NULL;
        OtrlTLV *tlvs = NULL;
        OtrlTLV *tlv = NULL;
        OtrlMessageType msgtype;
        ConnContext *context;
        HV * contact = (HV*)CHANNEL2CONTACT(channel);
        HV * account = (HV*)CONTACT2ACCOUNT(contact);
        OTRctx *ctx = ACCOUNT2CTX(account);
        char *contact_name;
        char *account_name;
        char *account_protocol;

        if ( ! input ) {
            XSRETURN_NO;
        }

        contact_name = SvPV_nolen(HASHGET(contact, "name", 4));
        account_name = SvPV_nolen(HASHGET(account, "name", 4));
        account_protocol = SvPV_nolen(HASHGET(account, "protocol", 8));

        msgtype = otrl_proto_message_type(input);

        res = otrl_message_receiving(ctx->userstate,
            &callbacks,
            channel /* opdata */,
            account_name, account_protocol,
            contact_name,
            input,
            &newmessage,
            &tlvs,
            &context,
            NULL /* add_app_info */,
            NULL /* add_app_info_data */);

        if ( context ) {
            if (newmessage) {

                ENTER;
                SAVETMPS;

                PUSHMARK(SP);
                XPUSHs( channel );
                XPUSHs( sv_2mortal( newSVpvn( "on_read", 7 )));
                XPUSHs( sv_2mortal( newSVpv( newmessage, 0 )));
                PUTBACK;

                otrl_message_free(newmessage);

                call_method( "_ev", G_DISCARD | G_VOID );

                FREETMPS;
                LEAVE;

            } else {
                otrl_message_free(newmessage);
            }
        }

        tlv = otrl_tlv_find(tlvs, OTRL_TLV_DISCONNECTED);
        if (tlv) {
            if ( hv_exists((HV*)SvRV(channel), "on_gone_insecure", 16) ) {

                ENTER;
                SAVETMPS;

                PUSHMARK(SP);
                XPUSHs( channel );
                XPUSHs( sv_2mortal( newSVpvn( "on_gone_insecure", 16 )));
                PUTBACK;

                call_method( "_ev", G_DISCARD | G_VOID );

                FREETMPS;
                LEAVE;

                (void)hv_store((HV*)SvRV(channel), "gone_secure", 11, &PL_sv_no, 0);
            }
        }

        otrl_tlv_free(tlvs);

        if ( res == 1) {
            int gone_secure = SvTRUE(HASHGET(channel, "gone_secure", 11));

            /* gone_secure */
            if ( gone_secure
                    &&
                    ( /* our init */
                        msgtype == OTRL_MSGTYPE_REVEALSIG
                        ||
                     /* their init */
                        msgtype == OTRL_MSGTYPE_SIGNATURE
                    )
                    && context->msgstate == OTRL_MSGSTATE_ENCRYPTED
                    && context->auth.authstate == OTRL_AUTHSTATE_NONE
            ) {
                gone_secure_cb(
                    (void*) channel,
                    context
                );
            }
            XSRETURN_NO;
        }

        XSRETURN_YES;
    }

void
sessions(channel)
    SV * channel
    PROTOTYPE: $
    PREINIT:
        HV * sessions;
        HE * entry;
        I32 count;
    PPCODE:
    {
        sessions = (HV*)SvRV(HASHGET(channel, "known_sessions", 14));
        count = hv_iterinit(sessions);

        EXTEND(SP, count);

        while ( (entry = hv_iternext(sessions)) ) {
            I32 klen;
            char *key = hv_iterkey( entry, &klen );

            XPUSHs(sv_2mortal(newSVpvn(key, klen)));
        }
    }

void
current_session(channel)
    SV * channel
    PROTOTYPE: $
    PREINIT:
        ConnContext *context;
        OTRctx * ctx;
        char *contact_name;
        char * account_name;
        char * account_protocol;
    PPCODE:
    {
        HV * contact = (HV*)CHANNEL2CONTACT(channel);
        HV * account = (HV*)CONTACT2ACCOUNT(contact);

        ctx = CHANNEL2CTX(channel);

        contact_name = SvPV_nolen(HASHGET(contact, "name", 4));
        account_name = SvPV_nolen(HASHGET(account, "name", 4)); 
        account_protocol = SvPV_nolen(HASHGET(account, "protocol", 8)); 

        context = otrl_context_find(
            ctx->userstate, contact_name, account_name, account_protocol,
            SvUV(HASHGET(channel, "selected_instag", 15)), 0, NULL, NULL, NULL );

        if ( context ) {
            XPUSHs( sv_2mortal( newSVuv(context->their_instance) ) );

            XSRETURN(1);
        }

        XSRETURN_UNDEF;
    }


void
select_session(channel, session)
    SV * channel
    SV * session
    PROTOTYPE: $$
    PREINIT:
        otrl_instag_t instag;
        ConnContext *context;
        OTRctx * ctx;
        char *contact_name;
        char *account_name;
        char *account_protocol;
    PPCODE:
    {
        HV * contact = (HV*)CHANNEL2CONTACT(channel);
        HV * account = (HV*)CONTACT2ACCOUNT(contact);
        ctx = ACCOUNT2CTX(account);

        instag = SvUV(session);

        contact_name = SvPV_nolen(HASHGET(contact, "name", 4));
        account_name = SvPV_nolen(HASHGET(account, "name", 4));
        account_protocol = SvPV_nolen(HASHGET(account, "protocol", 8));

        context = otrl_context_find(
            ctx->userstate, contact_name, account_name, account_protocol,
            instag, 0, NULL, NULL, NULL );

        if ( context ) {
            (void)hv_store((HV*)SvRV(channel), "selected_instag", 6, newSVuv(instag), 0);

            send_default_query_msg(channel);

            XSRETURN_YES;
        }

        XSRETURN_NO;
    }

void
status(channel)
    SV * channel
    PROTOTYPE: $ 
    PREINIT:
        ConnContext *context;
        Fingerprint *fingerprint;
        OTRctx *ctx;
        char *contact_name;
        char *account_name;
        char *account_protocol;
    PPCODE:
    {
        HV * contact = (HV*)CHANNEL2CONTACT(channel);
        HV * account = (HV*)CONTACT2ACCOUNT(contact);
        ctx = ACCOUNT2CTX(account);

        contact_name = SvPV_nolen(HASHGET(contact, "name", 4));
        account_name = SvPV_nolen(HASHGET(account, "name", 4));
        account_protocol = SvPV_nolen(HASHGET(account, "protocol", 8));

        context = otrl_context_find(
            ctx->userstate, contact_name, account_name, account_protocol,
            SvUV(HASHGET(channel, "selected_instag", 15)), 0, NULL, NULL, NULL );

        if (context) {
            TrustLevel this_level = otrp_plugin_context_to_trust(context);

            XPUSHs( newSVpv( TrustStates[this_level], 0 ) );

            XSRETURN(1);
        }
        XSRETURN_UNDEF;
    }


