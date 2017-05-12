#ifndef ENUM2SV_H_INCLUDED
#define ENUM2SV_H_INCLUDED

SV *ldap_deref_aliases2sv_noinc(I32 ix);
SV *ldap_error2sv_noinc(I32 ix);
SV *ldap_op2sv_noinc(I32 ix);
SV *ldap_scope2sv_noinc(I32 ix);
SV *ldap_filter2sv_noinc(I32 ix);
SV *ldap_auth2sv_noinc(I32 ix);
SV *ldap_modop2sv_noinc(I32 ix);

#endif
