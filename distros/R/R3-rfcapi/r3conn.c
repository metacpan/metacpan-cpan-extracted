/*
	r3conn.c
	Copyright (c) 1999 Johan Schoen. All rights reserved.

	revision history:

	0.01	1999-03-22	schoen
		created first version

	0.20	1999-10-28	schoen
		last changes before first upload to CPAN

	0.30	1999-11-05	schoen
		added support for R/3 pre 40A
*/

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <saprfc.h>
#include "r3rfc.h"

H_R3RFC_CONN r3_new_conn(char * client,
			char * user,
			char * password,
			char * language,
			char * hostname,
			int sysnr,
			char * gwhost,
			char * gwservice,
			int trace)
{
	static RFC_HANDLE hRfc;
	static RFC_OPTIONS RfcOptions;
	static RFC_CONNOPT_R3ONLY RfcConnoptR3only;
	static H_R3RFC_CONN h;

	memset(&RfcOptions, 0, sizeof(RFC_OPTIONS));
	memset(&RfcConnoptR3only, 0, sizeof(RFC_CONNOPT_R3ONLY));
	RfcOptions.client = client;
  	RfcOptions.user = user;
  	RfcOptions.password = password;
  	RfcOptions.language = language;
	RfcOptions.mode = RFC_MODE_R3ONLY;
	if (hostname != NULL && hostname[0] == 0)
    		RfcConnoptR3only.hostname = NULL;
	else 
		RfcConnoptR3only.hostname = hostname;
	RfcConnoptR3only.sysnr = sysnr;
	if (gwhost != NULL && gwhost[0] == 0)
		RfcConnoptR3only.gateway_host = NULL;
	else 
		RfcConnoptR3only.gateway_host = gwhost;
	if (gwservice != NULL && gwservice[0] == 0) 
		RfcConnoptR3only.gateway_service = NULL;
	else
		RfcConnoptR3only.gateway_service = gwservice;
	RfcOptions.connopt = &RfcConnoptR3only;
	RfcOptions.trace = trace;
	hRfc = RfcOpen(&RfcOptions); 
	if (hRfc==RFC_HANDLE_NULL)
	{
		r3_set_rfcapi_exception("RFC_HANDLE_NULL");
		return NULL;
	}
	h = malloc(sizeof(R3RFC_CONN));
	if (h)
	{
		memset(h, 0, sizeof(R3RFC_CONN));
		h->h_rfc=hRfc;
	}	
	else
	{
		r3_set_rfcapi_exception("MALLOC_FAILED");
		return NULL;
	}
	return h;
}

void r3_del_conn(H_R3RFC_CONN h)
{
	RfcClose(h->h_rfc);
	free(h);
}

void r3_set_pre4(H_R3RFC_CONN h)
{
	h->pre4=1;
}

/* EOF r3conn.c */
