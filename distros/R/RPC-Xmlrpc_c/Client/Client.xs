#include <stdbool.h>
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <xmlrpc-c/base.h>
#include <xmlrpc-c/util.h>
#include <xmlrpc-c/client.h>

static void
returnCreateData(xmlrpc_env      const env,
                 xmlrpc_client * const clientP,
                 SV *            const execObjR,
                 SV *            const errorRetR) {

    if (SvROK(errorRetR)) {
        SV * const errorRet = SvRV(errorRetR);

        if (env.fault_occurred)
            sv_setpv(errorRet, env.fault_string);
        else
            sv_setsv(errorRet, &PL_sv_undef);
    }

    if (!env.fault_occurred) {
        SV * const execObj      = SvRV(execObjR);
    
        sv_setuv(execObj, (unsigned long)clientP);
    }
}



static void
returnCallData(xmlrpc_env     const env,
               xmlrpc_value * const resultP,
               SV *           const resultR,
               SV *           const errorRetR) {

    if (SvROK(errorRetR)) {
        SV * const errorRet = SvRV(errorRetR);

        if (env.fault_occurred)
            sv_setpv(errorRet, env.fault_string);
        else
            sv_setsv(errorRet, &PL_sv_undef);
    }

    if (!env.fault_occurred) {
        SV * const result = SvRV(resultR);
    
        sv_setuv(result, (unsigned long)resultP);
    }
}



static void
returnCallXmlData(xmlrpc_env         const env,
                  xmlrpc_mem_block * const xmlP,
                  SV *               const xmlR,
                  SV *               const errorRetR) {

    if (SvROK(errorRetR)) {
        SV * const errorRet = SvRV(errorRetR);

        if (env.fault_occurred)
            sv_setpv(errorRet, env.fault_string);
        else
            sv_setsv(errorRet, &PL_sv_undef);
    }

    if (!env.fault_occurred) {
        SV * const xml = SvRV(xmlR);

        xmlrpc_env env;

        xmlrpc_env_init(&env);

        XMLRPC_TYPED_MEM_BLOCK_APPEND(char, &env, xmlP, "\0", 1);

        sv_setpv(xml, XMLRPC_TYPED_MEM_BLOCK_CONTENTS(char, xmlP));

        xmlrpc_env_clean(&env);
    }
}



MODULE = RPC::Xmlrpc_c::Client PACKAGE = RPC::Xmlrpc_c::Client
PROTOTYPES: ENABLE



void
_client_setup_global_const(errorRetR)

    SV * errorRetR;

    CODE:
    {
        if (!SvROK(errorRetR))
            XSRETURN_EMPTY;
        else {
            SV * const errorRet = SvRV(errorRetR);

            xmlrpc_env env;

            xmlrpc_env_init(&env);

            xmlrpc_client_setup_global_const(&env);

            if (env.fault_occurred)
                sv_setpv(errorRet, env.fault_string);
            else
                sv_setsv(errorRet, &PL_sv_undef);

            xmlrpc_env_clean(&env);
        }
    }


void
_clientCreate(_transportOps, _transport, execObjR, errorRetR)

    unsigned long _transportOps;
    unsigned long _transport;
    SV * execObjR;
    SV * errorRetR;

    CODE:
    {
        xmlrpc_client * clientP;
        xmlrpc_env env;
            
        xmlrpc_env_init(&env);

        if (!SvROK(execObjR))
            xmlrpc_faultf(&env,
                          "executable object argument is not a reference");

        if (!env.fault_occurred) {
            struct xmlrpc_client_transport_ops * const transportOpsP =
                (struct xmlrpc_client_transport_ops *) _transportOps;
            struct xmlrpc_client_transport * const transportP =
                (struct xmlrpc_client_transport *) _transport;

            struct xmlrpc_clientparms clientParms;

            clientParms.transport          = NULL;
            clientParms.transportparmsP    = NULL;
            clientParms.transportparm_size = 0;
            clientParms.transportOpsP      = transportOpsP;
            clientParms.transportP         = transportP;
 
            xmlrpc_client_create(&env, 0, "", "",
                                 &clientParms, XMLRPC_CPSIZE(transportP),
                                 &clientP);
        }
        returnCreateData(env, clientP, execObjR, errorRetR);

        xmlrpc_env_clean(&env);
    }



void
_clientDestroy(_client)
    unsigned long _client;
    CODE:
    {
        xmlrpc_client * const clientP = (xmlrpc_client *)_client;
        xmlrpc_client_destroy(clientP);
    }


void
_clientCall(_client, serverUrl, methodName, _paramArray, resultR, errorRetR)

    unsigned long _client;
    const char * serverUrl;
    const char * methodName;
    unsigned long _paramArray;
    SV * resultR;
    SV * errorRetR;

    CODE:
    {
        xmlrpc_client * const clientP      = (xmlrpc_client *)_client;
        xmlrpc_value *  const paramArrayP  = (xmlrpc_value *)_paramArray;
        xmlrpc_value * resultP;

        xmlrpc_server_info * serverInfoP;
        xmlrpc_env env;
        
        XMLRPC_ASSERT_ARRAY_OK(paramArrayP);

        xmlrpc_env_init(&env);
        
        serverInfoP = xmlrpc_server_info_new(&env, serverUrl);
        
        if (!env.fault_occurred) {
            xmlrpc_client_call2(&env, clientP, serverInfoP, methodName,
                                paramArrayP, &resultP);

            xmlrpc_server_info_free(serverInfoP);
        }

        returnCallData(env, resultP, resultR, errorRetR);

        xmlrpc_env_clean(&env);
    }



void
_callXml(methodName, _paramArray, xmlR, errorRetR)

    const char * methodName;
    unsigned long _paramArray;
    SV * xmlR;
    SV * errorRetR;

    CODE:
    {
        xmlrpc_value *  const paramArrayP  = (xmlrpc_value *)_paramArray;

        xmlrpc_env env;

        xmlrpc_mem_block output;

        XMLRPC_ASSERT_ARRAY_OK(paramArrayP);

        xmlrpc_env_init(&env);

        XMLRPC_TYPED_MEM_BLOCK_INIT(char, &env, &output, 0);

        xmlrpc_serialize_call(&env, &output, methodName, paramArrayP);

        returnCallXmlData(env, &output, xmlR, errorRetR);

        XMLRPC_TYPED_MEM_BLOCK_CLEAN(char, &output);  

        xmlrpc_env_clean(&env);
    }


