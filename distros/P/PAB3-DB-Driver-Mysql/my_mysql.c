#include <errmsg.h>

#ifdef USE_THREADS
#ifdef WIN32
#include <windows.h>
#else
#include <pthread.h>
#endif
#endif

#include "my_mysql.h"


struct st_refbuf {
	struct st_refbuf *prev, *next;
};

#define refbuf_add(rbs,rbd)     _refbuf_add( (struct st_refbuf *) (rbs), (struct st_refbuf *) (rbd) )
#define refbuf_rem(rb)          _refbuf_rem( (struct st_refbuf *) (rb) )

void _refbuf_add( struct st_refbuf *rbs, struct st_refbuf *rbd );
void _refbuf_rem( struct st_refbuf *rb );


void my_set_error( my_cxt_t *cxt, const char *tpl, ... ) {
	va_list ap;
	MY_CON *con = my_mysql_con_find_by_tid( cxt, get_current_thread_id() );
	va_start( ap, tpl );
	if( con != NULL )
		vsprintf( con->my_error, tpl, ap );
	else
		vsprintf( cxt->lasterror, tpl, ap );
	va_end( ap );
}

UPTR _my_verify_linkid( my_cxt_t *cxt, UPTR linkid, int error ) {
	if( linkid ) {
		return my_mysql_con_exists( cxt, (MY_CON *) linkid ) ? (UPTR) linkid : 0;
	}
#ifdef USE_THREADS
	else {
		linkid = (UPTR) my_mysql_con_find_by_tid( cxt, get_current_thread_id() );
		if( linkid )
			return linkid;
		if( error )
			sprintf( cxt->lasterror, "No connection found" );
		return 0;
	}
#endif
	if( ! cxt->lastcon ) {
		if( error )
			sprintf( cxt->lasterror, "No connection found" );
		return 0;
	}
	return (UPTR) cxt->lastcon;
}

int my_mysql_get_type( my_cxt_t *cxt, UPTR *ptr ) {
	MY_STMT *s1;
	MY_CON *c1;
	MY_RES *r1;
	if( ! *ptr ) {
		*ptr = my_verify_linkid( cxt, *ptr );
		return *ptr != 0 ? 3 : 0;
	}
	for( c1 = cxt->con; c1 != NULL; c1 = c1->next ) {
		if( (UPTR) c1 == *ptr ) return MY_TYPE_CON;
		for( r1 = c1->res; r1 != NULL; r1 = r1->next )
			if( (UPTR) r1 == *ptr ) return MY_TYPE_RES;
		for( s1 = c1->first_stmt; s1 != NULL; s1 = s1->next )
			if( (UPTR) s1 == *ptr ) return MY_TYPE_STMT;
	}
	my_set_error( cxt, "Unknown link ID 0x%07X", *ptr );
	return 0;
}

void my_mysql_cleanup( my_cxt_t *cxt ) {
	MY_CON *c1, *c2;
	c1 = cxt->con;
	while( c1 ) {
		c2 = c1->next;
		my_mysql_con_free( c1 );
		c1 = c2;
	}
	cxt->lastcon = cxt->con = 0;
	//Safefree( cxt->lasterror );
}

void my_mysql_cleanup_connections( my_cxt_t *cxt ) {
	MY_CON *c1;
	c1 = cxt->con;
	while( c1 ) {
		my_mysql_con_cleanup( c1 );
		c1 = c1->next;
	}
}

MY_CON *my_mysql_con_add( my_cxt_t *cxt, MYSQL *mysql, DWORD client_flag ) {
	MY_CON *con;
	Newz( 1, con, 1, MY_CON );
	con->conid = mysql;
	con->tid = get_current_thread_id();
	con->client_flag = client_flag;
	STR_CREATEANDCOPY( mysql->host, con->host );
	STR_CREATEANDCOPY( mysql->user, con->user );
	STR_CREATEANDCOPY( mysql->passwd, con->passwd );
	STR_CREATEANDCOPY( mysql->unix_socket, con->unix_socket );
	STR_CREATEANDCOPY( mysql->db, con->db );
	con->port = mysql->port;
	con->my_flags = MYCF_AUTOCOMMIT;
	if( cxt->con == NULL )
		cxt->con = con;
	else
		refbuf_add( cxt->lastcon, con );
	cxt->lastcon = con;
	return con;
}

void my_mysql_con_free( MY_CON *con ) {
	my_mysql_con_cleanup( con );
	mysql_close( con->conid );
	Safefree( con->charset );
	Safefree( con->host );
	Safefree( con->user );
	Safefree( con->passwd );
	Safefree( con->unix_socket );
	Safefree( con->db );
	Safefree( con->res );
	Safefree( con->conid );
	Safefree( con );
}

void my_mysql_con_rem( my_cxt_t *cxt, MY_CON *con ) {
	if( con == cxt->lastcon )
		cxt->lastcon = con->prev;
	if( con == cxt->con )
		cxt->con = con->next;
	refbuf_rem( con );
	my_mysql_con_free( con );
}

void my_mysql_con_cleanup( MY_CON *con ) {
	MY_RES *r1, *r2;
	MY_STMT *s1, *s2;
	s1 = con->first_stmt;
	while( s1 ) {
		s2 = s1->next;
		my_mysql_stmt_free( s1 );
		s1 = s2;
	}
	con->first_stmt = con->last_stmt = NULL;
	r1 = con->res;
	while( r1 ) {
		r2 = r1->next;
		mysql_free_result( r1->res );
		Safefree( r1 );
		r1 = r2;
	}
	con->res = con->lastres = NULL;
}

int my_mysql_con_exists( my_cxt_t *cxt, MY_CON *con ) {
	MY_CON *c1;
	for( c1 = cxt->con; c1 != NULL; c1 = c1->next )
		if( con == c1 ) return MY_TYPE_CON;
	my_set_error( cxt, "Unknown connection ID 0x%07X", con );
	return 0;
}

MY_CON *my_mysql_con_find_by_tid( my_cxt_t *cxt, DWORD tid ) {
	MY_CON *c1;
	for( c1 = cxt->con; c1 != NULL; c1 = c1->next )
		if( c1->tid == tid ) return c1;
	return NULL;
}

MY_RES *my_mysql_res_add( MY_CON *con, MYSQL_RES *res ) {
	MY_RES *ret;
	Newz( 1, ret, 1, MY_RES );
	ret->res = res;
	ret->con = con;
	ret->numrows = mysql_num_rows( res );
	if( con->res == NULL )
		con->res = ret;
	else
		refbuf_add( con->lastres, ret );
	con->lastres = ret;
	return ret;
}

void my_mysql_res_rem( MY_RES *res ) {
	MY_CON *con;
	if( res == NULL ) return;
//	printf( "mysql free result 0x%07X\n", res );
	mysql_free_result( res->res );
	con = res->con;
	if( con->lastres == res )
		con->lastres = res->prev;
	if( con->res == res )
		con->res = res->next;
	refbuf_rem( res );
	Safefree( res );
}

int my_mysql_res_exists( my_cxt_t *cxt, MY_RES *res ) {
	MY_RES *r1;
	MY_CON *c1;
	if( res != NULL ) {
		for( c1 = cxt->con; c1 != NULL; c1 = c1->next ) {
			for( r1 = c1->res; r1 != NULL; r1 = r1->next )
				if( r1 == res ) return 1;
		}
	}
	my_set_error( cxt, "Unknown result ID 0x%07X", res );
	return 0;
}

int my_mysql_reconnect( MY_CON *con ) {
	MYSQL *res;
	my_mysql_con_cleanup( con );
	mysql_close( con->conid );
	res = mysql_real_connect(
		con->conid,
		con->host, con->user, con->passwd, con->db, con->port,
		con->unix_socket, ( con->client_flag ^ CLIENT_RECONNECT )
	);
	if( ! res ) return 0;
	if( con->charset != 0 ) {
		char *sql, *p1;
		New( 1, sql, 13 + con->charset_length, char );
		p1 = my_strcpy( sql, "SET NAMES '" );
		p1 = my_strcpy( p1, con->charset );
		p1 = my_strcpy( p1, "'" );
		mysql_real_query( con->conid, sql, 12 + con->charset_length );
		Safefree( sql );
	}
	return res != NULL;
}

MY_STMT *my_mysql_stmt_init( MY_CON *con, const char *query, size_t length ) {
	MY_STMT *stmt;
	int hr;
	Newz( 1, stmt, 1, MY_STMT );
	if( stmt == NULL ) return NULL;
	stmt->stmt = mysql_stmt_init( con->conid );
	hr = mysql_stmt_prepare( stmt->stmt, query, (DWORD) length ); 
	if( hr != 0 ) {
		Safefree( stmt );
		return NULL;
	}
	if( con->first_stmt == NULL )
		con->first_stmt = stmt;
	else
		refbuf_add( con->last_stmt, stmt );
	con->last_stmt = stmt;
	stmt->con = con;
	stmt->param_count = mysql_stmt_param_count( stmt->stmt );
	if( stmt->param_count > 0 ) {
		Newz( 1, stmt->params, stmt->param_count, MYSQL_BIND );
		Newz( 1, stmt->param_types, stmt->param_count, char );
	}
	return stmt;
}

void my_mysql_stmt_free( MY_STMT *stmt ) {
	DWORD i;
	if( stmt == NULL ) return;
	if( stmt->meta != NULL ) {
		mysql_free_result( stmt->meta );
		stmt->meta = NULL;
	}
	if( stmt->stmt != NULL ) {
		mysql_stmt_close( stmt->stmt );
		stmt->stmt = NULL;
	}
	for( i = 0; i < stmt->param_count; i ++ ) {
		my_mysql_bind_free( &stmt->params[i] );
	}
	for( i = 0; i < stmt->field_count; i ++ ) {
		my_mysql_bind_free( &stmt->result[i] );
	}
	Safefree( stmt->params );
	Safefree( stmt->param_types );
	Safefree( stmt->result );
	Safefree( stmt );
}

void my_mysql_stmt_rem( MY_STMT *stmt ) {
	MY_CON *con;
	if( stmt == NULL ) return;
	con = stmt->con;
	if( con->first_stmt == stmt )
		con->first_stmt = stmt->next;
	if( con->last_stmt == stmt )
		con->last_stmt = stmt->prev;
	refbuf_rem( stmt );
	my_mysql_stmt_free( stmt );
}

int my_mysql_stmt_exists( my_cxt_t *cxt, MY_STMT *stmt ) {
	MY_STMT *s1;
	MY_CON *c1;
	if( stmt != NULL ) {
		for( c1 = cxt->con; c1 != NULL; c1 = c1->next ) {
			for( s1 = c1->first_stmt; s1 != NULL; s1 = s1->next )
				if( s1 == stmt ) return MY_TYPE_STMT;
		}
	}
	my_set_error( cxt, "Unknown statement ID 0x%07X", stmt );
	return 0;
}

int my_mysql_stmt_or_res( my_cxt_t *cxt, UPTR ptr ) {
	MY_RES *r1;
	MY_STMT *s1;
	MY_CON *c1;
	if( ptr != 0 ) {
		for( c1 = cxt->con; c1 != NULL; c1 = c1->next ) {
			for( r1 = c1->res; r1 != NULL; r1 = r1->next )
				if( (UPTR) r1 == ptr ) return MY_TYPE_RES;
			for( s1 = c1->first_stmt; s1 != NULL; s1 = s1->next )
				if( (UPTR) s1 == ptr ) return MY_TYPE_STMT;
		}
	}
	my_set_error( cxt, "Unknown result or statement ID 0x%07X", ptr );
	return 0;
}

int my_mysql_stmt_or_con( my_cxt_t *cxt, UPTR *ptr ) {
	MY_STMT *s1;
	MY_CON *c1;
	if( ! *ptr ) {
		*ptr = my_verify_linkid( cxt, *ptr );
		return *ptr != 0 ? 3 : 0;
	}
	for( c1 = cxt->con; c1 != NULL; c1 = c1->next ) {
		if( (UPTR) c1 == *ptr ) return MY_TYPE_CON;
		for( s1 = c1->first_stmt; s1 != NULL; s1 = s1->next )
			if( (UPTR) s1 == *ptr ) return MY_TYPE_STMT;
	}
	my_set_error( cxt, "Unknown statement or connection ID 0x%07X", *ptr );
	return 0;
}

int my_mysql_bind_param( MY_STMT *stmt, DWORD p_num, SV *val, char type ) {
	MYSQL_BIND *bind;
	STRLEN svlen;
	char *p1;
	if( stmt->stmt == NULL ) return 0;
	if( p_num == 0 || stmt->param_count < p_num ) {
		sprintf( stmt->con->my_error,
			"Parameter %lu out of range (%lu)",
			p_num, stmt->param_count
		);
		return 0;
	}
	if( type != 0 )
		stmt->param_types[p_num - 1] = type;
	bind = &stmt->params[p_num - 1];
	if( ! SvOK( val ) ) {
		bind->buffer_type = MYSQL_TYPE_NULL;
		return 1;
	}
	switch( stmt->param_types[p_num - 1] ) {
	case 'i':
		bind->buffer_type = MYSQL_TYPE_LONG;
		Renew( bind->buffer, 1, int );
		if( SvIOK_UV( val ) ) {
			bind->is_unsigned = 1;
			*((int *) bind->buffer) = (int) SvUV( val );
		}
		else {
			bind->is_unsigned = 0;
			*((int *) bind->buffer) = (int) SvIV( val );
		}
		return 1;
	case 'd':
		bind->buffer_type = MYSQL_TYPE_DOUBLE;
		Renew( bind->buffer, 1, double );
		*((double *) bind->buffer) = SvNV( val );
		return 1;
	case 's':
		bind->buffer_type = MYSQL_TYPE_STRING;
		svlen = SvLEN( val );
		Renew( bind->buffer, svlen + 1, char );
		p1 = SvPV( val, svlen );
		Copy( p1, bind->buffer, svlen + 1, char );
		Renew( bind->length, 1, unsigned long );
		*bind->length = (unsigned long) svlen;
		return 1;
	case 'b':
		bind->buffer_type = MYSQL_TYPE_BLOB;
		svlen = SvLEN( val );
		Renew( bind->buffer, svlen, char );
		p1 = SvPVbyte( val, svlen );
		Copy( p1, bind->buffer, svlen, char );
		Renew( bind->length, 1, unsigned long );
		*bind->length = (unsigned long) svlen;
		return 1;
	}
	// autodetect type
	if( SvIOK( val ) ) {
		bind->buffer_type = MYSQL_TYPE_LONG;
		Renew( bind->buffer, 1, int );
		if( SvIOK_UV( val ) ) {
			bind->is_unsigned = 1;
			*((int *) bind->buffer) = (int) SvUV( val );
		}
		else {
			bind->is_unsigned = 0;
			*((int *) bind->buffer) = (int) SvIV( val );
		}
	}
	else if( SvNOK( val ) ) {
		bind->buffer_type = MYSQL_TYPE_DOUBLE;
		Renew( bind->buffer, 1, double );
		*((double *) bind->buffer) = SvNV( val );
	}
	else {
		svlen = SvLEN( val );
		bind->buffer_type = MYSQL_TYPE_STRING;
		Renew( bind->buffer, svlen, char );
		p1 = SvPV( val, svlen );
		Copy( p1, bind->buffer, svlen, char );
		Renew( bind->length, 1, unsigned long );
		*bind->length = (unsigned long) svlen;
	}
	return 1;
}

void my_mysql_bind_free( MYSQL_BIND *bind ) {
	if( bind == NULL ) return;
	if( bind->buffer != NULL ) {
		Safefree( bind->buffer );
	}
	if( bind->length != NULL ) {
		Safefree( bind->length );
	}
	if( bind->is_null != NULL ) {
		Safefree( bind->is_null );
	}
	Zero( bind, 1, MYSQL_BIND );
}

int my_mysql_handle_return( MY_CON *con, long ret ) {
	switch( ret ) {
	case 0:
		// all fine
		return 0;
	case 1:
	case CR_SERVER_GONE_ERROR:
	case CR_SERVER_LOST:
		if( ( con->client_flag & CLIENT_RECONNECT ) != 0 ) {
			ret = my_mysql_reconnect( con );
			if( ! ret ) return mysql_errno( con->conid );
		}
		return 0;
	}
	return ret;
}

DWORD get_current_thread_id() {
#ifdef USE_THREADS
#ifdef _WIN32
	return GetCurrentThreadId();
#else
	return (DWORD) pthread_self();
#endif
#else
	return 0;
#endif
}

void _refbuf_add( struct st_refbuf *rbs, struct st_refbuf *rbd ) {
	while( rbs ) {
		if( rbs->next == NULL ) {
			rbs->next = rbd;
			rbd->prev = rbs;
			return;
		}
		rbs = rbs->next;
	}
}

void _refbuf_rem( struct st_refbuf *rb ) {
	if( rb ) {
		struct st_refbuf *rbp = rb->prev;
		struct st_refbuf *rbn = rb->next;
		if( rbp ) {
			rbp->next = rbn;
		}
		if( rbn ) {
			rbn->prev = rbp;
		}
	}
}

/*
#define CRC32_POLYNOMIAL 0xEDB88320

DWORD my_crc32( const char *str, DWORD len ) {
	DWORD idx, bit, data, crc = 0xffffffff;
	for( idx = 0; idx < len; idx ++ ) {
		data = *str ++;
	    for( bit = 0; bit < 8; bit ++, data >>= 1 ) {
			crc = ( crc >> 1 ) ^ ( ( ( crc ^ data ) & 1 ) ? CRC32_POLYNOMIAL : 0 );
		}
	}
	return crc;
}
*/

char *my_strncpy( char *dst, const char *src, size_t len ) {
	register char ch;
	for( ; len > 0; len -- ) {
		if( ( ch = *src ++ ) == '\0' ) {
			*dst = '\0';
			return dst;
		}
		*dst ++ = ch;
	}
	*dst = '\0';
	return dst;
}

char *my_strcpy( char *dst, const char *src ) {
	register char ch;
	while( 1 ) {
		if( (ch = *src ++) == '\0' )
			break;
		*dst ++ = ch;
	}
	*dst = '\0';
	return dst;
}

const char HEX_FROM_CHAR[] = {
	'0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
	'A', 'B', 'C', 'D', 'E', 'F'
};

char *my_itoa( register char *str, long value, int radix ) {
	int rem;
	char tmp[21], *ret = tmp, neg;
	if( value >= 0 )
		neg = 0;
	else {
		value = -value;
		neg = 1;
	}
	switch( radix ) {
	case 16:
		do {
			rem = (int) (value % 16);
			value /= 16;
			*ret ++ = HEX_FROM_CHAR[rem];
		} while( value > 0 );
		break;
	default:
		do {
			*ret ++ = (char) ((value % radix) + '0');
			value /= radix;
		} while( value > 0 );
		if( neg )
			*ret ++ = '-';
	}
	for( ret --; ret >= tmp; *str ++ = *ret -- );
	*str = '\0';
	return str;
}

char *my_ltoa( register char *str, XLONG value, int radix ) {
	int rem;
	char tmp[21], *ret = tmp, neg;
	if( value >= 0 )
		neg = 0;
	else {
		value = -value;
		neg = 1;
	}
	switch( radix ) {
	case 16:
		do {
			rem = (int) (value % 16);
			value /= 16;
			*ret ++ = HEX_FROM_CHAR[rem];
		} while( value > 0 );
		break;
	default:
		do {
			*ret ++ = (char) ((value % radix) + '0');
			value /= radix;
		} while( value > 0 );
		if( neg )
			*ret ++ = '-';
	}
	for( ret --; ret >= tmp; *str ++ = *ret -- );
	*str = '\0';
	return str;
}
