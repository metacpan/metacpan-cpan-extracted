#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include <mysql.h>
#include <errmsg.h>

#include "my_mysql.h"

MODULE = PAB3::DB::Driver::Mysql		PACKAGE = PAB3::DB::Driver::Mysql

BOOT:
{
	MY_CXT_INIT;
	MY_CXT.con = MY_CXT.lastcon = NULL;
	MY_CXT.lasterror[0] = '\0';
#ifdef USE_THREADS
	//MUTEX_INIT( &MY_CXT.thread_lock );
#endif
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


#/*****************************************************************************
# * _connect( [server [, user [, passwd [, db [, client_flag]]]]] )
# *****************************************************************************/

void *
_connect( server = NULL, user = NULL, passwd = NULL, db = NULL, client_flag = 0 )
const char *server
const char *user
const char *passwd
const char *db
unsigned long client_flag
PREINIT:
	dMY_CXT;
	MY_CON *con;
	MYSQL *mysql, *res;
	DWORD cf;
	size_t l1;
	char *s1, *tmp = NULL;
	unsigned int port = 0;
	const char *socket = NULL, *host = NULL;
CODE:
	cf = client_flag;
	if( ( cf & CLIENT_RECONNECT ) != 0 ) cf ^= CLIENT_RECONNECT;
	New( 1, mysql, 1, MYSQL );
	if( ! mysql ) {
		/* out of memory! */
		Perl_croak( aTHX_ "PANIC: running out of memory!" );
	}
	if( server && server[0] != '\0' ) {
		l1 = strlen( server );
		STR_CREATEANDCOPYN( server, tmp, l1 );
		if( ( s1 = strchr( tmp, ':' ) ) ) {
			*s1 ++ = '\0';
			host = tmp;
			switch( *s1 ) {
			case '0': case '1': case '2': case '3': case '4':
			case '5': case '6': case '7': case '8': case '9':
				port = atoi( s1 );
				break;
			default:
				socket = s1;
				break;
			}
		}
		else if( *tmp == '/' ) {
			socket = tmp;
		}
		else {
			host = tmp;
		}
	}
	mysql_init( mysql );
	res = mysql_real_connect( mysql, host, user, passwd, db, port, socket, cf );
	if( res ) {
		con = my_mysql_con_add( &MY_CXT, mysql, client_flag );
		RETVAL = con;
	}
	else {
		strncpy( MY_CXT.lasterror, mysql_error( mysql ), sizeof( MY_CXT.lasterror ) );
		MY_CXT.lasterrno = mysql_errno( mysql );
		//MY_CXT.lastcon = NULL;
		Safefree( mysql );
		RETVAL = 0;
	}
OUTPUT:
	RETVAL
CLEANUP:
	Safefree( tmp );


#/******************************************************************************
# * reconnect( [linkid] )
# ******************************************************************************/

int
reconnect( linkid = 0 )
	void *linkid;
PREINIT:
	dMY_CXT;
	MY_CON *con;
	int r;
CODE:
	con = (MY_CON *) my_verify_linkid( &MY_CXT, linkid );
	if( con == NULL ) goto error;
	r = my_mysql_reconnect( con );
	if( ! r ) goto error;
	RETVAL = 1;
	goto exit;
error:
	RETVAL = 0;
exit:
OUTPUT:
	RETVAL


#/******************************************************************************
# * close( [linkid] )
# ******************************************************************************/

int
close( linkid = 0 )
	void * linkid;
PREINIT:
	dMY_CXT;
CODE:
	switch( my_mysql_get_type( &MY_CXT, &linkid ) ) {
	case MY_TYPE_CON:
		my_mysql_con_rem( &MY_CXT, (MY_CON *) linkid );
		RETVAL = 1;
		break;
	case MY_TYPE_RES:
		my_mysql_res_rem( (MY_RES *) linkid );
		RETVAL = 1;
		break;
	case MY_TYPE_STMT:
		my_mysql_stmt_rem( (MY_STMT *) linkid );
		RETVAL = 1;
		break;
	default:
		RETVAL = 0;
	}
OUTPUT:
	RETVAL


#/******************************************************************************
# * query( [linkid, ] query )
# ******************************************************************************/

IV
query( ... )
PREINIT:
	dMY_CXT;
	const char *sql;
	void * linkid = 0;
	MY_CON *con = NULL;
	size_t sqllen;
	long ret, try_count = 0, itemp = 0;
	MYSQL_RES *result;
CODE:
	switch( items ) {
	case 2:
		linkid = INT2PTR( void *, SvIV( ST(0) ) );
		itemp ++;
	case 1:
		sql = (const char *) SvPV_nolen( ST( itemp ) );
		break;
	default:	
		Perl_croak( aTHX_ "Usage: " __PACKAGE__ "::query(linkid = 0, query)" );
	}
	con = (MY_CON *) my_verify_linkid( &MY_CXT, linkid );
	if( con == NULL ) goto error;
	sqllen = strlen( sql );
retry:
	ret = mysql_real_query( con->conid, sql, (DWORD) sqllen );
	if( ret != 0 ) {
		if( try_count ++ == 0 )
			ret = my_mysql_handle_return( con, ret );
		if( ret != 0 ) goto error;
		goto retry;
	}
	result = mysql_store_result( con->conid );
	if( result ) {
		MY_RES *res = my_mysql_res_add( con, result );
		res->numrows = mysql_num_rows( result );
		RETVAL = PTR2IV( res );
	}
	else {
		if( mysql_field_count( con->conid ) == 0 )
			RETVAL = 1;
		else
			goto error;
	}
	goto exit;
error:
	RETVAL = 0;
exit:
OUTPUT:
	RETVAL


#/******************************************************************************
# * prepare( [linkid, ] query )
# ******************************************************************************/

IV
prepare( ... )
PREINIT:
	dMY_CXT;
	MY_CON *con;
	void * linkid = 0;
	const char *sql;
	int try_count = 0, itemp = 0;
	MY_STMT *stmt;
	DWORD num_fields, i;
	MYSQL_FIELD *fields;
	MYSQL_BIND *bind;
CODE:
	switch( items ) {
	case 2:
		linkid = INT2PTR( void *, SvIV( ST(0) ) );
		itemp ++;
	case 1:
		sql = (const char *) SvPV_nolen( ST( itemp ) );
		break;
	default:	
		Perl_croak( aTHX_ "Usage: " __PACKAGE__ "::prepare(linkid = 0, query)" );
	}
	con = (MY_CON *) my_verify_linkid( &MY_CXT, linkid );
	if( con == NULL ) goto error;
//MYSQL_VERSION_ID		50116
retry:
	stmt = my_mysql_stmt_init( con, sql, strlen( sql ) );
	if( stmt == NULL ) {
		if( try_count ++ == 0 )
			RETVAL = my_mysql_handle_return( con, 1 );
		if( RETVAL != 0 ) goto error;
		goto retry;
	}
	/* bind result */
	stmt->meta = mysql_stmt_result_metadata( stmt->stmt );
	if( stmt->meta != NULL ) {
		stmt->field_count = num_fields =
			mysql_stmt_field_count( stmt->stmt );
		fields = mysql_fetch_fields( stmt->meta );
		Newz( 0, stmt->result, num_fields, MYSQL_BIND );
		for( i = 0; i < num_fields; i ++ ) {
			bind = &stmt->result[i];
			switch( fields[i].type ) {
			case MYSQL_TYPE_TINY:
				bind->buffer_type = MYSQL_TYPE_TINY;
				bind->buffer_length = sizeof( char );
				break;
			case MYSQL_TYPE_SHORT:
				bind->buffer_type = MYSQL_TYPE_SHORT;
				bind->buffer_length = sizeof( short );
				break;
			case MYSQL_TYPE_LONG:
				bind->buffer_type = MYSQL_TYPE_LONG;
				bind->buffer_length = sizeof( long );
				break;
			case MYSQL_TYPE_FLOAT:
			case MYSQL_TYPE_DOUBLE:
				bind->buffer_type = MYSQL_TYPE_DOUBLE;
				bind->buffer_length = sizeof( double );
				break;
			default:
				bind->buffer_type = MYSQL_TYPE_STRING;
				bind->buffer_length = fields[i].length;
				break;
			}
			New( 1, bind->length, 1, DWORD );
			New( 1, bind->buffer, bind->buffer_length, char );
			New( 1, bind->is_null, 1, my_bool );
		}
	}
	RETVAL = PTR2IV( stmt );
goto exit;
error:
	RETVAL = 0;
exit:
OUTPUT:
	RETVAL


#/******************************************************************************
# * bind_param( stmtid, p_num, val )
# ******************************************************************************/

int
bind_param( stmtid, p_num, val = NULL, type = 0 )
	void * stmtid;
	U32 p_num;
	SV *val;
	char type;
PREINIT:
	dMY_CXT;
	MY_STMT *stmt;
CODE:
	stmt = (MY_STMT *) stmtid;
	if( my_mysql_stmt_exists( &MY_CXT, stmt ) )
		RETVAL = my_mysql_bind_param( stmt, p_num, val, type );
	else
		RETVAL = 0;
OUTPUT:
	RETVAL


#/******************************************************************************
# * execute( stmtid, [*params] )
# ******************************************************************************/

IV
execute( stmtid, ... )
	void * stmtid;
PREINIT:
	dMY_CXT;
	MY_STMT *stmt;
	DWORD i;
CODE:
	stmt = (MY_STMT *) stmtid;
	if( ! my_mysql_stmt_exists( &MY_CXT, stmt ) ) goto error;
	for( i = 1; i < (DWORD) items; i ++ ) {
		RETVAL = my_mysql_bind_param( stmt, i, ST( i ), 0 );
		if( RETVAL == 0 ) goto error;
	}
	if( stmt->param_count ) {
		RETVAL = mysql_stmt_bind_param( stmt->stmt, stmt->params );
		if( RETVAL != 0 ) goto error;
	}
	// execute statement
	RETVAL = mysql_stmt_execute( stmt->stmt ); 
	if( RETVAL != 0 ) goto error;
	// store result
	if( stmt->meta != NULL ) {
		mysql_stmt_bind_result( stmt->stmt, stmt->result );
		RETVAL = mysql_stmt_store_result( stmt->stmt );
		if( RETVAL != 0 ) goto error;
		stmt->numrows = mysql_stmt_affected_rows( stmt->stmt );
	}
	RETVAL = PTR2IV( stmt );
	goto exit;
error:
	RETVAL = 0;
exit:
OUTPUT:
	RETVAL


#/******************************************************************************
# * num_fields( resid )
# ******************************************************************************/

UV
num_fields( resid )
	void * resid;
PREINIT:
	dMY_CXT;
CODE:
	switch( my_mysql_stmt_or_res( &MY_CXT, resid ) ) {
	case MY_TYPE_RES:
		RETVAL = mysql_num_fields( ( (MY_RES *) resid )->res );
		break;
	case MY_TYPE_STMT:
		RETVAL = mysql_num_fields( ( (MY_STMT *) resid )->meta );
		break;
	default:
		RETVAL = 0;
		break;
	}
OUTPUT:
	RETVAL


#/******************************************************************************
# * num_rows( resid )
# ******************************************************************************/

void
num_rows( resid )
	void * resid;
PREINIT:
	dMY_CXT;
#ifndef HAS_UV64
	char tmp[21], *p1;
#endif
CODE:
	switch( my_mysql_stmt_or_res( &MY_CXT, resid ) ) {
	case MY_TYPE_RES:
#ifdef HAS_UV64
		ST(0) = sv_2mortal( newSVuv( ( (MY_RES *) resid )->numrows ) );
#else
		if( ( (MY_RES *) resid )->numrows <= 0xffffffff ) {
			ST(0) = sv_2mortal( newSVuv( ( (MY_RES *) resid )->numrows ) );
		}
		else {
			p1 = my_ltoa( tmp, ( (MY_RES *) resid )->numrows, 10 );
			ST(0) = sv_2mortal( newSVpvn( tmp, p1 - tmp ) );
		}
#endif
		break;
	case MY_TYPE_STMT:
#ifdef HAS_UV64
		ST(0) = sv_2mortal( newSVuv( ( (MY_STMT *) resid )->numrows ) );
#else
		if( ( (MY_STMT *) resid )->numrows <= 0xffffffff ) {
			ST(0) = sv_2mortal( newSVuv( ( (MY_STMT *) resid )->numrows ) );
		}
		else {
			p1 = my_ltoa( tmp, ( (MY_STMT *) resid )->numrows, 10 );
			ST(0) = sv_2mortal( newSVpvn( tmp, p1 - tmp ) );
		}
#endif
		break;
	default:
		ST(0) = &PL_sv_undef;
		break;
	}


#/******************************************************************************
# * fetch_names( resid )
# ******************************************************************************/

void
fetch_names( resid )
	void * resid;
PREINIT:
	dMY_CXT;
	MYSQL_RES *res = NULL;
	MYSQL_FIELD *fields;
	int num_fields, i;
PPCODE:
	switch( my_mysql_stmt_or_res( &MY_CXT, resid ) ) {
	case MY_TYPE_RES:
		res = ( (MY_RES *) resid )->res;
		break;
	case MY_TYPE_STMT:
		res = ( (MY_STMT *) resid )->meta;
		break;
	default:
		goto exit;
	}
	fields = mysql_fetch_fields( res );
	num_fields = mysql_num_fields( res );
	for( i = 0; i < num_fields; i ++ ) {
		XPUSHs( sv_2mortal(
			newSVpvn( fields[i].name, fields[i].name_length )
		) );	
	}
exit:
	{}


#/******************************************************************************
# * fetch_field( resid [, offset] )
# ******************************************************************************/

void
fetch_field( resid, offset = -1 )
	void * resid;
	long offset;
PREINIT:
	dMY_CXT;
	MYSQL_RES *res;
	MYSQL_FIELD *field;
	unsigned int flags;
PPCODE:
	switch( my_mysql_stmt_or_res( &MY_CXT, resid ) ) {
	case MY_TYPE_RES:
		res = ( (MY_RES *) resid )->res;
		break;
	case MY_TYPE_STMT:
		res = ( (MY_STMT *) resid )->meta;
		break;
	default:
		goto exit;
	}
	if( offset >= 0 )
		mysql_field_seek( res, offset );
	field = mysql_fetch_field( res );
	if( field == NULL ) goto exit;
	XPUSHs( sv_2mortal( newSVpvn( "name", 4 ) ) );
	XPUSHs( sv_2mortal( newSVpvn( field->name, field->name_length ) ) );
	XPUSHs( sv_2mortal( newSVpvn( "table", 5 ) ) );
	XPUSHs( sv_2mortal( newSVpvn( field->table, field->table_length ) ) );
	XPUSHs( sv_2mortal( newSVpvn( "catalog", 7 ) ) );
	XPUSHs( sv_2mortal( newSVpvn( field->catalog, field->catalog_length ) ) );
	XPUSHs( sv_2mortal( newSVpvn( "length", 6 ) ) );
	XPUSHs( sv_2mortal( newSVuv( field->length ) ) );
	XPUSHs( sv_2mortal( newSVpvn( "default", 7 ) ) );
	XPUSHs( sv_2mortal( newSVpvn( field->def, field->def_length ) ) );
	flags = field->flags;
	XPUSHs( sv_2mortal( newSVpvn( "nullable", 8 ) ) );
	XPUSHs( sv_2mortal( newSViv( ( flags & NOT_NULL_FLAG ) == 0 ) ) );
	XPUSHs( sv_2mortal( newSVpvn( "primary", 6 ) ) );
	XPUSHs( sv_2mortal( newSViv( ( flags & PRI_KEY_FLAG ) != 0 ) ) );
	XPUSHs( sv_2mortal( newSVpvn( "unique", 6 ) ) );
	XPUSHs( sv_2mortal( newSViv( ( flags & UNIQUE_KEY_FLAG ) != 0 ) ) );
	XPUSHs( sv_2mortal( newSVpvn( "index", 5 ) ) );
	XPUSHs( sv_2mortal( newSViv( ( flags & MULTIPLE_KEY_FLAG ) != 0 ) ) );
	XPUSHs( sv_2mortal( newSVpvn( "identity", 8 ) ) );
	XPUSHs( sv_2mortal( newSViv( ( flags & AUTO_INCREMENT_FLAG ) != 0 ) ) );
	XPUSHs( sv_2mortal( newSVpvn( "numeric", 7 ) ) );
	XPUSHs( sv_2mortal( newSViv( ( flags & NUM_FLAG ) != 0 ) ) );
	XPUSHs( sv_2mortal( newSVpvn( "binary", 6 ) ) );
	XPUSHs( sv_2mortal( newSViv( ( flags & BINARY_FLAG ) != 0 ) ) );
	XPUSHs( sv_2mortal( newSVpvn( "zerofill", 8 ) ) );
	XPUSHs( sv_2mortal( newSViv( ( flags & ZEROFILL_FLAG ) != 0 ) ) );
	XPUSHs( sv_2mortal( newSVpvn( "unsigned", 8 ) ) );
	XPUSHs( sv_2mortal( newSViv( ( flags & UNSIGNED_FLAG ) != 0 ) ) );
exit:
	{}


#/******************************************************************************
# * field_seek( resid [, offset] )
# ******************************************************************************/

U32
field_seek( resid, offset = 0 )
	void * resid;
	U32 offset;
PREINIT:
	dMY_CXT;
CODE:
	switch( my_mysql_stmt_or_res( &MY_CXT, resid ) ) {
	case MY_TYPE_RES:
		RETVAL = mysql_field_seek( ( (MY_RES *) resid )->res, offset );
		break;
	case MY_TYPE_STMT:
		RETVAL = mysql_field_seek( ( (MY_STMT *) resid )->meta, offset );
		break;
	default:
		RETVAL = 0;
		break;
	}
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
	switch( my_mysql_stmt_or_res( &MY_CXT, resid ) ) {
	case MY_TYPE_RES:
		RETVAL = mysql_field_tell( ( (MY_RES *) resid )->res );
		break;
	case MY_TYPE_STMT:
		RETVAL = mysql_field_tell( ( (MY_STMT *) resid )->meta );
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
	MY_RES *res;
	MYSQL_ROW row;
	DWORD *lengths;
	MY_STMT *stmt;
	MYSQL_BIND *result;
	DWORD num_fields, i;
PPCODE:
	switch( my_mysql_stmt_or_res( &MY_CXT, resid ) ) {
	case MY_TYPE_RES:
		res = (MY_RES *) resid;
		row = mysql_fetch_row( res->res );
		if( ! row ) goto error;
		num_fields = mysql_num_fields( res->res );
		lengths = mysql_fetch_lengths( res->res );
		EXTEND( SP, num_fields );
		for( i = 0; i < num_fields; i ++ ) {
			if( row[i] )
				XPUSHs( sv_2mortal( newSVpvn( row[i], lengths[i] ) ) );
			else
				XPUSHs( &PL_sv_undef );	
		}
		res->rowpos ++;
		break;
	case MY_TYPE_STMT:
		stmt = (MY_STMT *) resid;
		if( mysql_stmt_fetch( stmt->stmt ) != 0 ) goto error;
		EXTEND( SP, stmt->field_count );
		for( i = 0; i < stmt->field_count; i ++ ) {
			result = &stmt->result[i];
			if( *(result->is_null) )
				XPUSHs( &PL_sv_undef );	
			else
			switch( result->buffer_type ) {
			case MYSQL_TYPE_TINY:
				if( result->is_unsigned )
					XPUSHs( sv_2mortal( newSVuv( *((char *) result->buffer) ) ) );
				else
					XPUSHs( sv_2mortal( newSViv( *((char *) result->buffer) ) ) );
				break;
			case MYSQL_TYPE_SHORT:
				if( result->is_unsigned )
					XPUSHs( sv_2mortal( newSVuv( *((short *) result->buffer) ) ) );
				else
					XPUSHs( sv_2mortal( newSViv( *((short *) result->buffer) ) ) );
				break;
			case MYSQL_TYPE_LONG:
				if( result->is_unsigned )
					XPUSHs( sv_2mortal( newSVuv( *((long *) result->buffer) ) ) );
				else
					XPUSHs( sv_2mortal( newSViv( *((long *) result->buffer) ) ) );
				break;
			case MYSQL_TYPE_DOUBLE:
				XPUSHs( sv_2mortal( newSVnv( *((double *) result->buffer) ) ) );
				break;
			default:
				XPUSHs( sv_2mortal( newSVpvn( result->buffer, *(result->length) ) ) );
				break;
			}
		}
		stmt->rowpos ++;
		break;
	}
error:
	{}


#/******************************************************************************
# * fetch_col( resid )
# ******************************************************************************/

void
fetch_col( resid )
	void * resid;
PREINIT:
	dMY_CXT;
	MY_RES *res;
	MYSQL_ROW row;
	DWORD *lengths;
	MY_STMT *stmt;
	MYSQL_BIND *result;
PPCODE:
	switch( my_mysql_stmt_or_res( &MY_CXT, resid ) ) {
	case MY_TYPE_RES:
		res = (MY_RES *) resid;
		EXTEND( SP, res->numrows );
		while( ( row = mysql_fetch_row( res->res ) ) ) {
			lengths = mysql_fetch_lengths( res->res );
			if( lengths[0] > 0 )
				XPUSHs( sv_2mortal( newSVpvn( row[0], lengths[0] ) ) );	
			else
				XPUSHs( &PL_sv_undef );	
		}
		res->rowpos = res->numrows;
		break;
	case MY_TYPE_STMT:
		stmt = (MY_STMT *) resid;
		EXTEND( SP, stmt->numrows );
		while( mysql_stmt_fetch( stmt->stmt ) == 0 ) {
			result = &stmt->result[0];
			if( *(result->is_null) )
				XPUSHs( &PL_sv_undef );	
			else
			switch( result->buffer_type ) {
			case MYSQL_TYPE_TINY:
				if( result->is_unsigned )
					XPUSHs( sv_2mortal( newSVuv( *((char *) result->buffer) ) ) );
				else
					XPUSHs( sv_2mortal( newSViv( *((char *) result->buffer) ) ) );
				break;
			case MYSQL_TYPE_SHORT:
				if( result->is_unsigned )
					XPUSHs( sv_2mortal( newSVuv( *((short *) result->buffer) ) ) );
				else
					XPUSHs( sv_2mortal( newSViv( *((short *) result->buffer) ) ) );
				break;
			case MYSQL_TYPE_LONG:
				if( result->is_unsigned )
					XPUSHs( sv_2mortal( newSVuv( *((long *) result->buffer) ) ) );
				else
					XPUSHs( sv_2mortal( newSViv( *((long *) result->buffer) ) ) );
				break;
			case MYSQL_TYPE_DOUBLE:
				XPUSHs( sv_2mortal( newSVnv( *((double *) result->buffer) ) ) );
				break;
			default:
				XPUSHs( sv_2mortal( newSVpvn( result->buffer, *(result->length) ) ) );
				break;
			}
		}
		stmt->rowpos = stmt->numrows;
		break;
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
	MYSQL_ROW row;
	MYSQL_FIELD *fields;
	MY_STMT *stmt;
	MYSQL_BIND *result;
	DWORD *lengths;
	DWORD num_fields, i;
PPCODE:
	switch( my_mysql_stmt_or_res( &MY_CXT, resid ) ) {
	case MY_TYPE_RES:
		res = (MY_RES *) resid;
		row = mysql_fetch_row( res->res );
		if( ! row ) goto error;
		num_fields = mysql_num_fields( res->res );
		lengths = mysql_fetch_lengths( res->res );
		fields = mysql_fetch_fields( res->res );
		EXTEND( SP, num_fields * 2 );
		for( i = 0; i < num_fields; i ++ ) {
			XPUSHs( sv_2mortal(
				newSVpvn( fields[i].name, fields[i].name_length )
			) );	
			if( row[i] )
				XPUSHs( sv_2mortal( newSVpvn( row[i], lengths[i] ) ) );	
			else
				XPUSHs( &PL_sv_undef );	
		}
		res->rowpos ++;
		break;
	case MY_TYPE_STMT:
		stmt = (MY_STMT *) resid;
		if( mysql_stmt_fetch( stmt->stmt ) != 0 ) goto error;
		fields = mysql_fetch_fields( stmt->meta );
		EXTEND( SP, stmt->field_count * 2 );
		for( i = 0; i < stmt->field_count; i ++ ) {
			XPUSHs( sv_2mortal(
				newSVpvn( fields[i].name, fields[i].name_length )
			) );	
			result = &stmt->result[i];
			if( *(result->is_null) )
				XPUSHs( &PL_sv_undef );	
			else
			switch( result->buffer_type ) {
			case MYSQL_TYPE_TINY:
				if( result->is_unsigned )
					XPUSHs( sv_2mortal( newSVuv( *((char *) result->buffer) ) ) );
				else
					XPUSHs( sv_2mortal( newSViv( *((char *) result->buffer) ) ) );
				break;
			case MYSQL_TYPE_SHORT:
				if( result->is_unsigned )
					XPUSHs( sv_2mortal( newSVuv( *((short *) result->buffer) ) ) );
				else
					XPUSHs( sv_2mortal( newSViv( *((short *) result->buffer) ) ) );
				break;
			case MYSQL_TYPE_LONG:
				if( result->is_unsigned )
					XPUSHs( sv_2mortal( newSVuv( *((long *) result->buffer) ) ) );
				else
					XPUSHs( sv_2mortal( newSViv( *((long *) result->buffer) ) ) );
				break;
			case MYSQL_TYPE_DOUBLE:
				XPUSHs( sv_2mortal( newSVnv( *((double *) result->buffer) ) ) );
				break;
			default:
				XPUSHs( sv_2mortal( newSVpvn( result->buffer, *(result->length) ) ) );
				break;
			}
		}
		stmt->rowpos ++;
		break;
	}
error:
	{}


#/******************************************************************************
# * fetch_lengths( resid )
# ******************************************************************************/

void
fetch_lengths( resid )
	void * resid;
PREINIT:
	dMY_CXT;
	DWORD *lengths;
	DWORD num_fields, i;
	MY_STMT *stmt;
PPCODE:
	switch( my_mysql_stmt_or_res( &MY_CXT, resid ) ) {
	case MY_TYPE_RES:
		lengths = mysql_fetch_lengths( ( (MY_RES *) resid )->res );
		if( lengths ) {
			num_fields = mysql_num_fields( ( (MY_RES *) resid )->res );
			EXTEND( SP, num_fields );
			for( i = 0; i < num_fields; i ++ ) {
				XPUSHs( sv_2mortal( newSVuv( lengths[i] ) ) );	
			}
		}
		break;
	case MY_TYPE_STMT:
		stmt = (MY_STMT *) resid;
		EXTEND( SP, stmt->field_count );
		for( i = 0; i < stmt->field_count; i ++ ) {
			XPUSHs( sv_2mortal( newSVuv( *(stmt->result[i].length) ) ) );	
		}
	}


#/******************************************************************************
# * row_seek( resid, offset )
# ******************************************************************************/

int
row_seek( resid, offset = 0 )
	void * resid;
	UV offset;
PREINIT:
	dMY_CXT;
	MY_RES *res;
	MY_STMT *stmt;
CODE:
	switch( my_mysql_stmt_or_res( &MY_CXT, resid ) ) {
	case MY_TYPE_RES:
		res = (MY_RES *) resid;
		if( offset >= (UV) res->numrows )
			offset = (UV) res->numrows - 1;
		mysql_data_seek( res->res, offset );
		res->rowpos = offset;
		RETVAL = 1;
		break;
	case MY_TYPE_STMT:
		stmt = (MY_STMT *) resid;
		if( offset >= (UV) stmt->numrows )
			offset = (UV) stmt->numrows - 1;
		mysql_stmt_data_seek( stmt->stmt, offset );
		stmt->rowpos = offset;
		RETVAL = 1;
		break;
	default:
		RETVAL = 0;
	}
OUTPUT:
	RETVAL


#/******************************************************************************
# * row_tell( resid )
# ******************************************************************************/

UV
row_tell( resid )
	void * resid;
PREINIT:
	dMY_CXT;
CODE:
	switch( my_mysql_stmt_or_res( &MY_CXT, resid ) ) {
	case MY_TYPE_RES:
		RETVAL = (UV) ( (MY_RES *) resid )->rowpos;
		break;
	case MY_TYPE_STMT:
		RETVAL = (UV) ( (MY_STMT *) resid )->rowpos;
		break;
	default:
		RETVAL = 0;
	}
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
	switch( my_mysql_stmt_or_res( &MY_CXT, resid ) ) {
	case MY_TYPE_RES:
		my_mysql_res_rem( (MY_RES *) resid );
		RETVAL = 1;
		break;
	case MY_TYPE_STMT:
		my_mysql_stmt_rem( (MY_STMT *) resid );
		RETVAL = 1;
		break;
	default:
		RETVAL = 0;
	}
OUTPUT:
	RETVAL


#/******************************************************************************
# * insert_id( [linkid [, field [, table [, schema]]]] )
# ******************************************************************************/

void
insert_id( linkid = 0, field = NULL, table = NULL, schema = NULL )
	void * linkid;
	const char *field;
	const char *table;
	const char *schema;
PREINIT:
	dMY_CXT;
#ifndef HAS_UV64
	UXLONG rv;
	char tmp[21], *p1;
#endif
CODE:
	switch( my_mysql_stmt_or_con( &MY_CXT, &linkid ) ) {
	case MY_TYPE_CON:
#ifdef HAS_UV64
		ST(0) = sv_2mortal(
			newSVuv( mysql_insert_id( ( (MY_CON *) linkid )->conid ) )
		);
#else
		rv = mysql_insert_id( ( (MY_CON *) linkid )->conid );
		if( rv <= 0xffffffff ) {
			ST(0) = sv_2mortal( newSVuv( rv ) );
		}
		else {
			p1 = my_ltoa( tmp, rv, 10 );
			ST(0) = sv_2mortal( newSVpvn( tmp, p1 - tmp ) );
		}
#endif
		break;
	case MY_TYPE_STMT:
#ifdef HAS_UV64
		ST(0) = sv_2mortal(
			newSVuv( mysql_stmt_insert_id( ( (MY_STMT *) linkid )->stmt ) )
		);
#else
		rv = mysql_stmt_insert_id( ( (MY_STMT *) linkid )->stmt );
		if( rv <= 0xffffffff ) {
			ST(0) = sv_2mortal( newSVuv( rv ) );
		}
		else {
			p1 = my_ltoa( tmp, rv, 10 );
			ST(0) = sv_2mortal( newSVpvn( tmp, p1 - tmp ) );
		}
#endif
		break;
	default:
		ST(0) = &PL_sv_undef;
	}


#/******************************************************************************
# * affected_rows( [linkid] )
# ******************************************************************************/

void
affected_rows( linkid = 0 )
	void * linkid;
PREINIT:
	dMY_CXT;
#ifndef HAS_UV64
	UXLONG ret;
	char tmp[21], *p1;
#endif
CODE:
	switch( my_mysql_stmt_or_con( &MY_CXT, &linkid ) ) {
	case MY_TYPE_CON:
#ifdef HAS_UV64
		ST(0) = sv_2mortal(
			newSVuv( mysql_affected_rows( ( (MY_CON *) linkid )->conid ) )
		);
#else
		ret = mysql_affected_rows( ( (MY_CON *) linkid )->conid );
		if( ret <= 0xffffffff ) {
			ST(0) = sv_2mortal( newSVuv( ret ) );
		}
		else {
			p1 = my_ltoa( tmp, ret, 10 );
			ST(0) = sv_2mortal( newSVpvn( tmp, p1 - tmp ) );
		}
#endif
		break;
	case MY_TYPE_STMT:
#ifdef HAS_UV64
		ST(0) = sv_2mortal(
			newSVuv( mysql_stmt_affected_rows( ( (MY_STMT *) linkid )->stmt ) )
		);
#else
		ret = mysql_stmt_affected_rows( ( (MY_STMT *) linkid )->stmt );
		if( ret <= 0xffffffff ) {
			ST(0) = sv_2mortal( newSVuv( ret ) );
		}
		else {
			p1 = my_ltoa( tmp, ret, 10 );
			ST(0) = sv_2mortal( newSVpvn( tmp, p1 - tmp ) );
		}
#endif
		break;
	default:
		ST(0) = &PL_sv_undef;
	}


#/******************************************************************************
# * quote( val )
# ******************************************************************************/

void
quote( val )
const char *val
PREINIT:
	char *res = NULL;
	int l, i, dp;
CODE:
	l = (int) strlen( val );
	New( 1, res, l * 2 + 3, char );
	dp = 1;
	res[0] = '\'';
	for( i = l; i > 0; i -- ) {
		switch( *val ) {
		case '\'':
			res[dp ++] = '\\';
			res[dp ++] = '\'';
			val ++;
			break;
		default:
			res[dp ++] = *val ++;
			break;
		}
	}
	res[dp ++] = '\'';
	res[dp] = 0;
	ST(0) = newSVpvn( res, dp );
	sv_2mortal( ST(0) );
CLEANUP:
	free( res );


#/******************************************************************************
# * quote_id( ... )
# ******************************************************************************/

void
quote_id( ... )
PREINIT:
	const char *str;
	char *res = NULL;
	int i;
	size_t j, rlen, rpos;
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
			res[rpos ++] = '`';
			for( j = 0; j < len; j ++ ) {
				switch( str[j] ) {
				case '`':
					res[rpos ++] = '`';
					res[rpos ++] = '`';
					break;
				default:
					res[rpos ++] = str[j];
					break;
				}
			}
			res[rpos ++] = '`';
		}
	}
	res[rpos] = '\0';
	ST(0) = sv_2mortal( newSVpvn( res, rpos ) );
CLEANUP:
	Safefree( res );


#/******************************************************************************
# * escape( [linkid ,] val )
# ******************************************************************************/

void
escape( ... )
PREINIT:
	dMY_CXT;
	char *tmp = 0;
	size_t len;
	const char *val;
	void *linkid;
CODE:
    if( items < 1 || items > 2 )
		Perl_croak( aTHX_ "Usage: " __PACKAGE__ "::escape(linkid = 0, val)" );
	if( items < 2 ) {
		linkid = NULL;
	    val = (const char *) SvPV_nolen( ST(0) );
	}
	else {
		linkid = INT2PTR( void *, SvIV( ST(0) ) );
	    val = (const char *) SvPV_nolen( ST(1) );
	}
	if( ! ( linkid = my_verify_linkid( &MY_CXT, linkid ) ) ) goto error;
	len = strlen( val );
	New( 1, tmp, len * 2 + 1, char );
	len = mysql_real_escape_string( ( (MY_CON *) linkid )->conid, tmp, val, (DWORD) len );
	ST(0) = sv_2mortal( newSVpvn( tmp, len ) );
error:
CLEANUP:
	Safefree( tmp );


#/******************************************************************************
# * set_charset( [linkid, ] charset )
# ******************************************************************************/

int
set_charset( ... )
PREINIT:
	dMY_CXT;
	const char *charset;
	void *linkid = NULL;
	MY_CON *con;
	DWORD version;
	STRLEN cslen, sqllen;
	int res, itemp = 0;
	char *sql, *p1;
CODE:
    if( items < 1 || items > 2 )
		Perl_croak( aTHX_ "Usage: " __PACKAGE__ "::set_charset(linkid = 0, charset)" );
	if( items > 1 ) {
		linkid = INT2PTR( void *, SvIV( ST(itemp) ) );
		itemp ++;
	}
    charset = (const char *) SvPVx( ST( itemp ), cslen );
	con = (MY_CON *) my_verify_linkid( &MY_CXT, linkid );
	if( con == NULL ) goto error;
	version = mysql_get_server_version( con->conid );
	// 5.1.5 -> 50105 
	// 4.1.0 -> 40100
	if( version < 40100 ) {
		RETVAL = 1;
		goto exit;
	}
	// SET NAMES 'xxx'
	sqllen = cslen + 12;
	New( 1, sql, sqllen + 1, char );
	p1 = my_strcpy( sql, "SET NAMES '" );
	p1 = my_strcpy( p1, charset );
	p1 = my_strcpy( p1, "'" );
	res = mysql_real_query( con->conid, sql, (DWORD) sqllen );
	Safefree( sql );
	if( res ) goto error;
	Safefree( con->charset );
	New( 1, con->charset, cslen + 1, char );
	memcpy( con->charset, charset, cslen + 1 );
	con->charset_length = (DWORD) cslen;
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
CODE:
	RETVAL = ( linkid = my_verify_linkid( &MY_CXT, linkid ) )
		? ( (MY_CON *) linkid )->charset
		: NULL
	;
OUTPUT:
	RETVAL


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
	con = (MY_CON *) my_verify_linkid( &MY_CXT, linkid );
	if( con == NULL ) goto error;
	if( mode ) {
		if( ( con->my_flags & MYCF_AUTOCOMMIT ) == 0 ) {
			int r = mysql_autocommit( con->conid, FALSE );
			if( r != 0 ) goto error;
			con->my_flags |= MYCF_AUTOCOMMIT;
		}
	}
	else {
		if( ( con->my_flags & MYCF_AUTOCOMMIT ) != 0 ) {
			int r = mysql_autocommit( con->conid, TRUE );
			if( r != 0 ) goto error;
			con->my_flags ^= MYCF_AUTOCOMMIT;
		}
	}
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
begin_work( linkid = 0 )
	void * linkid;
PREINIT:
	dMY_CXT;
	MY_CON *con;
CODE:
	if( ! ( linkid = my_verify_linkid( &MY_CXT, linkid ) ) ) goto error;
	con = (MY_CON *) linkid;
	if( ( con->my_flags & MYCF_TRANSACTION ) == 0 ) {
		int r = mysql_autocommit( con->conid, FALSE );
		if( r != 0 ) goto error;
		con->my_flags |= MYCF_TRANSACTION;
	}
	RETVAL = 1;
	goto exit;
error:
	RETVAL = 0;
exit:
OUTPUT:
	RETVAL


#/******************************************************************************
# * commit( [linkid] )
# ******************************************************************************/

int
commit( linkid = 0 )
	void * linkid;
PREINIT:
	dMY_CXT;
	MY_CON *con;
CODE:
	if( ! ( linkid = my_verify_linkid( &MY_CXT, linkid ) ) ) goto error;
	con = (MY_CON *) linkid;
	if( ( con->my_flags & MYCF_TRANSACTION ) != 0 ) {
		int r = mysql_commit( con->conid );
		if( r != 0  ) goto error;
		con->my_flags ^= MYCF_TRANSACTION;
		if( ( con->my_flags & MYCF_AUTOCOMMIT ) != 0 ) {
			r = mysql_autocommit( con->conid, TRUE );
			if( r != 0 ) goto error;
		}
	}
	RETVAL = 1;
	goto exit;
error:
	RETVAL = 0;
exit:
OUTPUT:
	RETVAL


#/******************************************************************************
# * rollback( [linkid] )
# ******************************************************************************/

int
rollback( linkid = 0 )
	void * linkid;
PREINIT:
	dMY_CXT;
	MY_CON *con;
CODE:
	if( ! ( linkid = my_verify_linkid( &MY_CXT, linkid ) ) ) goto error;
	con = (MY_CON *) linkid;
	if( ( con->my_flags & MYCF_TRANSACTION ) != 0 ) {
		int r = mysql_rollback( con->conid );
		if( r != 0 ) goto error;
		con->my_flags ^= MYCF_TRANSACTION;
		if( ( con->my_flags & MYCF_AUTOCOMMIT ) != 0 ) {
			r = mysql_autocommit( con->conid, TRUE );
			if( r != 0 ) goto error;
		}
	}
	RETVAL = 1;
	goto exit;
error:
	RETVAL = 0;
exit:
OUTPUT:
	RETVAL


#/******************************************************************************
# * show_catalogs( [linkid, [wild]] )
# ******************************************************************************/

void
show_catalogs( linkid = 0, wild = NULL )
	void * linkid;
	const char *wild;
PREINIT:
	dMY_CXT;
	MY_CON *con;
	MYSQL_RES *res;
	MYSQL_ROW row;
PPCODE:
	if( ! ( linkid = my_verify_linkid( &MY_CXT, linkid ) ) ) goto error;
	con = (MY_CON *) linkid;
	res = mysql_list_dbs( con->conid, wild );
	if( res ) {
		while( ( row = mysql_fetch_row( res ) ) ) {
			if( row[0] != 0 ) {
				XPUSHs( sv_2mortal( newSVpvn( row[0], strlen( row[0] ) ) ) );
			}
		}
		mysql_free_result( res );
	}
error:
	{}


#/******************************************************************************
# * show_tables( [linkid [, schema [, db [, wild]]]] )
# ******************************************************************************/

void
show_tables( linkid = 0, schema = NULL, db = NULL, wild = NULL )
	void * linkid;
	const char *db;
	const char *schema;
	const char *wild;
PREINIT:
	dMY_CXT;
	MY_CON *con;
	MYSQL_RES *res;
	MYSQL_ROW row;
	char sql[512], *p1;
	AV *av;
PPCODE:
	if( ! ( linkid = my_verify_linkid( &MY_CXT, linkid ) ) ) goto error;
	con = (MY_CON *) linkid;
	if( db && db[0] != '\0' ) {
		p1 = my_strcpy( sql, "SHOW TABLES FROM `" );
		p1 = my_strcpy( p1, db );
		p1 = my_strcpy( p1, "`" );
		if( wild && wild[0] != '\0' ) {
			p1 = my_strcpy( p1, " LIKE " );
			p1 = my_strcpy( p1, wild );
		}
		if( mysql_real_query( con->conid, sql, (DWORD) (p1 - sql) ) == 0 ) {
			res = mysql_store_result( con->conid );
		}
		else {
			res = 0;
		}
	}
	else {
		res = mysql_list_tables( con->conid, wild );
	}
	if( res ) {
		while( ( row = mysql_fetch_row( res ) ) ) {
			if( row[0] != 0 ) {
				// TABLE, SCHEMA, DB, TYPE
				av = (AV *) sv_2mortal( (SV *) newAV() );
				av_push( av, newSVpvn( row[0], strlen( row[0] ) ) );
				av_push( av, &PL_sv_undef );
				av_push( av, newSVpv( db, 0 ) );
				// todo: add, detect "views"
				av_push( av, newSVpvn( "table", 5 ) );
				XPUSHs( sv_2mortal( newRV( (SV *) av ) ) );
			}
		}
		mysql_free_result( res );
	}
error:
	{}


#/******************************************************************************
# * show_fields( [linkid, ] table [, schema [, db, [wild]]]] )
# ******************************************************************************/

void
show_fields( ... )
PREINIT:
	dMY_CXT;
	void * linkid = 0;
	const char *table = NULL;
	const char *schema = NULL;
	const char *db = NULL;
	const char *wild = NULL;
	int itemp = 0;
	MY_CON *con;
	MYSQL_RES *res;
	MYSQL_ROW row;
	int numfields, numrows, r;
	char sql[512], *p1;
	AV *av;
PPCODE:
    if( items < ( SvIOK( ST(0) ) ? 2 : 1 ) || items > 5 )
		Perl_croak( aTHX_ "Usage: " __PACKAGE__ "::show_fields(linkid = 0, table, schema = NULL, db = NULL, wild = NULL)" );
	if( SvIOK( ST( itemp ) ) ) {
		linkid = INT2PTR( void *, SvIV( ST( itemp ) ) );
		itemp ++;
	}
	table = (const char *) SvPV_nolen( ST( itemp ) );
	itemp ++;
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
	con = (MY_CON *) my_verify_linkid( &MY_CXT, linkid );
	if( con == NULL ) goto error;
	p1 = my_strcpy( sql, "SHOW COLUMNS FROM `" );
	p1 = my_strcpy( p1, table );
	p1 = my_strcpy( p1, "`" );
	if( wild && wild[0] != '\0' ) {
		p1 = my_strcpy( p1, " LIKE '" );
		p1 = my_strcpy( p1, wild );
		p1 = my_strcpy( p1, "'" );
	}
	r = mysql_real_query( con->conid, sql, (DWORD) (p1 - sql) );
	if( r == 0 ) {
		res = mysql_store_result( con->conid );
		numrows = (DWORD) mysql_num_rows( res );
		numfields = mysql_num_fields( res );
		EXTEND( SP, numrows );
		// COLUMN, NULLABLE, DEFAULT, IS_PRIMARY, IS_UNIQUE, TYPENAME, AUTOINC
		while( ( row = mysql_fetch_row( res ) ) ) {
			av = (AV *) sv_2mortal( (SV *) newAV() );
			av_push( av, newSVpvn( row[0], strlen( row[0] ) ) );
			av_push( av, newSViv( strcmp( row[2], "NO" ) == 0 ? 0 : 1 ) );
			if( row[4] != 0 )
				av_push( av, newSVpvn( row[4], strlen( row[4] ) ) );
			else
				av_push( av, &PL_sv_undef );
			av_push( av, newSViv( strcmp( row[3], "PRI" ) == 0 ? 1 : 0 ) );
			av_push( av, newSViv( strcmp( row[3], "UNI" ) == 0 ? 1 : 0 ) );
			av_push( av, newSVpvn( row[1], strlen( row[1] ) ) );
			av_push( av, newSViv( strstr( row[5], "auto_increment" ) != 0 ? 1 : 0 ) );
			XPUSHs( sv_2mortal( newRV( (SV *) av ) ) );
		}
		mysql_free_result( res );
	}
error:
	{}


#/******************************************************************************
# * show_index( [linkid, ] table [, schema [, db]] )
# ******************************************************************************/

void
show_index( ... )
PREINIT:
	dMY_CXT;
	void * linkid = 0;
	const char *table = NULL;
	const char *schema = NULL;
	const char *db = NULL;
	MY_CON *con;
	MYSQL_RES *res;
	MYSQL_ROW row;
	char sql[512], *p1;
	int step, num_fields, num_rows, itemp = 0;
	long r;
	AV *av;
PPCODE:
    if( items < ( SvIOK( ST(0) ) ? 2 : 1 ) || items > 4 )
		Perl_croak( aTHX_ "Usage: " __PACKAGE__ "::show_index(linkid = 0, table, schema = NULL, db = NULL)" );
	if( SvIOK( ST( itemp ) ) ) {
		linkid = INT2PTR( void *, SvIV( ST( itemp ) ) );
		itemp ++;
	}
	table = (const char *) SvPV_nolen( ST( itemp ) );
	itemp ++;
	if( itemp < items ) {
		schema = (const char *) SvPV_nolen( ST( itemp ) );
		itemp ++;
	}
	if( itemp < items )
		db = (const char *) SvPV_nolen( ST( itemp ) );
	con = (MY_CON *) my_verify_linkid( &MY_CXT, linkid );
	if( con == NULL ) goto error;
	// SHOW INDEX FROM table FROM db
	p1 = my_strcpy( sql, "SHOW INDEX FROM `" );
	p1 = my_strcpy( p1, table );
	p1 = my_strcpy( p1, "`" );
	if( db != 0 && db[0] != '\0' ) {
		p1 = my_strcpy( p1, " FROM `" );
		p1 = my_strcpy( p1, db );
		p1 = my_strcpy( p1, "`" );
	}
	step = 0;
retry:
	r = mysql_real_query( con->conid, sql, (DWORD) (p1 - sql) );
	switch( r ) {
	case 0:
		break;
	case 1:
	case CR_SERVER_GONE_ERROR:
	case CR_SERVER_LOST:
		if( ( con->client_flag & CLIENT_RECONNECT ) != 0 && step == 0 ) {
			step ++;
			r = my_mysql_reconnect( con );
			if( ! r ) goto error;
			goto retry;
		}
	default:
		goto error;
	}
	res = mysql_store_result( con->conid );
	num_fields = mysql_num_fields( res );
	num_rows = (DWORD) mysql_num_rows( res );
	EXTEND( SP, num_rows );
	// NAME, COLUMN, TYPE
	while( ( row = mysql_fetch_row( res ) ) ) {
		av = (AV *) sv_2mortal( (SV *) newAV() );
		av_push( av, newSVpvn( row[2], strlen( row[2] ) ) );
		av_push( av, newSVpvn( row[4], strlen( row[4] ) ) );
		if( strcmp( row[2], "PRIMARY" ) == 0 )
			av_push( av, newSViv( 1 ) );
		else if( row[1][0] == '0' )
			av_push( av, newSViv( 2 ) );
		else
			av_push( av, newSViv( 3 ) );
		XPUSHs( sv_2mortal( newRV( (SV *) av ) ) );
	}
	mysql_free_result( res );
error:
	{}


#/******************************************************************************
# * sql_limit( sql, length, limit [, offset] )
# ******************************************************************************/

char *
sql_limit( sql, length, limit, offset = -1 )
    const char *sql;
    unsigned long length;
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
			New( 1, res, fc - sql + 22, char );
			rp = my_strncpy( res, sql, (DWORD) (fc - sql) );
		}
		else {
			New( 1, res, length + 22, char );
			rp = my_strncpy( res, sql, length );
		}
		if( offset >= 0 )
			sprintf( rp, " LIMIT %li, %li", offset, limit );
		else
			sprintf( rp, " LIMIT %li", limit );
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
# * errno( [linkid] )
# ******************************************************************************/

UV
errno( linkid = 0 )
	void * linkid;
PREINIT:
	dMY_CXT;
CODE:
	RETVAL = ( linkid = my_verify_linkid_noerror( &MY_CXT, linkid ) )
		? mysql_errno( ( (MY_CON *) linkid )->conid )
		: MY_CXT.lasterrno
	;
OUTPUT:
	RETVAL


#/*****************************************************************************
# * error( [linkid] )
# *****************************************************************************/

void
error( linkid = 0 )
	void * linkid;
PREINIT:
	dMY_CXT;
	MY_CON *con;
	const char *error;
CODE:
	con = (MY_CON *) my_verify_linkid_noerror( &MY_CXT, linkid );
	if( con != NULL ) {
		error = mysql_error( con->conid );
		if( error[0] == '\0' ) error = con->my_error;
	}
	else {
		error = MY_CXT.lasterror;
	}
	if( error && error[0] != '\0' )
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
	if( MY_CXT.con )
		my_mysql_cleanup( &MY_CXT );
#ifdef USE_THREADS
	//MUTEX_DESTROY( &MY_CXT.thread_lock );
#endif


#/******************************************************************************
# * _session_cleanup();
# ******************************************************************************/

void
_session_cleanup()
PREINIT:
	dMY_CXT;
CODE:
	my_mysql_cleanup_connections( &MY_CXT );
