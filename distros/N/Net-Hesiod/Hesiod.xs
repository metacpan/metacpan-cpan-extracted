#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/*The Makefile.PL should -I the directory with hesiod.h in it */
#include <hesiod.h> 
#include <string.h>
#include <pwd.h>
#include <netdb.h>

static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(char *name, int len, int arg)
{
    errno = EINVAL;
    return 0;
}

MODULE = Net::Hesiod		PACKAGE = Net::Hesiod		


double
constant(sv,arg)
    PREINIT:
	STRLEN		len;
    INPUT:
	SV *		sv
	char *		s = SvPV(sv, len);
	int		arg
    CODE:
	RETVAL = constant(s,len,arg);
    OUTPUT:
	RETVAL



PROTOTYPES: enable

int
hesiod_init(context)
	void *	context = NO_INIT;
	CODE:
		RETVAL = hesiod_init(&context);
	OUTPUT:
	context
	RETVAL

void
hesiod_end(context)
	void * context;

char *
hesiod_to_bind(context, name, type)
	void *	context;
	const char *	name;
	const char *	type;

void
hesiod_resolve(context,name,type)
	void *	context;
	const char *	name;
	const char *	type;
	PREINIT:
		char ** results;
		char ** res;
		int i;
		dTARGET;
		SV *tmp;
	PPCODE:
		results = hesiod_resolve(context,name,type);
		/* Handle an invalid query */
		if ( ! results ) { XSRETURN_EMPTY; }
		res = results;
		i =0;
		while ( *res )
		{	tmp = sv_newmortal();
			sv_setpv(tmp,*res);
			XPUSHs(tmp);
			i++;
			res++;
		}
		hesiod_free_list(context,results);
		XSRETURN(i);


void
hesiod_getpwnam(context,name)
	void *	context;
	const char *	name;
	PREINIT:
		struct passwd *pw;
		dTARGET;
		SV *tmp;
	PPCODE:
		pw = hesiod_getpwnam(context,name);
		/* Handle errors by returning empty */
		if ( ! pw ) { XSRETURN_EMPTY; }
		/* Presumably, have a valid response */
		tmp = sv_newmortal(); sv_setpv(tmp,pw->pw_name);
		XPUSHs(tmp);
		tmp = sv_newmortal(); sv_setpv(tmp,pw->pw_passwd);
		XPUSHs(tmp);
		tmp = sv_newmortal(); sv_setiv(tmp,pw->pw_uid);
		XPUSHs(tmp);
		tmp = sv_newmortal(); sv_setiv(tmp,pw->pw_gid);
		XPUSHs(tmp);
		tmp = sv_newmortal();
		/* Not all systems have a pw_quota or pw_comment elements. 
		** Solaris lacks pw_quota, having pw_age instead
		** Linux lacks both
			If missing, leave undef the return value 
		*/
#ifndef DONT_HAVE_PW_QUOTA
		sv_setiv(tmp,pw->pw_quota);
#else
		sv_setsv(tmp,&sv_undef);
#endif
		XPUSHs(tmp);
		tmp = sv_newmortal(); 
#ifndef DONT_HAVE_PW_COMMENT
		sv_setpv(tmp,pw->pw_comment);
#else
		sv_setsv(tmp,&sv_undef);
#endif
		XPUSHs(tmp);
		tmp = sv_newmortal(); sv_setpv(tmp,pw->pw_gecos);
		XPUSHs(tmp);
		tmp = sv_newmortal(); sv_setpv(tmp,pw->pw_dir);
		XPUSHs(tmp);
		tmp = sv_newmortal(); sv_setpv(tmp,pw->pw_shell);
		XPUSHs(tmp);
		hesiod_free_passwd(context,pw);
		XSRETURN(9);

void
hesiod_getpwuid(context,uid)
	void *	context;
	uid_t	uid;
	PREINIT:
		struct passwd *pw;
		dTARGET;
		SV *tmp;
	PPCODE:
		pw = hesiod_getpwuid(context,uid);
		/* Handle errors by returning empty */
		if ( ! pw ) { XSRETURN_EMPTY; }
		/* Presumably, have a valid response */
		tmp = sv_newmortal(); sv_setpv(tmp,pw->pw_name);
		XPUSHs(tmp);
		tmp = sv_newmortal(); sv_setpv(tmp,pw->pw_passwd);
		XPUSHs(tmp);
		tmp = sv_newmortal(); sv_setiv(tmp,pw->pw_uid);
		XPUSHs(tmp);
		tmp = sv_newmortal(); sv_setiv(tmp,pw->pw_gid);
		XPUSHs(tmp);
		tmp = sv_newmortal();
		/* Leave undef if lacking pw_quota or pw_comment */
#ifndef DONT_HAVE_PW_QUOTA
		sv_setiv(tmp,pw->pw_quota);
#else
		sv_setsv(tmp,&sv_undef);
#endif
		XPUSHs(tmp);
		tmp = sv_newmortal();
#ifndef DONT_HAVE_PW_COMMENT
		sv_setpv(tmp,pw->pw_comment);
#else
		sv_setsv(tmp,&sv_undef);
#endif
		XPUSHs(tmp);
		tmp = sv_newmortal(); sv_setpv(tmp,pw->pw_gecos);
		XPUSHs(tmp);
		tmp = sv_newmortal(); sv_setpv(tmp,pw->pw_dir);
		XPUSHs(tmp);
		tmp = sv_newmortal(); sv_setpv(tmp,pw->pw_shell);
		XPUSHs(tmp);
		hesiod_free_passwd(context,pw);
		XSRETURN(9);

struct servent *
hesiod_getservbyname(context,name, proto)
	void *	context;
	const char *	name;
	const char *	proto;
	PREINIT:
		struct servent *sent;
		dTARGET;
		SV *tmp;
		int port;
	PPCODE:
		sent = hesiod_getservbyname(context,name, proto);
		/* Handle errors by returning empty */
		if ( ! sent ) { XSRETURN_EMPTY; }
		/* Presumably, have a valid response */
		/* servent struct is supposed to store port number in
			network byte order.  We return it in host order
			to be consistent with perl getservbyname */
		port = ntohs(sent->s_port);
		tmp= sv_newmortal(); sv_setpv(tmp,sent->s_name);
		XPUSHs(tmp);
		/* WE now concat the alias list */
		tmp= sv_newmortal();
		if ( *sent->s_aliases )
		{ 	sv_setpv(tmp,*sent->s_aliases);
			sent->s_aliases++;
		} else
		{	sv_setsv(tmp,&sv_undef);
		}
		while ( *sent->s_aliases )
		{	sv_catpv(tmp,*sent->s_aliases);
			sent->s_aliases++;
		} 
		XPUSHs(tmp);

		tmp= sv_newmortal(); sv_setiv(tmp,port);
		XPUSHs(tmp);
		tmp= sv_newmortal(); sv_setpv(tmp,sent->s_proto);
		XPUSHs(tmp);

		hesiod_free_servent(context,sent);
		XSRETURN(4);

struct hesiod_postoffice *
hesiod_getmailhost(context,user)
	void *	context;
	char *	user;
	PREINIT:
		struct hesiod_postoffice *po;
		dTARGET;
		SV * tmp;
	PPCODE:
		po = hesiod_getmailhost(context,user);
		/* Handle errors by returning empty */
		if ( ! po ) { XSRETURN_EMPTY; }
		/* Presumably, have a valid response */
		tmp= sv_newmortal(); sv_setpv(tmp,po->hesiod_po_type);
		XPUSHs(tmp);
		tmp= sv_newmortal(); sv_setpv(tmp,po->hesiod_po_host);
		XPUSHs(tmp);
		tmp= sv_newmortal(); sv_setpv(tmp,po->hesiod_po_name);
		XPUSHs(tmp);
		hesiod_free_postoffice(context,po);
		XSRETURN(3);

