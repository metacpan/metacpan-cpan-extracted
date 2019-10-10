/* This file was modified by Howard Chu, hyc@symas.com, 2000-2003.
 * Most changes are #if OPENLDAP, some are not marked.
 */
#ifdef __cplusplus
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef __cplusplus
}
#endif

#include <lber.h>
#include <ldap.h>

#include <sasl/sasl.h>

/* Mozilla prototypes declare things as "const char *" while   */
/*      OpenLDAP uses "char *"                                 */

#ifdef MOZILLA_LDAP
 #define LDAP_CHAR const char
 #include <ldap_ssl.h>
#else

#ifndef OPENLDAP
 #include "ldap_compat.h"
#endif

 #define LDAP_CHAR char
#endif

#ifndef LDAP_RES_INTERMEDIATE
 #define LDAP_RES_INTERMEDIATE  0x79U /* 121 */
#endif

/* Function Prototypes for Internal Functions */

static char **av2modvals(AV *ldap_value_array_av, int ldap_isa_ber);
static LDAPMod *parse1mod(SV *ldap_value_ref,char *ldap_current_attribute,
    int ldap_add_func,int cont);
static LDAPMod **hash2mod(SV *ldap_change,int ldap_add_func, const char *func);

#ifdef OPENLDAP
   static int internal_rebind_proc(LDAP *ld,          LDAP_CONST char *url,
                                   ber_tag_t request, ber_int_t msgid,
                                   void *params);
#endif

/* The Name of the PERL function to return DN, PASSWD, AUTHTYPE on Rebind */
/* Set using 'set_rebind_proc()' */
SV *ldap_perl_rebindproc = NULL;


/* Use constant.h generated from constant.gen */
/* Courtesy of h.b.furuseth@usit.uio.no       */

#include "constant.h"


/* Strcasecmp - Some operating systems don't have this, including NT */

int StrCaseCmp(const char *s, const char *t)
{
   while (*s && *t && toupper(*s) == toupper(*t))
   {
      s++; t++;
   }
   return(toupper(*s) - toupper(*t));
}

/* av2modvals - Takes a single Array Reference (AV *) and returns */
/*    a null terminated list of char pointers.                    */

static
char **av2modvals(AV *ldap_value_array_av, int ldap_isa_ber)
{
   I32 ldap_arraylen;
   char **ldap_ch_modvalues = NULL;
   char *ldap_current_value_char = NULL;
   struct berval **ldap_bv_modvalues = NULL;
   struct berval *ldap_current_bval = NULL;
   SV **ldap_current_value_sv;
   int ldap_value_count = 0,ldap_pvlen,ldap_real_valuecount = 0;

   ldap_arraylen = av_len(ldap_value_array_av);
   if (ldap_arraylen < 0)
      return(NULL);

   if (ldap_isa_ber == 1)
   {
      New(1,ldap_bv_modvalues,2+ldap_arraylen,struct berval *);
   } else {
      New(1,ldap_ch_modvalues,2+ldap_arraylen,char *);
   }

   for (ldap_value_count = 0; ldap_value_count <=ldap_arraylen;
    ldap_value_count++)
   {
      ldap_current_value_sv = av_fetch(ldap_value_array_av,ldap_value_count,0);
      ldap_current_value_char = SvPV(*ldap_current_value_sv,PL_na);
      ldap_pvlen = SvCUR(*ldap_current_value_sv);
      if (strcmp(ldap_current_value_char,"") != 0)
      {
         if (ldap_isa_ber == 1)
         {
            New(1,ldap_current_bval,1,struct berval);
        ldap_current_bval->bv_len = ldap_pvlen;
        ldap_current_bval->bv_val = ldap_current_value_char;
        ldap_bv_modvalues[ldap_real_valuecount] = ldap_current_bval;
         } else {
            ldap_ch_modvalues[ldap_real_valuecount] = ldap_current_value_char;
         }
         ldap_real_valuecount++;
      }
   }
   if (ldap_isa_ber == 1)
   {
      ldap_bv_modvalues[ldap_real_valuecount] = NULL;
      return ((char **)ldap_bv_modvalues);
   } else {
      ldap_ch_modvalues[ldap_real_valuecount] = NULL;
      return (ldap_ch_modvalues);
   }
}


/* parse1mod - Take a single reference, figure out if it is a HASH, */
/*   ARRAY, or SCALAR, then extract the values and attributes and   */
/*   return a single LDAPMod pointer to this data.                  */

static
LDAPMod *parse1mod(SV *ldap_value_ref,char *ldap_current_attribute,
   int ldap_add_func,int cont)
{
   LDAPMod *ldap_current_mod;
   static HV *ldap_current_values_hv;
   HE *ldap_change_element;
   char *ldap_current_modop;
   SV *ldap_current_value_sv;
   I32 keylen;
   int ldap_isa_ber = 0;

   if (ldap_current_attribute == NULL)
      return(NULL);
   New(1,ldap_current_mod,1,LDAPMod);
   ldap_current_mod->mod_type = ldap_current_attribute;
   if (SvROK(ldap_value_ref))
   {
     if (SvTYPE(SvRV(ldap_value_ref)) == SVt_PVHV)
     {
      if (!cont)
      {
         ldap_current_values_hv = (HV *) SvRV(ldap_value_ref);
         hv_iterinit(ldap_current_values_hv);
      }
      if ((ldap_change_element = hv_iternext(ldap_current_values_hv)) == NULL)
     return(NULL);
      ldap_current_modop = hv_iterkey(ldap_change_element,&keylen);
      ldap_current_value_sv = hv_iterval(ldap_current_values_hv,
    ldap_change_element);
      if (ldap_add_func == 1)
      {
     ldap_current_mod->mod_op = 0;
      } else {
     if (strchr(ldap_current_modop,'a') != NULL)
     {
        ldap_current_mod->mod_op = LDAP_MOD_ADD;
     } else if (strchr(ldap_current_modop,'r') != NULL)
     {
        ldap_current_mod->mod_op = LDAP_MOD_REPLACE;
     } else if (strchr(ldap_current_modop,'d') != NULL) {
        ldap_current_mod->mod_op = LDAP_MOD_DELETE;
     } else {
        return(NULL);
     }
      }
      if (strchr(ldap_current_modop,'b') != NULL)
      {
     ldap_isa_ber = 1;
     ldap_current_mod->mod_op = ldap_current_mod->mod_op | LDAP_MOD_BVALUES;
      }
      if (SvTYPE(SvRV(ldap_current_value_sv)) == SVt_PVAV)
      {
     if (ldap_isa_ber == 1)
     {
        ldap_current_mod->mod_values =
          av2modvals((AV *)SvRV(ldap_current_value_sv),ldap_isa_ber);
     } else {
        ldap_current_mod->mod_values =
          av2modvals((AV *)SvRV(ldap_current_value_sv),ldap_isa_ber);
     }
      }
     } else if (SvTYPE(SvRV(ldap_value_ref)) == SVt_PVAV) {
      if (cont)
         return NULL;
      if (ldap_add_func == 1)
         ldap_current_mod->mod_op = 0;
      else
         ldap_current_mod->mod_op = LDAP_MOD_REPLACE;
      ldap_current_mod->mod_values = av2modvals((AV *)SvRV(ldap_value_ref),0);
      if (ldap_current_mod->mod_values == NULL)
      {
     ldap_current_mod->mod_op = LDAP_MOD_DELETE;
      }
     }
   } else {
      if (cont)
         return NULL;
      if (strcmp(SvPV(ldap_value_ref,PL_na),"") == 0)
      {
         if (ldap_add_func != 1)
         {
        ldap_current_mod->mod_op = LDAP_MOD_DELETE;
        ldap_current_mod->mod_values = NULL;
         } else {
            return(NULL);
         }
      } else {
         if (ldap_add_func == 1)
         {
            ldap_current_mod->mod_op = 0;
         } else {
        ldap_current_mod->mod_op = LDAP_MOD_REPLACE;
         }
         New(1,ldap_current_mod->mod_values,2,char *);
     ldap_current_mod->mod_values[0] = SvPV(ldap_value_ref,PL_na);
     ldap_current_mod->mod_values[1] = NULL;
      }
   }
   return(ldap_current_mod);
}


/* hash2mod - Cycle through all the keys in the hash and properly call */
/*    the appropriate functions to build a NULL terminated list of     */
/*    LDAPMod pointers.                                                */

static
LDAPMod ** hash2mod(SV *ldap_change_ref, int ldap_add_func, const char *func)
{
   LDAPMod **ldapmod = NULL;
   LDAPMod *ldap_current_mod;
   int ldap_attribute_count = 0;
   HE *ldap_change_element;
   char *ldap_current_attribute;
   SV *ldap_current_value_sv;
   I32 keylen;
   HV *ldap_change;

   if (!SvROK(ldap_change_ref) || SvTYPE(SvRV(ldap_change_ref)) != SVt_PVHV)
      croak("Net::LDAPapi::%s needs Hash reference as argument 3.",func);

   ldap_change = (HV *)SvRV(ldap_change_ref);

   hv_iterinit(ldap_change);
   while((ldap_change_element = hv_iternext(ldap_change)) != NULL)
   {
      ldap_current_attribute = hv_iterkey(ldap_change_element,&keylen);
      ldap_current_value_sv = hv_iterval(ldap_change,ldap_change_element);
      ldap_current_mod = parse1mod(ldap_current_value_sv,
    ldap_current_attribute,ldap_add_func,0);
      while (ldap_current_mod != NULL)
      {
         ldap_attribute_count++;
         (ldapmod
       ? Renew(ldapmod,1+ldap_attribute_count,LDAPMod *)
       : New(1,ldapmod,1+ldap_attribute_count,LDAPMod *));
         New(1,ldapmod[ldap_attribute_count -1],sizeof(LDAPMod),LDAPMod);
         Copy(ldap_current_mod,ldapmod[ldap_attribute_count-1],
       sizeof(LDAPMod),LDAPMod *);
         ldap_current_mod = parse1mod(ldap_current_value_sv,
           ldap_current_attribute,ldap_add_func,1);

      }
   }
   ldapmod[ldap_attribute_count] = NULL;
   return ldapmod;
}

/* internal_rebind_proc - Wrapper to call a PERL rebind process               */
/*   ldap_set_rebind_proc is slightly different between Mozilla and OpenLDAP  */

int
#ifdef OPENLDAP
internal_rebind_proc(LDAP *ld,          LDAP_CONST char *url,
                     ber_tag_t request, ber_int_t msgid,
                     void *params)
#endif
{
    return(LDAP_SUCCESS);
}

typedef struct bictx {
    char *authcid;
    char *passwd;
    char *realm;
    char *authzid;
} bictx;

static int
ldap_b2_interact(LDAP *ld, unsigned flags, void *def, void *inter)
{
    sasl_interact_t *in = inter;
    const char *p;
    bictx *ctx = def;
     for (;in->id != SASL_CB_LIST_END;in++)
    {
        p = NULL;
        switch(in->id)
        {
            case SASL_CB_GETREALM:
                p = ctx->realm;
                break;
            case SASL_CB_AUTHNAME:
                p = ctx->authcid;
                break;
            case SASL_CB_USER:
                p = ctx->authzid;
                break;
            case SASL_CB_PASS:
                p = ctx->passwd;
                break;
        }
        if (p)
        {
            in->len = strlen(p);
            in->result = p;
        }
    }
    return LDAP_SUCCESS;
}

static void
sv2timeval(SV *data, struct timeval *tv)
{
    if (SvPOK(data))
    { 
        /* set the NV flag if it's readable as a double */
        SvNV(data);
    }

    if (SvIOK(data) || SvNOK(data)) {
        tv->tv_sec = SvIV(data);
        tv->tv_usec = ((SvNV(data) - SvIV(data))*1000000);
    }
}

static SV *
timeval2sv(struct timeval *data)
{
   return newSVnv(data->tv_sec + ((double)data->tv_usec / 1000000));    
}

MODULE = Net::LDAPapi           PACKAGE = Net::LDAPapi

PROTOTYPES: ENABLE

double
constant(name,arg)
    char *          name
    int             arg


char *
constant_s(name)
    char *          name


int
ldap_initialize(ldp, url)
    LDAP *      ldp = NO_INIT
    LDAP_CHAR * url
    CODE:
    {
       RETVAL = ldap_initialize(&ldp, url);
    }
    OUTPUT:
    RETVAL
    ldp

int
ldap_create(ldp)
    LDAP ** ldp = NO_INIT
    CODE:
    {
        RETVAL = ldap_create(ldp);
    }
    OUTPUT:
    RETVAL
    ldp

int
ldap_bind_s(ldp, dn, passwd, authmethod)
    LDAP *      ldp
    LDAP_CHAR * dn
    LDAP_CHAR * passwd
    int         authmethod

int
ldap_set_option(ld,option,optdata)
    LDAP *          ld
    int             option
    SV *            optdata
    CODE:
    {
       void *optptr = NULL;

       struct timeval tv;

       int sv_i;

       switch(option) 
       {
#ifdef OPENLDAP
          case LDAP_OPT_TIMEOUT:
          case LDAP_OPT_NETWORK_TIMEOUT:
             sv2timeval(optdata, &tv);
             optptr = (void *)&tv;

             break;
#endif
          default:
             if (SvIOK(optdata)) 
             {
                sv_i = SvIV(optdata);
                optptr = (void *) &sv_i;
             }

             break;
       }

       RETVAL = ldap_set_option(ld,option,optptr);
    }
    OUTPUT:
    RETVAL

int
ldap_get_option(ld,option,optdata)
    LDAP *          ld
    int             option
    SV *            optdata
    CODE:
    {
       void *data = NULL;

       RETVAL = ldap_get_option(ld, option, &data);

       switch(option) 
       {
#ifdef OPENLDAP
          case LDAP_OPT_TIMEOUT:
          case LDAP_OPT_NETWORK_TIMEOUT:
             sv_setsv(SvRV(optdata), timeval2sv(data));
             break;
#endif
          default:
             sv_setiv(SvRV(optdata), (long)data);
             break;
       }

    }
    OUTPUT:
    RETVAL
    optdata

int
ldap_unbind_ext_s(ld,sctrls,cctrls)
    LDAP *          ld
    LDAPControl **  sctrls
    LDAPControl **  cctrls

int
ldap_search_s(ldp, base, scope, filter, attrs, attrsonly, res)
    LDAP *        ldp
    LDAP_CHAR *   base
    int           scope
    LDAP_CHAR *   filter
    LDAP_CHAR **  attrs
    int           attrsonly
    LDAPMessage * res = NO_INIT
    CODE:
    {
       RETVAL = ldap_search_s(ldp, base, scope, filter, attrs, attrsonly, &res);
    }
    OUTPUT:
    RETVAL
    res

#ifdef MOZILLA_LDAP

int
ldap_version(ver)
    LDAPVersion     *ver

#endif

int
ldap_abandon_ext(ld,msgid,sctrls,cctrls)
    LDAP *          ld
    int             msgid
    LDAPControl **  sctrls
    LDAPControl **  cctrls

int
ldap_add_ext(ld, dn, ldap_change_ref, sctrls, cctrls, msgidp)
    LDAP *         ld
    LDAP_CHAR *    dn
    SV *           ldap_change_ref
    LDAPControl ** sctrls
    LDAPControl ** cctrls
    int            msgidp = NO_INIT
    CODE:
    {
        LDAPMod ** attrs = hash2mod(ldap_change_ref, 1, "ldap_add_ext");
        RETVAL = ldap_add_ext(ld, dn, attrs, sctrls, cctrls, &msgidp);
        Safefree(attrs);
    }
    OUTPUT:
    RETVAL
    msgidp

int
ldap_add_ext_s(ld,dn,ldap_change_ref,sctrls,cctrls)
    LDAP *         ld
    LDAP_CHAR *    dn
    LDAPMod **     ldap_change_ref = hash2mod($arg, 1, "ldap_add_ext_s");
    LDAPControl ** sctrls
    LDAPControl ** cctrls
    CLEANUP:
       Safefree(ldap_change_ref);

int
ldap_sasl_bind(ld, dn, passwd, serverctrls, clientctrls, msgidp)
    LDAP *          ld
    LDAP_CHAR *     dn
    LDAP_CHAR *     passwd
    LDAPControl **  serverctrls
    LDAPControl **  clientctrls
    int             msgidp = NO_INIT
    CODE:
    {
        struct berval cred;

        if( passwd == NULL )
            cred.bv_val = "";
        else
            cred.bv_val = passwd;

        cred.bv_len = strlen(cred.bv_val);

        RETVAL = ldap_sasl_bind(ld, dn, LDAP_SASL_SIMPLE, &cred,
                                serverctrls, clientctrls, &msgidp);
    }
    OUTPUT:
    RETVAL
    msgidp

int
ldap_modify_ext(ld, dn, ldap_change_ref, sctrls, cctrls, msgidp)
    LDAP *         ld
    LDAP_CHAR *    dn
    SV *           ldap_change_ref
    LDAPControl ** sctrls
    LDAPControl ** cctrls
    int            msgidp = NO_INIT
    CODE:
    {
        LDAPMod ** mods  = hash2mod(ldap_change_ref, 0, "ldap_modify_ext");
        RETVAL = ldap_modify_ext(ld, dn, mods, sctrls, cctrls, &msgidp);
        Safefree(mods);
    }
    OUTPUT:
    RETVAL
    msgidp

int
ldap_modify_ext_s(ld,dn,ldap_change_ref,sctrl,cctrl)
    LDAP *         ld
    LDAP_CHAR *    dn
    LDAPMod **     ldap_change_ref = hash2mod($arg, 0, "$func_name");
    LDAPControl ** sctrl
    LDAPControl ** cctrl

int
ldap_rename(ld, dn, newrdn, newSuperior, deleteoldrdn, sctrls, cctrls, msgidp)
    LDAP *         ld
    LDAP_CHAR *    dn
    LDAP_CHAR *    newrdn
    LDAP_CHAR *    newSuperior
    int            deleteoldrdn
    LDAPControl ** sctrls
    LDAPControl ** cctrls
    int            msgidp = NO_INIT
    CODE:
    {
        RETVAL = ldap_rename(ld, dn, newrdn, newSuperior,
                    deleteoldrdn, sctrls, cctrls, &msgidp);
    }
    OUTPUT:
    RETVAL
    msgidp

int
ldap_rename_s(ld, dn, newrdn, newSuperior, deleteoldrdn, sctrls, cctrls)
    LDAP *         ld
    LDAP_CHAR *    dn
    LDAP_CHAR *    newrdn
    LDAP_CHAR *    newSuperior
    int            deleteoldrdn
    LDAPControl ** sctrls
    LDAPControl ** cctrls

int
ldap_compare_ext(ld,dn,attr,value,sctrls,cctrls,msgidp)
    LDAP *          ld
    LDAP_CHAR *     dn
    LDAP_CHAR *     attr
    LDAP_CHAR *     value
    LDAPControl **  sctrls
    LDAPControl **  cctrls
    int             msgidp = NO_INIT
    CODE:
    {
        struct berval bvalue;
        bvalue.bv_len = strlen(value);
        bvalue.bv_val = value;
        RETVAL = ldap_compare_ext(ld, dn, attr, &bvalue, sctrls, cctrls, &msgidp);
    }
    OUTPUT:
    RETVAL
    msgidp

int
ldap_compare_ext_s(ld, dn, attr, value, sctrls, cctrls)
    LDAP *         ld
    LDAP_CHAR *    dn
    LDAP_CHAR *    attr
    LDAP_CHAR *    value
    LDAPControl ** sctrls
    LDAPControl ** cctrls
    CODE:
    {
        struct berval bvalue;
        bvalue.bv_len = strlen(value);
        bvalue.bv_val = value;
        RETVAL = ldap_compare_ext_s(ld, dn, attr, &bvalue, sctrls, cctrls);
    }
    OUTPUT:
    RETVAL

int
ldap_delete_ext(ld,dn,sctrls,cctrls,msgidp)
    LDAP *         ld
    LDAP_CHAR *    dn
    LDAPControl ** sctrls
    LDAPControl ** cctrls
    int            msgidp = NO_INIT
    CODE:
    {
        RETVAL = ldap_delete_ext(ld, dn, sctrls, cctrls, &msgidp);
    }
    OUTPUT:
    RETVAL
    msgidp

int
ldap_delete_ext_s(ld,dn,sctrls,cctrls)
    LDAP *          ld
    LDAP_CHAR *     dn
    LDAPControl **  sctrls
    LDAPControl **  cctrls

int
ldap_search_ext(ld, base, scope, filter, attrs, attrsonly, sctrls, cctrls, timeout, sizelimit, msgidp)
    LDAP *           ld
    LDAP_CHAR *      base
    int              scope
    LDAP_CHAR *      filter
    SV *             attrs
    int              attrsonly
    LDAPControl **   sctrls
    LDAPControl **   cctrls
    SV *             timeout
    int              sizelimit
    int              msgidp = NO_INIT

    CODE:
    {
       char **attrs_char;
       SV **current;
       int arraylen,count;
       struct timeval tv_timeout;

       if (SvTYPE(SvRV(attrs)) != SVt_PVAV)
       {
          croak("Net::LDAPapi::ldap_search_ext needs ARRAY reference as argument 5.");
          XSRETURN(1);
       }

       if ((arraylen = av_len((AV *)SvRV(attrs))) < 0)
       {
          New(1,attrs_char,2,char *);
          attrs_char[0] = NULL;
       } else {
          New(1,attrs_char,arraylen+2,char *);
          for (count=0;count <= arraylen; count++)
          {
            current = av_fetch((AV *)SvRV(attrs),count,0);
            attrs_char[count] = SvPV(*current,PL_na);
          }
          attrs_char[arraylen+1] = NULL;
       }

       sv2timeval(timeout, &tv_timeout);

       RETVAL = ldap_search_ext(ld,        base,   scope,  filter,  attrs_char,
                                attrsonly, sctrls, cctrls, &tv_timeout, sizelimit,
                                &msgidp);
       Safefree(attrs_char);
    }
    OUTPUT:
    RETVAL
    msgidp

int
ldap_search_ext_s(ld, base, scope, filter, attrs, attrsonly, sctrls, cctrls, timeout, sizelimit, res)
    LDAP *           ld
    LDAP_CHAR *      base
    int              scope
    LDAP_CHAR *      filter
    SV *             attrs
    int              attrsonly
    LDAPControl **   sctrls
    LDAPControl **   cctrls
    SV *             timeout
    int              sizelimit
    LDAPMessage *    res = NO_INIT
    CODE:
    {
       char **attrs_char;
       SV **current;
       int arraylen,count;
       struct timeval tv_timeout;

       if (SvTYPE(SvRV(attrs)) == SVt_PVAV)
       {
          if ((arraylen = av_len((AV *)SvRV(attrs))) < 0)
          {
             New(1, attrs_char, 2, char *);
             attrs_char[0] = NULL;
          } else {
             New(1, attrs_char, arraylen+2, char *);
             for (count=0;count <= arraylen; count++)
             {
                current = av_fetch((AV *)SvRV(attrs),count,0);
                attrs_char[count] = SvPV(*current,PL_na);
             }
             attrs_char[arraylen+1] = NULL;
          }
       } else {
          croak("Net::LDAPapi::ldap_search_ext_s needs ARRAY reference as argument 5.");
          XSRETURN(1);
       }

       sv2timeval(timeout, &tv_timeout);

       RETVAL = ldap_search_ext_s(ld,base,scope,filter,attrs_char,attrsonly,sctrls,cctrls,&tv_timeout,sizelimit,&res);

       Safefree(attrs_char);
    }
    OUTPUT:
    RETVAL
    res

int
ldap_extended_operation(ld, oid, bv_val, bv_len,  sctrls, cctrls, msgidp)
    LDAP *           ld
    LDAP_CHAR *      oid
    LDAP_CHAR *      bv_val
    int              bv_len
    LDAPControl **   sctrls
    LDAPControl **   cctrls
    int              msgidp = NO_INIT

    CODE:
    {
       struct berval indata;

       if (bv_len == 0) {
          RETVAL = ldap_extended_operation(ld, oid, NULL,
                                           sctrls, cctrls,
                                           &msgidp);
       } else {
          indata.bv_val = bv_val;
          indata.bv_len = bv_len;

          RETVAL = ldap_extended_operation(ld, oid, &indata,
                                      sctrls, cctrls,
                                      &msgidp);
       }
    }
    OUTPUT:
    RETVAL
    msgidp

int
ldap_extended_operation_s(ld, oid, bv_val, bv_len,  sctrls, cctrls, retoidp, retdatap)
    LDAP *           ld
    LDAP_CHAR *      oid
    LDAP_CHAR *      bv_val
    int              bv_len
    LDAPControl **   sctrls
    LDAPControl **   cctrls
    char *        retoidp  = NO_INIT
    char *        retdatap = NO_INIT
    CODE:
    {
       struct berval indata, *retdata;

       if (bv_len == 0) {
          RETVAL = ldap_extended_operation_s(ld, oid, NULL,
                                             sctrls, cctrls,
                                             &retoidp, &retdata);
       } else {
          indata.bv_val = bv_val;
          indata.bv_len = bv_len;

          RETVAL = ldap_extended_operation_s(ld, oid, &indata,
                                             sctrls, cctrls,
                                             &retoidp, &retdata);
       }

       if (retdata != NULL)
          retdatap = ldap_strdup(retdata->bv_val);
      
       ber_memfree(retdata);
   }
   OUTPUT:
   RETVAL
   retoidp
   retdatap

int
ldap_whoami(ld, sctrls, cctrls, msgidp)
    LDAP *           ld
    LDAPControl **   sctrls
    LDAPControl **   cctrls
    int              msgidp = NO_INIT

    CODE:
    {
       RETVAL = ldap_whoami(ld, sctrls, cctrls,
                            &msgidp);
    }
    OUTPUT:
    RETVAL
    msgidp

int
ldap_whoami_s(ld, authzid, sctrls, cctrls)
    LDAP *           ld
    LDAPControl **   sctrls
    LDAPControl **   cctrls
    char *        authzid = NO_INIT
    CODE:
    {
       struct berval *retdata;

       RETVAL = ldap_whoami_s(ld, &retdata, sctrls, cctrls);

       if (retdata != NULL)
          authzid = ldap_strdup(retdata->bv_val);
      
       ber_memfree(retdata);
    }
    OUTPUT:
    RETVAL
    authzid

int
ldap_result(ld, msgid, all, timeout, result)
    LDAP *        ld
    int           msgid
    int           all
    SV *          timeout
    LDAPMessage * result = NO_INIT
    CODE:
    {
        struct timeval tv_timeout;

        sv2timeval(timeout, &tv_timeout);

        RETVAL = ldap_result(ld, msgid, all, &tv_timeout, &result);
    }
    OUTPUT:
    RETVAL
    result


int
ldap_msgfree(lm)
    LDAPMessage *   lm

void
ber_free(ber, freebuf)
    BerElement * ber
    int          freebuf

#if defined(MOZILLA_LDAP) || defined(OPENLDAP)

int
ldap_msgid(lm)
    LDAPMessage *   lm

int
ldap_msgtype(lm)
    LDAPMessage *   lm

#else

int
ldap_msgid(lm)
    LDAPMessage *   lm
    CODE:
    {
       RETVAL = lm->lm_msgid;
    }
    OUTPUT:
    RETVAL

int
ldap_msgtype(lm)
    LDAPMessage *   lm
    CODE:
    {
       RETVAL = lm->lm_msgtype;
    }
    OUTPUT:
    RETVAL

#endif

#if defined(MOZILLA_LDAP)

int
ldap_get_lderrno(ld,m,s)
    LDAP *          ld
    char *          m = NO_INIT
    char *          s = NO_INIT
    CODE:
    {
       RETVAL = ldap_get_lderrno(ld,&m,&s);
    }
    OUTPUT:
    RETVAL
    m
    s

int
ldap_set_lderrno(ld,e,m,s)
    LDAP *          ld
    int             e
    char *          m
    char *          s

#else

int
ldap_get_lderrno(ld,m,s)
    LDAP *          ld
    char *          m = NO_INIT
    char *          s = NO_INIT
    CODE:
    {
#ifdef OPENLDAP
       ldap_get_option(ld, LDAP_OPT_ERROR_NUMBER, &RETVAL);
       ldap_get_option(ld, LDAP_OPT_ERROR_STRING, &s);
       ldap_get_option(ld, LDAP_OPT_MATCHED_DN, &m);
#else
       RETVAL = ld->ld_errno;
       m = ld->ld_matched;
       s = ld->ld_error;
#endif
    }
    OUTPUT:
    RETVAL
    m
    s

int
ldap_set_lderrno(ld,e,m,s)
    LDAP *          ld
    int             e
    char *          m
    char *          s
    CODE:
    {
       RETVAL = 0;
#ifdef OPENLDAP
       ldap_set_option(ld, LDAP_OPT_ERROR_NUMBER, &e);
       ldap_set_option(ld, LDAP_OPT_ERROR_STRING, s);
       ldap_set_option(ld, LDAP_OPT_MATCHED_DN, m);
#else
       ld->ld_errno = e;
       ld->ld_matched = m;
       ld->ld_error = s;
#endif
    }
    OUTPUT:
    RETVAL

#endif

int
ldap_get_entry_controls(ld, entry, serverctrls_ref)
    LDAP        * ld
    LDAPMessage * entry
    SV *          serverctrls_ref
    CODE:
    {
        int i;

        if (SvTYPE(SvRV(serverctrls_ref)) != SVt_PVAV)
        {
           croak("Net::LDAPapi::ldap_get_entry_controls needs ARRAY reference as argument 3.");
            XSRETURN(-1);
        }

        AV *serverctrls_av = (AV *)SvRV(serverctrls_ref);

        LDAPControl **serverctrls = NULL;

        RETVAL = ldap_get_entry_controls( ld, entry, &serverctrls);

        // transfer returned controls to the perl code
        if( serverctrls != NULL ) {
            for( i = 0; serverctrls[i] != NULL; i++ )
                av_push(serverctrls_av, newSViv((IV)serverctrls[i]));
        }

        free(serverctrls);

        SvRV( serverctrls_ref ) = (SV *)serverctrls_av;
    }
    OUTPUT:
    RETVAL

int
ldap_parse_result(ld, msg, errorcodep, matcheddnp, errmsgp, referrals_ref, serverctrls_ref, freeit)
    LDAP *        ld
    LDAPMessage * msg
    int           errorcodep  = NO_INIT
    SV *          matcheddnp
    SV *          errmsgp
    SV *          referrals_ref
    SV *          serverctrls_ref
    int           freeit
    CODE:
    {
        int i;

        if (SvTYPE(SvRV(referrals_ref)) != SVt_PVAV)
        {
            croak("Net::LDAPapi::ldap_parse_result needs ARRAY reference as argument 6.");
            XSRETURN(-1);
        }

        if (SvTYPE(SvRV(serverctrls_ref)) != SVt_PVAV)
        {
            croak("Net::LDAPapi::ldap_parse_result needs ARRAY reference as argument 7.");
            XSRETURN(-1);
        }

        AV *serverctrls_av = (AV *)SvRV(serverctrls_ref);
        AV *referrals_av  = (AV *)SvRV(referrals_ref);
        char *matcheddn = NULL, *errmsg = NULL;
        LDAPControl **serverctrls = NULL;
        char **referrals = NULL;

        RETVAL =
            ldap_parse_result(ld,       msg,        &errorcodep,  &matcheddn,
                              &errmsg, &referrals, &serverctrls, freeit);

        // transfer returned referrals to the perl code
        if( referrals != NULL ) {
            for( i = 0; referrals[i] != NULL; i++ )
                av_push(referrals_av, newSViv((IV)referrals[i]));
        }

        // transfer returned controls to the perl code
        if( serverctrls != NULL ) {
            for( i = 0; serverctrls[i] != NULL; i++ )
                av_push(serverctrls_av, newSViv((IV)serverctrls[i]));
        }

        if (matcheddn) {
            sv_setpv(matcheddnp, matcheddn);
            free(matcheddn);
        }
        if (errmsg) {
            sv_setpv(errmsgp, errmsg);
            free(errmsg);
        }
        free(serverctrls);
        free(referrals);

        SvRV( referrals_ref ) = (SV *)referrals_av;
        SvRV( serverctrls_ref ) = (SV *)serverctrls_av;
    }
    OUTPUT:
    RETVAL
    errorcodep
    matcheddnp
    errmsgp

int
ldap_parse_extended_result(ld, msg, retoidp, retdatap, freeit)
    LDAP        * ld
    LDAPMessage * msg
    SV *          retoidp
    SV *          retdatap
    int           freeit
    CODE:
    {
       struct berval *retdata = NULL;
       char *retoid;
      
       RETVAL =
           ldap_parse_extended_result(ld, msg, &retoid,
                                      &retdata, freeit);

       sv_setpv(retoidp, retoid);
       if (retdata != NULL) {
          sv_setpvn(retdatap, retdata->bv_val, retdata->bv_len);
          ber_bvfree(retdata);
       }
    }
    OUTPUT:
    RETVAL
    retoidp
    retdatap
   
int
ldap_parse_intermediate(ld, msg, retoidp, retdatap, serverctrls_ref, freeit)
    LDAP        * ld
    LDAPMessage * msg
    SV *          retoidp
    SV *          retdatap
    SV *          serverctrls_ref
    int           freeit
    CODE:
    {
        int i;
        struct berval *retdata = NULL;
        char *retoid;

        if (SvTYPE(SvRV(serverctrls_ref)) != SVt_PVAV)
        {
            croak("Net::LDAPapi::ldap_parse_intermediate needs ARRAY reference as argument 5.");
            XSRETURN(-1);
        }

        AV *serverctrls_av = (AV *)SvRV(serverctrls_ref);

        LDAPControl **serverctrls = NULL;

        RETVAL =
            ldap_parse_intermediate(ld,       msg,          &retoid,
                                    &retdata, &serverctrls, freeit);

        sv_setpv(retoidp, retoid);
        if( retdata != NULL ) {
            sv_setpvn(retdatap, retdata->bv_val, retdata->bv_len);
            ber_bvfree(retdata);
        }

        // transfer returned controls to the perl code
        if( serverctrls != NULL ) {
            for( i = 0; serverctrls[i] != NULL; i++ )
                av_push(serverctrls_av, newSViv((IV)serverctrls[i]));
        }

        free(serverctrls);
        free(retoid);

        SvRV( serverctrls_ref ) = (SV *)serverctrls_av;
    }
    OUTPUT:
    RETVAL
    retoidp
    retdatap

int
ldap_parse_whoami(ld, msg, authzid)
    LDAP        * ld
    LDAPMessage * msg
    SV *          authzid
    CODE:
    {
        struct berval *retdata = NULL;
      
        RETVAL =
            ldap_parse_whoami(ld, msg, &retdata);

        if (retdata != NULL) {
            sv_setpvn(authzid, retdata->bv_val, retdata->bv_len);
            ber_bvfree(retdata);
        }
    }
    OUTPUT:
    RETVAL
    authzid

char *
ldap_control_oid(control)
    LDAPControl * control
    CODE:
    {
        RETVAL = control->ldctl_oid;
    }
    OUTPUT:
    RETVAL


SV *
ldap_control_berval(control)
    LDAPControl * control
    CODE:
    {
        RETVAL = newSVpv(control->ldctl_value.bv_val, control->ldctl_value.bv_len);
    }
    OUTPUT:
    RETVAL


int
ldap_control_critical(control)
    LDAPControl * control
    CODE:
    {
        RETVAL = control->ldctl_iscritical;
    }
    OUTPUT:
    RETVAL


char *
ldap_err2string(err)
    int err


int
ldap_count_references(ld, result)
    LDAP *ld
    LDAPMessage *result


int
ldap_count_entries(ld,result)
    LDAP *          ld
    LDAPMessage *   result


LDAPMessage *
ldap_first_entry(ld,result)
    LDAP *          ld
    LDAPMessage *   result


LDAPMessage *
ldap_next_entry(ld,preventry)
    LDAP *          ld
    LDAPMessage *   preventry

LDAPMessage *
ldap_first_message(ld, chain)
    LDAP        *ld
    LDAPMessage *chain

LDAPMessage *
ldap_next_message(ld, chain)
    LDAP        *ld
    LDAPMessage *chain

SV *
ldap_get_dn(ld,entry)
    LDAP *          ld
    LDAPMessage *   entry
    PREINIT:
       char * dn;
    CODE:
    {
       dn = ldap_get_dn(ld, entry);
       if (dn)
       {
          RETVAL = newSVpv(dn,0);
          ldap_memfree(dn);
       } else {
          RETVAL = &PL_sv_undef;
       }
    }
    OUTPUT:
    RETVAL

void
ldap_perror(ld,s)
	LDAP *          ld
	LDAP_CHAR *     s

char *
ldap_dn2ufn(dn)
    LDAP_CHAR *     dn

#if defined(OPENLDAP)
int
ldap_str2dn(str,dn,flags)
    LDAP_CHAR *    str
    LDAPDN *       dn
    unsigned       flags

int ldap_str2rdn(str,rdn,n_in,flags)
    LDAP_CHAR *    str
    LDAPRDN *      rdn
    char **        n_in
    unsigned       flags

#endif

void
ldap_explode_dn(dn,notypes)
    char *          dn
    int             notypes
    PPCODE:
    {
       char ** LDAPGETVAL;
       int i;

       if ((LDAPGETVAL = ldap_explode_dn(dn,notypes)) != NULL)
       {
           for (i = 0; LDAPGETVAL[i] != NULL; i++)
           {
          EXTEND(sp,1);
          PUSHs(sv_2mortal(newSVpv(LDAPGETVAL[i],strlen(LDAPGETVAL[i]))));
           }
          ldap_value_free(LDAPGETVAL);
       }
    }

void
ldap_explode_rdn(dn,notypes)
    char *          dn
    int     notypes
    PPCODE:
    {
       char ** LDAPGETVAL;
       int i;

       if ((LDAPGETVAL = ldap_explode_rdn(dn,notypes)) != NULL)
       {
           for (i = 0; LDAPGETVAL[i] != NULL; i++)
           {
          EXTEND(sp,1);
          PUSHs(sv_2mortal(newSVpv(LDAPGETVAL[i],strlen(LDAPGETVAL[i]))));
           }
          ldap_value_free(LDAPGETVAL);
       }
    }

SV *
ldap_first_attribute(ld,entry,ber)
    LDAP *          ld
    LDAPMessage *   entry
    BerElement *    ber = NO_INIT
    PREINIT:
       char * attr;
    CODE:
    {
       attr = ldap_first_attribute(ld, entry, &ber);
       if (attr)
       {
          RETVAL = newSVpv(attr,0);
          ldap_memfree(attr);
       } else {
          RETVAL = &PL_sv_undef;
       }
    }
    OUTPUT:
    RETVAL
    ber

SV *
ldap_next_attribute(ld,entry,ber)
    LDAP *          ld
    LDAPMessage *   entry
    BerElement *    ber
    PREINIT:
       char * attr;
    CODE:
    {
       attr = ldap_next_attribute(ld, entry, ber);
       if (attr)
       {
          RETVAL = newSVpv(attr,0);
          ldap_memfree(attr);
       } else {
          RETVAL = &PL_sv_undef;
       }
    }
    OUTPUT:
    RETVAL
    ber


void
ldap_get_values_len(ld,entry,target)
    LDAP *          ld
    LDAPMessage *   entry
    char *          target
    PPCODE:
    {
       struct berval ** LDAPGETVAL;
       int i;

       if ((LDAPGETVAL = ldap_get_values_len(ld,entry,target)) != NULL)
       {
           for (i = 0; LDAPGETVAL[i] != NULL; i++)
           {
          EXTEND(sp,1);
          PUSHs(sv_2mortal(newSVpv(LDAPGETVAL[i]->bv_val,LDAPGETVAL[i]->bv_len)));
           }
       }
    }

#ifdef MOZILLA_LDAP

int
ldapssl_client_init(certdbpath,certdbhandle)
    char *          certdbpath
    void *          certdbhandle

LDAP *
ldapssl_init(defhost,defport,defsecure)
    char *          defhost
    int             defport
    int             defsecure

int
ldapssl_install_routines(ld)
    LDAP *          ld

#endif

void
ldap_set_rebind_proc(ld,rebind_function,args)
    LDAP *          ld
    SV *            rebind_function
    void *          args
    CODE:
    {
       if (SvTYPE(SvRV(rebind_function)) != SVt_PVCV)
       {
          // rebind_function is not actually a function
          // and we set rebind function to NULL
#if defined(MOZILLA_LDAP) || defined(OPENLDAP)
          ldap_set_rebind_proc(ld,NULL,NULL);
#else
          ldap_set_rebind_proc(ld,NULL);
#endif
       } else {
          if (ldap_perl_rebindproc == (SV*)NULL)
             ldap_perl_rebindproc = newSVsv(rebind_function);
          else
             SvSetSV(ldap_perl_rebindproc, rebind_function);
#if defined(OPENLDAP)
          ldap_set_rebind_proc(ld, internal_rebind_proc, args);
#endif
       }
    }

HV *
ldap_get_all_entries(ld,result)
    LDAP *          ld
    LDAPMessage *   result
    CODE:
    {
       LDAPMessage *entry = NULL;
       char *dn = NULL, *attr = NULL;
       struct berval **vals = NULL;
       BerElement *ber = NULL;
       int count = 0;
       HV*   FullHash = newHV();

       for ( entry = ldap_first_entry(ld, result); entry != NULL;
        entry = ldap_next_entry(ld, entry) )
       {
          HV* ResultHash = newHV();
          SV* HashRef = newRV((SV*) ResultHash);

          if ((dn = ldap_get_dn(ld, entry)) == NULL)
              continue;

          for ( attr = ldap_first_attribute(ld, entry, &ber);
          attr != NULL;
          attr = ldap_next_attribute(ld, entry, ber) )
          {
              AV* AttributeValsArray = newAV();
              SV* ArrayRef = newRV((SV*) AttributeValsArray);
              if ((vals = ldap_get_values_len(ld, entry, attr)) != NULL)
              {
                  for (count=0; vals[count] != NULL; count++)
                  {
                      SV* SVval = newSVpvn(vals[count]->bv_val, vals[count]->bv_len);
                      av_push(AttributeValsArray, SVval);
                  }
              }
              hv_store(ResultHash, attr, strlen(attr), ArrayRef, 0);
              if (vals != NULL)
                  ldap_value_free_len(vals);
         }
         if (attr != NULL)
             ldap_memfree(attr);
         hv_store(FullHash, dn, strlen(dn), HashRef, 0);
         if (dn != NULL)
             ldap_memfree(dn);
#if defined(MOZILLA_LDAP) || defined(OPENLDAP)
         if (ber != NULL)
            ber_free(ber,0);
#endif
       }
       RETVAL = FullHash;
    }
    OUTPUT:
    RETVAL

int
ldap_is_ldap_url(url)
    LDAP_CHAR * url

SV *
ldap_url_parse(url)
    LDAP_CHAR *      url
    CODE:
    {
       LDAPURLDesc *realcomp;
       int count,ret;

       HV*   FullHash = newHV();
       RETVAL = newRV((SV*)FullHash);

       ret = ldap_url_parse(url,&realcomp);
       if (ret == 0)
       {
          static char *host_key = "host";
          static char *port_key = "port";
          static char *dn_key = "dn";
          static char *attr_key = "attr";
          static char *scope_key = "scope";
          static char *filter_key = "filter";
#ifdef MOZILLA_LDAP
          static char *options_key = "options";
          SV* options = newSViv(realcomp->lud_options);
#endif
#ifdef OPENLDAP
          static char *scheme_key = "scheme";
          static char *exts_key = "exts";
          AV* extsarray = newAV();
          SV* extsibref = newRV((SV*) extsarray);
          SV* scheme = newSVpv(realcomp->lud_scheme,0);
#endif
          SV* host = newSVpv(realcomp->lud_host,0);
          SV* port = newSViv(realcomp->lud_port);
          SV* dn; /* = newSVpv(realcomp->lud_dn,0); */
          SV* scope = newSViv(realcomp->lud_scope);
          SV* filter = newSVpv(realcomp->lud_filter,0);
          AV* attrarray = newAV();
          SV* attribref = newRV((SV*) attrarray);

          if (realcomp->lud_dn)
                 dn = newSVpv(realcomp->lud_dn,0);
          else
             dn = newSVpv("",0);

          if (realcomp->lud_attrs != NULL)
          {
             for (count=0; realcomp->lud_attrs[count] != NULL; count++)
             {
                SV* SVval = newSVpv(realcomp->lud_attrs[count],0);
                av_push(attrarray, SVval);
             }
          }
#ifdef OPENLDAP
          if (realcomp->lud_exts != NULL)
          {
             for (count=0; realcomp->lud_exts[count] != NULL; count++)
             {
                SV* SVval = newSVpv(realcomp->lud_exts[count],0);
                av_push(extsarray, SVval);
             }
          }
          hv_store(FullHash,exts_key,strlen(exts_key),extsibref,0);
          hv_store(FullHash,scheme_key,strlen(scheme_key),scheme,0);
#endif
          hv_store(FullHash,host_key,strlen(host_key),host,0);
          hv_store(FullHash,port_key,strlen(port_key),port,0);
          hv_store(FullHash,dn_key,strlen(dn_key),dn,0);
          hv_store(FullHash,attr_key,strlen(attr_key),attribref,0);
          hv_store(FullHash,scope_key,strlen(scope_key),scope,0);
          hv_store(FullHash,filter_key,strlen(filter_key),filter,0);
#ifdef MOZILLA_LDAP
          hv_store(FullHash,options_key,strlen(options_key),options,0);
#endif
          ldap_free_urldesc(realcomp);
       } else {
          RETVAL = &PL_sv_undef;
       }
    }
    OUTPUT:
    RETVAL

#ifndef OPENLDAP

int
ldap_url_search(ld,url,attrsonly)
    LDAP *      ld
    char *      url
    int     attrsonly

int
ldap_url_search_s(ld,url,attrsonly,result)
    LDAP *      ld
    char *      url
    int     attrsonly
    LDAPMessage *   result = NO_INIT
    CODE:
    {
       RETVAL = ldap_url_search_s(ld,url,attrsonly,&result);
    }
    OUTPUT:
    RETVAL
    result

int
ldap_url_search_st(ld,url,attrsonly,timeout,result)
    LDAP *      ld
    char *      url
    int     attrsonly
    SV * timeout
    LDAPMessage *   result = NO_INIT
    CODE:
    {
       struct timeval tv_timeout;

       sv2timeval(timeout, &tv_timeout);

       RETVAL = ldap_url_search_st(ld,url,attrsonly,&tv_timeout,&result);
    }
    OUTPUT:
    RETVAL
    result

#endif

int
ldap_sort_entries(ld,chain,attr)
    LDAP *      ld
    LDAPMessage *   chain
    char *      attr
    CODE:
    {
       RETVAL = ldap_sort_entries(ld,&chain,attr,StrCaseCmp);
    }
    OUTPUT:
    RETVAL
    chain

#ifdef MOZILLA_LDAP

int
ldap_multisort_entries(ld,chain,attrs)
    LDAP *      ld
    LDAPMessage *   chain
    SV *        attrs
    CODE:
    {
       char **attrs_char;
       SV ** current;
       int count,arraylen;
           if (SvTYPE(SvRV(attrs)) == SVt_PVAV)
           {
              if ((arraylen = av_len((AV *)SvRV(attrs))) < 0)
              {
                 New(1,attrs_char,2,char *);
                 attrs_char[0] = NULL;
              } else {
                 New(1,attrs_char,arraylen+2,char *);
                 for (count=0;count <= arraylen; count++)
                 {
                    current = av_fetch((AV *)SvRV(attrs),count,0);
                    attrs_char[count] = SvPV(*current,PL_na);
                 }
                 attrs_char[arraylen+1] = NULL;
              }
           } else {
              croak("Net::LDAPapi::ldap_multisort_entries needs ARRAY reference as argument 3.");
              XSRETURN(1);
           }
       RETVAL = ldap_multisort_entries(ld,&chain,attrs_char,StrCaseCmp);
    }
    OUTPUT:
    RETVAL
    chain

#endif

#ifdef OPENLDAP

int
ldap_start_tls(ld,serverctrls,clientctrls,msgidp)
    LDAP *         ld
    LDAPControl ** serverctrls
    LDAPControl ** clientctrls
    int            msgidp = NO_INIT
    CODE:
    {
        RETVAL = ldap_start_tls(ld, serverctrls, clientctrls, &msgidp);
    }
    OUTPUT:
    RETVAL
    msgidp

int
ldap_start_tls_s(ld,serverctrls,clientctrls)
    LDAP *         ld
    LDAPControl ** serverctrls
    LDAPControl ** clientctrls


int
ldap_sasl_interactive_bind_s(ld, who, passwd, serverctrls, clientctrls, mech, realm, authzid, props, flags)
    LDAP *         ld
    LDAP_CHAR *    who
    LDAP_CHAR *    passwd
    LDAPControl ** serverctrls
    LDAPControl ** clientctrls
    LDAP_CHAR *    mech
    LDAP_CHAR *    realm
    LDAP_CHAR *    authzid
    LDAP_CHAR *    props
    unsigned       flags
    CODE:
    {
        bictx ctx = {who, passwd, realm, authzid};
        if (props)
            ldap_set_option(ld, LDAP_OPT_X_SASL_SECPROPS, props);
        RETVAL = ldap_sasl_interactive_bind_s( ld, NULL, mech, serverctrls, clientctrls,
            flags, ldap_b2_interact, &ctx );
    }
    OUTPUT:
    RETVAL

int
ldap_sasl_bind_s(ld, dn, passwd, serverctrls, clientctrls, servercredp)
    LDAP *           ld
    LDAP_CHAR *      dn
    LDAP_CHAR *      passwd
    LDAPControl **   serverctrls
    LDAPControl **   clientctrls
    struct berval ** servercredp = NO_INIT
    CODE:
    {
        struct berval cred;

        if( passwd == NULL )
            cred.bv_val = "";
        else
            cred.bv_val = passwd;

        cred.bv_len = strlen(cred.bv_val);

	servercredp = 0;	/* mdw 20070918 */
        RETVAL = ldap_sasl_bind_s(ld, dn, LDAP_SASL_SIMPLE, &cred,
                                  serverctrls, clientctrls, servercredp);
    }
    OUTPUT:
    RETVAL
    servercredp

#endif

LDAPControl **
ldap_controls_array_init(total)
    int total
    CODE:
    {
        LDAPControl ** array;
        array = malloc(total * sizeof(LDAPControl *));
        RETVAL = array;
    }
    OUTPUT:
    RETVAL

void
ldap_controls_array_free(ctrls)
    LDAPControl ** ctrls
    CODE:
    {
        //int i;
        //for( i = 0; ctrls[i] != NULL; i++ )
        //    free((LDAPControl *)ctrls[i]);

        free(ctrls);
    }


void
ldap_control_set(array, ctrl, location)
    LDAPControl **array
    LDAPControl *ctrl
    int location
    CODE:
    {
        array[location] = ctrl;
    }

int
ldap_create_control(oid, bv_val, bv_len, iscritical, ctrlp)
    LDAP_CHAR *   oid
    LDAP_CHAR *   bv_val
    int           bv_len
    int           iscritical
    LDAPControl * ctrlp = NO_INIT
    CODE:
    {
        LDAPControl *ctrl = malloc(sizeof(LDAPControl));

        ctrl->ldctl_oid          = ber_strdup(oid);
        ber_mem2bv(bv_val, bv_len, 1, &ctrl->ldctl_value);
        ctrl->ldctl_iscritical   = iscritical;

        ctrlp = ctrl;

        RETVAL = 0;
    }
    OUTPUT:
    RETVAL
    ctrlp

void
ldap_control_free (ctrl)
    LDAPControl *ctrl

BerElement *
ber_alloc_t(options);
    int options
