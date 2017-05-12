/*
 *  DBD::mysql - DBI driver for the mysql database
 *
 *  Copyright (c) 1997, 1998  Jochen Wiedmann
 *
 *  You may distribute this under the terms of either the GNU General Public
 *  License or the Artistic License, as specified in the Perl README file,
 *  with the exception that it cannot be placed on a CD-ROM or similar media
 *  for commercial distribution without the prior approval of the author.
 *
 *  Author:  Jochen Wiedmann
 *           Am Eisteich 9
 *           72555 Metzingen
 *           Germany
 *
 *           Email: joe@ispsoft.de
 *           Fax: +49 7123 / 14892
 *
 *
 *  $Id: dbdimp.c,v 1.5 1999/09/21 08:51:08 joe Exp $
 */


#ifdef WIN32
#include "windows.h"
#include "winsock.h"
#endif

#include "dbdimp.h"

#if defined(WIN32)  &&  defined(WORD)
    /*  Don't exactly know who's responsible for defining WORD ... :-(  */
#undef WORD
typedef short WORD;
#endif


#include "bindparam.h"


DBISTATE_DECLARE;

#if defined(DBD_MYSQL)  &&  (MYSQL_VERSION_ID >= 32300 || defined(mysql_errno))
#define have_mysql_errno
#endif
#if defined(DBD_MYSQL)  &&  defined(have_mysql_errno)
#define DO_ERROR(h, c, s) do_error(h, (int) mysql_errno(s), mysql_error(s))
#else
#define DO_ERROR(h, c, s) do_error(h, c, MyError(s))
#endif


typedef struct sql_type_info_s {
    const char* type_name;
    int data_type;
    int column_size;
    const char* literal_prefix;
    const char* literal_suffix;
    const char* create_params;
    int nullable;
    int case_sensitive;
    int searchable;
    int unsigned_attribute;
    int fixed_prec_scale;
    int auto_unique_value;
    const char* local_type_name;
    int minimum_scale;
    int maximum_scale;
    int num_prec_radix;
    int native_type;
    int is_num;
} sql_type_info_t;

#if defined(DBD_MYSQL)

/*
 *  The order of the following is important: The first column of a given
 *  data_type is choosen to represent all columns of the same type.
 */
static const sql_type_info_t SQL_GET_TYPE_INFO_values[] = {
  { "varchar",    SQL_VARCHAR,                    255, "'",  "'",  "max length",
    1, 0, 1, 0, 0, 0, "variable length string",
    0, 0, 0, FIELD_TYPE_VAR_STRING,  0
    /* 0 */
  },
  { "decimal",   SQL_DECIMAL,                      15, NULL, NULL, "precision,scale",
    1, 0, 1, 0, 0, 0, "double",
    0, 6, 2, FIELD_TYPE_DECIMAL,     1
    /* 1 */
  },
  { "tinyint",   SQL_TINYINT,                       3, NULL, NULL, NULL,
    1, 0, 1, 0, 0, 0, "Tiny integer",
    0, 0, 10, FIELD_TYPE_TINY,        1
    /* 2 */
  },
  { "smallint",  SQL_SMALLINT,                      5, NULL, NULL, NULL,
    1, 0, 1, 0, 0, 0, "Short integer",
    0, 0, 10, FIELD_TYPE_SHORT,       1
    /* 3 */
  },
  { "integer",   SQL_INTEGER,                      10, NULL, NULL, NULL,
    1, 0, 1, 0, 0, 0, "integer",
    0, 0, 10, FIELD_TYPE_LONG,        1
    /* 4 */
  },
  { "float",     SQL_REAL,                          7,  NULL, NULL, NULL,
    1, 0, 0, 0, 0, 0, "float",
    0, 2, 2, FIELD_TYPE_FLOAT,       1
    /* 5 */
  },
  { "double",    SQL_DOUBLE,                       15,  NULL, NULL, NULL,
    1, 0, 1, 0, 0, 0, "double",
    0, 4, 2, FIELD_TYPE_DOUBLE,      1
    /* 6 */
  },
  /*
    FIELD_TYPE_NULL ?
  */
  { "timestamp", SQL_TIMESTAMP,                    14, "'", "'", NULL,
    0, 0, 1, 0, 0, 0, "timestamp",
    0, 0, 0, FIELD_TYPE_TIMESTAMP,   0
    /* 7 */
  },
  { "bigint",    SQL_BIGINT,                       20, NULL, NULL, NULL,
    1, 0, 1, 0, 0, 0, "Longlong integer",
    0, 0, 10, FIELD_TYPE_LONGLONG,    1
    /* 8 */
  },
  { "middleint", SQL_INTEGER,                       8, NULL, NULL, NULL,
    1, 0, 1, 0, 0, 0, "Medium integer",
    0, 0, 10, FIELD_TYPE_INT24,       1
    /* 9 */
  },
  { "date",      SQL_DATE,                         10, "'",  "'",  NULL,
    1, 0, 1, 0, 0, 0, "date",
    0, 0, 0, FIELD_TYPE_DATE,        0
    /* 10 */
  },
  { "time",      SQL_TIME,                          6, "'",  "'",  NULL,
    1, 0, 1, 0, 0, 0, "time",
    0, 0, 0, FIELD_TYPE_TIME,        0
    /* 11 */
  },
  { "datetime",  SQL_TIMESTAMP,                    21, "'",  "'",  NULL,
    1, 0, 1, 0, 0, 0, "datetime",
    0, 0, 0, FIELD_TYPE_DATETIME,    0
    /* 12 */
  },
  { "year",      SQL_SMALLINT,                      4, NULL, NULL, NULL,
    1, 0, 1, 0, 0, 0, "year",
    0, 0, 0, FIELD_TYPE_YEAR,        0
    /* 13 */
  },
  { "date",      SQL_DATE,                         10, "'",  "'",  NULL,
    1, 0, 1, 0, 0, 0, "date",
    0, 0, 0, FIELD_TYPE_NEWDATE,     0
    /* 14 */
  },
  { "enum",      SQL_VARCHAR,                     255, "'",  "'",  NULL,
    1, 0, 1, 0, 0, 0, "enum(value1,value2,value3...)",
    0, 0, 0, FIELD_TYPE_ENUM,        0
    /* 15 */
  },
  { "set",       SQL_VARCHAR,                     255, "'",  "'",  NULL,
    1, 0, 1, 0, 0, 0, "set(value1,value2,value3...)",
    0, 0, 0, FIELD_TYPE_SET,         0
    /* 16 */
  },
  { "blob",       SQL_LONGVARCHAR,              65535, "'",  "'",  NULL,
    1, 0, 1, 0, 0, 0, "binary large object (0-65535)",
    0, 0, 0, FIELD_TYPE_BLOB,        0
    /* 17 */
  },
  { "tinyblob",  SQL_LONGVARCHAR,                 255, "'",  "'",  NULL,
    1, 0, 1, 0, 0, 0, "binary large object (0-255) ",
    0, 0, 0, FIELD_TYPE_TINY_BLOB,   0
    /* 18 */
  },
  { "mediumblob", SQL_LONGVARCHAR,           16777215, "'",  "'",  NULL,
    1, 0, 1, 0, 0, 0, "binary large object",
    0, 0, 0, FIELD_TYPE_MEDIUM_BLOB, 0
    /* 19 */
  },
  { "longblob",   SQL_LONGVARCHAR,         2147483647, "'",  "'",  NULL,
    1, 0, 1, 0, 0, 0, "binary large object, use mediumblob instead",
    0, 0, 0, FIELD_TYPE_LONG_BLOB,   0
    /* 20 */
  },
  { "char",       SQL_CHAR,                       255, "'",  "'",  "max length",
    1, 0, 1, 0, 0, 0, "string",
    0, 0, 0, FIELD_TYPE_STRING,      0
    /* 21 */
  },

  { "decimal",            SQL_NUMERIC,            15,  NULL, NULL, "precision,scale",
    1, 0, 1, 0, 0, 0, "double",
    0, 6, 2, FIELD_TYPE_DECIMAL,     1
  },
  /*
  { "tinyint",            SQL_BIT,                  3, NULL, NULL, NULL,
    1, 0, 1, 0, 0, 0, "Tiny integer",
    0, 0, 10, FIELD_TYPE_TINY,        1
  },
  */
  { "tinyint unsigned",   SQL_TINYINT,              3, NULL, NULL, NULL,
    1, 0, 1, 1, 0, 0, "Tiny integer unsigned",
    0, 0, 10, FIELD_TYPE_TINY,        1
  },
  { "smallint unsigned",  SQL_SMALLINT,             5, NULL, NULL, NULL,
    1, 0, 1, 1, 0, 0, "Short integer unsigned",
    0, 0, 10, FIELD_TYPE_SHORT,       1
  },
  { "middleint unsigned", SQL_INTEGER,              8, NULL, NULL, NULL,
    1, 0, 1, 1, 0, 0, "Medium integer unsigned",
    0, 0, 10, FIELD_TYPE_INT24,       1
  },
  { "int unsigned",       SQL_INTEGER,             10, NULL, NULL, NULL,
    1, 0, 1, 1, 0, 0, "integer unsigned",
    0, 0, 10, FIELD_TYPE_LONG,        1
  },
  { "int",                SQL_INTEGER,             10, NULL, NULL, NULL,
    1, 0, 1, 0, 0, 0, "integer",
    0, 0, 10, FIELD_TYPE_LONG,        1
  },
  { "integer unsigned",   SQL_INTEGER,             10, NULL, NULL, NULL,
    1, 0, 1, 1, 0, 0, "integer",
    0, 0, 10, FIELD_TYPE_LONG,        1
  },
  { "bigint unsigned",    SQL_BIGINT,              20, NULL, NULL, NULL,
    1, 0, 1, 1, 0, 0, "Longlong integer unsigned",
    0, 0, 10, FIELD_TYPE_LONGLONG,    1
  },
  { "text",               SQL_LONGVARCHAR,      65535, "'",  "'",  NULL,
    1, 0, 1, 0, 0, 0, "large text object (0-65535)",
    0, 0, 0, FIELD_TYPE_BLOB,        0
  },
  { "mediumtext",         SQL_LONGVARCHAR,   16777215, "'",  "'",  NULL,
    1, 0, 1, 0, 0, 0, "large text object",
    0, 0, 0, FIELD_TYPE_MEDIUM_BLOB, 0
  }
};


static const sql_type_info_t* native2sql (int t) {
    switch (t) {
      case FIELD_TYPE_VAR_STRING:  return &SQL_GET_TYPE_INFO_values[0];
      case FIELD_TYPE_DECIMAL:     return &SQL_GET_TYPE_INFO_values[1];
      case FIELD_TYPE_TINY:        return &SQL_GET_TYPE_INFO_values[2];
      case FIELD_TYPE_SHORT:       return &SQL_GET_TYPE_INFO_values[3];
      case FIELD_TYPE_LONG:        return &SQL_GET_TYPE_INFO_values[4];
      case FIELD_TYPE_FLOAT:       return &SQL_GET_TYPE_INFO_values[5];
      case FIELD_TYPE_DOUBLE:      return &SQL_GET_TYPE_INFO_values[6];
      case FIELD_TYPE_TIMESTAMP:   return &SQL_GET_TYPE_INFO_values[7];
      case FIELD_TYPE_LONGLONG:    return &SQL_GET_TYPE_INFO_values[8];
      case FIELD_TYPE_INT24:       return &SQL_GET_TYPE_INFO_values[9];
      case FIELD_TYPE_DATE:        return &SQL_GET_TYPE_INFO_values[10];
      case FIELD_TYPE_TIME:        return &SQL_GET_TYPE_INFO_values[11];
      case FIELD_TYPE_DATETIME:    return &SQL_GET_TYPE_INFO_values[12];
      case FIELD_TYPE_YEAR:        return &SQL_GET_TYPE_INFO_values[13];
      case FIELD_TYPE_NEWDATE:     return &SQL_GET_TYPE_INFO_values[14];
      case FIELD_TYPE_ENUM:        return &SQL_GET_TYPE_INFO_values[15];
      case FIELD_TYPE_SET:         return &SQL_GET_TYPE_INFO_values[16];
      case FIELD_TYPE_BLOB:        return &SQL_GET_TYPE_INFO_values[17];
      case FIELD_TYPE_TINY_BLOB:   return &SQL_GET_TYPE_INFO_values[18];
      case FIELD_TYPE_MEDIUM_BLOB: return &SQL_GET_TYPE_INFO_values[19];
      case FIELD_TYPE_LONG_BLOB:   return &SQL_GET_TYPE_INFO_values[20];
      case FIELD_TYPE_STRING:      return &SQL_GET_TYPE_INFO_values[21];
      default:                     return &SQL_GET_TYPE_INFO_values[0];
    }
}

#else

const sql_type_info_t SQL_GET_TYPE_INFO_values[] = {
  { "int",       SQL_INTEGER,                      10, NULL, NULL, NULL,
    1, 0, 1, 0, 0, 0, "integer",
    0, 0, 10, INT_TYPE,    1
    /* 0 */
  },
  { "char",    SQL_VARCHAR,                       255, "'",  "'",  "max length",
    1, 0, 1, 0, 0, 0, "variable length string",
    0, 0, 0, CHAR_TYPE,   0
    /* 1 */
  },
  { "real",     SQL_REAL,                           7,  NULL, NULL, NULL,
    1, 0, 0, 0, 0, 0, "float",
    0, 2, 2, REAL_TYPE,   1
    /* 2 */
  },
  { "ident",    SQL_VARCHAR,                      255, "'",  "'",  "max length",
    1, 0, 1, 0, 0, 0, "identifier",
    0, 0, 0, IDENT_TYPE,  0
    /* 3 */
  },
  { "null",     SQL_VARCHAR,                      255, "'",  "'",  "max length",
    1, 0, 1, 0, 0, 0, "null type",
    0, 0, 0, NULL_TYPE,   0
    /* 4 */
  },
#if defined(TEXT_TYPE)
  { "text",     SQL_LONGVARCHAR,                  255, "'",  "'",  "max length",
    1, 0, 1, 0, 0, 0, "text type",
    0, 0, 0, TEXT_TYPE,   0
    /* 5 */
  },
  { "date",      SQL_DATE,                         10, "'",  "'",  NULL,
    1, 0, 1, 0, 0, 0, "date",
    0, 0, 0, DATE_TYPE,   0
    /* 6 */
  },
  { "uint",      SQL_INTEGER,                      10, NULL, NULL, NULL,
    1, 0, 1, 1, 0, 0, "integer unsigned",
    0, 0, 10, UINT_TYPE,   1
    /* 7 */
  },
  { "money",     SQL_VARCHAR,                      10, NULL,  NULL,  NULL,
    1, 0, 1, 0, 1, 0, "money type",
    0, 0, 10, MONEY_TYPE,  1
    /* 8 */
  },
  { "time",      SQL_TIME,                          6, NULL, NULL, NULL,
    1, 0, 1, 0, 0, 0, "time",
    0, 0, 0, TIME_TYPE,   0
    /* 9 */
  },
  { "idx",     SQL_VARCHAR,                       255, "'",  "'",  "max length",
    1, 0, 1, 0, 0, 0, "index type",
    0, 0, 0, IDX_TYPE,    0
    /* 10 */
  },
  { "sysvar",  SQL_VARCHAR,                       255, "'",  "'",  "max length",
    1, 0, 1, 0, 0, 0, "sysvar type",
    0, 0, 0, SYSVAR_TYPE, 0
    /* 11 */
  },
#endif
};

const sql_type_info_t* native2sql (int t) {
    switch (t) {
      case INT_TYPE:     return &SQL_GET_TYPE_INFO_values[0];
      case CHAR_TYPE:    return &SQL_GET_TYPE_INFO_values[1];
      case REAL_TYPE:    return &SQL_GET_TYPE_INFO_values[2];
      case IDENT_TYPE:   return &SQL_GET_TYPE_INFO_values[3];
      case NULL_TYPE:    return &SQL_GET_TYPE_INFO_values[4];
#if defined(TEXT_TYPE)
      case TEXT_TYPE:    return &SQL_GET_TYPE_INFO_values[5];
      case DATE_TYPE:    return &SQL_GET_TYPE_INFO_values[6];
      case UINT_TYPE:    return &SQL_GET_TYPE_INFO_values[7];
      case MONEY_TYPE:   return &SQL_GET_TYPE_INFO_values[8];
      case TIME_TYPE:    return &SQL_GET_TYPE_INFO_values[9];
      case IDX_TYPE:     return &SQL_GET_TYPE_INFO_values[10];
      case SYSVAR_TYPE:  return &SQL_GET_TYPE_INFO_values[11];
#endif
      default:           return &SQL_GET_TYPE_INFO_values[1];
    }
}

#endif

#define SQL_GET_TYPE_INFO_num \
	(sizeof(SQL_GET_TYPE_INFO_values)/sizeof(sql_type_info_t))


/***************************************************************************
 *
 *  Name:    dbd_init
 *
 *  Purpose: Called when the driver is installed by DBI
 *
 *  Input:   dbistate - pointer to the DBIS variable, used for some
 *               DBI internal things
 *
 *  Returns: Nothing
 *
 **************************************************************************/

void dbd_init(dbistate_t* dbistate) {
    DBIS = dbistate;
}


/***************************************************************************
 *
 *  Name:    do_error, do_warn
 *
 *  Purpose: Called to associate an error code and an error message
 *           to some handle
 *
 *  Input:   h - the handle in error condition
 *           rc - the error code
 *           what - the error message
 *
 *  Returns: Nothing
 *
 **************************************************************************/

void do_error(SV* h, int rc, char* what) {
    D_imp_xxh(h);
    STRLEN lna;

    SV *errstr = DBIc_ERRSTR(imp_xxh);
    sv_setiv(DBIc_ERR(imp_xxh), (IV)rc);	/* set err early	*/
    sv_setpv(errstr, what);
    DBIh_EVENT2(h, ERROR_event, DBIc_ERR(imp_xxh), errstr);
    if (dbis->debug >= 2)
	PerlIO_printf(DBILOGFP, "%s error %d recorded: %s\n",
		      what, rc, SvPV(errstr,lna));
}
void do_warn(SV* h, int rc, char* what) {
    D_imp_xxh(h);
    STRLEN lna;

    SV *errstr = DBIc_ERRSTR(imp_xxh);
    sv_setiv(DBIc_ERR(imp_xxh), (IV)rc);	/* set err early	*/
    sv_setpv(errstr, what);
    DBIh_EVENT2(h, WARN_event, DBIc_ERR(imp_xxh), errstr);
    if (dbis->debug >= 2)
	PerlIO_printf(DBILOGFP, "%s warning %d recorded: %s\n",
		      what, rc, SvPV(errstr,lna));
    warn("%s", what);
}
#define doquietwarn(s)                                            \
    {                                                             \
        SV* sv = perl_get_sv("DBD::~~dbd_driver~~::QUIET", FALSE);  \
        if (!sv  ||  !SvTRUE(sv)) {                               \
	    warn s;                                               \
	}                                                         \
    }



/***************************************************************************
 *
 *  Name:    _MyLogin, MyConnect
 *
 *  Purpose: Replacements for mysql_connect or msqlConnect
 *
 *  Input:   imp_dbh - database handle
 *
 *  Returns: TRUE for success, FALSE otherwise; you have to call
 *           do_error in the latter case.
 *
 *  Bugs:    The msql version needs to set the environment
 *           variable MSQL_TCP_PORT. There's absolutely no
 *           portable way of setting environment variables
 *           from within C: Neither setenv() nor putenv()
 *           are guaranteed to work. I have decided to use
 *           the internal perl functions setenv_getix()
 *           and my_setenv() instead, let's hope, this is safe.
 *
 *           Another problem was pointed out by Andreas:
 *           This isn't thread safe. We'll have fun with perl
 *           5.005 ... :-)
 *
 **************************************************************************/

int MyConnect(dbh_t *sock, char* unixSocket, char* host, char* port,
	      char* user, char* password, char* dbname, imp_dbh_t *imp_dbh) {
    int portNr;

    if (host && !*host) host = NULL;
    if (port && *port) {
        portNr = atoi(port);
    } else {
        portNr = 0;
    }
    if (user && !*user) user = NULL;
    if (password && !*password) password = NULL;

    if (dbis->debug >= 2)
        PerlIO_printf(DBILOGFP,
		      "imp_dbh->MyConnect: host = %s, port = %d, uid = %s," \
		      " pwd = %s\n",
		      host ? host : "NULL", portNr,
		      user ? user : "NULL",
		      password ? password : "NULL");

#ifdef DBD_MYSQL
    {
#ifdef MYSQL_USE_CLIENT_FOUND_ROWS
        unsigned int client_flag = CLIENT_FOUND_ROWS;
#else
	unsigned int client_flag = 0;
#endif
	mysql_init(*sock);

	if (imp_dbh) {
	    SV* sv = DBIc_IMP_DATA(imp_dbh);
	    imp_dbh->has_transactions = TRUE;
	    DBIc_set(imp_dbh, DBIcf_AutoCommit, &sv_yes);
	    if (sv  &&  SvROK(sv)) {
	        HV* hv = (HV*) SvRV(sv);
		SV** svp;
		STRLEN lna;

		if ((svp = hv_fetch(hv, "mysql_compression", 17, FALSE))  &&
		    *svp  &&  SvTRUE(*svp)) {
		    if (dbis->debug >= 2)
		        PerlIO_printf(DBILOGFP,
				      "imp_dbh->MyConnect: Enabling" \
				      " compression.\n");
		    mysql_options(*sock, MYSQL_OPT_COMPRESS, NULL);
		}
		if ((svp = hv_fetch(hv, "mysql_connect_timeout", 21, FALSE))
		    &&  *svp  &&  SvTRUE(*svp)) {
		  int to = SvIV(*svp);
		  if (dbis->debug >= 2)
		    PerlIO_printf(DBILOGFP,
				  "imp_dbh->MyConnect: Setting" \
				  " connect timeout (%d).\n",to);
		  mysql_options(*sock, MYSQL_OPT_CONNECT_TIMEOUT,
				(const char *)&to);
		}
		if ((svp = hv_fetch(hv, "mysql_read_default_file", 23,
				    FALSE))  &&
		    *svp  &&  SvTRUE(*svp)) {
		    char* df = SvPV(*svp, lna);
		    if (dbis->debug >= 2)
		        PerlIO_printf(DBILOGFP,
				      "imp_dbh->MyConnect: Reading" \
				      " default file %s.\n", df);
		    mysql_options(*sock, MYSQL_READ_DEFAULT_FILE, df);
		}
		if ((svp = hv_fetch(hv, "mysql_read_default_group", 24,
				    FALSE))  &&
		    *svp  &&  SvTRUE(*svp)) {
		    char* gr = SvPV(*svp, lna);
		    if (dbis->debug >= 2)
		        PerlIO_printf(DBILOGFP,
				      "imp_dbh->MyConnect: Using" \
				      " default group %s.\n", gr);
		    mysql_options(*sock, MYSQL_READ_DEFAULT_GROUP, gr);
		}
		if ((svp = hv_fetch(hv, "mysql_client_found_rows", 23,
				    FALSE))  &&  *svp) {
		    if (SvTRUE(*svp)) {
		        client_flag |= CLIENT_FOUND_ROWS;
		    } else {
		        client_flag &= ~CLIENT_FOUND_ROWS;
		    }
		}
	    }
        }
	if (dbis->debug >= 2)
	  PerlIO_printf(DBILOGFP, "imp_dbh->MyConnect: client_flags = %d\n",
			client_flag);
        return mysql_real_connect(*sock, host, user, password, dbname,
				  portNr, unixSocket, client_flag) ?
	  TRUE : FALSE;
    }
#else
    {
        /*
	 *  Setting a port for msql's client is extremely ugly: We have
	 *  to set an environment variable. Even worse, we cannot trust
	 *  in setenv or putenv being present, thus we need to use
	 *  internal, not documented, perl functions. :-(
	 */
        char buffer[32];
	char* oldPort = NULL;

	if (imp_dbh) {
	    imp_dbh->has_transactions = FALSE;
	    DBIc_set(imp_dbh, DBIcf_AutoCommit, &sv_yes);
	}

	sprintf(buffer, "%d", portNr);
	if (portNr) {
	    oldPort = environ[setenv_getix("MSQL_TCP_PORT")];
	    if (oldPort) {
	        char* copy = (char*) malloc(strlen(oldPort)+1);
		if (!copy) {
		    return FALSE;
		}
		strcpy(copy, oldPort);
		oldPort = copy;
	    }
	    my_setenv("MSQL_TCP_PORT", buffer);
	}
	*sock = msqlConnect(host);
	if (oldPort) {
	    my_setenv("MSQL_TCP_PORT", oldPort);
	    if (oldPort) { free(oldPort); }
	}
	if (*sock != -1  &&  dbname  &&  MySelectDb(*sock, dbname)) {
	    MyClose(*sock);
	    *sock = -1;
	}
	return (*sock == -1) ? FALSE : TRUE;
    }
#endif
}

static int _MyLogin(imp_dbh_t *imp_dbh) {
    SV* sv;
    SV** svp;
    HV* hv;
    char* dbname;
    char* host;
    char* port;
    char* user;
    char* password;
    char* unixSocket = NULL;
    STRLEN len, lna;

    sv = DBIc_IMP_DATA(imp_dbh);
    if (!sv  ||  !SvROK(sv)) {
        return FALSE;
    }
    hv = (HV*) SvRV(sv);
    if (SvTYPE(hv) != SVt_PVHV) {
        return FALSE;
    }
    if ((svp = hv_fetch(hv, "host", 4, FALSE))) {
        host = SvPV(*svp, len);
	if (!len) {
	    host = NULL;
	}
    } else {
        host = NULL;
    }
    if ((svp = hv_fetch(hv, "port", 4, FALSE))) {
        port = SvPV(*svp, lna);
    } else {
        port = NULL;
    }
    if ((svp = hv_fetch(hv, "user", 4, FALSE))) {
        user = SvPV(*svp, len);
	if (!len) {
	    user = NULL;
	}
    } else {
        user = NULL;
    }
    if ((svp = hv_fetch(hv, "password", 8, FALSE))) {
        password = SvPV(*svp, len);
	if (!len) {
	    password = NULL;
	}
    } else {
        password = NULL;
    }
    if ((svp = hv_fetch(hv, "database", 8, FALSE))) {
        dbname = SvPV(*svp, lna);
    } else {
        dbname = NULL;
    }
#ifdef DBD_MYSQL
    if ((svp = hv_fetch(hv, "mysql_socket", 12, FALSE))  &&
        *svp  &&  SvTRUE(*svp)) {
        unixSocket = SvPV(*svp, lna);
    }
#elif defined(IDX_TYPE)
    if ((svp = hv_fetch(hv, "msql_configfile", 15, FALSE))  &&
        *svp  &&  SvOK(*svp)) {
        char* cf = SvPV(*svp, lna);
        if (dbis->debug >= 2) {
            PerlIO_printf(DBILOGFP,
			  "imp_dbh->MyLogin: Loading config file %s\n",
                    cf);
        }
        if (msqlLoadConfigFile(cf) == -1) {
            croak("Failed to load config file %s", cf);
        }
    }
    if (port != 0) {
        doquietwarn(("Port settings are meaningless with mSQL 2." \
		     " Use msql_configfile instead."));  /* 1.21_07 */
    }
#endif

    if (dbis->debug >= 2)
        PerlIO_printf(DBILOGFP,
		      "imp_dbh->MyLogin: dbname = %s, uid = %s, pwd = %s," \
		      "host = %s, port = %s\n",
		      dbname ? dbname : "NULL",
		      user ? user : "NULL",
		      password ? password : "NULL",
		      host ? host : "NULL",
		      port ? port : "NULL");

#ifdef DBD_MYSQL
    imp_dbh->svsock = &imp_dbh->mysql;
#endif

    return MyConnect(&imp_dbh->svsock, unixSocket, host, port, user, password,
		     dbname, imp_dbh);
}


/***************************************************************************
 *
 *  Name:    dbd_db_login
 *
 *  Purpose: Called for connecting to a database and logging in.
 *
 *  Input:   dbh - database handle being initialized
 *           imp_dbh - drivers private database handle data
 *           dbname - the database we want to log into; may be like
 *               "dbname:host" or "dbname:host:port"
 *           user - user name to connect as
 *           password - passwort to connect with
 *
 *  Returns: TRUE for success, FALSE otherwise; do_error has already
 *           been called in the latter case
 *
 **************************************************************************/

int dbd_db_login(SV* dbh, imp_dbh_t* imp_dbh, char* dbname, char* user,
		 char* password) {
#ifdef dTHR
    dTHR;
#endif

    if (dbis->debug >= 2)
        PerlIO_printf(DBILOGFP,
		      "imp_dbh->connect: dsn = %s, uid = %s, pwd = %s\n",
		      dbname ? dbname : "NULL",
		      user ? user : "NULL",
		      password ? password : "NULL");

    if (!_MyLogin(imp_dbh)) {
	DO_ERROR(dbh, MyErrno(imp_dbh->svsock, JW_ERR_CONNECT),
		 imp_dbh->svsock);
	return FALSE;
    }

    /*
     *  Tell DBI, that dbh->disconnect should be called for this handle
     */
    DBIc_ACTIVE_on(imp_dbh);

    /*
     *  Tell DBI, that dbh->destroy should be called for this handle
     */
    DBIc_on(imp_dbh, DBIcf_IMPSET);

    return TRUE;
}


/***************************************************************************
 *
 *  Name:    dbd_db_commit
 *           dbd_db_rollback
 *
 *  Purpose: You guess what they should do. mSQL doesn't support
 *           transactions, so we stub commit to return OK
 *           and rollback to return ERROR in any case.
 *
 *  Input:   dbh - database handle being commited or rolled back
 *           imp_dbh - drivers private database handle data
 *
 *  Returns: TRUE for success, FALSE otherwise; do_error has already
 *           been called in the latter case
 *
 **************************************************************************/

int dbd_db_commit(SV* dbh, imp_dbh_t* imp_dbh) {
    if (DBIc_has(imp_dbh, DBIcf_AutoCommit)) {
        do_warn(dbh, TX_ERR_AUTOCOMMIT,
		"Commmit ineffective while AutoCommit is on");
	return TRUE;
    }

    if (imp_dbh->has_transactions) {
      if (MyQuery(imp_dbh->svsock, "COMMIT", 6) != 0) {
        do_error(dbh, TX_ERR_COMMIT, "Commit failed");
	return FALSE;
      }
    } else {
      do_warn(dbh, JW_ERR_NOT_IMPLEMENTED,
	      "Commmit ineffective while AutoCommit is on");
    }
    return TRUE;
}

int dbd_db_rollback(SV* dbh, imp_dbh_t* imp_dbh) {
    /* croak, if not in AutoCommit mode */
    if (DBIc_has(imp_dbh, DBIcf_AutoCommit)) {
        do_warn(dbh, TX_ERR_AUTOCOMMIT,
		"Rollback ineffective while AutoCommit is on");
	return FALSE;
    }

    if (imp_dbh->has_transactions) {
      if (MyQuery(imp_dbh->svsock, "ROLLBACK", 8) != 0) {
        do_error(dbh, TX_ERR_ROLLBACK, "ROLLBACK failed");
	return FALSE;
      }
    } else {
      do_error(dbh, JW_ERR_NOT_IMPLEMENTED,
	       "Rollback ineffective while AutoCommit is on");
    }
    return TRUE;
}


/***************************************************************************
 *
 *  Name:    dbd_db_disconnect
 *
 *  Purpose: Disconnect a database handle from its database
 *
 *  Input:   dbh - database handle being disconnected
 *           imp_dbh - drivers private database handle data
 *
 *  Returns: TRUE for success, FALSE otherwise; do_error has already
 *           been called in the latter case
 *
 **************************************************************************/

int dbd_db_disconnect(SV* dbh, imp_dbh_t* imp_dbh) {
#ifdef dTHR
    dTHR;
#endif

    /* We assume that disconnect will always work       */
    /* since most errors imply already disconnected.    */
    DBIc_ACTIVE_off(imp_dbh);
    if (dbis->debug >= 2)
        PerlIO_printf(DBILOGFP, "imp_dbh->svsock: %lx\n",
		      (long) &imp_dbh->svsock);
    MyClose(imp_dbh->svsock );

    /* We don't free imp_dbh since a reference still exists    */
    /* The DESTROY method is the only one to 'free' memory.    */
    return TRUE;
}


/***************************************************************************
 *
 *  Name:    dbd_discon_all
 *
 *  Purpose: Disconnect all database handles at shutdown time
 *
 *  Input:   dbh - database handle being disconnected
 *           imp_dbh - drivers private database handle data
 *
 *  Returns: TRUE for success, FALSE otherwise; do_error has already
 *           been called in the latter case
 *
 **************************************************************************/

int dbd_discon_all (SV *drh, imp_drh_t *imp_drh) {
#if defined(dTHR)
    dTHR;
#endif

    /* The disconnect_all concept is flawed and needs more work */
    if (!dirty && !SvTRUE(perl_get_sv("DBI::PERL_ENDING",0))) {
	sv_setiv(DBIc_ERR(imp_drh), (IV)1);
	sv_setpv(DBIc_ERRSTR(imp_drh),
		(char*)"disconnect_all not implemented");
	DBIh_EVENT2(drh, ERROR_event,
		    DBIc_ERR(imp_drh), DBIc_ERRSTR(imp_drh));
	return FALSE;
    }
    if (perl_destruct_level)
	perl_destruct_level = 0;
    return FALSE;
}


/***************************************************************************
 *
 *  Name:    dbd_db_destroy
 *
 *  Purpose: Our part of the dbh destructor
 *
 *  Input:   dbh - database handle being destroyed
 *           imp_dbh - drivers private database handle data
 *
 *  Returns: Nothing
 *
 **************************************************************************/

void dbd_db_destroy(SV* dbh, imp_dbh_t* imp_dbh) {

    /*
     *  Being on the safe side never hurts ...
     */
    if (DBIc_ACTIVE(imp_dbh)) {
        if (imp_dbh->has_transactions) {
	    if (!DBIc_has(imp_dbh, DBIcf_AutoCommit)) {
	        MyQuery(imp_dbh->svsock, "ROLLBACK", 8);
	    }
	}
        dbd_db_disconnect(dbh, imp_dbh);
    }

    /*
     *  Tell DBI, that dbh->destroy must no longer be called
     */
    DBIc_off(imp_dbh, DBIcf_IMPSET);
}


/***************************************************************************
 *
 *  Name:    dbd_db_STORE_attrib
 *
 *  Purpose: Function for storing dbh attributes; we currently support
 *           just nothing. :-)
 *
 *  Input:   dbh - database handle being modified
 *           imp_dbh - drivers private database handle data
 *           keysv - the attribute name
 *           valuesv - the attribute value
 *
 *  Returns: TRUE for success, FALSE otherwise
 *
 **************************************************************************/

int dbd_db_STORE_attrib(SV* dbh, imp_dbh_t* imp_dbh, SV* keysv, SV* valuesv) {
    STRLEN kl;
    char *key = SvPV(keysv, kl);
    SV *cachesv = Nullsv;
    int cacheit = FALSE;

    if (kl==10 && strEQ(key, "AutoCommit")){
      if (imp_dbh->has_transactions) {
        int oldval = DBIc_has(imp_dbh,DBIcf_AutoCommit);
	int newval = SvTRUE(valuesv);

 	/* if setting AutoCommit on ... */
	if (newval) {
	    if (!oldval) {
	        /*  Need to issue a commit before entering AutoCommit  */
	        if (MyQuery(imp_dbh->svsock,"COMMIT",6) != 0) {
		    do_error(dbh, TX_ERR_COMMIT,"COMMIT failed");
		    return FALSE;
		}
		if (MyQuery(imp_dbh->svsock, "SET AUTOCOMMIT=1", 16) != 0) {
		  do_error(dbh, TX_ERR_AUTOCOMMIT,
			   "Turning on AutoCommit failed");
		  return FALSE;
		}
		DBIc_set(imp_dbh, DBIcf_AutoCommit, newval);
	    }
	} else {
	    if (oldval) {
	        if (MyQuery(imp_dbh->svsock, "SET AUTOCOMMIT=0", 16) != 0) {
		  do_error(dbh, TX_ERR_AUTOCOMMIT,
			   "Turning off AutoCommit failed");
		  return FALSE;
		}
		DBIc_set(imp_dbh, DBIcf_AutoCommit, newval);
	    }
	}
      } else {
        /*
	 *  We do support neither transactions nor "AutoCommit".
	 *  But we stub it. :-)
	 */
        if (!SvTRUE(valuesv)) {
	    do_error(dbh, JW_ERR_NOT_IMPLEMENTED,
			   "Transactions not supported by database");
	    croak("Transactions not supported by database");
	}
      }
    } else {
        return FALSE;
    }

    if (cacheit) /* cache value for later DBI 'quick' fetch? */
        hv_store((HV*)SvRV(dbh), key, kl, cachesv, 0);
    return TRUE;
}


/***************************************************************************
 *
 *  Name:    dbd_db_FETCH_attrib
 *
 *  Purpose: Function for fetching dbh attributes; we currently support
 *           just nothing. :-)
 *
 *  Input:   dbh - database handle being queried
 *           imp_dbh - drivers private database handle data
 *           keysv - the attribute name
 *
 *  Returns: An SV*, if sucessfull; NULL otherwise
 *
 *  Notes:   Do not forget to call sv_2mortal in the former case!
 *
 **************************************************************************/

SV* dbd_db_FETCH_attrib(SV* dbh, imp_dbh_t* imp_dbh, SV* keysv) {
    STRLEN kl;
    char *key = SvPV(keysv, kl);

    switch (*key) {
      case 'A':
	if (strEQ(key, "AutoCommit")){
	  if (imp_dbh->has_transactions) {
	    return sv_2mortal(boolSV(DBIc_has(imp_dbh,DBIcf_AutoCommit)));
	  } else {
	    return &sv_yes;
	  }
	}
	break;
      case 'e':
	if (strEQ(key, "errno")) {
#if defined(DBD_MYSQL)  &&  defined(have_mysql_errno)
	    return sv_2mortal(newSViv((IV)mysql_errno(imp_dbh->svsock)));
#else
	    return sv_2mortal(newSViv(-1));
#endif
	} else if (strEQ(key, "errmsg")) {
	    char* msg = MyError(imp_dbh->svsock);
	    return sv_2mortal(newSVpv(msg, strlen(msg)));
	}
	break;
      case 'h':
	if (strEQ(key, "hostinfo")) {
	    char* hostinfo = MyGetHostInfo(imp_dbh->svsock);
	    return hostinfo ?
	        sv_2mortal(newSVpv(hostinfo, strlen(hostinfo))) : &sv_undef;
	}
	break;
#if defined(DBD_MYSQL)
      case 'i':
	if (strEQ(key, "info")) {
	    char* info = mysql_info(imp_dbh->svsock);
	    return info ? sv_2mortal(newSVpv(info, strlen(info))) : &sv_undef;
	}
	break;
      case 'm':
	if (kl == 14  &&  strEQ(key, "mysql_insertid")) {
	  /* We cannot return an IV, because the insertid is a long.
	   */
	  char buf[64];
	  sprintf(buf, "%lu", mysql_insert_id(imp_dbh->svsock));
	  return sv_2mortal(newSVpv(buf, strlen(buf)));
	}
	break;
#endif
      case 'p':
	if (kl == 9  &&  strEQ(key, "protoinfo")) {
	    return sv_2mortal(newSViv(MyGetProtoInfo(imp_dbh->svsock)));
	}
	break;
      case 's':
	if (kl == 10  &&  strEQ(key, "serverinfo")) {
	    char* serverinfo = MyGetServerInfo(imp_dbh->svsock);
	    return serverinfo ?
	      sv_2mortal(newSVpv(serverinfo, strlen(serverinfo))) : &sv_undef;
	} else if (strEQ(key, "sock")) {
	    return sv_2mortal(newSViv((IV) imp_dbh->svsock));
#if defined DBD_MYSQL
	} else if (strEQ(key, "sockfd")) {
	    return sv_2mortal(newSViv((IV) imp_dbh->svsock->net.fd));
#endif
	} else if (strEQ(key, "stats")) {
#if defined(DBD_MYSQL)
	    char* stats = mysql_stat(imp_dbh->svsock);
	    return stats ?
	        sv_2mortal(newSVpv(stats, strlen(stats))) : &sv_undef;
#elif defined(DBD_MSQL) && defined(IDX_TYPE)
	    return sv_2mortal(newSViv(msqlGetServerStats(imp_dbh->svsock)));
#endif
	}
	break;
#if defined(DBD_MYSQL)
      case 't':
	if (kl == 9  &&  strEQ(key, "thread_id")) {
	    return sv_2mortal(newSViv(mysql_thread_id(imp_dbh->svsock)));
	}
	break;
#endif
    }
    return Nullsv;
}


/***************************************************************************
 *
 *  Name:    dbd_st_prepare
 *
 *  Purpose: Called for preparing an SQL statement; our part of the
 *           statement handle constructor
 *
 *  Input:   sth - statement handle being initialized
 *           imp_sth - drivers private statement handle data
 *           statement - pointer to string with SQL statement
 *           attribs - statement attributes, currently not in use
 *
 *  Returns: TRUE for success, FALSE otherwise; do_error will
 *           be called in the latter case
 *
 **************************************************************************/

int dbd_st_prepare(SV* sth, imp_sth_t* imp_sth, char* statement, SV* attribs) {
    int i;

    /*
     *  Count the number of parameters
     */
    DBIc_NUM_PARAMS(imp_sth) = CountParam(statement);

    /*
     *  Initialize our data
     */
    imp_sth->done_desc = 0;
    imp_sth->cda = NULL;
    imp_sth->currow = 0;
#if defined(DBD_MYSQL)
    {
        SV** svp = DBD_ATTRIB_GET_SVP(attribs, "mysql_use_result", 16);
        imp_sth->use_mysql_use_result = svp && SvTRUE(*svp);
	if (dbis->debug >= 2)
	    PerlIO_printf(DBILOGFP, "Setting mysql_use_result to %d\n",
			  imp_sth->use_mysql_use_result);
    }
#endif
    for (i = 0;  i < AV_ATTRIB_LAST;  i++) {
	imp_sth->av_attr[i] = Nullav;
    }

    /*
     *  Allocate memory for parameters
     */
    imp_sth->params = AllocParam(DBIc_NUM_PARAMS(imp_sth));
    DBIc_IMPSET_on(imp_sth);

    return 1;
}


/***************************************************************************
 *
 *  Name:    dbd_st_internal_execute
 *
 *  Purpose: Internal version for executing a statement, called both from
 *           within the "do" and the "execute" method.
 *
 *  Inputs:  h - object handle, for storing error messages
 *           statement - query being executed
 *           attribs - statement attributes, currently ignored
 *           numParams - number of parameters being bound
 *           params - parameter array
 *           cdaPtr - where to store results, if any
 *           svsock - socket connected to the database
 *
 **************************************************************************/

int dbd_st_internal_execute(SV* h, SV* statement, SV* attribs, int numParams,
			    imp_sth_ph_t* params, result_t* cdaPtr,
			    dbh_t svsock, int use_mysql_use_result) {
    STRLEN slen;
    char* sbuf = SvPV(statement, slen);
    char* salloc = ParseParam(sbuf, &slen, params, numParams);

    if (salloc) {
        sbuf = salloc;
        if (dbis->debug >= 2) {
	    PerlIO_printf(DBILOGFP, "      Binding parameters: %s\n", sbuf);
	}
    }

    if (*cdaPtr) { MyFreeResult(*cdaPtr); *cdaPtr = NULL; }

    if (slen >= 10
	&&  tolower(sbuf[0]) == 'l'
	&&  tolower(sbuf[1]) == 'i'
	&&  tolower(sbuf[2]) == 's'
	&&  tolower(sbuf[3]) == 't') {
        if (slen >= 11
	    &&  tolower(sbuf[4]) == 'f'
	    &&  tolower(sbuf[5]) == 'i'
	    &&  tolower(sbuf[6]) == 'e'
	    &&  tolower(sbuf[7]) == 'l'
	    &&  tolower(sbuf[8]) == 'd'
	    &&  tolower(sbuf[9]) == 's'
	    &&  isspace(sbuf[10])) {
	    char* table;

	    slen -= 10;
	    sbuf += 10;
	    while (slen && isspace(*sbuf)) { --slen;  ++sbuf; }

	    if (!slen) {
	        do_error(h, JW_ERR_QUERY, "Missing table name");
		return -2;
	    }

	    if (!(table = malloc(slen+1))) {
	        do_error(h, JW_ERR_MEM, "Out of memory");
		return -2;
	    }
	    strncpy(table, sbuf, slen);
	    sbuf = table;
	    while (slen && !isspace(*sbuf)) { --slen;  ++sbuf; }
	    *sbuf++ = '\0';

	    *cdaPtr = MyListFields(svsock, table);
	    free(table);

	    if (!(*cdaPtr)) {
	        DO_ERROR(h, JW_ERR_LIST_FIELDS, svsock);
		return -2;
	    }

	    return 0;
#if defined(DBD_MSQL)  &&  defined(IDX_TYPE)
	} else if (tolower(sbuf[4]) == 'i'
		   &&  tolower(sbuf[5]) == 'n'
		   &&  tolower(sbuf[6]) == 'd'
		   &&  tolower(sbuf[7]) == 'e'
		   &&  tolower(sbuf[8]) == 'x'
		   &&  isspace(sbuf[9])) {
	    char* table;
	    char* index;

	    slen -= 9;
	    sbuf += 9;

	    while (slen && isspace(*sbuf)) { --slen;  ++sbuf; }
	    if (!slen) {
	        do_error(h, JW_ERR_QUERY, "Missing table name");
		return -2;
	    }
	    if (!(table = malloc(slen+1))) {
	        do_error(h, JW_ERR_MEM, "Out of memory");
		return -2;
	    }
	    strncpy(table, sbuf, slen);
	    sbuf = table;

	    while (slen && !isspace(*sbuf)) { --slen;  ++sbuf; }
	    if (slen) {
	        *sbuf++ = '\0';
		--slen;
	    }
	    while (slen && isspace(*sbuf)) { --slen;  ++sbuf; }
	    if (!slen) {
	        do_error(h, JW_ERR_QUERY, "Missing index name");
		free(table);
		return -2;
	    }
	    index = sbuf;
	    while (slen && !isspace(*sbuf)) { --slen;  ++sbuf; }
	    *sbuf++ = '\0';

	    *cdaPtr = msqlListIndex(svsock, table, index);
	    free(table);
	    if (!(*cdaPtr)) {
	        DO_ERROR(h, JW_ERR_LIST_INDEX, svsock);
		return -2;
	    }

	    return 0;
#endif
	}
    }

    if ((MyQuery(svsock, sbuf, slen) == -1)  &&
	(!MyReconnect(svsock, h)
	 ||	 (MyQuery(svsock, sbuf, slen) == -1))) {
        Safefree(salloc);
	DO_ERROR(h, JW_ERR_QUERY, svsock);
	return -2;
    }
    Safefree(salloc);

    /** Store the result from the Query */
#if defined(DBD_MYSQL)
    if (!(*cdaPtr = (use_mysql_use_result ?
		     mysql_use_result(svsock) : mysql_store_result(svsock)))) {
        return mysql_affected_rows(svsock);
#elif defined(DBD_MSQL)
    if (!(*cdaPtr = MyStoreResult(svsock))) {
        return -1;
#endif
    }

    return MyNumRows((*cdaPtr));
}


/***************************************************************************
 *
 *  Name:    dbd_st_execute
 *
 *  Purpose: Called for preparing an SQL statement; our part of the
 *           statement handle constructor
 *
 *  Input:   sth - statement handle being initialized
 *           imp_sth - drivers private statement handle data
 *
 *  Returns: TRUE for success, FALSE otherwise; do_error will
 *           be called in the latter case
 *
 **************************************************************************/

int dbd_st_execute(SV* sth, imp_sth_t* imp_sth) {
    D_imp_dbh_from_sth;
    SV** statement;
    int i;
#if defined (dTHR)
    dTHR;
#endif

    if (dbis->debug >= 2) {
        PerlIO_printf(DBILOGFP,
		      "    -> dbd_st_execute for %08lx\n", (u_long) sth);
    }

    if (!SvROK(sth)  ||  SvTYPE(SvRV(sth)) != SVt_PVHV) {
        croak("Expected hash array");
    }

    /*
     *  Free cached array attributes
     */
    for (i = 0;  i < AV_ATTRIB_LAST;  i++) {
	if (imp_sth->av_attr[i]) {
#ifdef DEBUGGING_MEMORY_LEAK
	    printf("Execute: Decrementing refcnt: old = %d\n",
		   SvREFCNT(imp_sth->av_attr[i]));
#endif
	    SvREFCNT_dec(imp_sth->av_attr[i]);
	}
	imp_sth->av_attr[i] = Nullav;
    }

    statement = hv_fetch((HV*) SvRV(sth), "Statement", 9, FALSE);
    if ((imp_sth->row_num =
	     dbd_st_internal_execute(sth, *statement, NULL,
				     DBIc_NUM_PARAMS(imp_sth),
				     imp_sth->params,
				     &imp_sth->cda,
				     imp_dbh->svsock,
				     imp_sth->use_mysql_use_result))
	!= -2) {
	if (!imp_sth->cda) {
#if defined(DBD_MYSQL)
	    imp_sth->insertid = mysql_insert_id(imp_dbh->svsock);
#endif
	} else {
	    /** Store the result in the current statement handle */
	    DBIc_ACTIVE_on(imp_sth);
	    DBIc_NUM_FIELDS(imp_sth) = MyNumFields(imp_sth->cda);
	    imp_sth->done_desc = 0;
	}
    }

    if (dbis->debug >= 2) {
        PerlIO_printf(DBILOGFP, "    <- dbd_st_execute %d rows\n",
		      imp_sth->row_num);
    }

    return imp_sth->row_num;
}


/***************************************************************************
 *
 *  Name:    dbd_describe
 *
 *  Purpose: Called from within the fetch method to describe the result
 *
 *  Input:   sth - statement handle being initialized
 *           imp_sth - our part of the statement handle, there's no
 *               need for supplying both; Tim just doesn't remove it
 *
 *  Returns: TRUE for success, FALSE otherwise; do_error will
 *           be called in the latter case
 *
 **************************************************************************/

int dbd_describe(SV* sth, imp_sth_t* imp_sth) {
    imp_sth->done_desc = 1;
    return TRUE;
}


/***************************************************************************
 *
 *  Name:    dbd_st_fetch
 *
 *  Purpose: Called for fetching a result row
 *
 *  Input:   sth - statement handle being initialized
 *           imp_sth - drivers private statement handle data
 *
 *  Returns: array of columns; the array is allocated by DBI via
 *           DBIS->get_fbav(imp_sth), even the values of the array
 *           are prepared, we just need to modify them appropriately
 *
 **************************************************************************/

AV* dbd_st_fetch(SV* sth, imp_sth_t* imp_sth) {
    int num_fields;
    int ChopBlanks;
    int i;
    AV *av;
    row_t cols;
#if defined(DBD_MYSQL)
#if (defined(MYSQL_VERSION_ID))  &&  (MYSQL_VERSION_ID > 32204)
    unsigned long* lengths;
#else
    unsigned int* lengths;
#endif
#endif

    ChopBlanks = DBIc_is(imp_sth, DBIcf_ChopBlanks);
    if (dbis->debug >= 2) {
        PerlIO_printf(DBILOGFP,
		      "    -> dbd_st_fetch for %08lx, chopblanks %d\n",
		      (u_long) sth, ChopBlanks);
    }

    if (!imp_sth->cda) {
        do_error(sth, JW_ERR_SEQUENCE, "fetch() without execute()");
        return Nullav;
    }

    imp_sth->currow++;
    if (!(cols = MyFetchRow(imp_sth->cda))) {
#if defined(DBD_MYSQL)
        if (!mysql_eof(imp_sth->cda)) {
	    D_imp_dbh_from_sth;
	    DO_ERROR(sth, JW_ERR_FETCH_ROW, imp_dbh->svsock);
	}
#endif
	if (!DBIc_COMPAT(imp_sth)) {
	    dbd_st_finish(sth, imp_sth);
	}
	return Nullav;
    }
#if defined(DBD_MYSQL)
    lengths = mysql_fetch_lengths(imp_sth->cda);
#endif
    av = DBIS->get_fbav(imp_sth);
    num_fields = AvFILL(av)+1;

    for(i=0; i < num_fields; ++i) {
        char* col = cols[i];
	SV *sv = AvARRAY(av)[i]; /* Note: we (re)use the SV in the AV	*/

	if (col) {
#if defined(DBD_MYSQL)
	    STRLEN len = lengths[i];
#elif defined(DBD_MSQL)
	    STRLEN len = strlen(col);
#endif
	    if (ChopBlanks) {
		while(len && col[len-1] == ' ') {
		    --len;
		}
	    }

	    if (dbis->debug >= 2) {
		PerlIO_printf(DBILOGFP, "      Storing row %d (%s) in %08lx\n",
			      i, col, (u_long) sv);
	    }
	    sv_setpvn(sv, col, len);
	} else {
	    (void) SvOK_off(sv);  /*  Field is NULL, return undef  */
	}
    }

    if (dbis->debug >= 2) {
        PerlIO_printf(DBILOGFP, "    <- dbd_st_fetch, %d cols\n", num_fields);
    }
    return av;
}


/***************************************************************************
 *
 *  Name:    dbd_st_finish
 *
 *  Purpose: Called for freeing a mysql result
 *
 *  Input:   sth - statement handle being finished
 *           imp_sth - drivers private statement handle data
 *
 *  Returns: TRUE for success, FALSE otherwise; do_error() will
 *           be called in the latter case
 *
 **************************************************************************/

int dbd_st_finish(SV* sth, imp_sth_t* imp_sth) {
#if defined (dTHR)
    dTHR;
#endif

    /* Cancel further fetches from this cursor.                 */
    /* We don't close the cursor till DESTROY.                  */
    /* The application may re execute it.                       */
    if (imp_sth && imp_sth->cda) {
        MyFreeResult(imp_sth->cda);
	imp_sth->cda = NULL;
    }
    DBIc_ACTIVE_off(imp_sth);
    return 1;
}


/***************************************************************************
 *
 *  Name:    dbd_st_destroy
 *
 *  Purpose: Our part of the statement handles destructor
 *
 *  Input:   sth - statement handle being destroyed
 *           imp_sth - drivers private statement handle data
 *
 *  Returns: Nothing
 *
 **************************************************************************/

void dbd_st_destroy(SV* sth, imp_sth_t* imp_sth) {
    int i;

    /* dbd_st_finish has already been called by .xs code if needed.	*/

    /*
     *  Free values allocated by dbd_bind_ph
     */
    FreeParam(imp_sth->params, DBIc_NUM_PARAMS(imp_sth));
    imp_sth->params = NULL;

    /*
     *  Free cached array attributes
     */
    for (i = 0;  i < AV_ATTRIB_LAST;  i++) {
	if (imp_sth->av_attr[i]) {
#ifdef DEBUGGING_MEMORY_LEAK
	    printf("DESTROY: Decrementing refcnt: old = %d\n",
		   SvREFCNT(imp_sth->av_attr[i]));
#endif
	    SvREFCNT_dec(imp_sth->av_attr[i]);
	}
	imp_sth->av_attr[i] = Nullav;
    }

    DBIc_IMPSET_off(imp_sth);           /* let DBI know we've done it   */
}


/***************************************************************************
 *
 *  Name:    dbd_st_STORE_attrib
 *
 *  Purpose: Modifies a statement handles attributes; we currently
 *           support just nothing
 *
 *  Input:   sth - statement handle being destroyed
 *           imp_sth - drivers private statement handle data
 *           keysv - attribute name
 *           valuesv - attribute value
 *
 *  Returns: TRUE for success, FALSE otrherwise; do_error will
 *           be called in the latter case
 *
 **************************************************************************/

int dbd_st_STORE_attrib(SV* sth, imp_sth_t* imp_sth, SV* keysv, SV* valuesv) {
    STRLEN(kl);
    char* key = SvPV(keysv, kl);
    int result = FALSE;

    if (dbis->debug >= 2) {
        PerlIO_printf(DBILOGFP,
		      "    -> dbd_st_STORE_attrib for %08lx, key %s\n",
		      (u_long) sth, key);
    }

#if defined(DBD_MYSQL)
    if (strEQ(key, "mysql_use_result")) {
        imp_sth->use_mysql_use_result = SvTRUE(valuesv);
    }
#endif

    if (dbis->debug >= 2) {
        PerlIO_printf(DBILOGFP,
		      "    <- dbd_st_STORE_attrib for %08lx, result %d\n",
		      (u_long) sth, result);
    }

    return result;
}


/***************************************************************************
 *
 *  Name:    dbd_st_FETCH_internal
 *
 *  Purpose: Retrieves a statement handles array attributes; we use
 *           a separate function, because creating the array
 *           attributes shares much code and it aids in supporting
 *           enhanced features like caching.
 *
 *  Input:   sth - statement handle; may even be a database handle,
 *               in which case this will be used for storing error
 *               messages only. This is only valid, if cacheit (the

 *               last argument) is set to TRUE.
 *           what - internal attribute number
 *           res - pointer to a DBMS result
 *           cacheit - TRUE, if results may be cached in the sth.
 *
 *  Returns: RV pointing to result array in case of success, NULL
 *           otherwise; do_error has already been called in the latter
 *           case.
 *
 **************************************************************************/

#ifndef IS_KEY
#define IS_KEY(A) (((A) & (PRI_KEY_FLAG | UNIQUE_KEY_FLAG | MULTIPLE_KEY_FLAG)) != 0)
#endif

SV* dbd_st_FETCH_internal(SV* sth, int what, result_t res, int cacheit) {
    D_imp_sth(sth);
    AV *av = Nullav;
    field_t curField;

    /*
     *  Are we asking for a legal value?
     */
    if (what < 0 ||  what >= AV_ATTRIB_LAST) {
	do_error(sth, JW_ERR_NOT_IMPLEMENTED, "Not implemented");

    /*
     *  Return cached value, if possible
     */
    } else if (cacheit  &&  imp_sth->av_attr[what]) {
	av = imp_sth->av_attr[what];

    /*
     *  Does this sth really have a result?
     */
    } else if (!res) {
	do_error(sth, JW_ERR_NOT_ACTIVE,
		 "statement contains no result");

    /*
     *  Do the real work.
     */
    } else {
	av = newAV();
	MyFieldSeek(res, 0);
	while ((curField = MyFetchField(res))) {
	    SV* sv;

	    switch(what) {
	      case AV_ATTRIB_NAME:
		sv = newSVpv(curField->name, strlen(curField->name));
		break;
	      case AV_ATTRIB_TABLE:
		sv = newSVpv(curField->table, strlen(curField->table));
		break;
	      case AV_ATTRIB_TYPE:
		sv = newSViv((int) curField->type);
		break;
	      case AV_ATTRIB_SQL_TYPE:
		sv = newSViv((int) native2sql(curField->type)->data_type);
		break;
	      case AV_ATTRIB_IS_PRI_KEY:
		sv = boolSV(IS_PRI_KEY(curField->flags));
		break;
	      case AV_ATTRIB_IS_NOT_NULL:
		sv = boolSV(IS_NOT_NULL(curField->flags));
		break;
	      case AV_ATTRIB_NULLABLE:
		sv = boolSV(!IS_NOT_NULL(curField->flags));
		break;
	      case AV_ATTRIB_LENGTH:
		sv = newSViv((int) curField->length);
		break;
	      case AV_ATTRIB_IS_NUM:
		sv = newSViv((int) native2sql(curField->type)->is_num);
		break;
	      case AV_ATTRIB_TYPE_NAME:
		sv = newSVpv((char*) native2sql(curField->type)->type_name, 0);
	        break;
#if defined(DBD_MYSQL)
	      case AV_ATTRIB_MAX_LENGTH:
		sv = newSViv((int) curField->max_length);
		break;
	      case AV_ATTRIB_IS_KEY:
		sv = boolSV(IS_KEY(curField->flags));
		break;
	      case AV_ATTRIB_IS_BLOB:
		sv = boolSV(IS_BLOB(curField->flags));
		break;
	      case AV_ATTRIB_SCALE:
		sv = newSViv((int) curField->decimals);
		break;
	      case AV_ATTRIB_PRECISION:
		sv = newSViv((int) (curField->length > curField->max_length) ?
			     curField->length : curField->max_length);
		break;
#else
	      case AV_ATTRIB_SCALE:
		sv = newSViv((int) curField->length);
		break;
	      case AV_ATTRIB_PRECISION:
		sv = newSViv((int) curField->length);
		break;
#endif
	      default:
		sv = &sv_undef;
		break;
	    }

	    av_push(av, sv);
	}

	/*
	 *  Ensure that this value is kept, decremented in
	 *  dbd_st_destroy and dbd_st_execute.
	 */
	if (cacheit) {
	    imp_sth->av_attr[what] = av;
	} else {
	    return sv_2mortal(newRV_noinc((SV*)av));
	}
    }

    if (av == Nullav) {
	return &sv_undef;
    }
    return sv_2mortal(newRV_inc((SV*)av));
}


/***************************************************************************
 *
 *  Name:    dbd_st_FETCH_attrib
 *
 *  Purpose: Retrieves a statement handles attributes
 *
 *  Input:   sth - statement handle being destroyed
 *           imp_sth - drivers private statement handle data
 *           keysv - attribute name
 *
 *  Returns: NULL for an unknown attribute, "undef" for error,
 *           attribute value otherwise.
 *
 **************************************************************************/

#define ST_FETCH_AV(what) \
    dbd_st_FETCH_internal(sth, (what), imp_sth->cda, TRUE)

SV* dbd_st_FETCH_attrib(SV* sth, imp_sth_t* imp_sth, SV* keysv) {
    STRLEN(kl);
    char* key = SvPV(keysv, kl);
    SV* retsv = Nullsv;
    if (kl < 2) {
        return Nullsv;
    }

    if (dbis->debug >= 2) {
        PerlIO_printf(DBILOGFP,
		      "    -> dbd_st_FETCH_attrib for %08lx, key %s\n",
		      (u_long) sth, key);
    }

    switch (*key) {
#ifdef DBD_MYSQL
      case 'a':
	if (strEQ(key, "affected_rows")) {
	  /* We cannot return an IV, because affected_rows is a long.
	   */
	  char buf[64];
	  D_imp_dbh_from_sth;
	  /* 1.21_07 */ 
	  doquietwarn(("$sth->{'affected_rows'} is deprecated," \
		       " use $sth->rows()"));
	  sprintf(buf, "%lu", mysql_affected_rows(imp_dbh->svsock));
	  retsv = sv_2mortal(newSVpv(buf, strlen(buf)));
	}
	break;
#endif
      case 'I':
	/*
	 *  Deprecated, use lower case versions.
	 */
	if (strEQ(key, "IS_PRI_KEY")) {
	    /* 1.21_07 */ 
	    doquietwarn(("$sth->{'IS_PRI_KEY'} is deprecated," \
			 " use $sth->{'~~lc_dbd_driver~~_is_pri_key'}"));
	    retsv = ST_FETCH_AV(AV_ATTRIB_IS_PRI_KEY);
	} else if (strEQ(key, "IS_NOT_NULL")) {
	    /* 1.21_07 */ 
	    doquietwarn(("$sth->{'IS_NOT_NULL'} is deprecated," \
			 " use $sth->{'NULLABLE'}"));
	    retsv = ST_FETCH_AV(AV_ATTRIB_IS_NOT_NULL);
#if defined(DBD_MYSQL)
	} else if (strEQ(key, "IS_KEY")) {
	    /* 1.21_07 */
	    doquietwarn(("$sth->{'IS_KEY'} is deprecated," \
			 " use $sth->{'~~lc_dbd_driver~~_is_key'}"));
	    retsv = ST_FETCH_AV(AV_ATTRIB_IS_KEY);
	} else if (strEQ(key, "IS_BLOB")) {
	    /* 1.21_07 */
	    doquietwarn(("$sth->{'IS_BLOB'} is deprecated," \
			 " use $sth->{'~~lc_dbd_driver~~_is_blob'}"));
	    retsv = ST_FETCH_AV(AV_ATTRIB_IS_BLOB);
#endif
	} else if (strEQ(key, "IS_NUM")) {
	    /* 1.21_07 */
	    doquietwarn(("$sth->{'IS_NUM'} is deprecated," \
			 " use $sth->{'~~lc_dbd_driver~~_is_num'}"));
	    retsv = ST_FETCH_AV(AV_ATTRIB_IS_NUM);
	}
	break;
      case 'L':
	/*
	 *  Deprecated, use lower case versions.
	 */
	if (strEQ(key, "LENGTH")) {
	    /* 1.21_07 */
#ifdef DBD_MYSQL
	    doquietwarn(("$sth->{'LENGTH'} is deprecated," \
			 " use $sth->{'~~lc_dbd_driver~~_length'}"));
#else
	    doquietwarn(("$sth->{'LENGTH'} is deprecated," \
			 " use $sth->{'PRECISION'}"));
#endif
	    retsv = ST_FETCH_AV(AV_ATTRIB_LENGTH);
	}
	break;
#if defined(DBD_MYSQL)
      case 'M':
	if (strEQ(key, "MAXLENGTH")) {
	    /* 1.21_07 */
	    doquietwarn(("$sth->{'MAXLENGTH'} is deprecated," \
			 " use $sth->{'~~lc_dbd_driver~~__max_length'}"));
	    retsv = ST_FETCH_AV(AV_ATTRIB_MAX_LENGTH);
	}
	break;
#endif
      case 'N':
	if (strEQ(key, "NAME")) {
	    retsv = ST_FETCH_AV(AV_ATTRIB_NAME);
	} else if (strEQ(key, "NULLABLE")) {
	    retsv = ST_FETCH_AV(AV_ATTRIB_NULLABLE);
	} else if (strEQ(key, "NUMROWS")) {
	    /* 1.21_07 */
	    doquietwarn(("$sth->{'NUMROWS'} is deprecated, use $sth->rows"));
	    retsv = sv_2mortal(newSViv((IV)imp_sth->row_num));
	} else if (strEQ(key, "NUMFIELDS")) {
	    /* 1.21_07 */
	    doquietwarn(("$sth->{'NUMFIELDS'} is deprecated," \
			  " use $sth->{'NUM_OF_FIELDS'"));
	    retsv = sv_2mortal(newSViv((IV) DBIc_NUM_FIELDS(imp_sth)));
	}
	break;
      case 'P':
	if (strEQ(key, "PRECISION")) {
	    retsv = ST_FETCH_AV(AV_ATTRIB_PRECISION);
	}
	break;
      case 'R':
	if (strEQ(key, "RESULT")) {
	    /* 1.21_07 */
	    doquietwarn(("$sth->{'RESULT'} is deprecated," \
			 " use $sth->{'~~lc_dbd_driver~~_result'}"));
	    retsv = sv_2mortal(newSViv((IV) imp_sth->cda));
	}
	break;
      case 'S':
	if (strEQ(key, "SCALE")) {
	    retsv = ST_FETCH_AV(AV_ATTRIB_SCALE);
	}
	break;
      case 'T':
	if (strEQ(key, "TYPE")) {
	    retsv = ST_FETCH_AV(AV_ATTRIB_SQL_TYPE);
	} else if (strEQ(key, "TABLE")) {
	    /* 1.21_07 */
	    doquietwarn(("$sth->{'TABLE'} is deprecated," \
			 " use $sth->{'~~lc_dbd_driver~~_table'}"));
	    retsv = ST_FETCH_AV(AV_ATTRIB_TABLE);
	}
	break;
      case 'f':
	if (strEQ(key, "format_max_size")) {
	    /* 1.21_07 */
	    doquietwarn(("$sth->{'format_max_size'} is deprecated," \
			 " use $sth->{'PRECISION'}"));
	    retsv = ST_FETCH_AV(AV_ATTRIB_LENGTH);
#if defined(DBD_MYSQL)
	} else if (strEQ(key, "format_default_size")) {
	    /* 1.21_07 */
	    doquietwarn(("$sth->{'format_max_size'} is deprecated," \
			 " use $sth->{'PRECISION'}"));
	    retsv = ST_FETCH_AV(AV_ATTRIB_MAX_LENGTH);
#endif
	} else if (strEQ(key, "format_right_justify")) {
	    /* 1.21_07 */
	    doquietwarn(("$sth->{'format_max_size'} is deprecated," \
			 " use $sth->{'~~lc_dbd_driver~~_is_num'}"));
	    retsv = ST_FETCH_AV(AV_ATTRIB_IS_NUM);
	} else if (strEQ(key, "format_type_name")) {
	    /* 1.21_07 */
	    doquietwarn(("$sth->{'format_type_name'} is deprecated," \
			 " use $sth->{'TYPE'}"));
	    retsv = ST_FETCH_AV(AV_ATTRIB_TYPE_NAME);
	}
	break;
      case 'i':
	if (strEQ(key, "insertid")) {
	  /* We cannot return an IV, because the insertid is a long.
	   */
	  char buf[64];
	  /* 1.21_07 */
	  doquietwarn(("$sth->{'insertid'} is deprecated," \
		       " use $sth->{'mysql_insertid'}"));
	  sprintf(buf, "%lu", imp_sth->insertid);
	  return sv_2mortal(newSVpv(buf, strlen(buf)));
	} else if (strEQ(key, "is_pri_key")) {
	    /* 1.21_07 */ 
	    doquietwarn(("$sth->{'is_pri_key'} is deprecated," \
			 " use $sth->{'~~lc_dbd_driver~~_is_pri_key'}"));
	    retsv = ST_FETCH_AV(AV_ATTRIB_IS_PRI_KEY);
	} else if (strEQ(key, "is_not_null")) {
	    /* 1.21_07 */ 
	    doquietwarn(("$sth->{'is_not_null'} is deprecated," \
			 " use $sth->{'NULLABLE'}"));
	    retsv = ST_FETCH_AV(AV_ATTRIB_IS_NOT_NULL);
#if defined(DBD_MYSQL)
	} else if (strEQ(key, "is_key")) {
	    /* 1.21_07 */
	    doquietwarn(("$sth->{'is_key'} is deprecated," \
			 " use $sth->{'~~lc_dbd_driver~~_is_key'}"));
	    retsv = ST_FETCH_AV(AV_ATTRIB_IS_KEY);
	} else if (strEQ(key, "is_blob")) {
	    /* 1.21_07 */
	    doquietwarn(("$sth->{'is_blob'} is deprecated," \
			 " use $sth->{'~~lc_dbd_driver~~_is_blob'}"));
	    retsv = ST_FETCH_AV(AV_ATTRIB_IS_BLOB);
#endif
	} else if (strEQ(key, "is_num")) {
	    /* 1.21_07 */
	    doquietwarn(("$sth->{'is_num'} is deprecated," \
			 " use $sth->{'~~lc_dbd_driver~~_is_num'}"));
	    retsv = ST_FETCH_AV(AV_ATTRIB_IS_NUM);
	}
	break;
      case 'l':
	if (strEQ(key, "length")) {
	    /* 1.21_07 */
	    doquietwarn(("$sth->{'length'} is deprecated," \
			 " use $sth->{'PRECISION'}"));
	    retsv = ST_FETCH_AV(AV_ATTRIB_LENGTH);
	}
	break;
      case 'm':
#if defined(DBD_MYSQL)
	switch (kl) {
	  case 10:
	    if (strEQ(key, "max_length")) {
	        /* 1.21_07 */
	        doquietwarn(("$sth->{'max_length'} is deprecated," \
			     " use $sth->{'~~lc_dbd_driver~~_max_length'}"));
		retsv = ST_FETCH_AV(AV_ATTRIB_MAX_LENGTH);
	    } else if (strEQ(key, "mysql_type")) {
	        retsv = ST_FETCH_AV(AV_ATTRIB_TYPE);
	    }
	    break;
	  case 11:
	    if (strEQ(key, "mysql_table")) {
	        retsv = ST_FETCH_AV(AV_ATTRIB_TABLE);
	    }
	    break;
	  case 12:
	    if (       strEQ(key, "mysql_is_key")) {
	        retsv = ST_FETCH_AV(AV_ATTRIB_IS_KEY);
	    } else if (strEQ(key, "mysql_is_num")) {
	        retsv = ST_FETCH_AV(AV_ATTRIB_IS_NUM);
	    } else if (strEQ(key, "mysql_length")) {
	        retsv = ST_FETCH_AV(AV_ATTRIB_LENGTH);
	    } else if (strEQ(key, "mysql_result")) {
	        retsv = sv_2mortal(newSViv((IV) imp_sth->cda));
	    }
	    break;
	  case 13:
	    if (strEQ(key, "mysql_is_blob")) {
	        retsv = ST_FETCH_AV(AV_ATTRIB_IS_BLOB);
	    }
	    break;
	  case 14:
	    if (strEQ(key, "mysql_insertid")) {
	      /* We cannot return an IV, because the insertid is a long.
	       */
	      char buf[64];
	      sprintf(buf, "%lu", imp_sth->insertid);
	      return sv_2mortal(newSVpv(buf, strlen(buf)));
	    }
	    break;
	  case 15:
	    if (strEQ(key, "mysql_type_name")) {
	        retsv = ST_FETCH_AV(AV_ATTRIB_TYPE_NAME);
	    }
	    break;
	  case 16:
	    if (       strEQ(key, "mysql_is_pri_key")) {
	        retsv = ST_FETCH_AV(AV_ATTRIB_IS_PRI_KEY);
	    } else if (strEQ(key, "mysql_max_length")) {
	        retsv = ST_FETCH_AV(AV_ATTRIB_MAX_LENGTH);
	    } else if (strEQ(key, "mysql_use_result")) {
	        retsv = boolSV(imp_sth->use_mysql_use_result);
	    }
	    break;
	}
#else
	switch (kl) {
	  case 9:
	    if (strEQ(key, "msql_type")) {
	        retsv = ST_FETCH_AV(AV_ATTRIB_TYPE);
	    }
	    break;
	  case 10:
	    if (strEQ(key, "msql_table")) {
	        retsv = ST_FETCH_AV(AV_ATTRIB_TABLE);
	    }
	    break;
	  case 11:
	    if (strEQ(key, "msql_is_num")) {
	        retsv = ST_FETCH_AV(AV_ATTRIB_IS_NUM);
	    } else if (strEQ(key, "msql_result")) {
	        retsv = sv_2mortal(newSViv((IV) imp_sth->cda));
	    }
	    break;
	  case 14:
	    if (strEQ(key, "msql_type_name")) {
	        retsv = ST_FETCH_AV(AV_ATTRIB_TYPE_NAME);
	    }
	    break;
	  case 15:
	    if (kl == 15  &&  strEQ(key, "msql_is_pri_key")) {
	        retsv = ST_FETCH_AV(AV_ATTRIB_IS_PRI_KEY);
	    }
	    break;
	}
#endif
	break;
      case 'r':
	if (strEQ(key, "result")) {
	    /* 1.21_07 */
	    doquietwarn(("$sth->{'result'} is deprecated," \
			 " use $sth->{'~~lc_dbd_driver~~_result'}"));
	    retsv = sv_2mortal(newSViv((IV) imp_sth->cda));
	}
	break;
      case 't':
	if (strEQ(key, "table")) {
	    /* 1.21_07 */
	    doquietwarn(("$sth->{'table'} is deprecated," \
			 " use $sth->{'~~lc_dbd_driver~~_table'}"));
	    retsv = ST_FETCH_AV(AV_ATTRIB_TABLE);
	}
	break;
    }

    return retsv;
}


/***************************************************************************
 *
 *  Name:    dbd_st_blob_read
 *
 *  Purpose: Used for blob reads if the statement handles "LongTruncOk"
 *           attribute (currently not supported by DBD::mysql)
 *
 *  Input:   SV* - statement handle from which a blob will be fetched
 *           imp_sth - drivers private statement handle data
 *           field - field number of the blob (note, that a row may
 *               contain more than one blob)
 *           offset - the offset of the field, where to start reading
 *           len - maximum number of bytes to read
 *           destrv - RV* that tells us where to store
 *           destoffset - destination offset
 *
 *  Returns: TRUE for success, FALSE otrherwise; do_error will
 *           be called in the latter case
 *
 **************************************************************************/

int dbd_st_blob_read (SV *sth, imp_sth_t *imp_sth, int field, long offset,
		      long len, SV *destrv, long destoffset) {
    return FALSE;
}


/***************************************************************************
 *
 *  Name:    dbd_bind_ph
 *
 *  Purpose: Binds a statement value to a parameter
 *
 *  Input:   sth - statement handle
 *           imp_sth - drivers private statement handle data
 *           param - parameter number, counting starts with 1
 *           value - value being inserted for parameter "param"
 *           sql_type - SQL type of the value
 *           attribs - bind parameter attributes, currently this must be
 *               one of the values SQL_CHAR, ...
 *           inout - TRUE, if parameter is an output variable (currently
 *               this is not supported)
 *           maxlen - ???
 *
 *  Returns: TRUE for success, FALSE otherwise
 *
 **************************************************************************/

int dbd_bind_ph (SV *sth, imp_sth_t *imp_sth, SV *param, SV *value,
		 IV sql_type, SV *attribs, int is_inout, IV maxlen) {
    int paramNum = SvIV(param);

    if (paramNum <= 0  ||  paramNum > DBIc_NUM_PARAMS(imp_sth)) {
        do_error(sth, JW_ERR_ILLEGAL_PARAM_NUM,
		       "Illegal parameter number");
	return FALSE;
    }

    if (is_inout) {
        do_error(sth, JW_ERR_NOT_IMPLEMENTED,
		       "Output parameters not implemented");
	return FALSE;
    }

    return BindParam(&imp_sth->params[paramNum - 1], value, sql_type);
}


#if defined(DBD_MYSQL)

/***************************************************************************
 *
 *  Name:    MysqlReconnect
 *
 *  Purpose: If the server has disconnected, try to reconnect.
 *
 *  Input:   h - database or statement handle
 *
 *  Returns: TRUE for success, FALSE otherwise
 *
 **************************************************************************/

int MysqlReconnect(SV* h) {
    D_imp_xxh(h);
    imp_dbh_t* imp_dbh;

    if (DBIc_TYPE(imp_xxh) == DBIt_ST) {
        imp_dbh = (imp_dbh_t*) DBIc_PARENT_COM(imp_xxh);
	h = DBIc_PARENT_H(imp_xxh);
    } else {
        imp_dbh = (imp_dbh_t*) imp_xxh;
    }

    if (!_MyLogin(imp_dbh)) {
	DO_ERROR(h, MyErrno(imp_dbh->svsock, JW_ERR_CONNECT),
		 imp_dbh->svsock);
	return FALSE;
    }
    return TRUE;
}

#endif


/***************************************************************************
 *
 *  Name:    dbd_db_type_info_all
 *
 *  Purpose: Implements $dbh->type_info_all
 *
 *  Input:   dbh - database handle
 *           imp_sth - drivers private database handle data
 *
 *  Returns: RV to AV of types
 *
 **************************************************************************/

#define PV_PUSH(c)                              \
    if (c) {                                    \
	sv = newSVpv((char*) (c), 0);           \
	SvREADONLY_on(sv);                      \
    } else {                                    \
        sv = &sv_undef;                         \
    }                                           \
    av_push(row, sv);

#define IV_PUSH(i) sv = newSViv((i)); SvREADONLY_on(sv); av_push(row, sv);

AV* dbd_db_type_info_all(SV* dbh, imp_dbh_t* imp_dbh) {
    AV* av = newAV();
    AV* row;
    HV* hv;
    SV* sv;
    int i;
    const char* cols[] = {
        "TYPE_NAME",
	"DATA_TYPE",
	"COLUMN_SIZE",
	"LITERAL_PREFIX",
	"LITERAL_SUFFIX",
	"CREATE_PARAMS",
	"NULLABLE",
	"CASE_SENSITIVE",
	"SEARCHABLE",
	"UNSIGNED_ATTRIBUTE",
	"FIXED_PREC_SCALE",
	"AUTO_UNIQUE_VALUE",
	"LOCAL_TYPE_NAME",
	"MINIMUM_SCALE",
	"MAXIMUM_SCALE",
	"NUM_PREC_RADIX",
	"~~lc_dbd_driver~~_native_type",
	"~~lc_dbd_driver~~_is_num"
    };

    hv = newHV();
    av_push(av, newRV_noinc((SV*) hv));
    for (i = 0;  i < (sizeof(cols) / sizeof(const char*));  i++) {
        if (!hv_store(hv, (char*) cols[i], strlen(cols[i]), newSViv(i), 0)) {
	    SvREFCNT_dec((SV*) av);
	    return Nullav;
	}
    }
    for (i = 0;  i < SQL_GET_TYPE_INFO_num;  i++) {
        const sql_type_info_t* t = &SQL_GET_TYPE_INFO_values[i];

	row = newAV();
	av_push(av, newRV_noinc((SV*) row));
	PV_PUSH(t->type_name);
	IV_PUSH(t->data_type);
	IV_PUSH(t->column_size);
	PV_PUSH(t->literal_prefix);
	PV_PUSH(t->literal_suffix);
	PV_PUSH(t->create_params);
	IV_PUSH(t->nullable);
	IV_PUSH(t->case_sensitive);
	IV_PUSH(t->searchable);
	IV_PUSH(t->unsigned_attribute);
	IV_PUSH(t->fixed_prec_scale);
	IV_PUSH(t->auto_unique_value);
	PV_PUSH(t->local_type_name);
	IV_PUSH(t->minimum_scale);
	IV_PUSH(t->maximum_scale);
	if (t->num_prec_radix) {
	    IV_PUSH(t->num_prec_radix);
	} else {
	    av_push(row, &sv_undef);
	}
	IV_PUSH(t->native_type);
	IV_PUSH(t->is_num);
    }
    return av;
}


SV* dbd_db_quote(SV* dbh, SV* str, SV* type) {
    SV* result;
    char* ptr;
    char* sptr;
    STRLEN len;

    if (!SvOK(str)) {
        result = newSVpv("NULL", 4);
    } else {
        if (type  &&  SvOK(type)) {
	    int i;
	    int tp = SvIV(type);
	    for (i = 0;  i < SQL_GET_TYPE_INFO_num;  i++) {
	        const sql_type_info_t* t = &SQL_GET_TYPE_INFO_values[i];
		if (t->data_type == tp) {
		    if (!t->literal_prefix) {
		        return Nullsv;
		    }
		    break;
		}
	    }
	}

        ptr = SvPV(str, len);
	result = newSV(len*2+3);
	sptr = SvPVX(result);

	*sptr++ = '\'';
	while (len--) {
	    switch (*ptr) {
	      case '\'':
		*sptr++ = '\\';
		*sptr++ = '\'';
		break;
	      case '\\':
		*sptr++ = '\\';
		*sptr++ = '\\';
		break;
#if defined(DBD_MYSQL)
	      case '\n':
		*sptr++ = '\\';
		*sptr++ = 'n';
		break;
	      case '\r':
		*sptr++ = '\\';
		*sptr++ = 'r';
		break;
	      case '\0':
		*sptr++ = '\\';
		*sptr++ = '0';
		break;
#endif
	      default:
		*sptr++ = *ptr;
		break;
	    }
	    ++ptr;
	}
	*sptr++ = '\'';
	SvPOK_on(result);
	SvCUR_set(result, sptr - SvPVX(result));
	*sptr++ = '\0';  /*  Never hurts NUL terminating a Perl
			  *	 string ...
			  */
    }
    return result;
}
