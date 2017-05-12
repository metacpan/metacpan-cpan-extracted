/* Edit this file in -*- C -*- Mode */
#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include <libpq-fe.h>

/*
 * V. Khera 17-OCT-1996
 *
 * Perl interface to Postgres95 SQL database engine.
 * Copyright 1996 Vivek Khera (vivek@khera.org).
 *
 * This module is distributed under the same terms as Perl itself.  See
 * the license file that came with it.
 *
 * Code for putline/getline is from Owen Taylor <owt1@cornell.edu>
 *
 * $Id: Postgres.xs,v 1.3 1996/11/19 19:25:56 khera Exp $
 */

/* name of package variable to hold error string values on error */
#define ERRORSTR "Postgres::error"

/* size of buffer for PQgetline */
#define LINEBUFLEN 1024

/*
 * need a structure to hold the index of the current tuple when iterating
 * through a SELECT result
 */

typedef struct
{
  int cur_row;
  PGresult *res;
} QUERY;


/* set the Perl error variable appropriately upon error */
static void
sql_error(PGconn* conn)
{
  SV *sve = perl_get_sv(ERRORSTR,TRUE|0x04);
  sv_setpv(sve,PQerrorMessage(conn));
}

/*
 * the only function in this package is the db_connect() function.  it returns
 * a handle to the connection from which queries are done.  This is the
 * only function exported from the entire module.
 */
MODULE = Postgres		PACKAGE = Postgres

PGconn *
db_connect(dbname,host=NULL,port=NULL)
	char *dbname;
	char *host;
	char *port;
    PROTOTYPE: $;$$
    CODE:
        RETVAL = PQsetdb(host,port,NULL,NULL,dbname);
	if (PQstatus(RETVAL) == CONNECTION_BAD) {
	  /* some error */
	  sql_error(RETVAL);
	  PQfinish(RETVAL);
	  RETVAL=NULL;
	}
    OUTPUT:
	RETVAL


MODULE = Postgres		PACKAGE = PGconnPtr	PREFIX = PQ

void
PQDESTROY(conn)
	PGconn *conn;
    PROTOTYPE: $
    CODE:
    /* called automatically when handle ceases to exist */
    /* printf("Destroyed connection handle\n"); */
	PQfinish(conn);


char *
PQdb(conn)
	PGconn *conn;
    PROTOTYPE: $

char *
PQhost(conn)
	PGconn *conn;
    PROTOTYPE: $

char *
PQoptions(conn)
	PGconn *conn;
    PROTOTYPE: $

char *
PQport(conn)
	PGconn *conn;
    PROTOTYPE: $

char *
PQtty(conn)
	PGconn *conn;
    PROTOTYPE: $

char *
PQerrorMessage(conn)
	PGconn *conn;
    PROTOTYPE: $

void
PQreset(conn)
	PGconn *conn;
    PROTOTYPE: $

void
PQputline(conn,str)
	PGconn *conn;
	char *str;
    PROTOTYPE: $$

char *
PQgetline(conn)
	PGconn *conn;
    PROTOTYPE: $
    PREINIT: 
        char buf[LINEBUFLEN];
        int result;
    CODE:
	ST(0) = sv_newmortal();
	sv_setpv(ST(0),"");
	for (;;) {
	  result = PQgetline(conn,buf,LINEBUFLEN);
	  if (result == EOF) {
	    /* it's not clear what this means -- it really should
	       never happen (except maybe for an error?) */
	    /* do we need to free the newmortal we created above?  how? */
	    ST(0) = &sv_undef;
	    break;
	  } else {
	    sv_catpv(ST(0),buf);
	    if (result == 0) {	/* no more data to fetch for line */
	      break;
	    }
	    /* otherwise, result == 1, get some more */
	  }
	}

int
PQendcopy(conn)
        PGconn *conn;
    PROTOTYPE: $
        
QUERY *
PQexecute(conn,query)
	PGconn *conn;
	char *query;
    PROTOTYPE: $$
    CODE:
	RETVAL = (QUERY *)malloc(sizeof(*RETVAL));
	if (RETVAL) {
	  RETVAL->res = PQexec(conn,query);
	  if (RETVAL->res == NULL) {
	    sql_error(conn);
	    free(RETVAL);
	    RETVAL=NULL;
	  } else {
	    switch (PQresultStatus(RETVAL->res)) {
	    case PGRES_COMMAND_OK:
	    case PGRES_COPY_IN:
	    case PGRES_COPY_OUT:
	      RETVAL->cur_row = -1; /* no rows returned on commands */
	      break;
	    case PGRES_TUPLES_OK:
	      RETVAL->cur_row = 0; /* for indexing into result */
	      break;
	    default:
	      {
		/* error or unsupported function */
		SV *sve = perl_get_sv(ERRORSTR,TRUE|0x04);
		sv_setpv(sve,"Not OK Return code");
		PQclear(RETVAL->res);
		free(RETVAL);
		RETVAL=NULL;
	      }
	      break;
	    }
	  }
	  /* should we set error message indicating failure of malloc() ? */
	}
    OUTPUT:
	RETVAL


MODULE = Postgres		PACKAGE = QUERYPtr	PREFIX = query_

void
query_DESTROY(q)
	QUERY *q;
    PROTOTYPE: $
    CODE:
    /* called automatically when handle ceases to exist */
    /* printf("Destroyed result handle\n"); */
	PQclear(q->res);
	free(q);

int
query_ntuples(q)
	QUERY *q;
    PROTOTYPE: $
    CODE:
	RETVAL=PQntuples(q->res);
    OUTPUT:
	RETVAL

int
query_nfields(q)
	QUERY *q;
    PROTOTYPE: $
    CODE:
	RETVAL=PQnfields(q->res);
    OUTPUT:
	RETVAL

char *
query_fname(q,field)
	QUERY *q;
	int field;
    PROTOTYPE: $$
    CODE:
	RETVAL=PQfname(q->res,field);
    OUTPUT:
	RETVAL

int
query_fnumber(q,fieldname)
	QUERY *q;
	char *fieldname;
    PROTOTYPE: $$
    CODE:
	RETVAL=PQfnumber(q->res,fieldname);
    OUTPUT:
	RETVAL

Oid
query_ftype(q,field)
	QUERY *q;
	int field;
    PROTOTYPE: $$
    CODE:
	RETVAL=PQftype(q->res,field);
    OUTPUT:
	RETVAL

int
query_fsize(q,field)
	QUERY *q;
	int field;
    PROTOTYPE: $$
    CODE:
	RETVAL=PQfsize(q->res,field);
    OUTPUT:
	RETVAL

char *
query_getvalue(q,tuple,field)
	QUERY *q;
	int tuple;
	int field;
    PROTOTYPE: $$$
    CODE:
	RETVAL=PQgetvalue(q->res,tuple,field);
    OUTPUT:
	RETVAL

int
query_getlength(q,tuple,field)
	QUERY *q;
	int tuple;
	int field;
    PROTOTYPE: $$$
    CODE:
	RETVAL=PQgetlength(q->res,tuple,field);
    OUTPUT:
	RETVAL

int
query_getisnull(q,tuple,field)
	QUERY *q;
	int tuple;
	int field;
    PROTOTYPE: $$$
    CODE:
	RETVAL=PQgetisnull(q->res,tuple,field);
    OUTPUT:
	RETVAL

char *
query_cmdStatus(q)
	QUERY *q;
    PROTOTYPE: $
    CODE:
	RETVAL=PQcmdStatus(q->res);
    OUTPUT:
	RETVAL

char *
query_oidStatus(q)
	QUERY *q;
    PROTOTYPE: $
    CODE:
	RETVAL=PQoidStatus(q->res);
    OUTPUT:
	RETVAL

void
query_fetchrow(q)
	QUERY *q;
    PROTOTYPE: $
    PPCODE:
    if (q && q->res) {
      int cols = PQnfields(q->res);
      /* return empty list when no more data */
      if (PQntuples(q->res) > q->cur_row) { /* out of tuples to return */
	int cur_col = 0;
	EXTEND(sp,cols);
	while(cur_col < cols) {
	  if (PQgetisnull(q->res,q->cur_row,cur_col))
	    PUSHs(&sv_undef);
	  else {
	    char *val = PQgetvalue(q->res,q->cur_row,cur_col);
	    PUSHs(sv_2mortal((SV*)newSVpv(val,0)));
	  }
	  ++cur_col;
	} /* while */
	++q->cur_row;		/* go to next row */
      } /* tuples to return */
      /* else just drop through and return empty list */
    } /* if q */
