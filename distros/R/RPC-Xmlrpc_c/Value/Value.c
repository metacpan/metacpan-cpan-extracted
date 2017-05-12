/*
  This file was NOT generated from .xs source.  (The interface is not
  simple enough for that language to be useful).

  However, we do use the xsub facilities to interface with the Perl
  interpreter.
*/

#include <stdbool.h>
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <xmlrpc-c/base.h>


static void
strfree(const char * const arg) {

    free((char *)arg);
}



static void
returnError(const char * const error,
            SV *         const errorR) {

    if (SvROK(errorR)) {
        SV * const errorSV = SvRV(errorR);

        if (error)
            sv_setpv(errorSV, error);
        else
            sv_setsv(errorSV, &PL_sv_undef);
    }
}



XS(XS_RPC__Xmlrpc_c__Value__valueIntCreate);

XS(XS_RPC__Xmlrpc_c__Value__valueIntCreate) {

    dXSARGS;

    if (items != 3)
        Perl_croak(aTHX_ "_valueIntCreate() called with %u arguments; "
                   "expected 3.", items);

    else {
        int  const value    = SvIV(ST(0));
        SV * const execObjR = ST(1);
        SV * const errorR   = ST(2);

        const char * error;
        xmlrpc_env env;

        xmlrpc_env_init(&env);

        if (!SvROK(execObjR))
            error = "executable object parameter is not a reference";
        else
            error = NULL;

        if (!error) {
            xmlrpc_value * valueP;

            valueP = xmlrpc_int_new(&env, value);

            if (env.fault_occurred)
                error = env.fault_string;
            else
                sv_setuv(SvRV(execObjR), (unsigned long)valueP);
        }
        returnError(error, errorR);

        xmlrpc_env_clean(&env);
    }
    XSRETURN_EMPTY;
}



XS(XS_RPC__Xmlrpc_c__Value__valueBoolCreate);

XS(XS_RPC__Xmlrpc_c__Value__valueBoolCreate) {

    dXSARGS;

    if (items != 3)
        Perl_croak(aTHX_ "_valueBoolCreate() called with %u arguments; "
                   "expected 3", items);
    else {
        xmlrpc_bool const value    = (SvIV(ST(0)) != 0);
        SV *        const execObjR = ST(1);
        SV *        const errorR   = ST(2);

        const char * error;
        xmlrpc_env env;

        xmlrpc_env_init(&env);

        if (!SvROK(execObjR))
            error = "executable object parameter is not a reference";
        else
            error = NULL;

        if (!error) {
            xmlrpc_value * valueP;

            valueP = xmlrpc_bool_new(&env, value);

            if (env.fault_occurred)
                error = env.fault_string;
            else
                sv_setuv(SvRV(execObjR), (unsigned long)valueP);
        }
        returnError(error, errorR);

        xmlrpc_env_clean(&env);
    }
    XSRETURN_EMPTY;
}



XS(XS_RPC__Xmlrpc_c__Value__valueDoubleCreate);

XS(XS_RPC__Xmlrpc_c__Value__valueDoubleCreate) {

    dXSARGS;

    if (items != 3)
        Perl_croak(aTHX_ "_valueDoubleCreate() called with %u arguments; "
                   "expected 3", items);
    else {
        double const value    = SvNV(ST(0));
        SV *   const execObjR = ST(1);
        SV *   const errorR   = ST(2);

        const char * error;
        xmlrpc_env env;

        xmlrpc_env_init(&env);

        if (!SvROK(execObjR))
            error = "executable object parameter is not a reference";
        else
            error = NULL;

        if (!error) {
            xmlrpc_value * valueP;

            valueP = xmlrpc_double_new(&env, value);

            if (env.fault_occurred)
                error = env.fault_string;
            else
                sv_setuv(SvRV(execObjR), (unsigned long)valueP);
        }
        returnError(error, errorR);

        xmlrpc_env_clean(&env);
    }
    XSRETURN_EMPTY;
}



XS(XS_RPC__Xmlrpc_c__Value__valueDatetimeCreate);

XS(XS_RPC__Xmlrpc_c__Value__valueDatetimeCreate) {

    dXSARGS;

    if (items != 3)
        Perl_croak(aTHX_ "_valueDatetimeCreate() called with %u arguments; "
                   "expected 3", items);
    else {
        time_t const value    = (time_t)SvIV(ST(0));
        SV *   const execObjR = ST(1);
        SV *   const errorR   = ST(2);

        const char * error;
        xmlrpc_env env;

        xmlrpc_env_init(&env);

        if (!SvROK(execObjR))
            error = "executable object parameter is not a reference";
        else
            error = NULL;

        if (!error) {
            xmlrpc_value * valueP;

            valueP = xmlrpc_datetime_new_sec(&env, value);

            if (env.fault_occurred)
                error = env.fault_string;
            else
                sv_setuv(SvRV(execObjR), (unsigned long)valueP);
        }
        returnError(error, errorR);

        xmlrpc_env_clean(&env);
    }
    XSRETURN_EMPTY;
}



static STRLEN
pvLen(SV * const svP) {

    STRLEN retval;

    SvPV(svP, retval);

    return retval;
}



XS(XS_RPC__Xmlrpc_c__Value__valueStringCreate);

XS(XS_RPC__Xmlrpc_c__Value__valueStringCreate) {

    dXSARGS;

    if (items != 3)
        Perl_croak(aTHX_ "_valueStringCreate() called with %u arguments; "
                   "expected 3", items);
    else {
        const char * const value    = SvPV_nolen(ST(0));
        STRLEN       const valueLen = pvLen(ST(0));
        SV *         const execObjR = ST(1);
        SV *         const errorR   = ST(2);

        const char * error;
        xmlrpc_env env;

        xmlrpc_env_init(&env);

        if (!SvROK(execObjR))
            error = "executable object parameter is not a reference";
        else
            error = NULL;

        if (!error) {
            xmlrpc_value * valueP;

            valueP = xmlrpc_string_new_lp(&env, valueLen, value);

            if (env.fault_occurred)
                error = env.fault_string;
            else
                sv_setuv(SvRV(execObjR), (unsigned long)valueP);
        }
        returnError(error, errorR);

        xmlrpc_env_clean(&env);
    }
    XSRETURN_EMPTY;
}



XS(XS_RPC__Xmlrpc_c__Value__valueBytestringCreate);

XS(XS_RPC__Xmlrpc_c__Value__valueBytestringCreate) {

    dXSARGS;

    if (items != 3)
        Perl_croak(aTHX_ "_valueBytestringCreate() called with %u arguments; "
                   "expected 3", items);
    else {
        const unsigned char * const value    = SvPV_nolen(ST(0));
        STRLEN                const valueLen = pvLen(ST(0));
        SV *                  const execObjR = ST(1);
        SV *                  const errorR   = ST(2);

        const char * error;
        xmlrpc_env env;

        xmlrpc_env_init(&env);

        if (!SvROK(execObjR))
            error = "executable object parameter is not a reference";
        else
            error = NULL;

        if (!error) {
            xmlrpc_value * valueP;

            valueP = xmlrpc_base64_new(&env, valueLen, value);

            if (env.fault_occurred)
                error = env.fault_string;
            else
                sv_setuv(SvRV(execObjR), (unsigned long)valueP);
        }
        returnError(error, errorR);

        xmlrpc_env_clean(&env);
    }
    XSRETURN_EMPTY;
}



XS(XS_RPC__Xmlrpc_c__Value__valueArrayCreateEmpty);

XS(XS_RPC__Xmlrpc_c__Value__valueArrayCreateEmpty) {

    dXSARGS;

    if (items != 2)
        Perl_croak(aTHX_ "_valueArrayCreateEmpty() called with %u arguments; "
                   "expected 2", items);
    else {
        SV * const execObjR = ST(0);
        SV * const errorR   = ST(1);

        const char * error;
        xmlrpc_env env;

        xmlrpc_env_init(&env);

        if (!SvROK(execObjR))
            error = "executable object parameter is not a reference";
        else
            error = NULL;

        if (!error) {
            xmlrpc_value * valueP;

            valueP = xmlrpc_array_new(&env);

            if (env.fault_occurred)
                error = env.fault_string;
            else
                sv_setuv(SvRV(execObjR), (unsigned long)valueP);
        }
        returnError(error, errorR);

        xmlrpc_env_clean(&env);
    }
    XSRETURN_EMPTY;
}



XS(XS_RPC__Xmlrpc_c__Value__arrayAppendItem);

XS(XS_RPC__Xmlrpc_c__Value__arrayAppendItem) {

    dXSARGS;

    if (items != 3)
        Perl_croak(aTHX_ "_arrayAppendItem() called with %u arguments; "
                   "expected 3", items);
    else {
        xmlrpc_value * const arrayP   = (xmlrpc_value *) SvUV(ST(0));
        xmlrpc_value * const newItemP = (xmlrpc_value *) SvUV(ST(1));
        SV *           const errorR   = ST(2);

        const char * error;
        xmlrpc_env env;

        xmlrpc_env_init(&env);

        xmlrpc_array_append_item(&env, arrayP, newItemP);

        if (env.fault_occurred)
            error = env.fault_string;
        else
            error = NULL;

        returnError(error, errorR);

        xmlrpc_env_clean(&env);
    }
    XSRETURN_EMPTY;
}



XS(XS_RPC__Xmlrpc_c__Value__valueStructCreateEmpty);

XS(XS_RPC__Xmlrpc_c__Value__valueStructCreateEmpty) {

    dXSARGS;

    if (items != 2)
        Perl_croak(aTHX_ "_valueStructCreateEmpty() called with %u arguments; "
                   "expected 2", items);
    else {
        SV * const execObjR = ST(0);
        SV * const errorR   = ST(1);

        const char * error;
        xmlrpc_env env;

        xmlrpc_env_init(&env);

        if (!SvROK(execObjR))
            error = "executable object parameter is not a reference";
        else
            error = NULL;

        if (!error) {
            xmlrpc_value * valueP;

            valueP = xmlrpc_struct_new(&env);

            if (env.fault_occurred)
                error = env.fault_string;
            else
                sv_setuv(SvRV(execObjR), (unsigned long)valueP);
        }
        returnError(error, errorR);

        xmlrpc_env_clean(&env);
    }
    XSRETURN_EMPTY;
}



XS(XS_RPC__Xmlrpc_c__Value__structSetValue);

XS(XS_RPC__Xmlrpc_c__Value__structSetValue) {

    dXSARGS;

    if (items != 4)
        Perl_croak(aTHX_ "_structSetValue() called with %u arguments; "
                   "expected 4", items);
    else {
        xmlrpc_value * const structP    = (xmlrpc_value *) SvUV(ST(0));
        const char *   const hashKey    = SvPV_nolen(ST(1));
        xmlrpc_value * const hashValueP = (xmlrpc_value *) SvUV(ST(2));
        SV *           const errorR     = ST(3);

        const char * error;
        xmlrpc_env env;

        xmlrpc_env_init(&env);

        xmlrpc_struct_set_value(&env, structP, hashKey, hashValueP);

        if (env.fault_occurred)
            error = env.fault_string;
        else
            error = NULL;

        returnError(error, errorR);

        xmlrpc_env_clean(&env);
    }
    XSRETURN_EMPTY;
}



XS(XS_RPC__Xmlrpc_c__Value__valueNilCreate);

XS(XS_RPC__Xmlrpc_c__Value__valueNilCreate) {

    dXSARGS;

    if (items != 2)
        Perl_croak(aTHX_ "_valueNilCreate() called with %u arguments; "
                   "expected 2", items);
    else {
        SV * const execObjR = ST(0);
        SV * const errorR   = ST(1);

        const char * error;
        xmlrpc_env env;

        xmlrpc_env_init(&env);

        if (!SvROK(execObjR))
            error = "executable object parameter is not a reference";
        else
            error = NULL;

        if (!error) {
            xmlrpc_value * valueP;

            valueP = xmlrpc_nil_new(&env);

            if (env.fault_occurred)
                error = env.fault_string;
            else
                sv_setuv(SvRV(execObjR), (unsigned long)valueP);
        }
        returnError(error, errorR);

        xmlrpc_env_clean(&env);
    }
    XSRETURN_EMPTY;
}



XS(XS_RPC__Xmlrpc_c__Value__valueI8Create);

XS(XS_RPC__Xmlrpc_c__Value__valueI8Create) {

    dXSARGS;

    if (items != 3)
        Perl_croak(aTHX_ "_valueI8Create() called with %u arguments; "
                   "expected 3.", items);

    else {
        long long const value    = SvIV(ST(0));
        SV *      const execObjR = ST(1);
        SV *      const errorR   = ST(2);

        const char * error;
        xmlrpc_env env;

        xmlrpc_env_init(&env);

        if (!SvROK(execObjR))
            error = "executable object parameter is not a reference";
        else
            error = NULL;

        if (!error) {
            xmlrpc_value * valueP;

            valueP = xmlrpc_i8_new(&env, value);

            if (env.fault_occurred)
                error = env.fault_string;
            else
                sv_setuv(SvRV(execObjR), (unsigned long)valueP);
        }
        returnError(error, errorR);

        xmlrpc_env_clean(&env);
    }
    XSRETURN_EMPTY;
}



XS(XS_RPC__Xmlrpc_c__Value__valueDestroy);

XS(XS_RPC__Xmlrpc_c__Value__valueDestroy) {

    dXSARGS;

    if (items != 1)
        Perl_croak(aTHX_ "_valueDestroy() called with %u arguments; "
                   "expected 1", items);
    else {
        xmlrpc_value * const valueP = (xmlrpc_value *) SvUV(ST(0));

        xmlrpc_DECREF(valueP);
    }
    XSRETURN_EMPTY;
}



XS(XS_RPC__Xmlrpc_c__Value__type);

XS(XS_RPC__Xmlrpc_c__Value__type) {

    dXSARGS;
    dXSTARG;

    if (items != 1)
        Perl_croak(aTHX_ "_type() called with %u arguments; expected 1",
                   items);
    else {
        xmlrpc_value * const valueP = (xmlrpc_value *) SvUV(ST(0));

        const char * retval;

        retval = NULL;  /* Stifle compile warning */
            
        switch (xmlrpc_value_type(valueP)) {
        case XMLRPC_TYPE_INT:      retval = "int";        break;
        case XMLRPC_TYPE_BOOL:     retval = "bool";       break;
        case XMLRPC_TYPE_DOUBLE:   retval = "double";     break;
        case XMLRPC_TYPE_DATETIME: retval = "datetime";   break;
        case XMLRPC_TYPE_STRING:   retval = "string";     break;
        case XMLRPC_TYPE_BASE64:   retval = "bytestring"; break;
        case XMLRPC_TYPE_ARRAY:    retval = "array";      break;
        case XMLRPC_TYPE_STRUCT:   retval = "struct";     break;
        case XMLRPC_TYPE_NIL:      retval = "nil";        break;
        case XMLRPC_TYPE_I8:       retval = "i8";         break;
        case XMLRPC_TYPE_C_PTR:
        case XMLRPC_TYPE_DEAD:
            assert(0);  /* We don't create values of these types */
        }
        sv_setpv(TARG, retval); XSprePUSH; PUSHTARG;
    }
    XSRETURN(1);
}



XS(XS_RPC__Xmlrpc_c__Value__valueInt);

XS(XS_RPC__Xmlrpc_c__Value__valueInt) {

    dXSARGS;
    dXSTARG;

    if (items != 1)
        Perl_croak(aTHX_ "_valueInt() called with %u arguments; expected 1",
                   items);
    else {
        xmlrpc_value * const valueP = (xmlrpc_value *) SvUV(ST(0));

        int retval;

        xmlrpc_env env;

        xmlrpc_env_init(&env);

        xmlrpc_read_int(&env, valueP, &retval);

        if (env.fault_occurred)
            croak("xmlrpc_read_int() failed!");
        
        xmlrpc_env_clean(&env);

        sv_setiv(TARG, retval); XSprePUSH; PUSHTARG;
    }
    XSRETURN(1);
}



XS(XS_RPC__Xmlrpc_c__Value__valueBool);

XS(XS_RPC__Xmlrpc_c__Value__valueBool) {

    dXSARGS;
    dXSTARG;

    if (items != 1)
        Perl_croak(aTHX_ "_valueBool() called with %u arguments; expected 1",
                   items);
    else {
        xmlrpc_value * const valueP = (xmlrpc_value *) SvUV(ST(0));
        
        xmlrpc_bool retval;

        xmlrpc_env env;

        xmlrpc_env_init(&env);

        xmlrpc_read_bool(&env, valueP, &retval);

        if (env.fault_occurred)
            croak("xmlrpc_read_bool() failed!");
        
        xmlrpc_env_clean(&env);

        sv_setiv(TARG, retval); XSprePUSH; PUSHTARG;
    }
    XSRETURN(1);
}



XS(XS_RPC__Xmlrpc_c__Value__valueDouble);

XS(XS_RPC__Xmlrpc_c__Value__valueDouble) {

    dXSARGS;
    dXSTARG;

    if (items != 1)
        Perl_croak(aTHX_ "_valueDouble() called with %u arguments; "
                   "expected 1", items);
    else {
        xmlrpc_value * const valueP = (xmlrpc_value *) SvUV(ST(0));
        
        double retval;

        xmlrpc_env env;

        xmlrpc_env_init(&env);

        xmlrpc_read_double(&env, valueP, &retval);

        if (env.fault_occurred)
            croak("xmlrpc_read_double() failed!");
        
        xmlrpc_env_clean(&env);

        sv_setnv(TARG, retval); XSprePUSH; PUSHTARG;
    }
    XSRETURN(1);
}



XS(XS_RPC__Xmlrpc_c__Value__valueDatetime);

XS(XS_RPC__Xmlrpc_c__Value__valueDatetime) {

    dXSARGS;
    dXSTARG;

    if (items != 1)
        Perl_croak(aTHX_ "_valueDatetime() called with %u arguments; "
                   "expected 1", items);
    else {
        xmlrpc_value * const valueP = (xmlrpc_value *) SvUV(ST(0));
        
        time_t retval;

        xmlrpc_env env;

        xmlrpc_env_init(&env);

        xmlrpc_read_datetime_sec(&env, valueP, &retval);

        if (env.fault_occurred)
            croak("xmlrpc_read_datetime() failed!");
        
        xmlrpc_env_clean(&env);

        sv_setiv(TARG, retval); XSprePUSH; PUSHTARG;
    }
    XSRETURN(1);
}



XS(XS_RPC__Xmlrpc_c__Value__valueString);

XS(XS_RPC__Xmlrpc_c__Value__valueString) {

    dXSARGS;
    dXSTARG;

    if (items != 1)
        Perl_croak(aTHX_ "_valueString() called with %u arguments; "
                   "expected 1", items);
    else {
        xmlrpc_value * const valueP = (xmlrpc_value *) SvUV(ST(0));
        
        const char * stringValue;
        size_t       stringLength;

        xmlrpc_env env;

        xmlrpc_env_init(&env);

        xmlrpc_read_string_lp(&env, valueP, &stringLength, &stringValue);

        if (env.fault_occurred)
            croak("xmlrpc_read_string_lp() failed!");
        
        xmlrpc_env_clean(&env);

        sv_setpvn(TARG, stringValue, stringLength); XSprePUSH; PUSHTARG;

        strfree(stringValue);
    }
    XSRETURN(1);
}



XS(XS_RPC__Xmlrpc_c__Value__valueBytestring);

XS(XS_RPC__Xmlrpc_c__Value__valueBytestring) {

    dXSARGS;
    dXSTARG;

    if (items != 1)
        Perl_croak(aTHX_ "_valueBytestring() called with %u arguments; "
                   "expected 1", items);
    else {
        xmlrpc_value * const valueP = (xmlrpc_value *) SvUV(ST(0));
        
        const unsigned char * bsValue;
        size_t                bsLength;

        xmlrpc_env env;

        xmlrpc_env_init(&env);

        xmlrpc_read_base64(&env, valueP, &bsLength, &bsValue);

        if (env.fault_occurred)
            croak("xmlrpc_read_base64() failed!");
        
        xmlrpc_env_clean(&env);

        sv_setpvn(TARG, bsValue, bsLength); XSprePUSH; PUSHTARG;

        free((unsigned char *)bsValue);
    }
    XSRETURN(1);
}



static void
getItemHandles(xmlrpc_value * const arrayP,
               unsigned int * const arraySizeP,
               SV ***         const handlesP) {
/*----------------------------------------------------------------------------
   Make a C array of SV's, each one being a handle to an executable
   XML_RPC value which is an item from the array *arrayP.

   The array is in newly malloc'ed storage; all the SVs are new.
-----------------------------------------------------------------------------*/
    unsigned int arraySize;
    xmlrpc_env env;

    xmlrpc_env_init(&env);

    arraySize = xmlrpc_array_size(&env, arrayP);

    if (env.fault_occurred)
        croak("xmlrpc_array_size() failed!");
    else {
        SV ** handles;
        unsigned int i;
        
        handles = malloc(arraySize * sizeof(handles[0]));
        
        if (handles == NULL)
            croak("Unable to allocate array");
        
        for (i = 0; i < arraySize; ++i) {
            xmlrpc_value * itemP;
            xmlrpc_array_read_item(&env, arrayP, i, &itemP);
            
            if (env.fault_occurred)
                croak("Failed to read item from XML-RPC value array");

            handles[i] = newSViv((unsigned long)itemP);
            
            /* The reference to *itemP we got above now becomes the 
               reference from handles[]
            */
        }
        *arraySizeP = arraySize;
        *handlesP = handles;
    }
    xmlrpc_env_clean(&env);
}



static void
freeItemHandles(SV **        const handles,
                unsigned int const arraySize) {
    
    unsigned int i;

    for (i = 0; i < arraySize; ++i)
        SvREFCNT_dec(handles[i]);

        /* Note that we do not release the xmlrpc_value handle which
           handles[i] holds.  Caller transferred that handle to someone else.
        */
    
    free(handles);
}    



XS(XS_RPC__Xmlrpc_c__Value__valueArray);

XS(XS_RPC__Xmlrpc_c__Value__valueArray) {

    dXSARGS;
    dXSTARG;

    if (items != 1)
        Perl_croak(aTHX_ "_valueArray() called with %u arguments; "
                   "expected 1", items);
    else {
        xmlrpc_value * const arrayP = (xmlrpc_value *) SvUV(ST(0));
        
        SV ** itemHandles;
        unsigned int arraySize;
        AV * perlArray;
        SV * retval;  /* A reference to 'perlArray' */

        getItemHandles(arrayP, &arraySize, &itemHandles);

        perlArray = av_make(arraySize, itemHandles);

        /* The references from itemHandles to the various xmlrpc_values
           are now the references from 'perlArray'.
        */

        freeItemHandles(itemHandles, arraySize);

        retval = newRV_noinc((SV *)perlArray);

        sv_setsv(TARG, retval); XSprePUSH; PUSHTARG;
        
        SvREFCNT_dec(retval);
    }
    XSRETURN(1);
}



static void
addStructMemberToHash(xmlrpc_value * const structP,
                      HV *           const perlHash,
                      unsigned int   const structIndex) {

    xmlrpc_env env;
    xmlrpc_value * keyP;
    xmlrpc_value * valueP;

    xmlrpc_env_init(&env);

    xmlrpc_struct_read_member(&env, structP, structIndex, &keyP, &valueP);
    
    if (env.fault_occurred)
        croak("Failed to read struct member");
    else {
        SV * const perlValue = newSViv((unsigned long)valueP);
        
        const char * key;
        size_t keylen;
        
        xmlrpc_read_string_lp(&env, keyP, &keylen, &key);
        
        if (env.fault_occurred)
            croak("Failed to read key string");
        else {
            SV ** rc;
            rc = hv_store(perlHash, key, keylen, perlValue, 0);
            if (rc == NULL)
                croak("Failed to store hash value for key '%s'", key);
            else
                SvREFCNT_inc(perlValue);
            strfree(key);
        }
        SvREFCNT_dec(perlValue);
        xmlrpc_DECREF(keyP);
        /* The reference we obtained to *valueP above now becomes the
           reference from 'perlHash' to it.
        */
    }
    xmlrpc_env_clean(&env);
}



XS(XS_RPC__Xmlrpc_c__Value__valueStruct);

XS(XS_RPC__Xmlrpc_c__Value__valueStruct) {

    dXSARGS;
    dXSTARG;

    if (items != 1)
        Perl_croak(aTHX_ "_valueStruct() called with %u arguments; "
                   "expected 1", items);
    else {
        xmlrpc_value * const structP = (xmlrpc_value *) SvUV(ST(0));
        
        xmlrpc_env env;
        unsigned int structSize;
        HV * perlHash;
        SV * retval;  /* A reference to 'perlHash' */

        perlHash = newHV();

        xmlrpc_env_init(&env);

        structSize = xmlrpc_struct_size(&env, structP);

        if (env.fault_occurred)
            croak("Failed to get struct size");
        else {
            unsigned int i;

            for (i = 0; i < structSize; ++i)
                addStructMemberToHash(structP, perlHash, i);

            retval = newRV_noinc((SV *)perlHash);
            
            sv_setsv(TARG, retval); XSprePUSH; PUSHTARG;
            
            SvREFCNT_dec(retval);
        }
        xmlrpc_env_clean(&env);
    }
    XSRETURN(1);
}



XS(XS_RPC__Xmlrpc_c__Value__valueI8);

XS(XS_RPC__Xmlrpc_c__Value__valueI8) {

    dXSARGS;
    dXSTARG;

    if (items != 1)
        Perl_croak(aTHX_ "_valueI8() called with %u arguments; "
                   "expected 1", items);
    else {
        xmlrpc_value * const valueP = (xmlrpc_value *) SvUV(ST(0));
        
        long long retval;

        xmlrpc_env env;

        xmlrpc_env_init(&env);

        xmlrpc_read_i8(&env, valueP, &retval);

        if (env.fault_occurred)
            croak("xmlrpc_read_i8() failed!");
        
        xmlrpc_env_clean(&env);

        sv_setiv(TARG, retval); XSprePUSH; PUSHTARG;
    }
    XSRETURN(1);
}



XS(boot_RPC__Xmlrpc_c__Value);

XS(boot_RPC__Xmlrpc_c__Value) {

    dXSARGS;

    char * const file = __FILE__;

    XS_VERSION_BOOTCHECK;

    newXSproto("RPC::Xmlrpc_c::Value::_valueIntCreate",
               XS_RPC__Xmlrpc_c__Value__valueIntCreate, file, "$$$");

    newXSproto("RPC::Xmlrpc_c::Value::_valueBoolCreate",
               XS_RPC__Xmlrpc_c__Value__valueBoolCreate, file, "$$$");

    newXSproto("RPC::Xmlrpc_c::Value::_valueDoubleCreate",
               XS_RPC__Xmlrpc_c__Value__valueDoubleCreate, file, "$$$");

    newXSproto("RPC::Xmlrpc_c::Value::_valueDatetimeCreate",
               XS_RPC__Xmlrpc_c__Value__valueDatetimeCreate, file, "$$$");

    newXSproto("RPC::Xmlrpc_c::Value::_valueStringCreate",
               XS_RPC__Xmlrpc_c__Value__valueStringCreate, file, "$$$");

    newXSproto("RPC::Xmlrpc_c::Value::_valueBytestringCreate",
               XS_RPC__Xmlrpc_c__Value__valueBytestringCreate, file, "$$$");

    newXSproto("RPC::Xmlrpc_c::Value::_valueArrayCreateEmpty",
               XS_RPC__Xmlrpc_c__Value__valueArrayCreateEmpty, file, "$$");

    newXSproto("RPC::Xmlrpc_c::Value::_arrayAppendItem",
               XS_RPC__Xmlrpc_c__Value__arrayAppendItem, file, "$$$");

    newXSproto("RPC::Xmlrpc_c::Value::_valueStructCreateEmpty",
               XS_RPC__Xmlrpc_c__Value__valueStructCreateEmpty, file, "$$");

    newXSproto("RPC::Xmlrpc_c::Value::_structSetValue",
               XS_RPC__Xmlrpc_c__Value__structSetValue, file, "$$$$");

    newXSproto("RPC::Xmlrpc_c::Value::_valueNilCreate",
               XS_RPC__Xmlrpc_c__Value__valueNilCreate, file, "$$");

    newXSproto("RPC::Xmlrpc_c::Value::_valueI8Create",
               XS_RPC__Xmlrpc_c__Value__valueI8Create, file, "$$$");

    newXSproto("RPC::Xmlrpc_c::Value::_valueDestroy",
               XS_RPC__Xmlrpc_c__Value__valueDestroy, file, "$");

    newXSproto("RPC::Xmlrpc_c::Value::_type",
               XS_RPC__Xmlrpc_c__Value__type, file, "$");

    newXSproto("RPC::Xmlrpc_c::Value::_valueInt",
               XS_RPC__Xmlrpc_c__Value__valueInt, file, "$");

    newXSproto("RPC::Xmlrpc_c::Value::_valueBool",
               XS_RPC__Xmlrpc_c__Value__valueBool, file, "$");

    newXSproto("RPC::Xmlrpc_c::Value::_valueDouble",
               XS_RPC__Xmlrpc_c__Value__valueDouble, file, "$");

    newXSproto("RPC::Xmlrpc_c::Value::_valueDatetime",
               XS_RPC__Xmlrpc_c__Value__valueDatetime, file, "$");

    newXSproto("RPC::Xmlrpc_c::Value::_valueString",
               XS_RPC__Xmlrpc_c__Value__valueString, file, "$");

    newXSproto("RPC::Xmlrpc_c::Value::_valueByestring",
               XS_RPC__Xmlrpc_c__Value__valueBytestring, file, "$");

    newXSproto("RPC::Xmlrpc_c::Value::_valueArray",
               XS_RPC__Xmlrpc_c__Value__valueArray, file, "$");

    newXSproto("RPC::Xmlrpc_c::Value::_valueStruct",
               XS_RPC__Xmlrpc_c__Value__valueStruct, file, "$");

    newXSproto("RPC::Xmlrpc_c::Value::_valueI8",
               XS_RPC__Xmlrpc_c__Value__valueI8, file, "$");

    XSRETURN_YES;
}
