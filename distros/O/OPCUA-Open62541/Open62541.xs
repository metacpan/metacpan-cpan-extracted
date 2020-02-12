/*
 * Copyright (c) 2020 Alexander Bluhm <bluhm@genua.de>
 *
 * This is free software; you can redistribute it and/or modify it under
 * the same terms as the Perl 5 programming language system itself.
 */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <open62541/types.h>
#include <open62541/statuscodes.h>
#include <open62541/server.h>
#include <open62541/server_config_default.h>

/* #define DEBUG */
#ifdef DEBUG
# define DPRINTF(format, args...)					\
	do {								\
		fprintf(stderr, "%s: " format "\n", __func__, ##args);	\
	} while (0)
#else
# define DPRINTF(format, x...)
#endif

/* types.h */
typedef UA_Boolean		OPCUA_Open62541_Boolean;
typedef UA_SByte		OPCUA_Open62541_SByte;
typedef UA_Byte			OPCUA_Open62541_Byte;
typedef UA_Int16		OPCUA_Open62541_Int16;
typedef UA_UInt16		OPCUA_Open62541_UInt16;
typedef UA_Int32		OPCUA_Open62541_Int32;
typedef UA_UInt32		OPCUA_Open62541_UInt32;
typedef UA_Int64		OPCUA_Open62541_Int64;
typedef UA_UInt64		OPCUA_Open62541_UInt64;
typedef UA_StatusCode		OPCUA_Open62541_StatusCode;

/* server.h */
typedef UA_Server *		OPCUA_Open62541_Server;
typedef struct {
	UA_ServerConfig *	svc_serverconfig;
	SV *			svc_server;
} *				OPCUA_Open62541_ServerConfig;

/* Magic callback for UA_Server_run() will change the C variable. */
static int
server_run_mgset(pTHX_ SV* sv, MAGIC* mg)
{
	volatile OPCUA_Open62541_Boolean	*running;

	DPRINTF("sv %p, mg %p, ptr %p", sv, mg, mg->mg_ptr);
	running = (void *)mg->mg_ptr;
	*running = (bool)SvTRUE(sv);
	return 0;
}

static MGVTBL server_run_mgvtbl = { 0, server_run_mgset, 0, 0, 0, 0, 0, 0 };

/*#########################################################################*/
MODULE = OPCUA::Open62541	PACKAGE = OPCUA::Open62541

PROTOTYPES: DISABLE

OPCUA_Open62541_Boolean
TRUE()
    CODE:
	RETVAL = UA_TRUE;
    OUTPUT:
	RETVAL

OPCUA_Open62541_Boolean
FALSE()
    CODE:
	RETVAL = UA_FALSE;
    OUTPUT:
	RETVAL

OPCUA_Open62541_SByte
SBYTE_MIN()
    CODE:
	RETVAL = UA_SBYTE_MIN;
    OUTPUT:
	RETVAL

OPCUA_Open62541_SByte
SBYTE_MAX()
    CODE:
	RETVAL = UA_SBYTE_MAX;
    OUTPUT:
	RETVAL

OPCUA_Open62541_Byte
BYTE_MIN()
    CODE:
	RETVAL = UA_BYTE_MIN;
    OUTPUT:
	RETVAL

OPCUA_Open62541_Byte
BYTE_MAX()
    CODE:
	RETVAL = UA_BYTE_MAX;
    OUTPUT:
	RETVAL

OPCUA_Open62541_Int16
INT16_MIN()
    CODE:
	RETVAL = UA_INT16_MIN;
    OUTPUT:
	RETVAL

OPCUA_Open62541_Int16
INT16_MAX()
    CODE:
	RETVAL = UA_INT16_MAX;
    OUTPUT:
	RETVAL

OPCUA_Open62541_UInt16
UINT16_MIN()
    CODE:
	RETVAL = UA_UINT16_MIN;
    OUTPUT:
	RETVAL

OPCUA_Open62541_UInt16
UINT16_MAX()
    CODE:
	RETVAL = UA_UINT16_MAX;
    OUTPUT:
	RETVAL

OPCUA_Open62541_Int32
INT32_MIN()
    CODE:
	RETVAL = UA_INT32_MIN;
    OUTPUT:
	RETVAL

OPCUA_Open62541_Int32
INT32_MAX()
    CODE:
	RETVAL = UA_INT32_MAX;
    OUTPUT:
	RETVAL

OPCUA_Open62541_UInt32
UINT32_MIN()
    CODE:
	RETVAL = UA_UINT32_MIN;
    OUTPUT:
	RETVAL

OPCUA_Open62541_UInt32
UINT32_MAX()
    CODE:
	RETVAL = UA_UINT32_MAX;
    OUTPUT:
	RETVAL

OPCUA_Open62541_Int64
INT64_MIN()
    CODE:
	RETVAL = UA_INT64_MIN;
    OUTPUT:
	RETVAL

OPCUA_Open62541_Int64
INT64_MAX()
    CODE:
	RETVAL = UA_INT64_MAX;
    OUTPUT:
	RETVAL

OPCUA_Open62541_UInt64
UINT64_MIN()
    CODE:
	RETVAL = UA_UINT64_MIN;
    OUTPUT:
	RETVAL

OPCUA_Open62541_UInt64
UINT64_MAX()
    CODE:
	RETVAL = UA_UINT64_MAX;
    OUTPUT:
	RETVAL

INCLUDE: Open62541-statuscodes.xsh

#############################################################################
MODULE = OPCUA::Open62541	PACKAGE = OPCUA::Open62541::Server		PREFIX = UA_Server_

OPCUA_Open62541_Server
UA_Server_new(class)
	char *				class
    INIT:
	if (strcmp(class, "OPCUA::Open62541::Server") != 0)
		croak("class '%s' is not OPCUA::Open62541::Server", class);
    CODE:
	RETVAL = UA_Server_new();
	DPRINTF("class %s, server %p", class, RETVAL);
    OUTPUT:
	RETVAL

OPCUA_Open62541_Server
UA_Server_newWithConfig(class, config)
	char *				class
	OPCUA_Open62541_ServerConfig	config
    INIT:
	if (strcmp(class, "OPCUA::Open62541::Server") != 0)
		croak("class '%s' is not OPCUA::Open62541::Server", class);
    CODE:
	RETVAL = UA_Server_newWithConfig(config->svc_serverconfig);
	DPRINTF("class %s, config %p, server %p", class,
	    config->svc_serverconfig, RETVAL);
    OUTPUT:
	RETVAL

void
UA_Server_DESTROY(server)
	OPCUA_Open62541_Server		server
    CODE:
	DPRINTF("server %p", server);
	UA_Server_delete(server);

OPCUA_Open62541_ServerConfig
UA_Server_getConfig(server)
	OPCUA_Open62541_Server		server
    CODE:
	RETVAL = malloc(sizeof(*RETVAL));
	if (RETVAL == NULL)
		XSRETURN_UNDEF;
	RETVAL->svc_serverconfig = UA_Server_getConfig(server);
	DPRINTF("server %p, config %p", server, RETVAL->svc_serverconfig);
	if (RETVAL->svc_serverconfig == NULL) {
		free(RETVAL);
		XSRETURN_UNDEF;
	}
	/* When server gets out of scope, config still uses its memory. */
	RETVAL->svc_server = SvREFCNT_inc(SvRV(ST(0)));
    OUTPUT:
	RETVAL

OPCUA_Open62541_StatusCode
UA_Server_run(server, running)
	OPCUA_Open62541_Server		server
	OPCUA_Open62541_Boolean		&running
    INIT:
	MAGIC *mg;
    CODE:
	/* If running is changed, the magic callback will report to server. */
	mg = sv_magicext(ST(1), NULL, PERL_MAGIC_ext, &server_run_mgvtbl,
	    (void *)&running, 0);
	DPRINTF("server %p, &running %p, mg %p", server, &running, mg);
	RETVAL = UA_Server_run(server, &running);
	sv_unmagicext(ST(1), PERL_MAGIC_ext, &server_run_mgvtbl);
    OUTPUT:
	RETVAL

OPCUA_Open62541_StatusCode
UA_Server_run_startup(server)
	OPCUA_Open62541_Server		server

OPCUA_Open62541_UInt16
UA_Server_run_iterate(server, waitInternal)
	OPCUA_Open62541_Server		server
	OPCUA_Open62541_Boolean		waitInternal

OPCUA_Open62541_StatusCode
UA_Server_run_shutdown(server)
	OPCUA_Open62541_Server		server

#############################################################################
MODULE = OPCUA::Open62541	PACKAGE = OPCUA::Open62541::ServerConfig	PREFIX = UA_ServerConfig_

void
UA_ServerConfig_DESTROY(config)
	OPCUA_Open62541_ServerConfig	config
    CODE:
	DPRINTF("config %p", config->svc_serverconfig);
	SvREFCNT_dec(config->svc_server);
	free(config);

OPCUA_Open62541_StatusCode
UA_ServerConfig_setDefault(config)
	OPCUA_Open62541_ServerConfig	config
    CODE:
	DPRINTF("config %p", config->svc_serverconfig);
	RETVAL = UA_ServerConfig_setDefault(config->svc_serverconfig);
    OUTPUT:
	RETVAL
