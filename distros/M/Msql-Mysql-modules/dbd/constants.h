#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <myMsql.h>


static double mymsql_constant(char* name, char* arg) {
    errno = 0;
    switch (*name) {
    case 'A':
	if (strEQ(name, "ANY_TYPE"))
#ifdef ANY_TYPE
	    return ANY_TYPE;
#else
	    goto not_there;
#endif
	break;
    case 'B':
	if (strEQ(name, "BLOB_FLAG"))
#ifdef BLOB_FLAG
	    return BLOB_FLAG;
#else
	goto not_there;
#endif
	break;
    case 'C':
	if (strEQ(name, "CHAR_TYPE"))
#ifdef CHAR_TYPE
	    return CHAR_TYPE;
#elif defined(DBD_MYSQL)
	    return FIELD_TYPE_STRING;
#else
	    goto not_there;
#endif
	break;
    case 'D':
	if (strEQ(name, "DATE_TYPE"))
#ifdef DATE_TYPE
	    return DATE_TYPE;
#elif defined(DBD_MYSQL)
	    return FIELD_TYPE_DATE;
#else
	    goto not_there;
#endif
	break;
    case 'F':
#ifdef DBD_MYSQL
	/*
	 *  mysql constants are implemented via enum, not as define's;
	 *  thus we cannot use "#ifdef constant"
	 */
	if (strnEQ(name, "FIELD_TYPE_", 11)) {
	    char* n = name+11;
	    switch(*n) {
	    case 'B':
		if (strEQ(n, "BLOB"))
		    return FIELD_TYPE_BLOB;
		break;
	    case 'C':
		if (strEQ(n, "CHAR"))
		    return FIELD_TYPE_CHAR;
		break;
	    case 'D':
		if (strEQ(n, "DECIMAL"))
		    return FIELD_TYPE_DECIMAL;
		if (strEQ(n, "DATE"))
		    return FIELD_TYPE_DATE;
		if (strEQ(n, "DATETIME"))
		    return FIELD_TYPE_DATETIME;
		if (strEQ(n, "DOUBLE"))
		    return FIELD_TYPE_DOUBLE;
		break;
	    case 'F':
		if (strEQ(n, "FLOAT"))
		    return FIELD_TYPE_FLOAT;
		break;
	    case 'I':
		if (strEQ(n, "INT24"))
		    return FIELD_TYPE_INT24;
		break;
	    case 'L':
		if (strEQ(n, "LONGLONG"))
		    return FIELD_TYPE_LONGLONG;
		if (strEQ(n, "LONG_BLOB"))
		    return FIELD_TYPE_LONG_BLOB;
		if (strEQ(n, "LONG"))
		    return FIELD_TYPE_LONG;
		break;
	    case 'M':
		if (strEQ(n, "MEDIUM_BLOB"))
		    return FIELD_TYPE_MEDIUM_BLOB;
		break;
	    case 'N':
		if (strEQ(n, "NULL"))
		    return FIELD_TYPE_NULL;
		break;
	    case 'S':
		if (strEQ(n, "SHORT"))
		    return FIELD_TYPE_SHORT;
		if (strEQ(n, "STRING"))
		    return FIELD_TYPE_STRING;
		break;
	    case 'T':
		if (strEQ(n, "TINY"))
#ifdef FIELD_TYPE_TINY
		    return FIELD_TYPE_TINY;
#else
		    return 1;
#endif
		if (strEQ(n, "TINY_BLOB"))
		    return FIELD_TYPE_TINY_BLOB;
		if (strEQ(n, "TIMESTAMP"))
		    return FIELD_TYPE_TIMESTAMP;
		if (strEQ(n, "TIME"))
		    return FIELD_TYPE_TIME;
		break;
	    case 'V':
		if (strEQ(n, "VAR_STRING"))
		    return FIELD_TYPE_VAR_STRING;
		break;
	    }
	}
#endif /* DBD_MYSQL */
	break;
    case 'I':
	if (strEQ(name, "IDENT_TYPE"))
#ifdef IDENT_TYPE
	    return IDENT_TYPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "INT_TYPE"))
#ifdef INT_TYPE
	    return INT_TYPE;
#elif defined(DBD_MYSQL)
	    return FIELD_TYPE_LONG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "IDX_TYPE"))
#ifdef IDX_TYPE
	    return IDX_TYPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "INT_TYPE"))
#ifdef INT_TYPE
	    return INT_TYPE;
#else
	    goto not_there;
#endif
	break;
    case 'L':
	if (strEQ(name, "LAST_REAL_TYPE"))
#ifdef LAST_REAL_TYPE
	    return LAST_REAL_TYPE;
#else
	    goto not_there;
#endif
	break;
    case 'M':
	if (strEQ(name, "MONEY_TYPE"))
#ifdef MONEY_TYPE
	    return MONEY_TYPE;
#else
	    goto not_there;
#endif
	break;
    case 'N':
	if (strEQ(name, "NOT_NULL_FLAG"))
#ifdef NOT_NULL_FLAG
	    return NOT_NULL_FLAG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NULL_TYPE"))
#ifdef NULL_TYPE
	    return NULL_TYPE;
#else
	    goto not_there;
#endif
	break;
    case 'P':
	if (strEQ(name, "PRI_KEY_FLAG"))
#ifdef PRI_KEY_FLAG
	    return PRI_KEY_FLAG;
#else
	    goto not_there;
#endif
	break;
    case 'R':
	if (strEQ(name, "REAL_TYPE"))
#ifdef REAL_TYPE
	    return REAL_TYPE;
#elif defined(DBD_MYSQL)
	    return FIELD_TYPE_DOUBLE;
#else
	    goto not_there;
#endif
	break;
    case 'S':
	if (strEQ(name, "SYSVAR_TYPE"))
#ifdef SYSVAR_TYPE
	    return SYSVAR_TYPE;
#else
	    goto not_there;
#endif
	break;
    case 'T':
	if (strEQ(name, "TEXT_TYPE"))
#ifdef TEXT_TYPE
	    return TEXT_TYPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TIME_TYPE"))
#ifdef TIME_TYPE
	    return TIME_TYPE;
#elif defined(DBD_MYSQL)
	    return FIELD_TYPE_TIME;
#else
	    goto not_there;
#endif
	break;
    case 'U':
	if (strEQ(name, "UINT_TYPE"))
#ifdef UINT_TYPE
	    return UINT_TYPE;
#else
	    goto not_there;
#endif
	break;
    case 'V':
	if (strEQ(name, "VARCHAR_TYPE"))
#ifdef VARCHAR_TYPE
	    return VARCHAR_TYPE;
#elif defined(DBD_MYSQL)
	    return FIELD_TYPE_VAR_STRING;
#else
	    goto not_there;
#endif
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

