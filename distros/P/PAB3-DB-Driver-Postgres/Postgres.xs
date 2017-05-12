#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include <stdlib.h>
#include <libpq-fe.h>
#include "my_postgres.h"

MODULE = PAB3::DB::Driver::Postgres		PACKAGE = PAB3::DB::Driver::Postgres

BOOT:
{
	MY_CXT_INIT;
	MY_CXT.firstcon = MY_CXT.lastcon = NULL;
	MY_CXT.lasterror[0] = '\0';
}


#/*****************************************************************************
# * CLONE( ... )
# *****************************************************************************/

#if defined(USE_ITHREADS) && defined(MY_CXT_KEY)

void
CLONE( ... )
CODE:
	MY_CXT_CLONE;

#endif


#/******************************************************************************
# * _connect( [host [, user [, auth [, db [, port [, flags]]]]]] )
# ******************************************************************************/

void *
_connect( server = NULL, user = NULL, auth = NULL, db = NULL, client_flag = 0 )
	const char *server;
	const char *user;
	const char *auth;
	const char *db;
	U32 client_flag;
PREINIT:
	dMY_CXT;
	char *s1, *tmp = NULL;
	MY_CON *con;
	PGconn *pcon;
	DWORD l1;
	const char *host = NULL, *port = NULL;
CODE:
	if( server && server[0] != '\0' ) {
		l1 = strlen( server );
		STR_CREATEANDCOPYN( server, tmp, l1 );
		host = tmp;
		if( ( s1 = strchr( tmp, ':' ) ) ) {
			*s1 ++ = '\0';
			port = s1;
		}
	}
	pcon = PQsetdbLogin( host, port, NULL, NULL, db, user, auth );
	Safefree( tmp );
	if( PQstatus( pcon ) == CONNECTION_OK ) {
		con = my_con_add( &MY_CXT, pcon );
		con->client_flag = client_flag | MYCF_AUTOCOMMIT;
		RETVAL = con;
	}
	else {
		s1 = PQerrorMessage( pcon );
		my_strcpy( MY_CXT.lasterror, s1 );
		PQfinish( pcon );
		RETVAL = 0;
	}
OUTPUT:
	RETVAL


#/******************************************************************************
# * close( [linkid] )
# ******************************************************************************/

void
close( linkid = 0 )
	void *linkid;
PREINIT:
	dMY_CXT;
CODE:
	switch( my_get_type( &MY_CXT, &linkid ) ) {
	case MY_TYPE_CON:
		my_con_rem( &MY_CXT, (MY_CON *) linkid );
		break;
	case MY_TYPE_RES:
		my_result_rem( (MY_RES *) linkid );
		break;
	case MY_TYPE_STMT:
		my_stmt_rem( (MY_STMT *) linkid );
		break;
	}


#/******************************************************************************
# * reconnect( [linkid] )
# ******************************************************************************/

int
reconnect( linkid = 0 )
	void * linkid;
PREINIT:
	dMY_CXT;
	MY_CON *con;
CODE:
	con = my_con_verify( &MY_CXT, linkid );
	if( con == NULL ) goto error;
	my_con_cleanup( con );
	PQreset( con->con );
	if( PQstatus( con->con ) != CONNECTION_OK ) goto error;
	if( con->charset )
		PQsetClientEncoding( con->con, con->charset );
	RETVAL = 1;
	goto exit;
error:
	RETVAL = 0;
exit:
OUTPUT:
	RETVAL


#/******************************************************************************
# * query( sql, [linkid] )
# ******************************************************************************/

IV
query( ... )
PREINIT:
	dMY_CXT;
	void *linkid = NULL;
	const char *sql;
	MY_CON *con;
	MY_RES *res;
	PGresult *pres;
	ExecStatusType stat;
	int step = 0, itemp = 0;
CODE:
	switch( items ) {
	case 2:
		linkid = INT2PTR( void *, SvIV( ST( itemp ) ) );
		itemp ++;
	case 1:
		sql = (const char *) SvPV_nolen( ST( itemp ) );
		break;
	default:	
		Perl_croak( aTHX_ "Usage: " __PACKAGE__ "::query(linkid = 0, query)" );
	}
	con = my_con_verify( &MY_CXT, linkid );
	if( con == NULL ) goto error;
retry:
	pres = PQexec( con->con, sql );
	stat = PQresultStatus( pres );
	switch( stat ) {
	case PGRES_TUPLES_OK:
		res = my_result_add( con, pres );
		con->affected_rows = res->numrows;
		RETVAL = PTR2IV( res );
		break;
	case PGRES_COMMAND_OK:
	case PGRES_COPY_OUT:
	case PGRES_COPY_IN:
		con->affected_rows = atol( PQcmdTuples( pres ) );
		//printf( "oid: %u\n,", PQoidValue( pres ) );
		PQclear( pres );
		RETVAL = 1;
		break;
	default:
		PQclear( pres );
		con->affected_rows = 0;
		if( step || ( con->client_flag & CLIENT_RECONNECT ) == 0 ) goto error;
		if( PQstatus( con->con ) != CONNECTION_OK ) {
			step ++;
			my_con_cleanup( con );
			PQreset( con->con );
			if( con->charset )
				PQsetClientEncoding( con->con, con->charset );
			goto retry;
		}
		break;
	}
	goto exit;
error:
	RETVAL = 0;
exit:
OUTPUT:
	RETVAL


#/******************************************************************************
# * prepare( [linkid, ] sql )
# ******************************************************************************/

IV
prepare( ... )
PREINIT:
	dMY_CXT;
	const char *sql;
	char *stmtname = NULL, *tmp = NULL;
	void *linkid = NULL;
	STRLEN sqllen = 0;
	MY_CON *con;
	MY_STMT *stmt;
	PGresult *pstmt = NULL;
	DWORD plen;
	int itemp = 0;
CODE:
	switch( items ) {
	case 3:
		linkid = INT2PTR( void *, SvIV( ST( 0 ) ) );
		sql = (const char *) SvPVx( ST( 1 ), sqllen );
		stmtname = (char *) SvPV_nolen( ST( 2 ) );
		break;
	case 2:
		linkid = INT2PTR( void *, SvIV( ST( 0 ) ) );
		itemp ++;
	case 1:
		sql = (const char *) SvPVx( ST( itemp ), sqllen );
		break;
	default:	
		Perl_croak( aTHX_ "Usage: " __PACKAGE__ "::prepare(linkid = 0, query)" );
	}
	con = (MY_CON *) my_con_verify( &MY_CXT, linkid );
	if( con == NULL ) goto error;
	New( 1, stmtname, sizeof( DWORD ) * 2 + 3, char );
	stmtname[0] = 's';
	stmtname[1] = 't';
	my_itoa( &stmtname[2], (int) con->stmt_counter ++, 16 );
	//printf( "using statement name [%s] %u\n", stmtname, con->stmt_counter - 1 );
	tmp = my_stmt_convert( sql, sqllen, &plen, NULL );
	pstmt = PQprepare( con->con, stmtname, tmp, 0, NULL );
	switch( PQresultStatus( pstmt ) ) {
	case PGRES_COMMAND_OK:
		stmt = my_stmt_add( con, stmtname, plen );
		RETVAL = PTR2IV( stmt );
		goto exit;
	default:
		goto error;
	}
error:
	RETVAL = 0;
	if( stmtname != NULL ) Safefree( stmtname );
exit:
	if( pstmt != NULL ) PQclear( pstmt );
	if( tmp != NULL ) Safefree( tmp );
OUTPUT:
	RETVAL


#/******************************************************************************
# * bind_param( stmtid, p_num, val [, type] )
# ******************************************************************************/

int
bind_param( stmtid, p_num, val = NULL, type = 0 )
	void *stmtid;
	U32 p_num;
	SV *val;
	char type;
PREINIT:
	dMY_CXT;
CODE:
	if( ! my_stmt_exists( &MY_CXT, stmtid ) )
		// statement does not exists
		RETVAL = 0;
	else
		RETVAL = my_stmt_bind_param( (MY_STMT *) stmtid, p_num, val, type );
OUTPUT:
	RETVAL


#/******************************************************************************
# * execute( stmtid, [*params] )
# ******************************************************************************/

IV
execute( stmtid, ... )
	void *stmtid;
PREINIT:
	dMY_CXT;
	MY_CON *con;
	MY_STMT *stmt;
	MY_RES *res;
	DWORD step = 0;
	int i;
	PGresult *pres = NULL;
CODE:
	if( ! my_stmt_exists( &MY_CXT, stmtid ) ) goto error;
	stmt = (MY_STMT *) stmtid;
	if( stmt->res != NULL ) {
		if( stmt->res->bound )
			my_result_rem( stmt->res );
		else
			stmt->res = NULL;
	}
	con = stmt->con;
	for( i = 1; i < items; i ++ )
		if( ! my_stmt_bind_param( stmt, i, ST( i ), 0 ) ) goto error;
	pres = PQexecPrepared(
		con->con, stmt->id, stmt->param_count,
		(const char * const *) stmt->param_values,
		stmt->param_lengths, stmt->param_formats, 0
	);
	switch( PQresultStatus( pres ) ) {
	case PGRES_TUPLES_OK:
		res = my_result_add( stmt->con, pres );
		stmt->res = res;
		res->stmt = stmt;
		con->affected_rows = res->numrows;
		RETVAL = PTR2IV( res );
		break;
	case PGRES_COMMAND_OK:
		RETVAL = 1;
		con->affected_rows = atol( PQcmdTuples( pres ) );
		PQclear( pres );
		break;
	default:
		con->affected_rows = 0;
		PQclear( pres );
		if( step || ( con->client_flag & CLIENT_RECONNECT ) == 0 ) goto error;
		if( PQstatus( con->con ) != CONNECTION_OK ) {
			step ++;
			my_con_cleanup( con );
			PQreset( con->con );
			if( con->charset )
				PQsetClientEncoding( con->con, con->charset );
		}
		goto error;
	}
	goto exit;
error:
	RETVAL = 0;
exit:
OUTPUT:
	RETVAL


#/******************************************************************************
# * free_result( resid )
# ******************************************************************************/

int
free_result( resid )
	void * resid;
PREINIT:
	dMY_CXT;
CODE:
	switch( my_stmt_or_result( &MY_CXT, resid ) ) {
	case MY_TYPE_RES:
		if( ((MY_RES *) resid)->stmt == NULL )
			my_result_rem( (MY_RES *) resid );
		else
			((MY_RES *) resid)->bound = 1;
		RETVAL = 1;
		break;
	case MY_TYPE_STMT:
		my_stmt_rem( (MY_STMT *) resid );
		RETVAL = 1;
		break;
	default:
		RETVAL = 0;
	}
OUTPUT:
	RETVAL


#/******************************************************************************
# * num_fields( resid )
# ******************************************************************************/

U32
num_fields( resid )
	void * resid;
PREINIT:
	dMY_CXT;
CODE:
	switch( my_stmt_or_result( &MY_CXT, resid ) ) {
	case MY_TYPE_RES:
		RETVAL = ( (MY_RES *) resid )->numfields;
		break;
	case MY_TYPE_STMT:
		RETVAL = ( (MY_STMT *) resid )->res != NULL
			? ( (MY_STMT *) resid )->res->numfields : 0;
		break;
	default:
		RETVAL = 0;
	}
OUTPUT:
	RETVAL


#/******************************************************************************
# * num_rows( resid )
# ******************************************************************************/

U32
num_rows( resid )
	void * resid;
PREINIT:
	dMY_CXT;
CODE:
	switch( my_stmt_or_result( &MY_CXT, resid ) ) {
	case MY_TYPE_RES:
		RETVAL = ( (MY_RES *) resid )->numrows;
		break;
	case MY_TYPE_STMT:
		RETVAL = ( (MY_STMT *) resid )->res != NULL
			? ( (MY_STMT *) resid )->res->numrows : 0;
		break;
	default:
		RETVAL = 0;
	}
OUTPUT:
	RETVAL


#/******************************************************************************
# * fetch_names( resid )
# ******************************************************************************/

void
fetch_names( resid )
	void * resid;
PREINIT:
	dMY_CXT;
	MY_RES *res;
	const char *name;
	int num_fields, i;
PPCODE:
	switch( my_stmt_or_result( &MY_CXT, resid ) ) {
	case MY_TYPE_RES:
		res = (MY_RES *) resid;
		break;
	case MY_TYPE_STMT:
		res = ( (MY_STMT *) resid )->res;
		break;
	}
	if( res != NULL ) {
		res = (MY_RES *) resid;
		num_fields = res->numfields;
		for( i = 0; i < num_fields; i ++ ) {
			name = PQfname( res->res, i );
			XPUSHs( sv_2mortal( newSVpvn( name, strlen( name ) ) ) );	
		}
	}


#/******************************************************************************
# * fetch_field( resid [, offset] )
# ******************************************************************************/

void
fetch_field( resid, offset = -1 )
	void * resid;
	long offset;
PREINIT:
	dMY_CXT;
	MY_RES *res = NULL;
	const char *tmps;
	UV tmpu;
PPCODE:
	switch( my_stmt_or_result( &MY_CXT, resid ) ) {
	case MY_TYPE_RES:
		res = (MY_RES *) resid;
		break;
	case MY_TYPE_STMT:
		res = ( (MY_STMT *) resid )->res;
		break;
	}
	if( res != NULL ) {
		if( offset >= 0 ) {
			if( (UV) offset >= res->numfields )
				res->fieldpos = res->numfields - 1;
			else
				res->fieldpos = offset;
		}
		if( res->fieldpos < res->numfields ) {
			XPUSHs( sv_2mortal( newSVpvn( "name", 4 ) ) );
			tmps = PQfname( res->res, res->fieldpos );
			XPUSHs( sv_2mortal( newSVpvn( tmps, strlen( tmps ) ) ) );
			XPUSHs( sv_2mortal( newSVpvn( "length", 6 ) ) );
			tmpu = PQfsize( res->res, res->fieldpos );
			XPUSHs( sv_2mortal( newSVuv( tmpu ) ) );
		}
	}


#/******************************************************************************
# * field_seek( resid [, offset] )
# ******************************************************************************/

U32
field_seek( resid, offset = 0 )
	void * resid;
	U32 offset;
PREINIT:
	dMY_CXT;
	MY_RES *res;
CODE:
	switch( my_stmt_or_result( &MY_CXT, resid ) ) {
	case MY_TYPE_RES:
		res = (MY_RES *) resid;
		break;
	case MY_TYPE_STMT:
		res = ( (MY_STMT *) resid )->res;
		break;
	}
	if( res != NULL ) {
		RETVAL = res->fieldpos;
		if( offset < 0 )
			res->fieldpos = 0;
		else if( offset >= res->numfields )
			res->fieldpos = res->numfields - 1;
		else
			res->fieldpos = offset;
	}
	else RETVAL = 0;
OUTPUT:
	RETVAL


#/******************************************************************************
# * field_tell( resid )
# ******************************************************************************/

U32
field_tell( resid )
	void * resid;
PREINIT:
	dMY_CXT;
CODE:
	switch( my_stmt_or_result( &MY_CXT, resid ) ) {
	case 1:
		RETVAL = ( (MY_RES *) resid )->fieldpos;
		break;
	case 2:
		RETVAL = ( (MY_STMT *) resid )->res != NULL
			? ( (MY_STMT *) resid )->res->fieldpos : 0;
		break;
	default:
		RETVAL = 0;
		break;
	}
OUTPUT:
	RETVAL


#/******************************************************************************
# * fetch_row( resid )
# ******************************************************************************/

void
fetch_row( resid )
	void * resid;
PREINIT:
	dMY_CXT;
	DWORD i, l;
	MY_RES *res;
	const char *val;
PPCODE:
	switch( my_stmt_or_result( &MY_CXT, resid ) ) {
	case MY_TYPE_RES:
		res = (MY_RES *) resid;
		break;
	case MY_TYPE_STMT:
		res = ( (MY_STMT *) resid )->res;
		break;
	}
	if( res != NULL ) {
		if( res->rowpos < res->numrows ) {
			EXTEND( SP, res->numfields );
			for( i = 0; i < res->numfields; i ++ ) {
				if( PQgetisnull( res->res, res->rowpos, i ) ) {
					XPUSHs( &PL_sv_undef );
				}
				else {
					l = PQgetlength( res->res, res->rowpos, i );
					val = PQgetvalue( res->res, res->rowpos, i );
					XPUSHs( sv_2mortal( newSVpvn( val, l ) ) );	
				}
			}
			res->rowpos ++;
		}
	}


#/******************************************************************************
# * fetch_col( resid )
# ******************************************************************************/

void
fetch_col( resid )
	void * resid;
PREINIT:
	dMY_CXT;
	MY_RES *res;
	DWORD i, l;
	const char *val;
PPCODE:
	switch( my_stmt_or_result( &MY_CXT, resid ) ) {
	case MY_TYPE_RES:
		res = (MY_RES *) resid;
		break;
	case MY_TYPE_STMT:
		res = ( (MY_STMT *) resid )->res;
		break;
	}
	if( res != NULL ) {
		EXTEND( SP, res->numrows );
		for( i = 0; i < res->numrows; i ++ ) {
			if( PQgetisnull( res->res, i, 0 ) ) {
				XPUSHs( &PL_sv_undef );	
			}
			else {
				l = PQgetlength( res->res, i, 0 );
				val = PQgetvalue( res->res, i, 0 );
				XPUSHs( sv_2mortal( newSVpvn( val, l ) ) );	
			}
		}
		res->rowpos = res->numrows;
	}


#/******************************************************************************
# * fetch_hash( resid )
# ******************************************************************************/

void
fetch_hash( resid )
	void * resid;
PREINIT:
	dMY_CXT;
	MY_RES *res;
	DWORD i, l;
	const char *val, *name;
PPCODE:
	switch( my_stmt_or_result( &MY_CXT, resid ) ) {
	case MY_TYPE_RES:
		res = (MY_RES *) resid;
		break;
	case MY_TYPE_STMT:
		res = ( (MY_STMT *) resid )->res;
		break;
	}
	if( res != NULL ) {
		if( res->rowpos < res->numrows ) {
			EXTEND( SP, res->numfields * 2 );
			for( i = 0; i < res->numfields; i ++ ) {
				name = PQfname( res->res, i );
				XPUSHs( sv_2mortal( newSVpvn( name, strlen( name ) ) ) );
				if( PQgetisnull( res->res, res->rowpos, i ) ) {
					XPUSHs( &PL_sv_undef );	
				}
				else {
					l = PQgetlength( res->res, res->rowpos, i );
					val = PQgetvalue( res->res, res->rowpos, i );
					XPUSHs( sv_2mortal( newSVpvn( val, l ) ) );	
				}
			}
			res->rowpos ++;
		}
	}


#/******************************************************************************
# * fetch_lengths( resid )
# ******************************************************************************/

void
fetch_lengths( resid )
	void * resid;
PREINIT:
	dMY_CXT;
	MY_RES *res;
	DWORD i, s;
PPCODE:
	switch( my_stmt_or_result( &MY_CXT, resid ) ) {
	case MY_TYPE_RES:
		res = (MY_RES *) resid;
		break;
	case MY_TYPE_STMT:
		res = ( (MY_STMT *) resid )->res;
		break;
	}
	if( res != NULL ) {
		EXTEND( SP, res->numfields );
		for( i = 0; i < res->numfields; i ++ ) {
			s = PQfsize( res->res, i );
			XPUSHs( sv_2mortal( newSVuv( s ) ) );	
		}
	}


#/******************************************************************************
# * row_seek( resid, offset )
# ******************************************************************************/

long
row_seek( resid, offset = 0 )
	void * resid;
	U32 offset;
PREINIT:
	dMY_CXT;
	MY_RES *res;
CODE:
	switch( my_stmt_or_result( &MY_CXT, resid ) ) {
	case MY_TYPE_RES:
		res = (MY_RES *) resid;
		break;
	case MY_TYPE_STMT:
		res = ( (MY_STMT *) resid )->res;
		break;
	}
	if( res != NULL ) {
		RETVAL = res->rowpos;
		if( offset < 0 )
			res->rowpos = 0;
		else if( offset >= res->numrows )
			res->rowpos = res->numrows - 1;
		else
			res->rowpos = offset;
	}
	else RETVAL = -1;
OUTPUT:
	RETVAL


#/******************************************************************************
# * row_tell( resid )
# ******************************************************************************/

long
row_tell( resid )
	void * resid;
PREINIT:
	dMY_CXT;
CODE:
	switch( my_stmt_or_result( &MY_CXT, resid ) ) {
	case MY_TYPE_RES:
		RETVAL = ( (MY_RES *) resid )->rowpos;
		break;
	case MY_TYPE_STMT:
		RETVAL = ( (MY_STMT *) resid )->res != NULL
			? ( (MY_STMT *) resid )->res->rowpos : 0;
		break;
	}
OUTPUT:
	RETVAL


#/******************************************************************************
# * insert_id( [linkid [, field [, table [, schema]]]] )
# ******************************************************************************/
# --> select currval('public."test_id_seq"');
void
insert_id( ... )
PREINIT:
	dMY_CXT;
	void * linkid = 0;
	int itemp = 0;
	const char *field = NULL;
	const char *table = NULL;
	const char *schema = NULL;
	MY_CON *con;
	char sql[256], *p1;
	PGresult *res;
CODE:
    if( items < 0 || items > 4 )
		Perl_croak( aTHX_ "Usage: " __PACKAGE__ "::insert_id(linkid = 0, field = 0, table = 0, schema = 0)" );
	if( SvIOK( ST( itemp ) ) ) {
		linkid = INT2PTR( void *, SvIV( ST( itemp ) ) );
		itemp ++;
	}
	if( itemp < items ) {
		field = (const char *) SvPV_nolen( ST( itemp ) );
		itemp ++;
	}
	if( itemp < items ) {
		table = (const char *) SvPV_nolen( ST( itemp ) );
		itemp ++;
	}
	if( itemp < items ) {
		schema = (const char *) SvPV_nolen( ST( itemp ) );
		itemp ++;
	}
	switch( my_stmt_or_con( &MY_CXT, &linkid ) ) {
	case MY_TYPE_CON:
		con = (MY_CON *) linkid;
		break;
	case MY_TYPE_STMT:
		con = ((MY_STMT *) linkid)->con;
		break;
	default:
		goto error;
	}
	if( ! table || ! field || table[0] == '\0' || field[0] == '\0' ) goto error;
	p1 = my_strcpy( sql, "SELECT CURRVAL('" );
	if( schema ) {
		p1 = my_strcpyl( p1, schema );
		*p1 ++ = '.';
	}
	*p1 ++ = '"';
	p1 = my_strcpyl( p1, table );
	*p1 ++ = '_';
	p1 = my_strcpyl( p1, field );
	p1 = my_strcpy( p1, "_seq\"')" );
	res = PQexec( con->con, sql );
	if( PQresultStatus( res ) == PGRES_TUPLES_OK ) {
		p1 = PQgetvalue( res, 0, 0 );
		ST(0) = sv_2mortal( newSVpvn( p1, strlen( p1 ) ) );
	}
	else {
		ST(0) = &PL_sv_undef;
	}
	PQclear( res );
	goto exit;
error:
	ST(0) = &PL_sv_undef;
exit:
	{}


#/******************************************************************************
# * affected_rows( [linkid] )
# ******************************************************************************/

U32
affected_rows( linkid = 0 )
	void * linkid;
PREINIT:
	dMY_CXT;
CODE:
	switch( my_stmt_or_con( &MY_CXT, &linkid ) ) {
	case MY_TYPE_CON:
		RETVAL = ((MY_CON *) linkid)->affected_rows;
		break;
	case MY_TYPE_STMT:
		RETVAL = ((MY_STMT *) linkid)->con->affected_rows;
		break;
	default:
		RETVAL = 0;
	}
OUTPUT:
	RETVAL


#/******************************************************************************
# * quote( val )
# ******************************************************************************/

void
quote( val )
	const char *val;
INIT:
	char *res = 0;
	int l, lmax, i, dp;
CODE:
	l = strlen( val );
	lmax = l * 2 + 3;
	New( 1, res, lmax, char );
	dp = 1;
	res[0] = '\'';
	for( i = 0; i < l; i ++ ) {
		if( val[i] == '\'' ) {
			res[dp ++] = '\'';
			res[dp ++] = '\'';
		}
		else {
			res[dp ++] = val[i];
		}
	}
	res[dp ++] = '\'';
	res[dp] = 0;
	ST(0) = sv_2mortal( newSVpvn( res, dp ) );
CLEANUP:
	Safefree( res );


#/******************************************************************************
# * quote_id( p1, ... )
# ******************************************************************************/

void
quote_id( p1, ... )
	const char *p1;
INIT:
	const char *str;
	char *res = 0;
	int i;
	unsigned long j, rlen, rpos;
	STRLEN len;
CODE:
	rlen = items * 127;
	New( 1, res, rlen, char );
	rpos = 0;
	for( i = 0; i < items; i ++ ) {
		len = SvLEN( ST(i) );
		str = (const char *) SvPV( ST(i), len );
		if( rpos + len * 2 > rlen ) {
			rlen = rpos + len * 2 + 3;
			Renew( res, rlen, char );
		}
		if( i > 0 ) res[rpos ++] = '.';
		if( i == items - 1 && len == 1 && str[0] == '*' ) {
			res[rpos ++] = '*';
		}
		else {
			res[rpos ++] = '"';
			for( j = 0; j < len; j ++ ) {
				if( str[j] == '"' ) {
					res[rpos ++] = '"';
					res[rpos ++] = '"';
				}
				else {
					res[rpos ++] = str[j];
				}
			}
			res[rpos ++] = '"';
		}
	}
	res[rpos] = '\0';
	ST(0) = sv_2mortal( newSVpvn( res, rpos ) );
CLEANUP:
	Safefree( res );


#/******************************************************************************
# * set_charset( [linkid, ] charset )
# ******************************************************************************/

unsigned int
set_charset( ... )
INIT:
	dMY_CXT;
	void * linkid = 0;
	const char *charset;
	MY_CON *con;
	STRLEN cslen;
	int res, itemp = 0;
CODE:
    if( items < 1 || items > 2 )
		Perl_croak( aTHX_ "Usage: " __PACKAGE__ "::set_charset(linkid = 0, charset)" );
	if( items > 1 ) {
		linkid = INT2PTR( void *, SvIV( ST( itemp ) ) );
		itemp ++;
	}
	charset = SvPVx( ST( itemp ), cslen );
	con = my_con_verify( &MY_CXT, linkid );
	if( con == NULL ) goto error;
	res = PQsetClientEncoding( con->con, charset );
	if( res != 0 ) goto error;
	Safefree( con->charset );
	New( 1, con->charset, cslen + 1, char );
	memcpy( con->charset, charset, cslen + 1 );
	con->charset_length = cslen;
	RETVAL = 1;
	goto exit;
error:
	RETVAL = 0;
exit:
OUTPUT:
	RETVAL


#/******************************************************************************
# * get_charset( [linkid] )
# ******************************************************************************/

const char *
get_charset( linkid = 0 )
	void * linkid;
PREINIT:
	dMY_CXT;
	MY_CON *con;
CODE:
	con = my_con_verify( &MY_CXT, linkid );
	RETVAL = con != NULL ? con->charset : NULL;
OUTPUT:
	RETVAL


#/******************************************************************************
# * sql_limit( sql, length, limit [, offset] )
# ******************************************************************************/

char *
sql_limit( sql, length, limit, offset = -1 )
	const char *sql;
	U32 length;
	long limit;
	long offset;
PREINIT:
	char *res, *rp;
	const char *fc;
	long i, fl, fp;
CODE:
	if( sql ) {
		const char *find = "limit";
		fl = 4; fp = 4; fc = 0;
		for( i = length - 1; i >= 0; i -- ) {
			if( tolower( sql[i] ) == find[fp] ) {
				fp --;
				if( fp < 0 ) {
					while( i > 0 && sql[-- i] == '0' ) {}
					fc = &sql[i];
					break;
				}
			}
			else if( fp < fl ) {
				fp = fl;
			}
		}
		if( fc ) {
			New( 1, res, fc - sql + 27, char );
			strncpy( res, sql, fc - sql );
			rp = res + ( fc - sql );
		}
		else {
			New( 1, res, length + 27, char );
			strncpy( res, sql, length );
			rp = res + length;
		}
		if( offset >= 0 )
			sprintf( rp, " LIMIT %u OFFSET %u", limit, offset );
		else
			sprintf( rp, " LIMIT %u", limit );
	}
	else {
		res = 0;
	}
	RETVAL = res;
OUTPUT:
	RETVAL
CLEANUP:
	Safefree( res );


#/******************************************************************************
# * auto_commit( [linkid, ] mode )
# ******************************************************************************/

int
auto_commit( linkid = 0, mode = 1 )
	void * linkid;
	int mode;
PREINIT:
	dMY_CXT;
	MY_CON *con;
CODE:
	con = my_con_verify( &MY_CXT, linkid );
	if( con == NULL ) goto error;
	if( mode ) {
		if( ( con->my_flags & MYCF_AUTOCOMMIT ) == 0 )
			con->my_flags |= MYCF_AUTOCOMMIT;
	}
	else {
		if( ( con->my_flags & MYCF_AUTOCOMMIT ) != 0 )
			con->my_flags ^= MYCF_AUTOCOMMIT;
	}
	//my_set_error( "Auto commit mode not supported" );
	RETVAL = 1;
	goto exit;
error:
	RETVAL = 0;
exit:
OUTPUT:
	RETVAL


#/******************************************************************************
# * begin_work( [linkid] )
# ******************************************************************************/

int
begin_work( linkid )
	void * linkid;
PREINIT:
	dMY_CXT;
	MY_CON *con;
	PGresult *res;
CODE:
	RETVAL = 0;
	con = my_con_verify( &MY_CXT, linkid );
	if( con == NULL ) goto exit;
	if( ( con->my_flags & MYCF_TRANSACTION ) == 0 ) {
		res = PQexec( con->con, "BEGIN" );
		if( PQresultStatus( res ) == PGRES_COMMAND_OK ) {
			con->my_flags |= MYCF_TRANSACTION;
			RETVAL = 1;
		}
		else
			RETVAL = 0;
		PQclear( res );
	}
	else
		RETVAL = 1;
exit:
OUTPUT:
	RETVAL


#/******************************************************************************
# * commit( [linkid] )
# ******************************************************************************/

int
commit( linkid )
	void * linkid;
PREINIT:
	dMY_CXT;
	MY_CON *con;
	PGresult *res;
CODE:
	RETVAL = 0;
	con = my_con_verify( &MY_CXT, linkid );
	if( con == NULL ) goto exit;
	if( ( con->my_flags & MYCF_TRANSACTION ) != 0 ) {
		res = PQexec( con->con, "COMMIT" );
		if( PQresultStatus( res ) == PGRES_COMMAND_OK ) {
			con->my_flags ^= MYCF_TRANSACTION;
			if( ( con->my_flags & MYCF_AUTOCOMMIT ) == 0 ) {
				// disable auto commit
				PQclear( res );
				res = PQexec( con->con, "BEGIN" );
				if( PQresultStatus( res ) == PGRES_COMMAND_OK )
					RETVAL = 1;
				else
					RETVAL = 0;
			}
			else
				RETVAL = 1;
		}
		else
			RETVAL = 0;
		PQclear( res );
	}
	else
		RETVAL = 1;
exit:
OUTPUT:
	RETVAL


#/******************************************************************************
# * rollback( [linkid] )
# ******************************************************************************/

int
rollback( linkid )
	void * linkid;
PREINIT:
	dMY_CXT;
	MY_CON *con;
	PGresult *res;
CODE:
	RETVAL = 0;
	con = my_con_verify( &MY_CXT, linkid );
	if( con == NULL ) goto exit;
	if( ( con->my_flags & MYCF_TRANSACTION ) != 0 ) {
		res = PQexec( con->con, "ROLLBACK" );
		if( PQresultStatus( res ) == PGRES_COMMAND_OK ) {
			con->my_flags ^= MYCF_TRANSACTION;
			if( ( con->my_flags & MYCF_AUTOCOMMIT ) == 0 ) {
				// disable auto commit
				PQclear( res );
				res = PQexec( con->con, "BEGIN" );
				if( PQresultStatus( res ) == PGRES_COMMAND_OK )
					RETVAL = 1;
				else
					RETVAL = 0;
			}
			else
				RETVAL = 1;
		}
		else
			RETVAL = 0;
		PQclear( res );
	}
	else
		RETVAL = 1;
exit:
OUTPUT:
	RETVAL


#/******************************************************************************
# * show_catalogs( [linkid [, wild]] )
# ******************************************************************************/

void
show_catalogs( linkid = 0, wild = 0 )
	void * linkid;
	const char *wild;
PREINIT:
	dMY_CXT;
	MY_CON *con;
	PGresult *pres;
	DWORD numrows, i, l;
	const char *val;
PPCODE:
	con = my_con_verify( &MY_CXT, linkid );
	if( con == NULL ) goto error;
	pres = PQexec( con->con, "select datname from pg_database" );
	if( PQresultStatus( pres ) == PGRES_TUPLES_OK ) {
		numrows = PQntuples( pres );
		for( i = 0; i < numrows; i ++ ) {
			l = PQgetlength( pres, i, 0 );
			val = PQgetvalue( pres, i, 0 );
			XPUSHs( sv_2mortal( newSVpvn( val, l ) ) );
		}
	}
	PQclear( pres );
error:
	{}


#/******************************************************************************
# * show_tables( [linkid [, schema [, db [, wild]]]] )
# ******************************************************************************/

void
show_tables( ... )
PREINIT:
	dMY_CXT;
	void *linkid = NULL;
	const char *db = NULL;
	const char *schema = NULL;
	const char *wild = NULL;
	MY_CON *con;
	char sql[1024], *p1;
	DWORD numrows, i, l, dbl;
	int itemp = 0;
	const char *val;
	AV *av;
	PGresult *res;
PPCODE:
    if( items < 0 || items > 4 )
		Perl_croak( aTHX_ "Usage: " __PACKAGE__ "::show_tables(linkid = 0, schema = NULL, db = NULL, wild = NULL)" );
	if( SvIOK( ST( itemp ) ) ) {
		linkid = INT2PTR( void *, SvIV( ST( itemp ) ) );
		itemp ++;
	}
	if( itemp < items ) {
		schema = (const char *) SvPV_nolen( ST( itemp ) );
		itemp ++;
	}
	if( itemp < items ) {
		db = (const char *) SvPV_nolen( ST( itemp ) );
		itemp ++;
	}
	if( itemp < items )
		wild = (const char *) SvPV_nolen( ST( itemp ) );
	con = my_con_verify( &MY_CXT, linkid );
	if( con == NULL ) goto error;
/*
SELECT
	c.relname AS objectname,
	n.nspname AS schemaname,
	c.relkind AS objecttype
FROM pg_class c
LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE ( c.relkind = 'r'::"char" OR c.relkind = 'v'::"char" ) AND ( n.nspname = 'schema' )
ORDER BY c.relkind, c.relname
*/
	p1 = my_strcpy( sql,
		"SELECT c.relname AS f0, n.nspname AS f1, c.relkind AS f2"
		" FROM pg_class c"
		" LEFT JOIN pg_namespace n ON n.oid = c.relnamespace"
		" WHERE ("
	);
	itemp = 0;
	if( wild == NULL || my_stristr( wild, "table" ) != NULL ) {
		p1 = my_strcpy( p1, "c.relkind = 'r'::\"char\"" );
		itemp ++;
	}
	if( wild == NULL || my_stristr( wild, "view" ) != NULL ) {
		if( itemp )
			p1 = my_strcpy( p1, " OR " );
		p1 = my_strcpy( p1, "c.relkind = 'v'::\"char\"" );
		itemp ++;
	}
	p1 = my_strcpy( p1, ")" );
	if( schema && schema[0] != '\0' ) {
		p1 = my_strcpy( p1, " AND n.nspname = '" );
		p1 = my_strcpy( p1, schema );
		p1 = my_strcpy( p1, "'" );
	}
	p1 = my_strcpy( p1, " ORDER BY c.relkind, c.relname" );
	//printf( "%s\n", sql );
	res = PQexec( con->con, sql );
	if( PQresultStatus( res ) == PGRES_TUPLES_OK ) {
		// only connected db is permitted
		db = PQdb( con->con );
		dbl = strlen( db );
		numrows = PQntuples( res );
		for( i = 0; i < numrows; i ++ ) {
			// TABLE, SCHEMA, DB, TYPE
			av = (AV *) sv_2mortal( (SV *) newAV() );
			l = PQgetlength( res, i, 0 );
			val = PQgetvalue( res, i, 0 );
			av_push( av, newSVpvn( val, l ) );
			l = PQgetlength( res, i, 1 );
			val = PQgetvalue( res, i, 1 );
			av_push( av, newSVpvn( val, l ) );
			av_push( av, newSVpvn( db, dbl ) );
			val = PQgetvalue( res, i, 2 );
			switch( val[0] ) {
			case 'r':
				av_push( av, newSVpvn( "table", 5 ) );
				break;
			case 'v':
				av_push( av, newSVpvn( "view", 4 ) );
				break;
			}
			XPUSHs( newRV( (SV *) av ) );
		}
	}
	PQclear( res );
error:
	{}


#/******************************************************************************
# * errno( [linkid] )
# ******************************************************************************/

int
errno( linkid = 0 )
	void * linkid;
PREINIT:
	dMY_CXT;
	MY_CON *con;
CODE:
	con = my_con_verify_noerror( &MY_CXT, linkid );
	RETVAL = con != NULL ? PQstatus( con->con ) : 0;
OUTPUT:
	RETVAL


#/******************************************************************************
# * error( [linkid] )
# ******************************************************************************/

void
error( linkid = 0 )
	void * linkid;
PREINIT:
	dMY_CXT;
	MY_CON *con;
	const char *error;
CODE:
	con = my_con_verify_noerror( &MY_CXT, linkid );
	if( con != NULL ) {
		error = PQerrorMessage( con->con );
		if( error[0] == '\0' ) error = con->my_error;
	}
	else {
		error = MY_CXT.lasterror;
	}
	if( error && error != '\0' )
		ST(0) = sv_2mortal( newSVpvn( error, strlen( error ) ) );
	else
		ST(0) = &PL_sv_undef;


#/******************************************************************************
# * _cleanup();
# ******************************************************************************/

void
_cleanup()
PREINIT:
	dMY_CXT;
CODE:
	my_cleanup( &MY_CXT );


#/******************************************************************************
# * _cleanupSession();
# ******************************************************************************/

void
_cleanupSession()
PREINIT:
	dMY_CXT;
CODE:
	my_cleanup_session( &MY_CXT );


#/******************************************************************************
# * _verify_linkid( [linkid] );
# ******************************************************************************/

void *
_verify_linkid( linkid = 0 )
	void * linkid;
PREINIT:
	dMY_CXT;
CODE:
	RETVAL = (void *) my_con_verify( &MY_CXT, linkid );
OUTPUT:
	RETVAL
