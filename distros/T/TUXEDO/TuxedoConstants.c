/*
 * TuxedoConstants.c
 *
 * This file contains a map of name/value pairs relating to tuxedo constants.
 * The map structure (namedConstants)contains a hash key that is used to 
 * locate the named value.  The first time a lookup occurs, the map structure 
 * is initialized and the hash values for all the entries in the map are 
 * calculated.
 *
 * To add a new constant, just add an entry to the namedConstants[] array.
 * You can specify an arbitrary value for the hash attribute when doing this 
 * because it will be overwritten when the actual hash value is calculated
 * doing the initialization.
 */

#ifdef WIN32
#include "perl.h"
#endif

#include <string.h>
#include <atmi.h>
#include <fml32.h>
#include <tpadm.h>
#include <errno.h>
#include <stdlib.h>
#include <stdio.h>

#ifndef WIN32
#include <signal.h>
#endif

typedef  unsigned long int  u4;   /* unsigned 4-byte type */
typedef  unsigned     char  u1;   /* unsigned 1-byte type */

typedef struct
{
    u4    hash;
    char *name;
    long value;
} NamedConstant;

NamedConstant namedConstants[] =
{
    /* flags to service routines */
    { 0, "TPNOBLOCK", TPNOBLOCK },
    { 0, "TPSIGRSTRT", TPSIGRSTRT },
    { 0, "TPNOREPLY", TPNOREPLY },
    { 0, "TPNOTRAN", TPNOTRAN },
    { 0, "TPTRAN", TPTRAN },
    { 0, "TPNOTIME", TPNOTIME },
    { 0, "TPABSOLUTE", TPABSOLUTE },
    { 0, "TPGETANY", TPGETANY },
    { 0, "TPNOCHANGE", TPNOCHANGE },
    { 0, "TPCONV", TPCONV },
    { 0, "TPSENDONLY", TPSENDONLY },
    { 0, "TPRECVONLY", TPRECVONLY },
    { 0, "TPACK", TPACK },

    /* flags to tpreturn() */
    { 0, "TPFAIL", TPFAIL },
    { 0, "TPSUCCESS", TPSUCCESS },
    { 0, "TPEXIT", TPEXIT },

    /* flags to tpscmt() */
    { 0, "TP_CMT_LOGGED", TP_CMT_LOGGED },
    { 0, "TP_CMT_COMPLETE", TP_CMT_COMPLETE },

    /* flags to tpinit() */
    { 0, "TPU_MASK", TPU_MASK },
    { 0, "TPU_SIG", TPU_SIG },
    { 0, "TPU_DIP", TPU_DIP },
    { 0, "TPU_IGN", TPU_IGN },
    { 0, "TPSA_FASTPATH", TPSA_FASTPATH },
    { 0, "TPSA_PROTECTED", TPSA_PROTECTED },
    { 0, "TPMULTICONTEXTS", TPMULTICONTEXTS },
    { 0, "TPU_THREAD", TPU_THREAD },

    /* flags to tpconvert() */
    { 0, "TPTOSTRING", TPTOSTRING },
    { 0, "TPCONVCLTID", TPCONVCLTID },
    { 0, "TPCONVTRANID", TPCONVTRANID },
    { 0, "TPCONVXID", TPCONVXID },
    { 0, "TPCONVMAXSTR", TPCONVMAXSTR },

    /* return values to tpchkauth */
    { 0, "TPNOAUTH", TPNOAUTH },
    { 0, "TPSYSAUTH", TPSYSAUTH },
    { 0, "TPAPPAUTH", TPAPPAUTH },

    /* tperrno values */
    { 0, "TPEABORT", TPEABORT },
    { 0, "TPEBADDESC", TPEBADDESC },
    { 0, "TPEBLOCK", TPEBLOCK },
    { 0, "TPEINVAL", TPEINVAL },
    { 0, "TPELIMIT", TPELIMIT },
    { 0, "TPENOENT", TPENOENT },
    { 0, "TPEOS", 	TPEOS },
    { 0, "TPEPERM", 	TPEPERM },
    { 0, "TPEPROTO", TPEPROTO },
    { 0, "TPESVCERR", TPESVCERR },
    { 0, "TPESVCFAIL", TPESVCFAIL },
    { 0, "TPESYSTEM", TPESYSTEM },
    { 0, "TPETIME", 	TPETIME },
    { 0, "TPETRAN", 	TPETRAN },
    { 0, "TPGOTSIG", TPGOTSIG },
    { 0, "TPERMERR", TPERMERR },
    { 0, "TPEITYPE", TPEITYPE },
    { 0, "TPEOTYPE", TPEOTYPE },
    { 0, "TPERELEASE", TPERELEASE },
    { 0, "TPEHAZARD", TPEHAZARD },
    { 0, "TPEHEURISTIC", TPEHEURISTIC },
    { 0, "TPEEVENT", TPEEVENT },
    { 0, "TPEMATCH", TPEMATCH },
    { 0, "TPEDIAGNOSTIC", TPEDIAGNOSTIC },
    { 0, "TPEMIB", 	TPEMIB },

    /* fml constants */
    { 0, "FLD_SHORT",  FLD_SHORT },
    { 0, "FLD_LONG",   FLD_LONG },
    { 0, "FLD_CHAR",   FLD_CHAR },
    { 0, "FLD_FLOAT",  FLD_FLOAT },
    { 0, "FLD_DOUBLE", FLD_DOUBLE },
    { 0, "FLD_STRING", FLD_STRING },
    { 0, "FLD_CARRAY", FLD_CARRAY },
    { 0, "FLD_PTR",    FLD_PTR },
    { 0, "FLD_FML32",  FLD_FML32 },
    { 0, "FLD_VIEW32", FLD_VIEW32 },
    { 0, "BADFLDID", BADFLDID },
    { 0, "MIB_ALLFLAGS", MIB_ALLFLAGS },
    { 0, "MIB_LOCAL", MIB_LOCAL },
    { 0, "MIB_PREIMAGE", MIB_PREIMAGE },
    { 0, "MIB_SELF", MIB_SELF },
    { 0, "MIBATT_KEYFIELD", MIBATT_KEYFIELD },
    { 0, "MIBATT_LOCAL", MIBATT_LOCAL },
    { 0, "MIBATT_NEWONLY", MIBATT_NEWONLY },
    { 0, "MIBATT_REGEXKEY", MIBATT_REGEXKEY },
    { 0, "MIBATT_REQUIRED", MIBATT_REQUIRED },
    { 0, "MIBATT_RUNTIME", MIBATT_RUNTIME },
    { 0, "MIBATT_SETKEY", MIBATT_SETKEY },
    { 0, "QMIB_FORCECLOSE", QMIB_FORCECLOSE },
    { 0, "QMIB_FORCEDELETE", QMIB_FORCEDELETE },
    { 0, "QMIB_FORCEPURGE", QMIB_FORCEPURGE },
    { 0, "TAEAPP", TAEAPP },
    { 0, "TAECONFIG", TAECONFIG },
    { 0, "TAEINVAL", TAEINVAL },
    { 0, "TAEOS", TAEOS },
    { 0, "TAEPERM", TAEPERM },
    { 0, "TAEPREIMAGE", TAEPREIMAGE },
    { 0, "TAEPROTO", TAEPROTO },
    { 0, "TAEREQUIRED", TAEREQUIRED },
    { 0, "TAESUPPORT", TAESUPPORT },
    { 0, "TAESYSTEM", TAESYSTEM },
    { 0, "TAEUNIQ", TAEUNIQ },
    { 0, "TAOK", TAOK },
    { 0, "TAPARTIAL", TAPARTIAL },
    { 0, "TAUPDATED", TAUPDATED },
    { 0, "TMIB_ADMONLY", TMIB_ADMONLY },
    { 0, "TMIB_APPONLY", TMIB_APPONLY },
    { 0, "TMIB_CONFIG", TMIB_CONFIG },
    { 0, "TMIB_GLOBAL", TMIB_GLOBAL },
    { 0, "TMIB_NOTIFY", TMIB_NOTIFY },

    /* queue constants */
    { 0, "TPQCORRID", TPQCORRID },
    { 0, "TPQFAILUREQ", TPQFAILUREQ },
    { 0, "TPQBEFOREMSGID", TPQBEFOREMSGID },
    { 0, "TPQGETBYMSGIDOLD", TPQGETBYMSGIDOLD },
    { 0, "TPQMSGID", TPQMSGID },
    { 0, "TPQPRIORITY", TPQPRIORITY },
    { 0, "TPQTOP", TPQTOP },
    { 0, "TPQWAIT", TPQWAIT },
    { 0, "TPQREPLYQ", TPQREPLYQ },
    { 0, "TPQTIME_ABS", TPQTIME_ABS },
    { 0, "TPQTIME_REL", TPQTIME_REL },
    { 0, "TPQGETBYCORRIDOLD", TPQGETBYCORRIDOLD },
    { 0, "TPQPEEK", TPQPEEK },
    { 0, "TPQDELIVERYQOS", TPQDELIVERYQOS },
    { 0, "TPQREPLYQOS", TPQREPLYQOS },
    { 0, "TPQEXPTIME_ABS", TPQEXPTIME_ABS },
    { 0, "TPQEXPTIME_REL", TPQEXPTIME_REL },
    { 0, "TPQEXPTIME_NONE", TPQEXPTIME_NONE },
    { 0, "TPQGETBYMSGID", TPQGETBYMSGID },
    { 0, "TPQGETBYCORRID", TPQGETBYCORRID },
    { 0, "TPQQOSDEFAULTPERSIST", TPQQOSDEFAULTPERSIST },
    { 0, "TPQQOSPERSISTENT", TPQQOSPERSISTENT },
    { 0, "TPQQOSNONPERSISTENT", TPQQOSNONPERSISTENT },

    { 0, "TPKEY_SIGNATURE", TPKEY_SIGNATURE },
    { 0, "TPKEY_DECRYPT", TPKEY_DECRYPT },
    { 0, "TPKEY_ENCRYPT", TPKEY_ENCRYPT },
    { 0, "TPKEY_VERIFICATION", TPKEY_VERIFICATION },
    { 0, "TPKEY_AUTOSIGN", TPKEY_AUTOSIGN },
    { 0, "TPKEY_AUTOENCRYPT", TPKEY_AUTOENCRYPT },
    { 0, "TPKEY_REMOVE", TPKEY_REMOVE },
    { 0, "TPKEY_REMOVEALL", TPKEY_REMOVEALL },
    { 0, "TPKEY_VERIFY", TPKEY_VERIFY },
    { 0, "TPEX_STRING", TPEX_STRING },
    { 0, "TPSEAL_OK", TPSEAL_OK },
    { 0, "TPSEAL_PENDING", TPSEAL_PENDING },
    { 0, "TPSEAL_EXPIRED_CERT", TPSEAL_EXPIRED_CERT },
    { 0, "TPSEAL_REVOKED_CERT", TPSEAL_REVOKED_CERT },
    { 0, "TPSEAL_TAMPERED_CERT", TPSEAL_TAMPERED_CERT },
    { 0, "TPSEAL_UNKNOWN", TPSEAL_UNKNOWN },
    { 0, "TPSIGN_OK", TPSIGN_OK },
    { 0, "TPSIGN_PENDING", TPSIGN_PENDING },
    { 0, "TPSIGN_EXPIRED", TPSIGN_EXPIRED },
    { 0, "TPSIGN_EXPIRED_CERT", TPSIGN_EXPIRED_CERT },
    { 0, "TPSIGN_POSTDATED", TPSIGN_POSTDATED },
    { 0, "TPSIGN_REVOKED_CERT", TPSIGN_REVOKED_CERT },
    { 0, "TPSIGN_TAMPERED_CERT", TPSIGN_TAMPERED_CERT },
    { 0, "TPSIGN_TAMPERED_MESSAGE", TPSIGN_TAMPERED_MESSAGE },
    { 0, "TPSIGN_UNKNOWN", TPSIGN_UNKNOWN },

    { 0, "TPNULLCONTEXT", TPNULLCONTEXT	 },
    { 0, "TPINVALIDCONTEXT", TPINVALIDCONTEXT	 },
    { 0, "TPSINGLECONTEXT", TPSINGLECONTEXT		 }

#ifndef WIN32
    ,{ 0, "SIGHUP", SIGHUP },
    { 0, "SIGINT", SIGINT },
    { 0, "SIGQUIT", SIGQUIT },
    { 0, "SIGILL", SIGILL },
    { 0, "SIGTRAP", SIGTRAP },
    { 0, "SIGIOT", SIGIOT },
    { 0, "SIGABRT", SIGABRT },
    { 0, "SIGEMT", SIGEMT },
    { 0, "SIGFPE", SIGFPE },
    { 0, "SIGKILL", SIGKILL },
    { 0, "SIGBUS", SIGBUS },
    { 0, "SIGSEGV", SIGSEGV },
    { 0, "SIGSYS", SIGSYS },
    { 0, "SIGPIPE", SIGPIPE },
    { 0, "SIGALRM", SIGALRM },
    { 0, "SIGTERM", SIGTERM },
    { 0, "SIGUSR1", SIGUSR1 },
    { 0, "SIGUSR2", SIGUSR2 },
    { 0, "SIGCLD", SIGCLD },
    { 0, "SIGCHLD", SIGCHLD },
    { 0, "SIGPWR", SIGPWR },
    { 0, "SIGWINCH", SIGWINCH },
    { 0, "SIGURG", SIGURG },
    { 0, "SIGPOLL", SIGPOLL },
    { 0, "SIGIO", SIGIO }
#endif
};

/* The mixing step */
#define mix(a,b,c) \
{ \
  a=a-b;  a=a-c;  a=a^(c>>13); \
  b=b-c;  b=b-a;  b=b^(a<<8);  \
  c=c-a;  c=c-b;  c=c^(b>>13); \
  a=a-b;  a=a-c;  a=a^(c>>12); \
  b=b-c;  b=b-a;  b=b^(a<<16); \
  c=c-a;  c=c-b;  c=c^(b>>5);  \
  a=a-b;  a=a-c;  a=a^(c>>3);  \
  b=b-c;  b=b-a;  b=b^(a<<10); \
  c=c-a;  c=c-b;  c=c^(b>>15); \
}

/* The whole new hash function */
u4 hash( k, initval)
register u1 *k;        /* the key */
u4           initval;  /* the previous hash, or an arbitrary value */
{

   register u4 a,b,c;  /* the internal state */
   u4          length = strlen( (char *)k );
   u4          len;    /* how many key bytes still need mixing */

   /* Set up the internal state */
   len = length;
   a = b = 0x9e3779b9;  /* the golden ratio; an arbitrary value */
   c = initval;         /* variable initialization of internal state */

   /*---------------------------------------- handle most of the key */
   while (len >= 12)
   {
      a=a+(k[0]+((u4)k[1]<<8)+((u4)k[2]<<16) +((u4)k[3]<<24));
      b=b+(k[4]+((u4)k[5]<<8)+((u4)k[6]<<16) +((u4)k[7]<<24));
      c=c+(k[8]+((u4)k[9]<<8)+((u4)k[10]<<16)+((u4)k[11]<<24));
      mix(a,b,c);
      k = k+12; len = len-12;
   }

   /*------------------------------------- handle the last 11 bytes */
   c = c+length;
   switch(len)              /* all the case statements fall through */
   {
   case 11: c=c+((u4)k[10]<<24);
   case 10: c=c+((u4)k[9]<<16);
   case 9 : c=c+((u4)k[8]<<8);
      /* the first byte of c is reserved for the length */
   case 8 : b=b+((u4)k[7]<<24);
   case 7 : b=b+((u4)k[6]<<16);
   case 6 : b=b+((u4)k[5]<<8);
   case 5 : b=b+k[4];
   case 4 : a=a+((u4)k[3]<<24);
   case 3 : a=a+((u4)k[2]<<16);
   case 2 : a=a+((u4)k[1]<<8);
   case 1 : a=a+k[0];
     /* case 0: nothing left to add */
   }
   mix(a,b,c);
   /*-------------------------------------------- report the result */
   return c;
}


static int compare( const void *a, const void *b )
{
    if ( ((NamedConstant *)a)->hash < ((NamedConstant *)b)->hash ) return -1;
    if ( ((NamedConstant *)a)->hash > ((NamedConstant *)b)->hash ) return  1;
    return ( strcmp( ((NamedConstant *)a)->name, ((NamedConstant *)b)->name ) );
}

static int tableInitialized = 0;

void InitTuxedoConstants()
{
    u4 hashVal = 0;
    long tableSize = sizeof(namedConstants)/sizeof(NamedConstant);
    long i = 0;

    if ( tableInitialized )
        return;

    for ( i = 0; i < tableSize; i++ )
    {
        hashVal = hash( namedConstants[i].name, 0 );
        namedConstants[i].hash = hashVal;
    }

    qsort( namedConstants, 
           sizeof(namedConstants)/sizeof(NamedConstant),
           sizeof(NamedConstant),
           compare
           );

    tableInitialized = 1;
}

long 
getTuxedoConstant( char *name )
{
    NamedConstant key, * nc;
    key.name = name;
    key.hash = hash( name, 0 );
    nc = (NamedConstant *)bsearch( &key, 
                                   namedConstants,
                                   sizeof(namedConstants)/sizeof(NamedConstant),
                                   sizeof(NamedConstant),
                                   compare
                                   );
    if ( nc != NULL )
    {
        errno = 0;
        return nc->value;
    }

   errno = EINVAL;
   return 0;
}


