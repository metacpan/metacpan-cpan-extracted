#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include </opt/PolicyDirector/include/ivadminapi.h>

static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant_IVADMIN_PROTOBJ_TYPE__NE(char *name, int len, int arg)
{
    if (24 + 6 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[24 + 6]) {
    case 'N':
	if (strEQ(name + 24, "TSEAL_NET")) {	/* IVADMIN_PROTOBJ_TYPE__NE removed */
#ifdef IVADMIN_PROTOBJ_TYPE__NETSEAL_NET
	    return IVADMIN_PROTOBJ_TYPE__NETSEAL_NET;
#else
	    goto not_there;
#endif
	}
    case 'S':
	if (strEQ(name + 24, "TSEAL_SVR")) {	/* IVADMIN_PROTOBJ_TYPE__NE removed */
#ifdef IVADMIN_PROTOBJ_TYPE__NETSEAL_SVR
	    return IVADMIN_PROTOBJ_TYPE__NETSEAL_SVR;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_IVADMIN_PROTOBJ_TYPE__N(char *name, int len, int arg)
{
    switch (name[23 + 0]) {
    case 'E':
	return constant_IVADMIN_PROTOBJ_TYPE__NE(name, len, arg);
    case 'O':
	if (strEQ(name + 23, "ON_EXIST_OBJ")) {	/* IVADMIN_PROTOBJ_TYPE__N removed */
#ifdef IVADMIN_PROTOBJ_TYPE__NON_EXIST_OBJ
	    return IVADMIN_PROTOBJ_TYPE__NON_EXIST_OBJ;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_IVADMIN_PROTOBJ_TYPE__P(char *name, int len, int arg)
{
    switch (name[23 + 0]) {
    case 'O':
	if (strEQ(name + 23, "ORT")) {	/* IVADMIN_PROTOBJ_TYPE__P removed */
#ifdef IVADMIN_PROTOBJ_TYPE__PORT
	    return IVADMIN_PROTOBJ_TYPE__PORT;
#else
	    goto not_there;
#endif
	}
    case 'R':
	if (strEQ(name + 23, "ROGRAM")) {	/* IVADMIN_PROTOBJ_TYPE__P removed */
#ifdef IVADMIN_PROTOBJ_TYPE__PROGRAM
	    return IVADMIN_PROTOBJ_TYPE__PROGRAM;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_IVADMIN_PROTOBJ_TYPE__A(char *name, int len, int arg)
{
    if (23 + 3 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[23 + 3]) {
    case 'C':
	if (strEQ(name + 23, "PP_CONTAINER")) {	/* IVADMIN_PROTOBJ_TYPE__A removed */
#ifdef IVADMIN_PROTOBJ_TYPE__APP_CONTAINER
	    return IVADMIN_PROTOBJ_TYPE__APP_CONTAINER;
#else
	    goto not_there;
#endif
	}
    case 'L':
	if (strEQ(name + 23, "PP_LEAF")) {	/* IVADMIN_PROTOBJ_TYPE__A removed */
#ifdef IVADMIN_PROTOBJ_TYPE__APP_LEAF
	    return IVADMIN_PROTOBJ_TYPE__APP_LEAF;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_IVADMIN_PROTOBJ_TYPE__D(char *name, int len, int arg)
{
    switch (name[23 + 0]) {
    case 'I':
	if (strEQ(name + 23, "IR")) {	/* IVADMIN_PROTOBJ_TYPE__D removed */
#ifdef IVADMIN_PROTOBJ_TYPE__DIR
	    return IVADMIN_PROTOBJ_TYPE__DIR;
#else
	    goto not_there;
#endif
	}
    case 'O':
	if (strEQ(name + 23, "OMAIN")) {	/* IVADMIN_PROTOBJ_TYPE__D removed */
#ifdef IVADMIN_PROTOBJ_TYPE__DOMAIN
	    return IVADMIN_PROTOBJ_TYPE__DOMAIN;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_IVADMIN_PROTOBJ_TYPE__(char *name, int len, int arg)
{
    switch (name[22 + 0]) {
    case 'A':
	return constant_IVADMIN_PROTOBJ_TYPE__A(name, len, arg);
    case 'C':
	if (strEQ(name + 22, "CONTAINER")) {	/* IVADMIN_PROTOBJ_TYPE__ removed */
#ifdef IVADMIN_PROTOBJ_TYPE__CONTAINER
	    return IVADMIN_PROTOBJ_TYPE__CONTAINER;
#else
	    goto not_there;
#endif
	}
    case 'D':
	return constant_IVADMIN_PROTOBJ_TYPE__D(name, len, arg);
    case 'E':
	if (strEQ(name + 22, "EXTERN_AUTH_SVR")) {	/* IVADMIN_PROTOBJ_TYPE__ removed */
#ifdef IVADMIN_PROTOBJ_TYPE__EXTERN_AUTH_SVR
	    return IVADMIN_PROTOBJ_TYPE__EXTERN_AUTH_SVR;
#else
	    goto not_there;
#endif
	}
    case 'F':
	if (strEQ(name + 22, "FILE")) {	/* IVADMIN_PROTOBJ_TYPE__ removed */
#ifdef IVADMIN_PROTOBJ_TYPE__FILE
	    return IVADMIN_PROTOBJ_TYPE__FILE;
#else
	    goto not_there;
#endif
	}
    case 'H':
	if (strEQ(name + 22, "HTTP_SVR")) {	/* IVADMIN_PROTOBJ_TYPE__ removed */
#ifdef IVADMIN_PROTOBJ_TYPE__HTTP_SVR
	    return IVADMIN_PROTOBJ_TYPE__HTTP_SVR;
#else
	    goto not_there;
#endif
	}
    case 'J':
	if (strEQ(name + 22, "JNCT")) {	/* IVADMIN_PROTOBJ_TYPE__ removed */
#ifdef IVADMIN_PROTOBJ_TYPE__JNCT
	    return IVADMIN_PROTOBJ_TYPE__JNCT;
#else
	    goto not_there;
#endif
	}
    case 'L':
	if (strEQ(name + 22, "LEAF")) {	/* IVADMIN_PROTOBJ_TYPE__ removed */
#ifdef IVADMIN_PROTOBJ_TYPE__LEAF
	    return IVADMIN_PROTOBJ_TYPE__LEAF;
#else
	    goto not_there;
#endif
	}
    case 'M':
	if (strEQ(name + 22, "MGMT_OBJ")) {	/* IVADMIN_PROTOBJ_TYPE__ removed */
#ifdef IVADMIN_PROTOBJ_TYPE__MGMT_OBJ
	    return IVADMIN_PROTOBJ_TYPE__MGMT_OBJ;
#else
	    goto not_there;
#endif
	}
    case 'N':
	return constant_IVADMIN_PROTOBJ_TYPE__N(name, len, arg);
    case 'P':
	return constant_IVADMIN_PROTOBJ_TYPE__P(name, len, arg);
    case 'W':
	if (strEQ(name + 22, "WEBSEAL_SVR")) {	/* IVADMIN_PROTOBJ_TYPE__ removed */
#ifdef IVADMIN_PROTOBJ_TYPE__WEBSEAL_SVR
	    return IVADMIN_PROTOBJ_TYPE__WEBSEAL_SVR;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_IVADMIN_P(char *name, int len, int arg)
{
    if (9 + 12 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[9 + 12]) {
    case 'U':
	if (strEQ(name + 9, "ROTOBJ_TYPE_UNKNOWN")) {	/* IVADMIN_P removed */
#ifdef IVADMIN_PROTOBJ_TYPE_UNKNOWN
	    return IVADMIN_PROTOBJ_TYPE_UNKNOWN;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (!strnEQ(name + 9,"ROTOBJ_TYPE_", 12))
	    break;
	return constant_IVADMIN_PROTOBJ_TYPE__(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_IVADMIN_AUDIT_A(char *name, int len, int arg)
{
    switch (name[15 + 0]) {
    case 'D':
	if (strEQ(name + 15, "DMIN")) {	/* IVADMIN_AUDIT_A removed */
#ifdef IVADMIN_AUDIT_ADMIN
	    return IVADMIN_AUDIT_ADMIN;
#else
	    goto not_there;
#endif
	}
    case 'L':
	if (strEQ(name + 15, "LL")) {	/* IVADMIN_AUDIT_A removed */
#ifdef IVADMIN_AUDIT_ALL
	    return IVADMIN_AUDIT_ALL;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_IVADMIN_A(char *name, int len, int arg)
{
    if (9 + 5 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[9 + 5]) {
    case 'A':
	if (!strnEQ(name + 9,"UDIT_", 5))
	    break;
	return constant_IVADMIN_AUDIT_A(name, len, arg);
    case 'D':
	if (strEQ(name + 9, "UDIT_DENY")) {	/* IVADMIN_A removed */
#ifdef IVADMIN_AUDIT_DENY
	    return IVADMIN_AUDIT_DENY;
#else
	    goto not_there;
#endif
	}
    case 'E':
	if (strEQ(name + 9, "UDIT_ERROR")) {	/* IVADMIN_A removed */
#ifdef IVADMIN_AUDIT_ERROR
	    return IVADMIN_AUDIT_ERROR;
#else
	    goto not_there;
#endif
	}
    case 'N':
	if (strEQ(name + 9, "UDIT_NONE")) {	/* IVADMIN_A removed */
#ifdef IVADMIN_AUDIT_NONE
	    return IVADMIN_AUDIT_NONE;
#else
	    goto not_there;
#endif
	}
    case 'P':
	if (strEQ(name + 9, "UDIT_PERMIT")) {	/* IVADMIN_A removed */
#ifdef IVADMIN_AUDIT_PERMIT
	    return IVADMIN_AUDIT_PERMIT;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_IVADMIN_RES(char *name, int len, int arg)
{
    if (11 + 6 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[11 + 6]) {
    case 'E':
	if (strEQ(name + 11, "PONSE_ERROR")) {	/* IVADMIN_RES removed */
#ifdef IVADMIN_RESPONSE_ERROR
	    return IVADMIN_RESPONSE_ERROR;
#else
	    goto not_there;
#endif
	}
    case 'I':
	if (strEQ(name + 11, "PONSE_INFO")) {	/* IVADMIN_RES removed */
#ifdef IVADMIN_RESPONSE_INFO
	    return IVADMIN_RESPONSE_INFO;
#else
	    goto not_there;
#endif
	}
    case 'W':
	if (strEQ(name + 11, "PONSE_WARNING")) {	/* IVADMIN_RES removed */
#ifdef IVADMIN_RESPONSE_WARNING
	    return IVADMIN_RESPONSE_WARNING;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_IVADMIN_R(char *name, int len, int arg)
{
    if (9 + 1 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[9 + 1]) {
    case 'A':
	if (strEQ(name + 9, "EASON_ALREADY_EXISTS")) {	/* IVADMIN_R removed */
#ifdef IVADMIN_REASON_ALREADY_EXISTS
	    return IVADMIN_REASON_ALREADY_EXISTS;
#else
	    goto not_there;
#endif
	}
    case 'S':
	if (!strnEQ(name + 9,"E", 1))
	    break;
	return constant_IVADMIN_RES(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_IVADMIN_S(char *name, int len, int arg)
{
    if (9 + 10 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[9 + 10]) {
    case 'G':
	if (strEQ(name + 9, "SOCRED_SSOGROUP")) {	/* IVADMIN_S removed */
#ifdef IVADMIN_SSOCRED_SSOGROUP
	    return IVADMIN_SSOCRED_SSOGROUP;
#else
	    goto not_there;
#endif
	}
    case 'W':
	if (strEQ(name + 9, "SOCRED_SSOWEB")) {	/* IVADMIN_S removed */
#ifdef IVADMIN_SSOCRED_SSOWEB
	    return IVADMIN_SSOCRED_SSOWEB;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_IVADMIN_CONTEXT_D(char *name, int len, int arg)
{
    switch (name[17 + 0]) {
    case 'C':
	if (strEQ(name + 17, "CEUSERREG")) {	/* IVADMIN_CONTEXT_D removed */
#ifdef IVADMIN_CONTEXT_DCEUSERREG
	    return IVADMIN_CONTEXT_DCEUSERREG;
#else
	    goto not_there;
#endif
	}
    case 'O':
	if (strEQ(name + 17, "OMINOUSERREG")) {	/* IVADMIN_CONTEXT_D removed */
#ifdef IVADMIN_CONTEXT_DOMINOUSERREG
	    return IVADMIN_CONTEXT_DOMINOUSERREG;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_IVADMIN_CO(char *name, int len, int arg)
{
    if (10 + 6 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[10 + 6]) {
    case 'A':
	if (strEQ(name + 10, "NTEXT_ADUSERREG")) {	/* IVADMIN_CO removed */
#ifdef IVADMIN_CONTEXT_ADUSERREG
	    return IVADMIN_CONTEXT_ADUSERREG;
#else
	    goto not_there;
#endif
	}
    case 'D':
	if (!strnEQ(name + 10,"NTEXT_", 6))
	    break;
	return constant_IVADMIN_CONTEXT_D(name, len, arg);
    case 'L':
	if (strEQ(name + 10, "NTEXT_LDAPUSERREG")) {	/* IVADMIN_CO removed */
#ifdef IVADMIN_CONTEXT_LDAPUSERREG
	    return IVADMIN_CONTEXT_LDAPUSERREG;
#else
	    goto not_there;
#endif
	}
    case 'M':
	if (strEQ(name + 10, "NTEXT_MULTIDOMAIN_ADUSERREG")) {	/* IVADMIN_CO removed */
#ifdef IVADMIN_CONTEXT_MULTIDOMAIN_ADUSERREG
	    return IVADMIN_CONTEXT_MULTIDOMAIN_ADUSERREG;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_IVADMIN_C(char *name, int len, int arg)
{
    switch (name[9 + 0]) {
    case 'A':
	if (strEQ(name + 9, "ALLTYPE")) {	/* IVADMIN_C removed */
#ifdef IVADMIN_CALLTYPE
	    return IVADMIN_CALLTYPE;
#else
	    goto not_there;
#endif
	}
    case 'O':
	return constant_IVADMIN_CO(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_IVADMIN_TOD_WEE(char *name, int len, int arg)
{
    if (15 + 1 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[15 + 1]) {
    case 'D':
	if (strEQ(name + 15, "KDAY")) {	/* IVADMIN_TOD_WEE removed */
#ifdef IVADMIN_TOD_WEEKDAY
	    return IVADMIN_TOD_WEEKDAY;
#else
	    goto not_there;
#endif
	}
    case 'E':
	if (strEQ(name + 15, "KEND")) {	/* IVADMIN_TOD_WEE removed */
#ifdef IVADMIN_TOD_WEEKEND
	    return IVADMIN_TOD_WEEKEND;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_IVADMIN_TOD_W(char *name, int len, int arg)
{
    if (13 + 1 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[13 + 1]) {
    case 'D':
	if (strEQ(name + 13, "ED")) {	/* IVADMIN_TOD_W removed */
#ifdef IVADMIN_TOD_WED
	    return IVADMIN_TOD_WED;
#else
	    goto not_there;
#endif
	}
    case 'E':
	if (!strnEQ(name + 13,"E", 1))
	    break;
	return constant_IVADMIN_TOD_WEE(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_IVADMIN_TOD_A(char *name, int len, int arg)
{
    switch (name[13 + 0]) {
    case 'L':
	if (strEQ(name + 13, "LL")) {	/* IVADMIN_TOD_A removed */
#ifdef IVADMIN_TOD_ALL
	    return IVADMIN_TOD_ALL;
#else
	    goto not_there;
#endif
	}
    case 'N':
	if (strEQ(name + 13, "NY")) {	/* IVADMIN_TOD_A removed */
#ifdef IVADMIN_TOD_ANY
	    return IVADMIN_TOD_ANY;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_IVADMIN_TOD_S(char *name, int len, int arg)
{
    switch (name[13 + 0]) {
    case 'A':
	if (strEQ(name + 13, "AT")) {	/* IVADMIN_TOD_S removed */
#ifdef IVADMIN_TOD_SAT
	    return IVADMIN_TOD_SAT;
#else
	    goto not_there;
#endif
	}
    case 'U':
	if (strEQ(name + 13, "UN")) {	/* IVADMIN_TOD_S removed */
#ifdef IVADMIN_TOD_SUN
	    return IVADMIN_TOD_SUN;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_IVADMIN_TOD_T(char *name, int len, int arg)
{
    switch (name[13 + 0]) {
    case 'H':
	if (strEQ(name + 13, "HU")) {	/* IVADMIN_TOD_T removed */
#ifdef IVADMIN_TOD_THU
	    return IVADMIN_TOD_THU;
#else
	    goto not_there;
#endif
	}
    case 'U':
	if (strEQ(name + 13, "UE")) {	/* IVADMIN_TOD_T removed */
#ifdef IVADMIN_TOD_TUE
	    return IVADMIN_TOD_TUE;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_IVADMIN_TOD_M(char *name, int len, int arg)
{
    switch (name[13 + 0]) {
    case 'I':
	if (strEQ(name + 13, "INUTES")) {	/* IVADMIN_TOD_M removed */
#ifdef IVADMIN_TOD_MINUTES
	    return IVADMIN_TOD_MINUTES;
#else
	    goto not_there;
#endif
	}
    case 'O':
	if (strEQ(name + 13, "ON")) {	/* IVADMIN_TOD_M removed */
#ifdef IVADMIN_TOD_MON
	    return IVADMIN_TOD_MON;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_IVADMIN_TO(char *name, int len, int arg)
{
    if (10 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[10 + 2]) {
    case 'A':
	if (!strnEQ(name + 10,"D_", 2))
	    break;
	return constant_IVADMIN_TOD_A(name, len, arg);
    case 'F':
	if (strEQ(name + 10, "D_FRI")) {	/* IVADMIN_TO removed */
#ifdef IVADMIN_TOD_FRI
	    return IVADMIN_TOD_FRI;
#else
	    goto not_there;
#endif
	}
    case 'M':
	if (!strnEQ(name + 10,"D_", 2))
	    break;
	return constant_IVADMIN_TOD_M(name, len, arg);
    case 'O':
	if (strEQ(name + 10, "D_OCLOCK")) {	/* IVADMIN_TO removed */
#ifdef IVADMIN_TOD_OCLOCK
	    return IVADMIN_TOD_OCLOCK;
#else
	    goto not_there;
#endif
	}
    case 'S':
	if (!strnEQ(name + 10,"D_", 2))
	    break;
	return constant_IVADMIN_TOD_S(name, len, arg);
    case 'T':
	if (!strnEQ(name + 10,"D_", 2))
	    break;
	return constant_IVADMIN_TOD_T(name, len, arg);
    case 'W':
	if (!strnEQ(name + 10,"D_", 2))
	    break;
	return constant_IVADMIN_TOD_W(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_IVADMIN_TI(char *name, int len, int arg)
{
    if (10 + 3 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[10 + 3]) {
    case 'L':
	if (strEQ(name + 10, "ME_LOCAL")) {	/* IVADMIN_TI removed */
#ifdef IVADMIN_TIME_LOCAL
	    return IVADMIN_TIME_LOCAL;
#else
	    goto not_there;
#endif
	}
    case 'U':
	if (strEQ(name + 10, "ME_UTC")) {	/* IVADMIN_TI removed */
#ifdef IVADMIN_TIME_UTC
	    return IVADMIN_TIME_UTC;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_IVADMIN_T(char *name, int len, int arg)
{
    switch (name[9 + 0]) {
    case 'I':
	return constant_IVADMIN_TI(name, len, arg);
    case 'O':
	return constant_IVADMIN_TO(name, len, arg);
    case 'R':
	if (strEQ(name + 9, "RUE")) {	/* IVADMIN_T removed */
#ifdef IVADMIN_TRUE
	    return IVADMIN_TRUE;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_IVADMIN_(char *name, int len, int arg)
{
    switch (name[8 + 0]) {
    case 'A':
	return constant_IVADMIN_A(name, len, arg);
    case 'C':
	return constant_IVADMIN_C(name, len, arg);
    case 'D':
	if (strEQ(name + 8, "DECLSPEC")) {	/* IVADMIN_ removed */
#ifdef IVADMIN_DECLSPEC
	    return IVADMIN_DECLSPEC;
#else
	    goto not_there;
#endif
	}
    case 'F':
	if (strEQ(name + 8, "FALSE")) {	/* IVADMIN_ removed */
#ifdef IVADMIN_FALSE
	    return IVADMIN_FALSE;
#else
	    goto not_there;
#endif
	}
    case 'M':
	if (strEQ(name + 8, "MAXRETURN")) {	/* IVADMIN_ removed */
#ifdef IVADMIN_MAXRETURN
	    return IVADMIN_MAXRETURN;
#else
	    goto not_there;
#endif
	}
    case 'P':
	return constant_IVADMIN_P(name, len, arg);
    case 'R':
	return constant_IVADMIN_R(name, len, arg);
    case 'S':
	return constant_IVADMIN_S(name, len, arg);
    case 'T':
	return constant_IVADMIN_T(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant(char *name, int len, int arg)
{
    errno = 0;
    if (0 + 7 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[0 + 7]) {
    case 'A':
	if (strEQ(name + 0, "IVADMINAPI_H")) {	/*  removed */
#ifdef IVADMINAPI_H
	    return IVADMINAPI_H;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (!strnEQ(name + 0,"IVADMIN", 7))
	    break;
	return constant_IVADMIN_(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}


MODULE = TAM::Admin		PACKAGE = TAM::Admin		


double
constant(sv,arg)
    PREINIT:
	STRLEN		len;
    INPUT:
	SV *		sv
	char *		s = SvPV(sv, len);
	int		arg
    CODE:
	RETVAL = constant(s,len,arg);
    OUTPUT:
	RETVAL


unsigned long
ivadmin_context_create(keyringfile,keyringstashfile,keyringpassword,userid,pwd,serverdn,serverhost,port,ctx,rsp)
	char * keyringfile
	char * keyringstashfile
	char * keyringpassword
	char * userid
	char * pwd
	char * serverdn
	char * serverhost
	unsigned long port
	ivadmin_context ctx = NO_INIT
	ivadmin_response rsp = NO_INIT
   CODE:
	RETVAL = ivadmin_context_create(keyringfile,keyringstashfile,keyringpassword,userid,pwd,serverdn,serverhost,port,&ctx,&rsp);
   OUTPUT:
	ctx
	rsp
	RETVAL
	
unsigned long
ivadmin_context_createdefault(userid, pwd, ctx, rsp)
	char * userid
	char * pwd
	ivadmin_context ctx = NO_INIT
	ivadmin_response rsp = NO_INIT
   CODE:
	RETVAL = ivadmin_context_createdefault(userid,pwd,&ctx,&rsp);
   OUTPUT:
	ctx
	rsp
	RETVAL
	
unsigned long
ivadmin_context_delete(ctx,rsp)
	ivadmin_context ctx
	ivadmin_response rsp = NO_INIT
   CODE:
	RETVAL = ivadmin_context_delete(ctx, &rsp);
   OUTPUT:
	rsp
	RETVAL
	
unsigned long
ivadmin_context_setdelcred(ctx,pacValue,pacLength,rsp)
	ivadmin_context ctx
	unsigned char * pacValue
	unsigned long pacLength
	ivadmin_response rsp = NO_INIT
   CODE:
	RETVAL = ivadmin_context_setdelcred(ctx,pacValue,pacLength,&rsp);
   OUTPUT:
	rsp
	RETVAL

unsigned long
ivadmin_user_get(ctx,userid,user,rsp)
	ivadmin_context ctx
	char * userid
	ivadmin_ldapuser user = NO_INIT
	ivadmin_response rsp = NO_INIT
   CODE:
	RETVAL = ivadmin_user_get(ctx, userid, &user, &rsp);
   OUTPUT:
	user
	rsp
	RETVAL

unsigned long
ivadmin_user_getbydn(ctx,dn,user,rsp)
	ivadmin_context ctx
	char * dn
	ivadmin_ldapuser user = NO_INIT
	ivadmin_response rsp = NO_INIT
   CODE:
	RETVAL = ivadmin_user_getbydn(ctx, dn, &user, &rsp);
   OUTPUT:
	user
	rsp
	RETVAL

const char * 
ivadmin_user_getcn(user)
	ivadmin_ldapuser user

const char * 
ivadmin_user_getdn(user)
	ivadmin_ldapuser user

const char * 
ivadmin_user_getid(user)
	ivadmin_ldapuser user

const char * 
ivadmin_user_getdescription(user)
	ivadmin_ldapuser user

unsigned long
ivadmin_user_setdescription(ctx,userid,description,rsp)
	ivadmin_context ctx
	char * userid
	char * description
	ivadmin_response rsp = NO_INIT
   CODE:
	RETVAL = ivadmin_user_setdescription(ctx, userid, description, &rsp);
   OUTPUT:
	rsp
	RETVAL

unsigned long
ivadmin_user_getaccountvalid(user)
	ivadmin_ldapuser user

unsigned long
ivadmin_user_setaccountvalid(ctx,userid,valid,rsp)
	ivadmin_context ctx
	char * userid
	unsigned long valid
	ivadmin_response rsp = NO_INIT
   CODE:
	RETVAL = ivadmin_user_setaccountvalid(ctx, userid, valid, &rsp);
   OUTPUT:
	rsp
	RETVAL

unsigned long
ivadmin_response_getok(rsp)
	ivadmin_response rsp

unsigned long
ivadmin_response_getcode(rsp,index)
	ivadmin_response rsp
	unsigned long index

const char *
ivadmin_response_getmessage(rsp,index)
	ivadmin_response rsp
	unsigned long index

unsigned long
ivadmin_response_getcount(rsp)
	ivadmin_response rsp

unsigned long
ivadmin_user_import2(ctx,userid,dn,groupid,ssouser,rsp)
	ivadmin_context ctx
	char * userid
	char * dn
	char * groupid
	unsigned long ssouser
	ivadmin_response rsp = NO_INIT
   CODE:
	RETVAL = ivadmin_user_import2(ctx, userid, dn, groupid, ssouser, &rsp);
   OUTPUT:
	rsp
	RETVAL

unsigned long
ivadmin_user_getssouser(user)
	ivadmin_ldapuser user

unsigned long
ivadmin_user_setssouser(ctx,userid,ssouser,rsp)
	ivadmin_context ctx
	char * userid
	unsigned long ssouser
	ivadmin_response rsp = NO_INIT
   CODE:
	RETVAL = ivadmin_user_setssouser(ctx, userid, ssouser, &rsp);
   OUTPUT:
	rsp
	RETVAL

unsigned long
ivadmin_user_delete2(ctx,userid,registry,rsp)
	ivadmin_context ctx
	char * userid
	unsigned long registry
	ivadmin_response rsp = NO_INIT
   CODE:
	RETVAL = ivadmin_user_delete2(ctx, userid, registry, &rsp);
   OUTPUT:
	rsp
	RETVAL

const char * 
ivadmin_user_getsn(user)
	ivadmin_ldapuser user

unsigned long
ivadmin_ssocred_create(ctx,ssoid,ssotype,userid,ssouserid,ssopassword,rsp)
	ivadmin_context ctx
	char * ssoid
	unsigned long ssotype
	char * userid
	char * ssouserid
	char * ssopassword
	ivadmin_response rsp = NO_INIT
   CODE:
	RETVAL = ivadmin_ssocred_create(ctx,ssoid,ssotype,userid,ssouserid,ssopassword,&rsp);
   OUTPUT:
	rsp
	RETVAL
	
unsigned long
ivadmin_ssoweb_get(ctx,ssowebid,ssoweb,rsp)
	ivadmin_context ctx
	char * ssowebid
	ivadmin_ssoweb ssoweb = NO_INIT
	ivadmin_response rsp = NO_INIT
   CODE:
	RETVAL = ivadmin_ssoweb_get(ctx,ssowebid,&ssoweb,&rsp);
   OUTPUT:
	ssoweb
	rsp
	RETVAL

unsigned long
ivadmin_group_import2(ctx,groupid,dn,group_container,rsp)
	ivadmin_context ctx
	char * groupid
	char * dn
	char * group_container
	ivadmin_response rsp = NO_INIT
   CODE:
	RETVAL = ivadmin_group_import2(ctx,groupid,dn,group_container,&rsp);
   OUTPUT:
	rsp
	RETVAL

unsigned long
ivadmin_group_delete2(ctx,groupid,registry,rsp)
	ivadmin_context ctx
	char * groupid
	unsigned long registry
	ivadmin_response rsp = NO_INIT
   CODE:
	RETVAL = ivadmin_group_delete2(ctx, groupid, registry, &rsp);
   OUTPUT:
	rsp
	RETVAL

unsigned long
ivadmin_group_get(ctx,groupid,group,rsp)
	ivadmin_context ctx
	char * groupid
	ivadmin_ldapgroup group = NO_INIT
	ivadmin_response rsp = NO_INIT
   CODE:
	RETVAL = ivadmin_group_get(ctx, groupid, &group, &rsp);
   OUTPUT:
	group
	rsp
	RETVAL

unsigned long
ivadmin_group_getbydn(ctx,dn,group,rsp)
	ivadmin_context ctx
	char * dn
	ivadmin_ldapgroup group = NO_INIT
	ivadmin_response rsp = NO_INIT
   CODE:
	RETVAL = ivadmin_group_getbydn(ctx, dn, &group, &rsp);
   OUTPUT:
	group
	rsp
	RETVAL

const char * 
ivadmin_group_getcn(group)
	ivadmin_ldapgroup group

const char * 
ivadmin_group_getdn(group)
	ivadmin_ldapgroup group

const char * 
ivadmin_group_getdescription(group)
	ivadmin_ldapgroup group

const char * 
ivadmin_group_getid(group)
	ivadmin_ldapgroup group

unsigned long
ivadmin_group_getmembers(ctx,groupid,userids,rsp)
	ivadmin_context ctx
	char * groupid
	AV * userids
	ivadmin_response rsp = NO_INIT
   PREINIT:
	char ** ids;
	int i;
	unsigned long count;
   CODE:
	RETVAL = ivadmin_group_getmembers(ctx, groupid, &count, &ids, &rsp);
	for ( i = 0; i < count; i++ ) {
		av_push(userids, newSVpv(ids[i],0));
	}
   OUTPUT:
	userids
	rsp
	RETVAL

unsigned long
ivadmin_user_getmemberships(ctx,userid,groupids,rsp)
	ivadmin_context ctx
	char * userid
	AV * groupids
	ivadmin_response rsp = NO_INIT
   PREINIT:
	char ** ids;
	int i;
	unsigned long count;
   CODE:
	RETVAL = ivadmin_user_getmemberships(ctx, userid, &count, &ids, &rsp);
	for ( i = 0; i < count; i++ ) {
		av_push(groupids, newSVpv(ids[i],0));
	}
   OUTPUT:
	groupids
	rsp
	RETVAL

unsigned long
ivadmin_ssogroup_list(ctx,ssogroupids,rsp)
	ivadmin_context ctx
	AV * ssogroupids
	ivadmin_response rsp = NO_INIT
   PREINIT:
	char ** ids;
	int i;
	unsigned long count;
   CODE:
	RETVAL = ivadmin_ssogroup_list(ctx, &count, &ids, &rsp);
	for ( i = 0; i < count; i++ ) {
		av_push(ssogroupids, newSVpv(ids[i],0));
	}
   OUTPUT:
	ssogroupids
	rsp
	RETVAL

unsigned long
ivadmin_ssogroup_get(ctx,ssogroupid,ssogroup,rsp)
	ivadmin_context ctx
	char * ssogroupid
	ivadmin_ssogroup ssogroup = NO_INIT
	ivadmin_response rsp = NO_INIT
   CODE:
	RETVAL = ivadmin_ssogroup_get(ctx,ssogroupid,&ssogroup,&rsp);
   OUTPUT:
	ssogroup
	rsp
	RETVAL

const char * 
ivadmin_ssogroup_getid(ssogroup)
	ivadmin_ssogroup ssogroup

const char * 
ivadmin_ssogroup_getdescription(ssogroup)
	ivadmin_ssogroup ssogroup

unsigned long
ivadmin_ssogroup_getresources(ssogroup, ssoids)
	ivadmin_ssogroup ssogroup
	AV * ssoids
   PREINIT:
	char ** ids;
	int i;
	unsigned long count;
   CODE:
	RETVAL = ivadmin_ssogroup_getresources(ssogroup, &count, &ids);
	for ( i = 0; i < count; i++ ) {
		av_push(ssoids, newSVpv(ids[i],0));
	}
   OUTPUT:
	ssoids
	RETVAL

unsigned long
ivadmin_ssoweb_list(ctx,ssowebids,rsp)
	ivadmin_context ctx
	AV * ssowebids
	ivadmin_response rsp = NO_INIT
   PREINIT:
	char ** ids;
	int i;
	unsigned long count;
   CODE:
	RETVAL = ivadmin_ssoweb_list(ctx, &count, &ids, &rsp);
	for ( i = 0; i < count; i++ ) {
		av_push(ssowebids, newSVpv(ids[i],0));
	}
   OUTPUT:
	ssowebids
	rsp
	RETVAL

const char * 
ivadmin_ssoweb_getid(ssoweb)
	ivadmin_ssoweb ssoweb

const char * 
ivadmin_ssoweb_getdescription(ssoweb)
	ivadmin_ssoweb ssoweb

const char *
ivadmin_ssocred_getid(ssocred)
	ivadmin_ssocred ssocred

const char *
ivadmin_ssocred_getssouser(ssocred)
	ivadmin_ssocred ssocred

const char *
ivadmin_ssocred_getuser(ssocred)
	ivadmin_ssocred ssocred

unsigned long
ivadmin_ssocred_get(ctx,ssoid,ssotype,userid,ssocred,rsp)
	ivadmin_context ctx
	char * ssoid
	unsigned long ssotype
	char * userid
	ivadmin_ssocred ssocred = NO_INIT
	ivadmin_response rsp = NO_INIT
   CODE:
	RETVAL = ivadmin_ssocred_get(ctx,ssoid,ssotype,userid,&ssocred,&rsp);
   OUTPUT:
	ssocred
	rsp
	RETVAL

unsigned long
ivadmin_ssocred_list(ctx,userid,ssocreds,rsp)
	ivadmin_context ctx
	char * userid
	AV * ssocreds
	ivadmin_response rsp = NO_INIT
   PREINIT:
	ivadmin_ssocred * ids;
	int i;
	unsigned long count;
   CODE:
	RETVAL = ivadmin_ssocred_list(ctx, userid, &count, &ids, &rsp);
	for ( i = 0; i < count; i++ ) {
		av_push(ssocreds, newSViv(PTR2IV(ids[i])));
	}
   OUTPUT:
	ssocreds
	rsp
	RETVAL

unsigned long
ivadmin_protobj_list3(ctx,objid,objs,rsp)
        ivadmin_context ctx
        char * objid
        AV * objs
        ivadmin_response rsp = NO_INIT
   PREINIT:
	int i;
        char ** ids;
        azn_attrlist_h_t indata;
        azn_attrlist_h_t outdata;
        char ** results;
        unsigned long objcount;
        unsigned long resultcount;
   CODE:
        RETVAL = ivadmin_protobj_list3(ctx, objid, &indata, &objcount, &ids, &outdata, &resultcount, &results, &rsp);
        for ( i = 0; i < objcount; i++ ) {
                av_push(objs, newSVpv(ids[i],0));
        }
   OUTPUT:
        objs
        rsp
	RETVAL
