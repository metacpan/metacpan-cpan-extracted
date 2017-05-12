/* Implementation of wmic as a perl shared library */
#define BUF_SZ 4096
static char help_buffer[BUF_SZ] = "0";

/* 
   Unix SMB/CIFS implementation.

   Copyright (C) Jelmer Vernooij 2005

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.
   
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   
   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

#include "includes.h"
#include "system/filesys.h"
#include "auth/credentials/credentials.h"

static const char *cmdline_get_userpassword(struct cli_credentials *credentials)
{
	char *ret;
	TALLOC_CTX *mem_ctx = talloc_new(NULL);

	const char *prompt_name = cli_credentials_get_unparsed_name(credentials, mem_ctx);
	const char *prompt;

	prompt = talloc_asprintf(mem_ctx, "Password for [%s]:", 
				 prompt_name);

	ret = getpass(prompt);

	talloc_free(mem_ctx);
	return ret;
}

void cli_credentials_set_cmdline_callbacks(struct cli_credentials *cred)
{
	cli_credentials_set_password_callback(cred, cmdline_get_userpassword);
}
/* 
   Unix SMB/CIFS implementation.
   Common popt routines

   Copyright (C) Tim Potter 2001,2002
   Copyright (C) Jelmer Vernooij 2002,2003,2005

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.
   
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   
   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

#include "includes.h"
#include "version.h"
#include "lib/cmdline/popt_common.h"

/* Handle command line options:
 *		-d,--debuglevel 
 *		-s,--configfile 
 *		-O,--socket-options 
 *		-V,--version
 *		-l,--log-base
 *		-n,--netbios-name
 *		-W,--workgroup
 *		--realm
 *		-i,--scope
 */

enum {OPT_OPTION=1,OPT_LEAK_REPORT,OPT_LEAK_REPORT_FULL,OPT_DEBUG_STDERR};

struct cli_credentials *cmdline_credentials = NULL;

static void popt_common_callback(poptContext con, 
			   enum poptCallbackReason reason,
			   const struct poptOption *opt,
			   const char *arg, const void *data)
{
	const char *pname;
	FILE *helpbuf = NULL;

	if (reason == POPT_CALLBACK_REASON_POST) {
		lp_load();
		/* Hook any 'every Samba program must do this, after
		 * the smb.conf is setup' functions here */
		return;
	}

	/* Find out basename of current program */
	pname = strrchr_m(poptGetInvocationName(con),'/');

	if (!pname)
		pname = poptGetInvocationName(con);
	else 
		pname++;

	if (reason == POPT_CALLBACK_REASON_PRE) {
		/* Hook for 'almost the first thing to do in a samba program' here */
		/* setup for panics */
		fault_setup(poptGetInvocationName(con));

		/* and logging */
		setup_logging(pname, DEBUG_STDOUT);
		return;
	}

	switch(opt->val) {
	case 'd':
		lp_set_cmdline("log level", arg);
		break;

	case OPT_DEBUG_STDERR:
		setup_logging(pname, DEBUG_STDERR);
		break;

	case 'V':
		helpbuf = fmemopen(help_buffer+1, BUF_SZ-1, "w");
		fprintf(helpbuf, "Version %s\n", SAMBA_VERSION_STRING );
		fclose(helpbuf);
		break;

	case 'O':
		if (arg) {
			lp_set_cmdline("socket options", arg);
		}
		break;

	case 's':
		if (arg) {
			lp_set_cmdline("config file", arg);
		}
		break;

	case 'l':
		if (arg) {
			char *new_logfile = talloc_asprintf(NULL, "%s/log.%s", arg, pname);
			lp_set_cmdline("log file", new_logfile);
			talloc_free(new_logfile);
		}
		break;
		
	case 'W':
		lp_set_cmdline("workgroup", arg);
		break;

	case 'r':
		lp_set_cmdline("realm", arg);
		break;
		
	case 'n':
		lp_set_cmdline("netbios name", arg);
		break;
		
	case 'i':
		lp_set_cmdline("netbios scope", arg);
		break;

	case 'm':
		lp_set_cmdline("client max protocol", arg);
		break;

	case 'R':
		lp_set_cmdline("name resolve order", arg);
		break;

	case OPT_OPTION:
		if (!lp_set_option(arg)) {
			helpbuf = fmemopen(help_buffer+1, BUF_SZ-1, "w");
			fprintf(helpbuf, "Error setting option '%s'\n", arg);
			fclose(helpbuf);
		}
		break;

	case OPT_LEAK_REPORT:
		talloc_enable_leak_report();
		break;

	case OPT_LEAK_REPORT_FULL:
		talloc_enable_leak_report_full();
		break;

	}
}

struct poptOption popt_common_connection[] = {
	{ NULL, 0, POPT_ARG_CALLBACK, popt_common_callback },
	{ "name-resolve", 'R', POPT_ARG_STRING, NULL, 'R', "Use these name resolution services only", "NAME-RESOLVE-ORDER" },
	{ "socket-options", 'O', POPT_ARG_STRING, NULL, 'O', "socket options to use", "SOCKETOPTIONS" },
	{ "netbiosname", 'n', POPT_ARG_STRING, NULL, 'n', "Primary netbios name", "NETBIOSNAME" },
	{ "workgroup", 'W', POPT_ARG_STRING, NULL, 'W', "Set the workgroup name", "WORKGROUP" },
	{ "realm", 0, POPT_ARG_STRING, NULL, 'r', "Set the realm name", "REALM" },
	{ "scope", 'i', POPT_ARG_STRING, NULL, 'i', "Use this Netbios scope", "SCOPE" },
	{ "maxprotocol", 'm', POPT_ARG_STRING, NULL, 'm', "Set max protocol level", "MAXPROTOCOL" },
	{ NULL }
};

struct poptOption popt_common_samba[] = {
	{ NULL, 0, POPT_ARG_CALLBACK|POPT_CBFLAG_PRE|POPT_CBFLAG_POST, popt_common_callback },
	{ "debuglevel",   'd', POPT_ARG_STRING, NULL, 'd', "Set debug level", "DEBUGLEVEL" },
	{ "debug-stderr", 0, POPT_ARG_NONE, NULL, OPT_DEBUG_STDERR, "Send debug output to STDERR", NULL },
	{ "configfile",   's', POPT_ARG_STRING, NULL, 's', "Use alternative configuration file", "CONFIGFILE" },
	{ "option",         0, POPT_ARG_STRING, NULL, OPT_OPTION, "Set smb.conf option from command line", "name=value" },
	{ "log-basename", 'l', POPT_ARG_STRING, NULL, 'l', "Basename for log/debug files", "LOGFILEBASE" },
	{ "leak-report",     0, POPT_ARG_NONE, NULL, OPT_LEAK_REPORT, "enable talloc leak reporting on exit", NULL },	
	{ "leak-report-full",0, POPT_ARG_NONE, NULL, OPT_LEAK_REPORT_FULL, "enable full talloc leak reporting on exit", NULL },
	{ NULL }
};

struct poptOption popt_common_version[] = {
	{ NULL, 0, POPT_ARG_CALLBACK, popt_common_callback },
	{ "version", 'V', POPT_ARG_NONE, NULL, 'V', "Print version" },
	{ NULL }
};

/* 
   Unix SMB/CIFS implementation.
   Credentials popt routines

   Copyright (C) Jelmer Vernooij 2002,2003,2005

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.
   
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   
   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

#include "includes.h"
#include "lib/cmdline/popt_common.h"
#include "lib/cmdline/credentials.h"
#include "auth/credentials/credentials.h"
#include "auth/credentials/credentials_krb5.h"
#include "auth/gensec/gensec.h"

/* Handle command line options:
 *		-U,--user
 *		-A,--authentication-file
 *		-k,--use-kerberos
 *		-N,--no-pass
 *		-S,--signing
 *              -P --machine-pass
 *                 --simple-bind-dn
 *                 --password
 *                 --use-security-mechanisms
 */


static BOOL dont_ask;

enum opt { OPT_SIMPLE_BIND_DN, OPT_PASSWORD, OPT_KERBEROS, OPT_GENSEC_MECHS };

/*
  disable asking for a password
*/
void popt_common_dont_ask(void)
{
	dont_ask = True;
}

static void popt_common_credentials_callback(poptContext con, 
						enum poptCallbackReason reason,
						const struct poptOption *opt,
						const char *arg, const void *data)
{
	FILE *helpbuf = NULL;

	if (reason == POPT_CALLBACK_REASON_PRE) {
		cmdline_credentials = cli_credentials_init(talloc_autofree_context());
		return;
	}
	
	if (reason == POPT_CALLBACK_REASON_POST) {
		cli_credentials_guess(cmdline_credentials);

		if (!dont_ask) {
			cli_credentials_set_cmdline_callbacks(cmdline_credentials);
		}
		return;
	}

	switch(opt->val) {
	case 'U':
		{
			char *lp;

			cli_credentials_parse_string(cmdline_credentials, arg, CRED_SPECIFIED);
			/* This breaks the abstraction, including the const above */
			if ((lp=strchr_m(arg,'%'))) {
				lp[0]='\0';
				lp++;
				/* Try to prevent this showing up in ps */
				memset(lp,0,strlen(lp));
			}
		}
		break;

	case OPT_PASSWORD:
		cli_credentials_set_password(cmdline_credentials, arg, CRED_SPECIFIED);
		/* Try to prevent this showing up in ps */
		memset(discard_const(arg),0,strlen(arg));
		break;

	case 'A':
		cli_credentials_parse_file(cmdline_credentials, arg, CRED_SPECIFIED);
		break;

	case 'S':
		lp_set_cmdline("client signing", arg);
		break;

	case 'P':
		/* Later, after this is all over, get the machine account details from the secrets.ldb */
		cli_credentials_set_machine_account_pending(cmdline_credentials);
		break;

	case OPT_KERBEROS:
	{
		BOOL use_kerberos = True;
		/* Force us to only use kerberos */
		if (arg) {
			if (!set_boolean(arg, &use_kerberos)) {
				helpbuf = fmemopen(help_buffer+1, BUF_SZ-1, "w");
				fprintf(helpbuf, "Error parsing -k %s\n", arg);
				fclose(helpbuf);
				break;
			}
		}
		
		cli_credentials_set_kerberos_state(cmdline_credentials, 
						   use_kerberos 
						   ? CRED_MUST_USE_KERBEROS
						   : CRED_DONT_USE_KERBEROS);
		break;
	}
	case OPT_GENSEC_MECHS:
		/* Convert a list of strings into a list of available authentication standards */
		
		break;
		
	case OPT_SIMPLE_BIND_DN:
		cli_credentials_set_bind_dn(cmdline_credentials, arg);
		break;
	}
}



struct poptOption popt_common_credentials[] = {
	{ NULL, 0, POPT_ARG_CALLBACK|POPT_CBFLAG_PRE|POPT_CBFLAG_POST, popt_common_credentials_callback },
	{ "user", 'U', POPT_ARG_STRING, NULL, 'U', "Set the network username", "[DOMAIN\\]USERNAME[%PASSWORD]" },
	{ "no-pass", 'N', POPT_ARG_NONE, &dont_ask, True, "Don't ask for a password" },
	{ "password", 0, POPT_ARG_STRING, NULL, OPT_PASSWORD, "Password" },
	{ "authentication-file", 'A', POPT_ARG_STRING, NULL, 'A', "Get the credentials from a file", "FILE" },
	{ "signing", 'S', POPT_ARG_STRING, NULL, 'S', "Set the client signing state", "on|off|required" },
	{ "machine-pass", 'P', POPT_ARG_NONE, NULL, 'P', "Use stored machine account password (implies -k)" },
	{ "simple-bind-dn", 0, POPT_ARG_STRING, NULL, OPT_SIMPLE_BIND_DN, "DN to use for a simple bind" },
	{ "kerberos", 'k', POPT_ARG_STRING, NULL, OPT_KERBEROS, "Use Kerberos" },
	{ "use-security-mechanisms", 0, POPT_ARG_STRING, NULL, OPT_GENSEC_MECHS, "Restricted list of authentication mechanisms available for use with this authentication"},
	{ NULL }
};
/*
   WMI Sample client
   Copyright (C) 2006 Andrzej Hajda <andrzej.hajda@wp.pl>
   Modifications for library use (C) 2012 Joshua Megerman <josh@honorablemenschen.com>

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

#include <stdio.h>
#include "includes.h"
#include "lib/cmdline/popt_common.h"
#include "librpc/rpc/dcerpc.h"
#include "librpc/gen_ndr/ndr_oxidresolver.h"
#include "librpc/gen_ndr/ndr_oxidresolver_c.h"
#include "librpc/gen_ndr/ndr_dcom.h"
#include "librpc/gen_ndr/ndr_dcom_c.h"
#include "librpc/gen_ndr/ndr_remact_c.h"
#include "librpc/gen_ndr/ndr_epmapper_c.h"
#include "librpc/gen_ndr/com_dcom.h"
#include "librpc/rpc/dcerpc_table.h"

#include "lib/com/dcom/dcom.h"
#include "lib/com/proto.h"
#include "lib/com/dcom/proto.h"

#include "wmi/wmi.h"

struct WBEMCLASS;
struct WBEMOBJECT;

#include "wmi/proto.h"

extern int DEBUGLEVEL;

struct program_args {
    char *hostname;
    char *query;
    char *ns;
    char *delim;
};

static int parse_args(int argc, char *argv[], struct program_args *pmyargs)
{
    poptContext pc;
    int opt, i;

    int argc_new;
    char **argv_new;

    FILE *helpbuf = NULL;

    struct poptOption long_options[] = {
	POPT_AUTOHELP
	POPT_COMMON_SAMBA
	POPT_COMMON_CONNECTION
	POPT_COMMON_CREDENTIALS
	POPT_COMMON_VERSION
        {"namespace", 0, POPT_ARG_STRING, &pmyargs->ns, 0,
         "WMI namespace, default to root\\cimv2", 0},
	{"delimiter", 0, POPT_ARG_STRING, &pmyargs->delim, 0,
	 "delimiter to use when querying multiple values, default to '|'", 0},
	POPT_TABLEEND
    };

    pc = poptGetContext("wmi", argc, (const char **) argv,
	        long_options, POPT_CONTEXT_KEEP_FIRST);

    poptSetOtherOptionHelp(pc, "//host query\n\nExample: wmic -U [domain/]adminuser%password //host \"select * from Win32_ComputerSystem\"");

    while ((opt = poptGetNextOpt(pc)) != -1) {
	helpbuf = fmemopen(help_buffer+1, BUF_SZ-1, "w");
	poptPrintUsage(pc, helpbuf, 0);
	poptFreeContext(pc);
	fclose(helpbuf);
	return(1);
    }

    if (strlen(help_buffer) > 1) {
	return(1);
    }

    argv_new = discard_const_p(char *, poptGetArgs(pc));

    argc_new = argc;
    for (i = 0; i < argc; i++) {
	if (argv_new[i] == NULL) {
	    argc_new = i;
	    break;
	}
    }

    if (argc_new != 3
	|| strncmp(argv_new[1], "//", 2) != 0) {
	helpbuf = fmemopen(help_buffer+1, BUF_SZ-1, "w");
	poptPrintUsage(pc, helpbuf, 0);
	poptFreeContext(pc);
	fclose(helpbuf);
	return(1);
    }

    /* skip over leading "//" in host name */
    pmyargs->hostname = argv_new[1] + 2;
    pmyargs->query = argv_new[2];
    poptFreeContext(pc);

    return(0);
}

#define WERR_CHECK(msg) if (!W_ERROR_IS_OK(result)) { \
			    DEBUG(0, ("ERROR: %s\n", msg)); \
			    goto error; \
			} else { \
			    DEBUG(1, ("OK   : %s\n", msg)); \
			}

#define RETURN_CVAR_ARRAY_STR(fmt, arr) {\
        uint32_t i;\
	char *r;\
\
        if (!arr) {\
                return talloc_strdup(mem_ctx, "NULL");\
        }\
	r = talloc_strdup(mem_ctx, "(");\
        for (i = 0; i < arr->count; ++i) {\
		r = talloc_asprintf_append(r, fmt "%s", arr->item[i], (i+1 == arr->count)?"":",");\
        }\
        return talloc_asprintf_append(r, ")");\
}

char *string_CIMVAR(TALLOC_CTX *mem_ctx, union CIMVAR *v, enum CIMTYPE_ENUMERATION cimtype)
{
	switch (cimtype) {
        case CIM_SINT8: return talloc_asprintf(mem_ctx, "%d", v->v_sint8);
        case CIM_UINT8: return talloc_asprintf(mem_ctx, "%u", v->v_uint8);
        case CIM_SINT16: return talloc_asprintf(mem_ctx, "%d", v->v_sint16);
        case CIM_UINT16: return talloc_asprintf(mem_ctx, "%u", v->v_uint16);
        case CIM_SINT32: return talloc_asprintf(mem_ctx, "%d", v->v_sint32);
        case CIM_UINT32: return talloc_asprintf(mem_ctx, "%u", v->v_uint32);
        case CIM_SINT64: return talloc_asprintf(mem_ctx, "%lld", v->v_sint64);
        case CIM_UINT64: return talloc_asprintf(mem_ctx, "%llu", v->v_sint64);
        case CIM_REAL32: return talloc_asprintf(mem_ctx, "%f", (double)v->v_uint32);
        case CIM_REAL64: return talloc_asprintf(mem_ctx, "%f", (double)v->v_uint64);
        case CIM_BOOLEAN: return talloc_asprintf(mem_ctx, "%s", v->v_boolean?"True":"False");
        case CIM_STRING:
        case CIM_DATETIME:
        case CIM_REFERENCE: return talloc_asprintf(mem_ctx, "%s", v->v_string);
        case CIM_CHAR16: return talloc_asprintf(mem_ctx, "Unsupported");
        case CIM_OBJECT: return talloc_asprintf(mem_ctx, "Unsupported");
        case CIM_ARR_SINT8: RETURN_CVAR_ARRAY_STR("%d", v->a_sint8);
        case CIM_ARR_UINT8: RETURN_CVAR_ARRAY_STR("%u", v->a_uint8);
        case CIM_ARR_SINT16: RETURN_CVAR_ARRAY_STR("%d", v->a_sint16);
        case CIM_ARR_UINT16: RETURN_CVAR_ARRAY_STR("%u", v->a_uint16);
        case CIM_ARR_SINT32: RETURN_CVAR_ARRAY_STR("%d", v->a_sint32);
        case CIM_ARR_UINT32: RETURN_CVAR_ARRAY_STR("%u", v->a_uint32);
        case CIM_ARR_SINT64: RETURN_CVAR_ARRAY_STR("%lld", v->a_sint64);
        case CIM_ARR_UINT64: RETURN_CVAR_ARRAY_STR("%llu", v->a_uint64);
        case CIM_ARR_REAL32: RETURN_CVAR_ARRAY_STR("%f", v->a_real32);
        case CIM_ARR_REAL64: RETURN_CVAR_ARRAY_STR("%f", v->a_real64);
        case CIM_ARR_BOOLEAN: RETURN_CVAR_ARRAY_STR("%d", v->a_boolean);
        case CIM_ARR_STRING: RETURN_CVAR_ARRAY_STR("%s", v->a_string);
        case CIM_ARR_DATETIME: RETURN_CVAR_ARRAY_STR("%s", v->a_datetime);
        case CIM_ARR_REFERENCE: RETURN_CVAR_ARRAY_STR("%s", v->a_reference);
	default: return talloc_asprintf(mem_ctx, "Unsupported");
	}
}

#undef RETURN_CVAR_ARRAY_STR

char *expand_string(char *dest, const char *source) {

	if (dest) {
		dest = realloc(dest, (strlen(dest) + strlen(source) + 1));
		strncat(dest, source, strlen(source));
	} else {
		dest = strdup(source);
	}

	return dest;

}

char *wmic(int argc, char **argv)
{
	struct program_args args = {};
	uint32_t cnt = 5, ret;
	char *class_name = NULL;
	char buffer[2048];
	char *returnbuf = NULL;
	WERROR result;
	NTSTATUS status;
	struct IWbemServices *pWS = NULL;

	DEBUGLEVEL = -1;
        if (parse_args(argc, argv, &args)) {
		return help_buffer;
	};

	/* Set default return for success */	
	returnbuf = expand_string(returnbuf, "1");

	/* apply default values if not given by user*/
	if (!args.ns) args.ns = "root\\cimv2";
	if (!args.delim) args.delim = "|";

	dcerpc_init();
	dcerpc_table_init();

	dcom_proxy_IUnknown_init();
	dcom_proxy_IWbemLevel1Login_init();
	dcom_proxy_IWbemServices_init();
	dcom_proxy_IEnumWbemClassObject_init();
	dcom_proxy_IRemUnknown_init();
	dcom_proxy_IWbemFetchSmartEnum_init();
	dcom_proxy_IWbemWCOSmartEnum_init();

	struct com_context *ctx = NULL;
	com_init_ctx(&ctx, NULL);
	dcom_client_init(ctx, cmdline_credentials);

	result = WBEM_ConnectServer(ctx, args.hostname, args.ns, 0, 0, 0, 0, 0, 0, &pWS);
	WERR_CHECK("Login to remote object.");

	struct IEnumWbemClassObject *pEnum = NULL;
	result = IWbemServices_ExecQuery(pWS, ctx, "WQL", args.query, WBEM_FLAG_RETURN_IMMEDIATELY | WBEM_FLAG_ENSURE_LOCATABLE, NULL, &pEnum);
	WERR_CHECK("WMI query execute.");

	IEnumWbemClassObject_Reset(pEnum, ctx);
	WERR_CHECK("Reset result of WMI query.");

	do {
		uint32_t i, j;
		struct WbemClassObject *co[cnt];

		result = IEnumWbemClassObject_SmartNext(pEnum, ctx, 0xFFFFFFFF, cnt, co, &ret);
		/* WERR_BADFUNC is OK, it means only that there is less returned objects than requested */
		if (!W_ERROR_EQUAL(result, WERR_BADFUNC)) {
			WERR_CHECK("Retrieve result data.");
		} else {
			DEBUG(1, ("OK   : Retrieved less objects than requested (it is normal).\n"));
		}
		if (!ret) break;

		for (i = 0; i < ret; ++i) {
			if (!class_name || strcmp(co[i]->obj_class->__CLASS, class_name)) {
				if (class_name) talloc_free(class_name);
				class_name = talloc_strdup(ctx, co[i]->obj_class->__CLASS);
				snprintf(buffer, 2048, "CLASS: %s\n", class_name);
				returnbuf = expand_string(returnbuf, buffer);
				for (j = 0; j < co[i]->obj_class->__PROPERTY_COUNT; ++j) {
					snprintf(buffer, 2048, "%s%s", j?args.delim:"", co[i]->obj_class->properties[j].name);
					returnbuf = expand_string(returnbuf, buffer);
				}
				snprintf(buffer, 2048, "\n");
				returnbuf = expand_string(returnbuf, buffer);
			}
			for (j = 0; j < co[i]->obj_class->__PROPERTY_COUNT; ++j) {
				char *s;
				s = string_CIMVAR(ctx, &co[i]->instance->data[j], co[i]->obj_class->properties[j].desc->cimtype & CIM_TYPEMASK);
				snprintf(buffer, 2048, "%s%s", j?args.delim:"", s);
				returnbuf = expand_string(returnbuf, buffer);
			}
			snprintf(buffer, 2048, "\n");
			returnbuf = expand_string(returnbuf, buffer);
		}
	} while (ret == cnt);
	talloc_free(ctx);
	return returnbuf;
error:
	status = werror_to_ntstatus(result);
	snprintf(buffer, 2048, "0NTSTATUS: %s - %s\n", nt_errstr(status), get_friendly_nt_error_msg(status));
	if (returnbuf) {
		free(returnbuf);
	}
	returnbuf = strdup(buffer);
	talloc_free(ctx);
	return returnbuf;
}

/*
   Net::WMIClient.xs glue code
   Copyright (C) 2012 Joshua Megerman <josh@honorablemenschen.com>

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <setjmp.h>
#include <signal.h>

char *wmic(int argc, char *argv[]);

jmp_buf jumper;
void alarm_handler(int sig) {

	longjmp(jumper, 1);

}

char *call_wmic(int timeout, int argc, AV *avref) {
	int i, len;
	char *argv[argc];
	SV **elem;

	len = av_len(avref) + 1;
	
	for(i = 0; i < len; i++) {
		elem = av_fetch(avref, i, 0);
		argv[i] = SvPV_nolen(*elem);
	}

	signal(SIGALRM, alarm_handler);
	alarm(timeout);
	if (setjmp(jumper) == 0) {
		return wmic(argc, argv);
	} else {
		return("0TIMEOUT");
	}
}


MODULE = Net::WMIClient	PACKAGE = Net::WMIClient	

PROTOTYPES: DISABLE

char *
call_wmic (timeout, argc, avref)
	int	timeout
	int	argc
	AV *	avref
