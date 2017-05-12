#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef USE_OPENSSL
#include <openssl/ssl.h>
#endif
#ifdef USE_SMTPAUTH
#include <auth-client.h>
#endif
#include <libesmtp.h>

#include "const-c.inc"

typedef smtp_session_t		Net__ESMTP__Session;
typedef smtp_message_t		Net__ESMTP__Message;
typedef smtp_recipient_t	Net__ESMTP__Recipient;
typedef smtp_etrn_node_t	Net__ESMTP__EtrnNode;

typedef enum header_option	Net__ESMTP__HeaderOption;
typedef enum rfc2822_timeouts	Net__ESMTP__RFC822Timeouts;

typedef HV *			Net__ESMTP__Status;
#ifdef _auth_client_h
typedef auth_context_t		Net__ESMTP__Auth;
#else
typedef void *			Net__ESMTP__Auth;
#endif


void
callback_eventcb (smtp_session_t session, int event_no, void *arg, ...)
{
    va_list ap;
    smtp_message_t message;
    smtp_recipient_t recipient;
    char *text;
    int intarg, *intptr, count;
    long longarg;
    SV *svfunc = NULL;
    SV *svuser_data = NULL;
    SV **sv, *svobj, *rvobj, *svobjarg;
    HV *hvarray;

    dSP ;

    if (!arg || !SvROK((SV *)arg))
	return;

    ENTER ;
    SAVETMPS;
	

    hvarray = (HV *)(SvRV((SV *)arg));
    intptr = NULL;

    sv = hv_fetch(hvarray, "func", 4, FALSE);
    if (sv == (SV**)NULL)
      croak("callback_enum_eventcb: Internal error fetching func ...\n") ;
    svfunc = *sv;

    sv = hv_fetch(hvarray, "user_data", 9, FALSE);
    if (sv == (SV**)NULL)
      croak("callback_enum_eventcb: Internal error fetching user_data ...\n") ;
    svuser_data = *sv;

    svobj = sv_newmortal ();
    rvobj = sv_setref_pv (svobj, "Net::ESMTP::Session", session);

    PUSHMARK(sp);
    XPUSHs(rvobj);
    XPUSHs(sv_2mortal(newSViv(event_no)));
    XPUSHs(sv_mortalcopy(svuser_data));

    va_start (ap, arg);
    /* Protocol progress */
    switch (event_no) {
	case SMTP_EV_CONNECT:		/* <empty arg list> */
	    break;
	case SMTP_EV_MAILSTATUS:	/* char* message->reverse_path_mailbox, message */
	    text = va_arg (ap, char *);
	    message = va_arg (ap, smtp_message_t);

	    XPUSHs(sv_2mortal(newSVpvn(text, strlen(text))));
	    svobjarg = sv_newmortal();
	    XPUSHs(sv_setref_pv (svobjarg, "Net::ESMTP::Message", message));
	    break;
	case SMTP_EV_RCPTSTATUS: /* char* session->rsp_recipient->mailbox, session->rsp_recipient */
	    text = va_arg (ap, char *);
	    recipient = va_arg (ap, smtp_recipient_t);

	    XPUSHs(sv_2mortal(newSVpvn(text, strlen(text))));
	    svobjarg = sv_newmortal();
	    XPUSHs(sv_setref_pv (svobjarg, "Net::ESMTP::Recipient", recipient));
	    break;
	case SMTP_EV_MESSAGEDATA:	/* session->current_message, int len */
	    message = va_arg (ap, smtp_message_t);
	    intarg = va_arg (ap, int);
    	
	    svobjarg = sv_newmortal();
	    XPUSHs(sv_setref_pv (svobjarg, "Net::ESMTP::Message", message));
	    XPUSHs(sv_2mortal(newSViv(intarg)));
	    break;
	case SMTP_EV_MESSAGESENT:	/* session->current_message */
	    message = va_arg (ap, smtp_message_t);

	    svobjarg = sv_newmortal();
	    XPUSHs(sv_setref_pv (svobjarg, "Net::ESMTP::Message", message));
	    break;
	case SMTP_EV_DISCONNECT:	/* <empty arg list> */
	    break;

    /* Protocol extension progress */
	case SMTP_EV_ETRNSTATUS:	/* int node->option, char* node->domain */
	    intarg = va_arg (ap, int);
	    text = va_arg (ap, char *);

	    XPUSHs(sv_2mortal(newSViv(intarg)));
	    XPUSHs(sv_2mortal(newSVpvn(text, strlen(text))));
	    break;

    /* Required extensions */
	case SMTP_EV_EXTNA_DSN:		/* int &quit_now */
	    intptr = va_arg (ap, int *);
	case SMTP_EV_EXTNA_8BITMIME:	/* <empty arg list> */
	    break;
	case SMTP_EV_EXTNA_STARTTLS:	/* NULL (protocol.c) */
	    break;
	case SMTP_EV_EXTNA_ETRN:	/* int &quit_now */
	case SMTP_EV_EXTNA_CHUNKING:	/* int &quit_now */
	    intptr = va_arg (ap, int *);
	    break;
	case SMTP_EV_EXTNA_BINARYMIME:	/* <empty arg list> */
	    break;

    /* Extensions specific events */
	case SMTP_EV_DELIVERBY_EXPIRED:	/* long session->min_by_time - by_time, int &adjust */
	    longarg = va_arg (ap, long);
	    intptr = va_arg (ap, int *);

	    XPUSHs(sv_2mortal(newSVnv(longarg)));
	    break;

    /* STARTTLS */
	case SMTP_EV_WEAK_CIPHER:		/* int bits, int &ok */
	    intarg = va_arg (ap, int);
	    intptr = va_arg (ap, int *);

	    XPUSHs(sv_2mortal(newSViv(intarg)));
	    break;
	case SMTP_EV_STARTTLS_OK: /* SSL* ssl, SSL_get_cipher (ssl), SSL_get_cipher_bits (ssl, NULL) */
	    /* UNSUPPORTED */
	    break;
	case SMTP_EV_INVALID_PEER_CERTIFICATE:	/* long vfy_result, int &ok */
	    longarg = va_arg (ap, long);
	    intptr = va_arg (ap, int *);

	    XPUSHs(sv_2mortal(newSVnv(longarg)));
	    break;
	case SMTP_EV_NO_PEER_CERTIFICATE:	/* int &ok */
	case SMTP_EV_WRONG_PEER_CERTIFICATE:	/* int &ok */
	    intptr = va_arg (ap, int *);
	    break;
	case SMTP_EV_NO_CLIENT_CERTIFICATE:	/* int &ok */
	    intptr = va_arg (ap, int *);
	    break;
	case SMTP_EV_UNUSABLE_CLIENT_CERTIFICATE:	/* <empty arg list> */
	    break;
	case SMTP_EV_UNUSABLE_CA_LIST:	/* <empty arg list> */
	    break;
    }
    va_end (ap);

    PUTBACK ;

    SPAGAIN ;

    if (svfunc) {
	if (intptr != NULL) {
	    count = perl_call_sv(svfunc, G_SCALAR);
	    if (count > 0)
		*intptr = POPi;
	} else {
	    perl_call_sv(svfunc, G_DISCARD);
	}
    }

    PUTBACK ;
    FREETMPS ;
    LEAVE ;
}


void
callback_enum_messagecb (smtp_message_t message, void *arg)
{
    SV *svfunc = NULL;
    SV *svuser_data = NULL;
    SV **sv, *svobj, *rvobj;
    HV *hvarray;

    dSP ;

    if (!arg || !SvROK((SV *)arg))
	return;

    hvarray = (HV *)(SvRV((SV *)arg));

    sv = hv_fetch(hvarray, "func", 4, FALSE);
    if (sv == (SV**)NULL)
      croak("callback_enum_messagecb: Internal error fetching func ...\n") ;
    svfunc = *sv;

    sv = hv_fetch(hvarray, "user_data", 9, FALSE);
    if (sv == (SV**)NULL)
      croak("callback_enum_messagecb: Internal error fetching user_data ...\n") ;
    svuser_data = *sv;

    svobj = sv_newmortal ();
    rvobj = sv_setref_pv (svobj, "Net::ESMTP::Message", message);

    PUSHMARK(sp);
    XPUSHs(rvobj);
    XPUSHs(sv_mortalcopy(svuser_data));
    PUTBACK ;
    if (svfunc)
	perl_call_sv(svfunc, G_DISCARD);

}


void
callback_enum_recipientcb (smtp_recipient_t recipient,
		const char *mailbox, void *arg)
{
    SV *svfunc = NULL;
    SV *svuser_data = NULL;
    SV **sv, *svobj, *rvobj;
    HV *hvarray;

    dSP ;

    if (!arg || !SvROK((SV *)arg))
	return;

    hvarray = (HV *)(SvRV((SV *)arg));

    sv = hv_fetch(hvarray, "func", 4, FALSE);
    if (sv == (SV**)NULL)
      croak("callback_enum_recipientcb: Internal error fetching func ...\n") ;
    svfunc = *sv;

    sv = hv_fetch(hvarray, "user_data", 9, FALSE);
    if (sv == (SV**)NULL)
      croak("callback_enum_recipientcb: Internal error fetching user_data ...\n") ;
    svuser_data = *sv;

    svobj = sv_newmortal ();
    rvobj = sv_setref_pv (svobj, "Net::ESMTP::Recipient", recipient);

    PUSHMARK(sp);
    XPUSHs(rvobj);
    XPUSHs(sv_2mortal(newSVpvn(mailbox, strlen(mailbox))));
    XPUSHs(sv_mortalcopy(svuser_data));
    PUTBACK ;
    if (svfunc)
	perl_call_sv(svfunc, G_DISCARD);

}


void
callback_enum_nodecb (smtp_etrn_node_t node,
		int option, const char *domain, void *arg)
{
    SV *svfunc = NULL;
    SV *svuser_data = NULL;
    SV **sv, *svobj, *rvobj;
    HV *hvarray;

    dSP ;

    if (!arg || !SvROK((SV *)arg))
	return;

    hvarray = (HV *)(SvRV((SV *)arg));

    sv = hv_fetch(hvarray, "func", 4, FALSE);
    if (sv == (SV**)NULL)
      croak("callback_enum_nodecb: Internal error fetching func ...\n") ;
    svfunc = *sv;

    sv = hv_fetch(hvarray, "user_data", 9, FALSE);
    if (sv == (SV**)NULL)
      croak("callback_enum_nodecb: Internal error fetching user_data ...\n") ;
    svuser_data = *sv;

    svobj = sv_newmortal ();
    rvobj = sv_setref_pv (svobj, "Net::ESMTP::ETRNNode", node);

    PUSHMARK(sp);
    XPUSHs(rvobj);
    XPUSHs(sv_2mortal(newSViv(option)));
    XPUSHs(sv_2mortal(newSVpvn(domain, strlen(domain))));
    XPUSHs(sv_mortalcopy(svuser_data));
    PUTBACK ;
    if (svfunc)
	perl_call_sv(svfunc, G_DISCARD);

}


void
callback_monitorcb (const char *buf, int buflen, int writing, void *arg)
{
    SV *svfunc = NULL;
    SV *svuser_data = NULL;
    SV **sv;
    HV *hvarray;

    dSP ;

    if (!arg || !SvROK((SV *)arg))
	return;

    hvarray = (HV *)(SvRV((SV *)arg));

    sv = hv_fetch(hvarray, "func", 4, FALSE);
    if (sv == (SV**)NULL)
      croak("callback_monitorcb: Internal error fetching func ...\n") ;
    svfunc = *sv;

    sv = hv_fetch(hvarray, "user_data", 9, FALSE);
    if (sv == (SV**)NULL)
      croak("callback_monitorcb: Internal error fetching user_data ...\n") ;
    svuser_data = *sv;

    PUSHMARK(sp);
    XPUSHs(sv_2mortal(newSVpvn(buf,  buflen)));
    XPUSHs(sv_2mortal(newSViv(writing)));
    XPUSHs(sv_mortalcopy(svuser_data));
    PUTBACK ;
    if (svfunc)
	perl_call_sv(svfunc, G_DISCARD);

}


/* I am not sure that callback_auth_interactcb works,
 * since perl can free the result strings before C library would use it */
#ifdef _auth_client_h
int
callback_auth_interactcb (auth_client_request_t request,
		char **result, int fields, void *arg)
{
    SV *svfunc = NULL;
    SV *svuser_data = NULL;
    SV **sv, *rvobj;
    HV *hvarray;
    HV *hvrequest;
    AV *avreq;
    int i, ret = 1;

    dSP ;
    int count = 0;
    I32 ax;

    ENTER ;
    SAVETMPS;

    if (!arg || !SvROK((SV *)arg))
	return 0;

    hvarray = (HV *)(SvRV((SV *)arg));

    sv = hv_fetch(hvarray, "func", 4, FALSE);
    if (sv == (SV**)NULL)
      croak("callback_auth_interactcb: Internal error fetching func ...\n") ;
    svfunc = *sv;

    sv = hv_fetch(hvarray, "user_data", 9, FALSE);
    if (sv == (SV**)NULL)
      croak("callback_auth_interactcb: Internal error fetching user_data ...\n") ;
    svuser_data = *sv;

    avreq = (AV *)sv_2mortal((SV *)newAV()); /* array of requests */
    for (i=0; i<fields; ++i) {
        hvrequest = (HV *)sv_2mortal((SV *)newHV());
        hv_store(hvrequest, "name",   4, newSVpvn(request[i].name, strlen(request[i].name)), 0);
        hv_store(hvrequest, "flags",  5, newSViv(request[i].flags), 0);
        hv_store(hvrequest, "prompt", 6, newSVpvn(request[i].prompt, strlen(request[i].prompt)), 0);
        hv_store(hvrequest, "size",   4, newSViv(request[i].size), 0);
	av_push(avreq, newRV((SV *)hvrequest));
    }

    rvobj = newRV((SV *)avreq);

    PUSHMARK(sp);
    XPUSHs(rvobj);
    XPUSHs(sv_mortalcopy(svuser_data));
    PUTBACK ;

    if (svfunc)
	count = perl_call_sv(svfunc, G_ARRAY);

    SPAGAIN ;
    SP -= count ; /* we can use ST(i) */
    ax = (SP - PL_stack_base) + 1 ;

    for (i=0; i<count; i++) {
	SV *svstr = sv_mortalcopy(ST(i));
	result[i] = (char *) SvPV_nolen(svstr);
    }

    /* fail if there are no result or less items than requested */
    if (count < fields)
	ret = 0;

    PUTBACK ;
    FREETMPS ;
    LEAVE ;

    return ret;
}
#endif

/* returns a length of the password, not the command status */
int
callback_starttls_set_password (char *buf, int buflen, int rwflag, void *arg)
{
    int ret = 0;
    SV *svfunc = NULL;
    SV *svuser_data = NULL;
    SV **sv;
    HV *hvarray;

    dSP ;
    int count = 0;

    ENTER ;
    SAVETMPS;

    if (!arg || !SvROK((SV *)arg))
	return 0;

    hvarray = (HV *)(SvRV((SV *)arg));

    sv = hv_fetch(hvarray, "func", 4, FALSE);
    if (sv == (SV**)NULL)
      croak("callback_starttls_set_password: Internal error fetching func ...\n") ;
    svfunc = *sv;

    sv = hv_fetch(hvarray, "user_data", 9, FALSE);
    if (sv == (SV**)NULL)
      croak("callback_starttls_set_password: Internal error fetching user_data ...\n") ;
    svuser_data = *sv;

    PUSHMARK(sp);
    XPUSHs(sv_2mortal(newSViv(rwflag)));
    XPUSHs(sv_mortalcopy(svuser_data));
    PUTBACK ;

    if (svfunc)
        count = perl_call_sv(svfunc, G_SCALAR);

    SPAGAIN ;

    if (count) {
	STRLEN n_a;
	char *text = POPpx;
	int len = n_a;

	if (len + 1 > buflen || len == 0 || !text)
	    ret = 0;
	else
	    strcpy (buf, text);

	ret = len; /* return length of the returned password string */
    } else {
	ret = 0;
    }

    PUTBACK ;
    FREETMPS ;
    LEAVE ;

    return ret;
}


const char *
callback_messagecb (void **buf, int *len, void *arg)
{
    SV *svfunc = NULL;
    SV *svuser_data = NULL;
    SV **sv;
    HV *hvarray;

    dSP ;
    int count = 0;

    ENTER ;
    SAVETMPS;

    if (!arg || !SvROK((SV *)arg))
	return NULL;

    hvarray = (HV *)(SvRV((SV *)arg));

    sv = hv_fetch(hvarray, "func", 4, FALSE);
    if (sv == (SV**)NULL)
      croak("callback_messagecb: Internal error fetching func ...\n") ;
    svfunc = *sv;

    sv = hv_fetch(hvarray, "user_data", 9, FALSE);
    if (sv == (SV**)NULL)
      croak("callback_messagecb: Internal error fetching user_data ...\n") ;
    svuser_data = *sv;

    PUSHMARK(sp);
    /* len is NULL at the begining */
    if (len == NULL) {
      XPUSHs(&PL_sv_undef);
    } else {
      XPUSHs(sv_2mortal(newSViv(*len)));
    }
    XPUSHs(sv_mortalcopy(svuser_data));
    PUTBACK ;
    if (svfunc) {
	if (len == NULL) {
	    perl_call_sv(svfunc, G_DISCARD);
	} else {
	    count = perl_call_sv(svfunc, G_SCALAR);
	}
    }

    SPAGAIN ;

    if (count > 0) {
	STRLEN n_a;
	char *text = POPpx;

	if (n_a <= 0 || !text)
	    *len = 0;
	else {
	    *buf = realloc (*buf, n_a);
	    strncpy (*buf, text, n_a);
	    *len = n_a;
	}
    }

    PUTBACK ;
    FREETMPS ;
    LEAVE ;

    if (len == NULL)
	return NULL;
    else
        return *buf;
}

MODULE = Net::ESMTP		PACKAGE = Net::ESMTP

PROTOTYPES: ENABLE

INCLUDE: const-xs.inc

BOOT:
#ifdef _auth_client_h
auth_client_init();
#endif

SV *
smtp_version ()
    PREINIT:
	char				buf[256];
    CODE:
	if (!smtp_version (buf, 255, 0))
	    XSRETURN_UNDEF;
	RETVAL = newSVpv (buf, 1);
    OUTPUT:
	RETVAL

MODULE = Net::ESMTP		PACKAGE = Net::ESMTP	PREFIX = smtp_

int
smtp_starttls_set_password_cb(callback, svdata = 0)
	SV *				callback
	SV *				svdata
    PREINIT:
	HV *			rh;
    CODE:
	rh = (HV *)sv_2mortal((SV *)newHV());
	hv_store(rh, "user_data", 9, newSVsv(svdata), 0);
	hv_store(rh, "func", 4, newSVsv(callback), 0);
	RETVAL = smtp_starttls_set_password_cb (callback_starttls_set_password, newRV((SV *)rh));
    OUTPUT:
	RETVAL


MODULE = Net::ESMTP		PACKAGE = Net::ESMTP::Session	PREFIX = smtp_

Net::ESMTP::Session
smtp_new (Class = "Net::ESMTP::Session")
	const char *			Class
    CODE:
	RETVAL = smtp_create_session ();
    OUTPUT:
	RETVAL

void
DESTROY (session)
	Net::ESMTP::Session		session
    CODE:
#ifdef _auth_client_h
	smtp_auth_set_context (session, NULL);
#endif
	smtp_destroy_session (session);

Net::ESMTP::Message
smtp_add_message (session)
	Net::ESMTP::Session		session

int
smtp_set_server (session, hostport)
	Net::ESMTP::Session		session
	const char *			hostport

int
smtp_set_hostname (session, hostname)
	Net::ESMTP::Session		session
	const char *			hostname

int
smtp_start_session (session)
	Net::ESMTP::Session		session

 #
 # application data (void *)
 #
void *
smtp_set_application_data (session, data)
	Net::ESMTP::Session		session
	void *				data

void *
smtp_get_application_data (session)
	Net::ESMTP::Session		session

int
smtp_option_require_all_recipients (session, state)
	Net::ESMTP::Session		session
	int				state

#ifdef _auth_client_h
int
smtp_auth_set_context (session, context)
	Net::ESMTP::Session		session
	Net::ESMTP::Auth		context

#endif

long
smtp_set_timeout (session, which, value)
	Net::ESMTP::Session		session
	int				which
	long				value

int
smtp_set_eventcb (session, callback, svdata = 0)
	Net::ESMTP::Session		session
	SV *				callback
	SV *				svdata
    PREINIT:
	HV *				rh;
    CODE:
	rh = (HV *)sv_2mortal((SV *)newHV());
	hv_store(rh, "user_data", 9, newSVsv(svdata), 0);
	hv_store(rh, "func", 4, newSVsv(callback), 0);
	RETVAL = smtp_set_eventcb (session, callback_eventcb, newRV((SV *)rh));
    OUTPUT:
	RETVAL

int
smtp_set_monitorcb (session, callback, svdata = 0, headers = 0)
	Net::ESMTP::Session		session
	SV *				callback
	SV *				svdata
	int				headers
    PREINIT:
	HV *				rh;
    CODE:
	rh = (HV *)sv_2mortal((SV *)newHV());
	hv_store(rh, "user_data", 9, newSVsv(svdata), 0);
	hv_store(rh, "func", 4, newSVsv(callback), 0);
	RETVAL = smtp_set_monitorcb (session, callback_monitorcb, newRV((SV *)rh), headers);
    OUTPUT:
	RETVAL

 ## RFC 1985.  Remote Message Queue Starting (ETRN)

Net::ESMTP::EtrnNode
smtp_etrn_add_node (session, option, node)
	Net::ESMTP::Session		session
	int				option
	const char *			node

int
smtp_etrn_enumerate_nodes (session, callback, svdata = 0)
	Net::ESMTP::Session		session
	SV *				callback
	SV *				svdata
    PREINIT:
	HV *				rh;
    CODE:
	rh = (HV *)sv_2mortal((SV *)newHV());
	hv_store(rh, "user_data", 9, newSVsv(svdata), 0);
	hv_store(rh, "func", 4, newSVsv(callback), 0);
	RETVAL = smtp_etrn_enumerate_nodes (session, callback_enum_nodecb, newRV((SV *)rh));
    OUTPUT:
	RETVAL

int
smtp_enumerate_messages (session, callback, svdata = 0)
	Net::ESMTP::Session		session
	SV *				callback
	SV *				svdata
    PREINIT:
	HV *				rh;
    CODE:
	rh = (HV *)sv_2mortal((SV *)newHV());
	hv_store(rh, "user_data", 9, newSVsv(svdata), 0);
	hv_store(rh, "func", 4, newSVsv(callback), 0);
	RETVAL = smtp_enumerate_messages (session, callback_enum_messagecb, newRV((SV *)rh));
    OUTPUT:
	RETVAL

 ## RFC 3207.  SMTP Starttls extension.

int
smtp_starttls_enable (session, how = Starttls_ENABLED)
	Net::ESMTP::Session		session
	int				how

int
smtp_starttls_set_ctx (session, ctx)
	Net::ESMTP::Session		session
	void *				ctx
    CODE:
#ifdef USE_OPENSSL
	RETVAL = smtp_starttls_set_ctx (session, ctx);
#else
	RETVAL = 0;
#endif
    OUTPUT:
	RETVAL


MODULE = Net::ESMTP		PACKAGE = Net::ESMTP::Message	PREFIX = smtp_

int
smtp_set_reverse_path (message, mailbox)
	Net::ESMTP::Message		message
	const char *			mailbox

int
smtp_set_header (message, header, ...)
	Net::ESMTP::Message		message
	const char *			header
    CODE:
        RETVAL = -1;
	if (!header || strlen(header) <= 2) {
	    XSRETURN(0);
	}
	// set_date
	if (!strncasecmp(header, "Date", 4)) {
	    if (items == 3)
	        RETVAL = smtp_set_header (message, header, SvNV(ST(2)));
	}
    /* Omit special cases, since they are the same to the application */
	/*
	else
	// set_from phrase, mailbox (many values are allowed)
	if (!strncasecmp(header, "Disposition-Notification-To", 27) ||
	    !strncasecmp(header, "From", 4)) {
	    if (items == 4)
		RETVAL = smtp_set_header (message, header, SvPV(ST(2),0), SvPV(ST(3),0));
	}
        else
	// set_string_null
	if (!strncasecmp(header, "Message-Id", 10)) {
	    if (items == 3)
	        RETVAL = smtp_set_header (message, header, SvPV(ST(2),0));
	}
	else
	// set_sender phrase, mailbox (one value is allowed)
	if (!strncasecmp(header, "Sender", 6)) {
	    if (items == 4)
		RETVAL = smtp_set_header (message, header, SvPV(ST(2),0), SvPV(ST(3),0));
	}
	else
	// set_to phrase, mailbox
	if (!strncasecmp(header, "To", 2)) {
	    if (items == 4)
		RETVAL = smtp_set_header (message, header, SvPV(ST(2),0), SvPV(ST(3),0));
	}
	else
	// set_cc phrase, mailbox
	if (!strncasecmp(header, "Cc", 2) ||
	    !strncasecmp(header, "Bcc", 3) ||
	    !strncasecmp(header, "Reply-To", 8)) {
	    if (items == 4)
		RETVAL = smtp_set_header (message, header, SvPV(ST(2),0), SvPV(ST(3),0));
	}
	*/
	else
	{
	    if (items == 3)
	        RETVAL = smtp_set_header (message, header, SvPV_nolen(ST(2)));
	    else
	    if (items == 4)
	        RETVAL = smtp_set_header (message, header, SvPV_nolen(ST(2)), SvPV_nolen(ST(3)));
	}
	if (RETVAL == -1) {
	    RETVAL = 0;
	    warn ("Wrong number of arguments for header '%s'", header);
	}
    OUTPUT:
	RETVAL

int
smtp_set_header_option (message, header, option, ...)
	Net::ESMTP::Message		message
	const char *			header
	Net::ESMTP::HeaderOption	option
    CODE:
	if (items == 3) {
	    RETVAL = smtp_set_header_option (message, header, option);
	} else if (items == 4) {
	    RETVAL = smtp_set_header_option (message, header, option, SvIV(ST(3)));
	} else {
	    croak("Usage: Net::ESMTP::Message::set_header_option(message, header, option[, value])");
	}
    OUTPUT:
	RETVAL

int
smtp_set_resent_headers (message, onoff)
	Net::ESMTP::Message		message
	int				onoff

int
smtp_set_messagecb (message, callback, svdata = 0)
	Net::ESMTP::Message		message
	SV *				callback
	SV *				svdata
    PREINIT:
	HV *				rh;
    CODE:
	rh = (HV *)sv_2mortal((SV *)newHV());
	hv_store(rh, "user_data", 9, newSVsv(svdata), 0);
	hv_store(rh, "func", 4, newSVsv(callback), 0);
	RETVAL = smtp_set_messagecb (message, callback_messagecb, newRV((SV *)rh));
    OUTPUT:
	RETVAL

 #
 # Standard callbacks for reading the message from the application.
 #

int
smtp_set_message_fp (message, fp)
	Net::ESMTP::Message		message
	FILE *				fp

int
smtp_set_message_str (message, str)
	Net::ESMTP::Message		message
	char *				str


 #
 # Net::ESMTP::Status
 #

Net::ESMTP::Status
smtp_message_transfer_status (message)
	Net::ESMTP::Message		message
    PREINIT:
	HV				*hv;
	const smtp_status_t		*stat;
    CODE:
	stat = smtp_message_transfer_status (message);
	if (!stat)
	    XSRETURN_UNDEF;
	hv = (HV *)sv_2mortal((SV *)newHV());
	if (!hv)
	    XSRETURN_UNDEF;
	hv_store(hv, "code",        4 ,newSViv(stat->code) , 0);
	hv_store(hv, "text",        4 ,newSVpvn(stat->text, strlen(stat->text)) , 0);
	hv_store(hv, "enh_class",   9 ,newSViv(stat->enh_class) , 0);
	hv_store(hv, "enh_subject",11 ,newSViv(stat->enh_subject) , 0);
	hv_store(hv, "enh_detail", 10 ,newSViv(stat->enh_detail) , 0);
	RETVAL = hv;
    OUTPUT:
	RETVAL



Net::ESMTP::Status
smtp_reverse_path_status (message)
	Net::ESMTP::Message		message
    PREINIT:
	HV				*hv;
	const smtp_status_t		*stat;
    CODE:
	stat = smtp_reverse_path_status (message);
	if (!stat)
	    XSRETURN_UNDEF;
	hv = (HV *)sv_2mortal((SV *)newHV());
	if (!hv)
	    XSRETURN_UNDEF;
	hv_store(hv, "code",        4 ,newSViv(stat->code) , 0);
	hv_store(hv, "text",        4 ,newSVpvn(stat->text, strlen(stat->text)) , 0);
	hv_store(hv, "enh_class",   9 ,newSViv(stat->enh_class) , 0);
	hv_store(hv, "enh_subject",11 ,newSViv(stat->enh_subject) , 0);
	hv_store(hv, "enh_detail", 10 ,newSViv(stat->enh_detail) , 0);
	RETVAL = hv;
    OUTPUT:
	RETVAL

int
smtp_message_reset_status (message)
	Net::ESMTP::Message		message

 ## RFC 1891.  Delivery Status Notification (DSN)

int
smtp_dsn_set_ret (message, flags)
	Net::ESMTP::Message		message
	int				flags

int
smtp_dsn_set_envid (message, envid)
	Net::ESMTP::Message		message
	const char *			envid

 ## RFC 1870.  SMTP Size extension.

int
smtp_size_set_estimate (message, size)
	Net::ESMTP::Message		message
	unsigned long			size

 ## RFC 1652.  8bit-MIME Transport

int
smtp_8bitmime_set_body (message, body)
	Net::ESMTP::Message		message
	int				body

 ## RFC 2852.  Deliver By

int
smtp_deliverby_set_mode (message, time, mode, trace)
	Net::ESMTP::Message		message
	long				time
	int				mode
	int				trace


MODULE = Net::ESMTP		PACKAGE = Net::ESMTP::Message	PREFIX = smtp_message_

 #
 # application data (void *)
 #

void *
smtp_message_set_application_data (message, data)
	Net::ESMTP::Message		message
	void *				data

void *
smtp_message_get_application_data (message)
	Net::ESMTP::Message		message

MODULE = Net::ESMTP		PACKAGE = Net::ESMTP::Message	PREFIX = smtp_

Net::ESMTP::Recipient
smtp_add_recipient (message, mailbox)
	Net::ESMTP::Message		message
	const char *			mailbox

int
smtp_enumerate_recipients (message, callback, svdata = 0)
	Net::ESMTP::Message		message
	SV *				callback
	SV *				svdata
    PREINIT:
	HV *				rh;
    CODE:
	rh = (HV *)sv_2mortal((SV *)newHV());
	hv_store(rh, "user_data", 9, newSVsv(svdata), 0);
	hv_store(rh, "func", 4, newSVsv(callback), 0);
	RETVAL = smtp_enumerate_recipients (message, callback_enum_recipientcb, newRV((SV *)rh));
    OUTPUT:
	RETVAL


MODULE = Net::ESMTP		PACKAGE = Net::ESMTP::Recipient	PREFIX = smtp_

Net::ESMTP::Status
smtp_recipient_status (recipient)
	Net::ESMTP::Recipient		recipient
    PREINIT:
	HV				*hv;
	const smtp_status_t		*stat;
    CODE:
	stat = smtp_recipient_status (recipient);
	if (!stat)
	    XSRETURN_UNDEF;
	hv = (HV *)sv_2mortal((SV *)newHV());
	if (!hv)
	    XSRETURN_UNDEF;
	hv_store(hv, "code",        4 ,newSViv(stat->code) , 0);
	hv_store(hv, "text",        4 ,newSVpvn(stat->text, strlen(stat->text)) , 0);
	hv_store(hv, "enh_class",   9 ,newSViv(stat->enh_class) , 0);
	hv_store(hv, "enh_subject",11 ,newSViv(stat->enh_subject) , 0);
	hv_store(hv, "enh_detail", 10 ,newSViv(stat->enh_detail) , 0);
	RETVAL = hv;
    OUTPUT:
	RETVAL

int
smtp_recipient_check_complete (recipient)
	Net::ESMTP::Recipient		recipient

int
smtp_recipient_reset_status (recipient)
	Net::ESMTP::Recipient		recipient

 ## RFC 1891.  Delivery Status Notification (DSN)

int
smtp_dsn_set_notify (recipient, notify)
	Net::ESMTP::Recipient		recipient
	int				notify

int
smtp_dsn_set_orcpt (recipient, address_type, address)
	Net::ESMTP::Recipient		recipient
	const char *			address_type
	const char *			address


MODULE = Net::ESMTP		PACKAGE = Net::ESMTP::Recipient	PREFIX = smtp_recipient_

 #
 # application data (void *)
 #

void *
smtp_recipient_set_application_data (recipient, data)
	Net::ESMTP::Recipient		recipient
	void *				data

void *
smtp_recipient_get_application_data (recipient)
	Net::ESMTP::Recipient		recipient


MODULE = Net::ESMTP		PACKAGE = Net::ESMTP

int
smtp_errno ()

SV *
smtp_strerror (error)
	int				error
    PREINIT:
	char				buf[256];
    char                *ret;
    CODE:
	if ((ret = smtp_strerror (error, buf, 255)) == NULL)
	    XSRETURN_UNDEF;
	RETVAL = newSVpv (ret, 0);
    OUTPUT:
	RETVAL


MODULE = Net::ESMTP		PACKAGE = Net::ESMTP::EtrnNode	PREFIX = smtp_

 ## RFC 1985.  Remote Message Queue Starting (ETRN)

Net::ESMTP::Status
smtp_etrn_node_status (node)
	Net::ESMTP::EtrnNode		node
    PREINIT:
	HV				*hv;
	const smtp_status_t		*stat;
    CODE:
	stat = smtp_etrn_node_status (node);
	if (!stat)
	    XSRETURN_UNDEF;
	hv = (HV *)sv_2mortal((SV *)newHV());
	if (!hv)
	    XSRETURN_UNDEF;
	hv_store(hv, "code",        4 ,newSViv(stat->code) , 0);
	hv_store(hv, "text",        4 ,newSVpvn(stat->text, strlen(stat->text)) , 0);
	hv_store(hv, "enh_class",   9 ,newSViv(stat->enh_class) , 0);
	hv_store(hv, "enh_subject",11 ,newSViv(stat->enh_subject) , 0);
	hv_store(hv, "enh_detail", 10 ,newSViv(stat->enh_detail) , 0);
	RETVAL = hv;
    OUTPUT:
	RETVAL

MODULE = Net::ESMTP		PACKAGE = Net::ESMTP::EtrnNode	PREFIX = smtp_etrn_

void *
smtp_etrn_set_application_data (node, data)
	Net::ESMTP::EtrnNode		node
	void *				data

void *
smtp_etrn_get_application_data (node)
	Net::ESMTP::EtrnNode		node


MODULE = Net::ESMTP		PACKAGE = Net::ESMTP::Auth	PREFIX = auth_

Net::ESMTP::Auth
auth_new (Class = "Net::ESMTP::Auth")
	const char *			Class
    CODE:
#ifdef _auth_client_h
	RETVAL = auth_create_context ();
#else
	RETVAL = &PL_sv_undef;
#endif
    OUTPUT:
	RETVAL

void
DESTROY (context)
	Net::ESMTP::Auth		context
    CODE:
#ifdef _auth_client_h
	auth_destroy_context (context);
#endif

#ifdef _auth_client_h

int
auth_set_mechanism_flags (context, set, clear)
	Net::ESMTP::Auth		context
	unsigned int			set
	unsigned int			clear

int
auth_set_mechanism_ssf (context, min_ssf)
	Net::ESMTP::Auth		context
	int				min_ssf

int
auth_set_interact_cb (context, callback, svdata = 0)
	Net::ESMTP::Auth		context
	SV *				callback
	SV *				svdata
    PREINIT:
	HV *				rh;
    CODE:
	rh = (HV *)sv_2mortal((SV *)newHV());
	hv_store(rh, "user_data", 9, newSVsv(svdata), 0);
	hv_store(rh, "func", 4, newSVsv(callback), 0);
	RETVAL = auth_set_interact_cb (context, callback_auth_interactcb, newRV((SV *)rh));
    OUTPUT:
	RETVAL

int
auth_client_enabled(context)
	Net::ESMTP::Auth		context

int
auth_set_mechanism(context, name)
	Net::ESMTP::Auth		context
	const char *			name

const char *
auth_mechanism_name (context)
	Net::ESMTP::Auth		context

SV *
auth_response(context, challenge)
	Net::ESMTP::Auth		context
	const char *			challenge
    PREINIT:
	const char *			text;
	int				len;
    CODE:
	text = auth_response(context, challenge, &len);
	RETVAL = newSVpvn (text, len);
    OUTPUT:
	RETVAL

int
auth_get_ssf(context)
	Net::ESMTP::Auth		context

SV *
auth_encode(context, svsrc)
	Net::ESMTP::Auth		context
	SV *				svsrc
    PREINIT:
	char				*dstbuf;
	char				*srcbuf;
	int				dstlen;
	STRLEN				srclen;
    CODE:
	srcbuf = SvPV(svsrc, srclen);
	auth_encode(&dstbuf, &dstlen, srcbuf, srclen, (void *)context);
	if (dstlen > 0) {
	    RETVAL = newSVpvn (dstbuf, dstlen);
	} else {
	    XSRETURN_UNDEF;
	}
    OUTPUT:
	RETVAL

SV *
auth_decode(context, svsrc)
	Net::ESMTP::Auth		context
	SV *				svsrc
    PREINIT:
	char				*dstbuf;
	char				*srcbuf;
	int				dstlen;
	STRLEN				srclen;
    CODE:
	srcbuf = SvPV(svsrc, srclen);
	auth_decode(&dstbuf, &dstlen, srcbuf, srclen, (void *)context);
	if (dstlen > 0) {
	    RETVAL = newSVpvn (dstbuf, dstlen);
	} else {
	    XSRETURN_UNDEF;
	}
    OUTPUT:
	RETVAL



int
auth_set_external_id (context, identity)
	Net::ESMTP::Auth		context
	const char *			identity

#endif
