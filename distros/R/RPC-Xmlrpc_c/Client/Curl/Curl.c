/*
  This file was NOT generated from .xs source.  (The interface is not
  simple enough for that language to be useful).

  However, we do use the xsub facilities to interface with the Perl
  interpreter.
*/

#define _BSD_SOURCE 1      /* Make sure strdup() is in string.h */
#define _XOPEN_SOURCE 500  /* Make sure strdup() is in string.h */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdbool.h>
#include <stdlib.h>
#include <string.h>

#include <xmlrpc-c/base.h>
#include <xmlrpc-c/client.h>
#include <xmlrpc-c/transport.h>



static void
strfree(const char * const string) {

    free((void*)string);
}



static bool
streq(const char * const comparand,
      const char * const comparator) {

    return (strcmp(comparand, comparator) == 0);
}



static void
returnData(const char *                     const error,
           struct xmlrpc_client_transport * const transportP,
           SV *                             const execObjR,
           SV *                             const transportOpsR,
           SV *                             const errorRetR) {

    if (SvROK(errorRetR)) {
        SV * const errorRet = SvRV(errorRetR);

        if (error)
            sv_setpv(errorRet, error);
        else
            sv_setsv(errorRet, &PL_sv_undef);
    }

    if (!error) {
        SV * const execObj      = SvRV(execObjR);
        SV * const transportOps = SvRV(transportOpsR);
    
        sv_setuv(execObj, (unsigned long)transportP);
        sv_setuv(transportOps, (unsigned long)&xmlrpc_curl_transport_ops);
    }
}



static void
fetchHvUint(HV *                     const hashP,
            const char *             const key,
            unsigned int *           const valueP) {
/*----------------------------------------------------------------------------
   Get the value of the hash member with key 'key' in the hash
   *hashP as an unsigned integer value.

   Return it as *valueP; return *valueP == 0 if there is no such
   member or its value is Perl "undefined."
-----------------------------------------------------------------------------*/
    SV ** const valueSvPP = hv_fetch(hashP, key, strlen(key), 0);
    
    if (valueSvPP == NULL)
        *valueP = 0;
    else{
        SV * const valueSvP = *valueSvPP;

        assert(valueSvP);

        if (SvOK(valueSvP)) {
            if (!looks_like_number(valueSvP))
                croak("Value of hash member '%s' is not a number", key);
            else {
                double const valueNum = SvNV(valueSvP);

                if (valueNum < 0)
                    croak("Value of hash member '%s' is negative", key);

                if ((unsigned int)valueNum != valueNum)
                    croak("Value of hash member '%s' is fractional", key);

                *valueP = (unsigned int)valueNum;
            }

        } else
            *valueP = 0;
    }
}



static void
fetchHvString(HV *          const hashP,
              const char *  const key,
              const char ** const valueP) {
/*----------------------------------------------------------------------------
   Get the value of the hash member with key 'key' in the hash
   *hashP as an ASCIIZ string.

   Return it as *valueP; return *valueP == NULL if there is no such
   member or its value is Perl "undefined."
   
   If the value is not a Perl string (and Perl can't make it one), croak.

   If the value contains a NUL character (which means it can't be
   represented as an ASCIIZ string), croak.
-----------------------------------------------------------------------------*/
    SV ** const valueSvPP = hv_fetch(hashP, key, strlen(key), 0);
             
    if (valueSvPP == NULL)
        *valueP = NULL;
    else {
        SV * const valueSvP = *valueSvPP;

        assert(valueSvP);
        
        if (SvOK(valueSvP)) {
            if (!SvPOK(valueSvP))
                croak("Value of hash member '%s' is not a string", key);
            else {
                const char * value;
                STRLEN valueLen;

                value = SvPV(valueSvP, valueLen);

                if (strlen(value) != valueLen) {
                    croak("Value of hash member '%s' contains a NUL "
                          "character (after '%s')", key, value);
                } else
                    *valueP = strdup(value);
            }
        } else
            *valueP = NULL;
    }
}



static void
fetchHvBool(HV *          const hashP,
            const char *  const key,
            xmlrpc_bool * const valueP) {
/*----------------------------------------------------------------------------
   Get the value of the hash member with key 'key' in the hash
   *hashP as a boolean value.

   Return it as *valueP; return *valueP == false if there is no such
   member or its value is Perl "undefined."
-----------------------------------------------------------------------------*/
    SV ** const valueSvPP = hv_fetch(hashP, key, strlen(key), 0);
             
    if (valueSvPP == NULL)
        *valueP = false;
    else {
        SV * const valueSvP = *valueSvPP;

        assert(valueSvP);
        
        *valueP = SvTRUE(valueSvP);
    }
}


static void
fetchHvSslversion(HV *                     const hashP,
                  const char *             const key,
                  enum xmlrpc_sslversion * const valueP) {
/*----------------------------------------------------------------------------
   Get the value of the hash member with key 'key' in the hash
   *hashP as an SSL version.

   Return it as *valueP; return *valueP == XMLRPC_SSLVERSION_DEFAULT
   if there is no such member or its value is Perl "undefined."
   
   If the value is not a Perl string (and Perl can't make it one), croak.
   If the value of the string is not a legal SSL version name, croak.
-----------------------------------------------------------------------------*/
    const char * stringValue;

    fetchHvString(hashP, key, &stringValue);

    if (stringValue) {
        if (streq(stringValue, "DEFAULT"))
            *valueP = XMLRPC_SSLVERSION_DEFAULT;
        else if (streq(stringValue, "TLSv1"))
            *valueP = XMLRPC_SSLVERSION_TLSv1;
        else if (streq(stringValue, "SSLv2"))
            *valueP = XMLRPC_SSLVERSION_SSLv2;
        else if (streq(stringValue, "SSLv3"))
            *valueP = XMLRPC_SSLVERSION_SSLv3;
        else
            croak("Invalid SSL version value '%s' for '%s' member of hash.  "
                  "Valid values are 'DEFAULT', 'TLSv1', 'SSLv2', and "
                  "SSLv3",
                  stringValue, key);

        strfree(stringValue);
    } else
        *valueP = XMLRPC_SSLVERSION_DEFAULT;
}



static void
makeXportParms(SV *                            const xportParmsR,
               struct xmlrpc_curl_xportparms * const xportParmsP,
               unsigned int *                  const parmSizeP,
               const char **                   const errorP) {
/*----------------------------------------------------------------------------
   Assuming *xportParmsR is a reference to a hash, build *xportParmsR
   from the information in the hash.  Return as *parmSizeP the size in
   bytes of the prefix of *xportParmsR that we set.

   Example: the xportParmsP->network_interface value is
   $xportParmsR->{network_interface}.

   Default the parameters that are not mentioned in the hash.
-----------------------------------------------------------------------------*/
    HV * const inHashP = (HV *)SvRV(xportParmsR);

    fetchHvString(inHashP, "network_interface",
                  &xportParmsP->network_interface);
    fetchHvBool(inHashP, "no_ssl_verifypeer",
                &xportParmsP->no_ssl_verifypeer);
    fetchHvBool(inHashP, "no_ssl_verifyhost",
                &xportParmsP->no_ssl_verifyhost);
    fetchHvString(inHashP, "user_agent",
                  &xportParmsP->user_agent);
    fetchHvString(inHashP, "ssl_cert",
                  &xportParmsP->ssl_cert);
    fetchHvString(inHashP, "sslcerttype",
                  &xportParmsP->sslcerttype);
    fetchHvString(inHashP, "sslcertpasswd",
                  &xportParmsP->sslcertpasswd);
    fetchHvString(inHashP, "sslkey",
                  &xportParmsP->sslkey);
    fetchHvString(inHashP, "sslkeytype",
                  &xportParmsP->sslkeytype);
    fetchHvString(inHashP, "sslkeypasswd",
                  &xportParmsP->sslkeypasswd);
    fetchHvString(inHashP, "sslengine",
                  &xportParmsP->sslengine);
    fetchHvBool(inHashP, "sslengine_default",
                &xportParmsP->sslengine_default);
    fetchHvSslversion(inHashP, "sslversion",
                      &xportParmsP->sslversion);
    fetchHvString(inHashP, "cainfo",
                  &xportParmsP->cainfo);
    fetchHvString(inHashP, "capath",
                  &xportParmsP->capath);
    fetchHvString(inHashP, "randomfile",
                  &xportParmsP->randomfile);
    fetchHvString(inHashP, "egdsocket",
                  &xportParmsP->egdsocket);
    fetchHvString(inHashP, "ssl_cipher_list",
                  &xportParmsP->ssl_cipher_list);
    fetchHvUint(inHashP, "timeout", 
                &xportParmsP->timeout);

    *parmSizeP = XMLRPC_CXPSIZE(timeout);
    *errorP = NULL;
}



static void
unmakeXportParms(struct xmlrpc_curl_xportparms const xportParms) {

    if (xportParms.network_interface)
        strfree(xportParms.network_interface);
    if (xportParms.user_agent)
        strfree(xportParms.user_agent);
    if (xportParms.ssl_cert)
        strfree(xportParms.ssl_cert);
    if (xportParms.sslcerttype)
        strfree(xportParms.sslcerttype);
    if (xportParms.sslcertpasswd)
        strfree(xportParms.sslcertpasswd);
    if (xportParms.sslkey)
        strfree(xportParms.sslkey);
    if (xportParms.sslkeytype)
        strfree(xportParms.sslkeytype);
    if (xportParms.sslkeypasswd)
        strfree(xportParms.sslkeypasswd);
    if (xportParms.sslengine)
        strfree(xportParms.sslengine);
    if (xportParms.cainfo)
        strfree(xportParms.cainfo);
    if (xportParms.capath)
        strfree(xportParms.capath);
    if (xportParms.randomfile)
        strfree(xportParms.randomfile);
    if (xportParms.egdsocket)
        strfree(xportParms.egdsocket);
    if (xportParms.ssl_cipher_list)
        strfree(xportParms.ssl_cipher_list);
}



XS(XS_RPC__Xmlrpc_c__Client__Curl__transportCreate);
XS(XS_RPC__Xmlrpc_c__Client__Curl__transportCreate) {

    dXSARGS;

    if (items != 4)
        Perl_croak(aTHX_ "_transportCreate() called with %u arguments; "
                   "expected 4.", items);
    else {
        SV * const xportParmsR   = ST(0);
        SV * const execObjR      = ST(1);
        SV * const transportOpsR = ST(2);
        SV * const errorRetR     = ST(3);

        struct xmlrpc_client_transport * transportP;
        const char * error;
        xmlrpc_env env;

        if (!SvROK(xportParmsR))
            error = "Transport parameter argument is not a reference";
        else if (SvTYPE(SvRV(xportParmsR)) != SVt_PVHV)
            error = "Transport parameter argument is reference to something "
                    "other than a hash";
        else if (!SvROK(execObjR))
            error = "executable object argument is not a reference";
        else if (!SvROK(transportOpsR))
            error = "transport ops argument is not a reference";
        else
            error = NULL;

        if (!error) {
            struct xmlrpc_curl_xportparms xportParms;
            unsigned int xportParmSize;
            makeXportParms(xportParmsR, &xportParms, &xportParmSize, &error);

            if (!error) {
                xmlrpc_env_init(&env);

                xmlrpc_curl_transport_ops.create(
                    &env, 0, "", "", (struct xmlrpc_xportparms *)&xportParms,
                    xportParmSize,
                    &transportP);

                if (env.fault_occurred)
                    error = env.fault_string;

                xmlrpc_env_clean(&env);

                unmakeXportParms(xportParms);
            }
        }
        returnData(error, transportP, execObjR, transportOpsR, errorRetR);
    }
    XSRETURN_EMPTY;
}



XS(XS_RPC__Xmlrpc_c__Client__Curl__transportDestroy);

XS(XS_RPC__Xmlrpc_c__Client__Curl__transportDestroy) {

    dXSARGS;

    if (items != 1)
        Perl_croak(aTHX_ "_transportDestroy() called with %u arguments; "
                   "expected 1.", items);
    else {
        unsigned long const _transport = SvUV(ST(0));

        struct xmlrpc_client_transport * const transportP =
            (struct xmlrpc_client_transport *)_transport;

        xmlrpc_curl_transport_ops.destroy(transportP);
    }
    XSRETURN_EMPTY;
}



XS(boot_RPC__Xmlrpc_c__Client__Curl);

XS(boot_RPC__Xmlrpc_c__Client__Curl) {

    dXSARGS;

    char * const file = __FILE__;

    XS_VERSION_BOOTCHECK;

    newXSproto("RPC::Xmlrpc_c::Client::Curl::_transportCreate",
               XS_RPC__Xmlrpc_c__Client__Curl__transportCreate, file, "$$$$");

    newXSproto("RPC::Xmlrpc_c::Client::Curl::_transportDestroy",
               XS_RPC__Xmlrpc_c__Client__Curl__transportDestroy, file, "$");

    XSRETURN_YES;
}

