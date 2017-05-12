/****************************************************************************/
/* ldap_compat.h - Header file to add ldap_*_option support and other       */
/*     Functions to NON-Mozilla Development Kits.                           */
/* Author: Clayton Donley - donley@wwa.com                                  */
/* Date:   Tue Aug 26 13:13:32 CDT 1997                                     */
/****************************************************************************/

#define ldap_memfree(x) Safefree(x)

/*
 * OpenLDAP already defines these macros
 */

#ifndef OPENLDAP
#define LDAP_OPT_DEREF 2
#define LDAP_OPT_SIZELIMIT 3
#define LDAP_OPT_TIMELIMIT 4
#define LDAP_OPT_REFERRALS 8

#define LDAP_OPT_ON  1
#define LDAP_OPT_OFF 0
#endif
