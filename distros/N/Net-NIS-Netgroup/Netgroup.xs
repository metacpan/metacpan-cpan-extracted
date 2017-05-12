/*
 * $Id: Netgroup.xs,v 1.3 2010/08/12 14:10:24 bastian Exp $
 *
 * Copyright (C) 2009, 2010 Collax GmbH
 *                    (Bastian Friedrich <bastian.friedrich@collax.com>)
 */

#include <unistd.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = Net::NIS::Netgroup PACKAGE = Net::NIS::Netgroup

SV *
getdomainname()
    PREINIT:
    	int len = 512;
	char buf[512];
    PPCODE:
    	int ret = getdomainname(buf, len);
	if (ret == -1) {
		XPUSHs(&PL_sv_undef);
	} else {
		XPUSHs(sv_2mortal(newSVpv(buf, 0)));
	}

IV *
setdomainname(name)
    const char *name
    PREINIT:
    	int len = strlen(name) + 1;
    PPCODE:
    	int ret = setdomainname(name, len);
	if (ret == -1) {
		XPUSHs(&PL_sv_undef);
	} else {
		XPUSHs(sv_2mortal(newSViv(1)));
	}

IV *
innetgr(sv_netgroup, sv_host, sv_user, sv_domain)
    SV *sv_netgroup
    SV *sv_host
    SV *sv_user
    SV *sv_domain
    PREINIT:
	char *netgroup;
	char *host;
	char *user;
	char *domain;

	int ret;

    PPCODE:
	ret = 0;

	if (!SvOK(sv_netgroup)) { netgroup = NULL; } else { netgroup = SvPV_nolen(sv_netgroup); }
	if (!SvOK(sv_host)) { host = NULL; } else { host = SvPV_nolen(sv_host); }
	if (!SvOK(sv_user)) { user = NULL; } else { user = SvPV_nolen(sv_user); }
	if (!SvOK(sv_domain)) { domain = NULL; } else { domain = SvPV_nolen(sv_domain); }

    	/*
    	printf("xs code: netgroup == %s\n", netgroup);
    	printf("xs code: host == '%s'\n", host);
    	printf("xs code: user == '%s'\n", user);
    	printf("xs code: domain == '%s'\n", domain);
	*/
	if (netgroup) {
	    	ret = innetgr(netgroup, host, user, domain);
	}
	if (ret == 1) {
		XPUSHs(sv_2mortal(newSViv(1)));
	} else {
		XPUSHs(&PL_sv_undef);
	}


AV *
listnetgr(netgroup, stringify = 0)
	char *netgroup
	bool stringify

    PREINIT:
	char *host;
	char *user;
	char *domain;

	HV *el;
	char *buf;
	int bufsize = 256;
	int len;
    PPCODE:

	if (stringify) {
		buf = malloc(bufsize);
		if (!buf) {
			Perl_croak(aTHX_ "Could not allocate memory");
		}
	}

	setnetgrent(netgroup);

	while (getnetgrent (&host, &user, &domain)) {
		if (stringify) {
			if (!host) host = "";
			if (!user) user = "";
			if (!domain) domain = "";
			len = strlen("(,,)") + strlen(host) + strlen(user) + strlen(domain);
			if ((len+1) > bufsize) {
				bufsize = len + 1;
				buf = realloc(buf, bufsize);
				if (!buf) {
					Perl_croak(aTHX_ "Could not allocate memory");
				}
			}
			sprintf(buf, "(%s,%s,%s)", host, user, domain);
			XPUSHs(sv_2mortal(newSVpv(buf, len)));
		} else {
			el = newHV();

			hv_store(el, "host", strlen("host"), host ? newSVpv(strdup(host), 0) : newSV(0), 0);
			hv_store(el, "user", strlen("user"), user ? newSVpv(strdup(user), 0) : newSV(0), 0);
			hv_store(el, "domain", strlen("domain"), domain ? newSVpv(strdup(domain), 0) : newSV(0), 0);

			XPUSHs(sv_2mortal(newRV_noinc((SV*)el)));
		}
	}

	if (stringify) {
		free(buf);
	}

	endnetgrent();

