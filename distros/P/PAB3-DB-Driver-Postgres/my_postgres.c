#include "my_postgres.h"

#include <stdlib.h>

struct st_refbuf {
	struct st_refbuf *prev, *next;
};

void _refbuf_add( struct st_refbuf *rbs, struct st_refbuf *rbd );
void _refbuf_rem( struct st_refbuf *rb );

#define refbuf_add(rbs,rbd)     _refbuf_add( (struct st_refbuf *) (rbs), (struct st_refbuf *) (rbd) )
#define refbuf_rem(rb)          _refbuf_rem( (struct st_refbuf *) (rb) )


void my_set_error( my_cxt_t *cxt, const char *tpl, ... ) {
	va_list ap;
	MY_CON *con = my_con_find_by_tid( cxt, get_current_thread_id() );
	va_start( ap, tpl );
	if( con != NULL )
		vsprintf( con->my_error, tpl, ap );
	else
		vsprintf( cxt->lasterror, tpl, ap );
	va_end( ap );
}

void my_cleanup( my_cxt_t *cxt ) {
	MY_CON *c1, *c2;
	c1 = cxt->firstcon;
	while( c1 != NULL ) {
		c2 = c1->next;
		my_con_free( c1 );
		c1 = c2;
	}
	cxt->firstcon = cxt->lastcon = NULL;
}

void my_cleanup_session( my_cxt_t *cxt ) {
	MY_CON *c1;
	for( c1 = cxt->firstcon; c1 != NULL; c1 = c1->next ) {
		my_con_cleanup( c1 );
	}
}

int my_get_type( my_cxt_t *cxt, UPTR *ptr ) {
	MY_STMT *s1;
	MY_CON *c1;
	MY_RES *r1;
	void *pp;
	if( ! *ptr ) {
		*ptr = (UPTR) my_con_verify( cxt, *ptr );
		return *ptr != 0 ? MY_TYPE_CON : 0;
	}
	pp = (void *) *ptr;
	for( c1 = cxt->firstcon; c1 != NULL; c1 = c1->next ) {
		if( c1 == pp ) return MY_TYPE_CON;
		for( r1 = c1->firstres; r1 != NULL; r1 = r1->next )
			if( r1 == pp ) return MY_TYPE_RES;
		for( s1 = c1->first_stmt; s1 != NULL; s1 = s1->next )
			if( s1 == pp ) return MY_TYPE_STMT;
	}
	my_set_error( cxt, "Unknown link ID 0x%07X", *ptr );
	return 0;
}

MY_CON *my_con_add( my_cxt_t *cxt, PGconn *conn ) {
	MY_CON *con;
	Newz( 1, con, 1, MY_CON );
	con->con = conn;
	con->tid = get_current_thread_id();
	if( cxt->firstcon == NULL )
		cxt->firstcon = con;
	else
		refbuf_add( cxt->lastcon, con );
	cxt->lastcon = con;
	return con;
}

void my_con_cleanup( MY_CON *con ) {
	MY_RES *r1, *r2;
	MY_STMT *s1, *s2;
	r1 = con->firstres;
	while( r1 ) {
		r2 = r1->next;
		my_result_free( r1 );
		r1 = r2;
	}
	con->firstres = con->lastres = NULL;
	s1 = con->first_stmt;
	while( s1 ) {
		s2 = s1->next;
		my_stmt_free( s1 );
		s1 = s2;
	}
	con->first_stmt = con->last_stmt = NULL;
}

void my_con_free( MY_CON *con ) {
	my_con_cleanup( con );
	PQfinish( con->con );
	Safefree( con->charset );
	Safefree( con );
}

void my_con_rem( my_cxt_t *cxt, MY_CON *con ) {
	if( con == cxt->firstcon )
		cxt->firstcon = con->next;
	if( con == cxt->lastcon )
		cxt->lastcon = con->prev;
	refbuf_rem( con );
	my_con_free( con );
}

int my_con_exists( my_cxt_t *cxt, UPTR ptr ) {
	MY_CON *c1;
	for( c1 = cxt->firstcon; c1 != NULL; c1 = c1->next ) {
		if( (UPTR) c1 == ptr ) return MY_TYPE_CON;
	}
	my_set_error( cxt, "Unknown connection ID 0x%07X", ptr );
	return 0;
}

MY_CON *my_con_find_by_tid( my_cxt_t *cxt, DWORD tid ) {
	MY_CON *c1;
	for( c1 = cxt->firstcon; c1 != NULL; c1 = c1->next ) {
		if( c1->tid == tid ) return c1;
	}
	return NULL;
}

MY_CON *_my_con_verify( my_cxt_t *cxt, UPTR linkid, int error ) {
	if( linkid ) {
		return my_con_exists( cxt, linkid ) ? (MY_CON *) linkid : NULL;
	}
#ifdef USE_THREADS
	else {
		linkid = (UPTR) my_con_find_by_tid( cxt, get_current_thread_id() );
		if( linkid ) return (MY_CON *) linkid;
		if( error )
			sprintf( cxt->lasterror, "No connection found" );
		return NULL;
	}
#endif
	if( cxt->lastcon )
		return cxt->lastcon;
	if( error )
		sprintf( cxt->lasterror, "No connection found" );
	return NULL;
}

MY_RES *my_result_add( MY_CON *con, PGresult *pres ) {
	MY_RES *res;
	Newz( 1, res, 1, MY_RES );
	res->con = con;
	res->res = pres;
	res->numfields = PQnfields( pres );
	res->numrows = PQntuples( pres );
	if( con->firstres == NULL )
		con->firstres = res;
	else
		refbuf_add( con->lastres, res );
	con->lastres = res;
	return res;
}

void my_result_free( MY_RES *res ) {
	PQclear( res->res );
	if( res->stmt != NULL )
		res->stmt->res = NULL;
	Safefree( res );
}

void my_result_rem( MY_RES *res ) {
	MY_CON *con = res->con;
	if( res == con->firstres )
		con->firstres = res->next;
	if( res == con->lastres )
		con->lastres = res->prev;
	refbuf_rem( res );
	my_result_free( res );
}

int my_result_exists( my_cxt_t *cxt, UPTR ptr ) {
	MY_CON *con;
	MY_RES *r1;
	for( con = cxt->lastcon; con != NULL; con = con->prev ) {
		for( r1 = con->lastres; r1 != NULL; r1 = r1->prev ) {
			if( (UPTR) r1 == ptr ) return MY_TYPE_RES;
		}
	}
	my_set_error( cxt, "Unknown result ID 0x%07X", ptr );
	return 0;
}

char *my_stmt_convert( const char *sql, DWORD sqllen, DWORD *plen, DWORD *slen ) {
	const char *p1;	
	char *tmp, *p2, ch;
	DWORD i, ccp = 0, php = 1;	
	int step = 0;
	New( 1, tmp, sqllen * 2, char );
	for( i = 0, p1 = sql, p2 = tmp; i < sqllen; i ++, p1 ++ ) {
		switch( ( ch = *p1 ) ) {
		case '\'':
			if( ccp < i ) {
				if( step == 0 ) {
					step = 1;
					ccp = i + 1;
				}
				else if( step == 1 ) {
					step = 0;
				}
			}
			*p2 ++ = '\'';
			break;
		case '"':
			if( ccp < i ) {
				if( step == 0 ) {
					step = 2;
					ccp = i + 1;
				}
				else if( step == 2 ) {
					step = 0;
				}
			}
			*p2 ++ = '"';
			break;
		case '\\':
			ccp = i + 1;
			*p2 ++ = '\\';
			break;
		case '?':
			if( step == 0 ) {
				// replace ? with $1, $2, $3, ...
				*p2 ++ = '$';
				p2 = my_itoa( p2, php ++, 10 );
			}
			else
				*p2 ++ = '?';
			break;
		default:
			*p2 ++ = ch;
		}
	}
	*p2 = '\0';
	if( plen != NULL ) *plen = php - 1;
	if( slen != NULL ) *slen = p2 - tmp;
	return tmp;
}

MY_STMT *my_stmt_add( MY_CON *con, char *stmtname, DWORD plen ) {
	MY_STMT *stmt;
	Newz( 1, stmt, 1, MY_STMT );
	if( plen > 0 ) {
		Newz( 1, stmt->param_values, plen, char * );
		Newz( 1, stmt->param_lengths, plen, int );
		Newz( 1, stmt->param_formats, plen, int );
		Newz( 1, stmt->param_types, plen, char );
		stmt->param_count = plen;
	}
	stmt->con = con;
	stmt->id = stmtname;
	if( con->first_stmt == NULL )
		con->first_stmt = stmt;
	else
		refbuf_add( con->last_stmt, stmt );
	con->last_stmt = stmt;
	return stmt;
}

void my_stmt_free( MY_STMT *stmt ) {
	int i;
	Safefree( stmt->id );
	Safefree( stmt->param_lengths );
	Safefree( stmt->param_formats );
	for( i = stmt->param_count - 1; i >= 0; i -- )
		Safefree( stmt->param_values[i] );
	Safefree( stmt->param_values );
	Safefree( stmt->param_types );
	if( stmt->res != NULL ) {
		if( stmt->res->bound )
			my_result_rem( stmt->res );
		else
			stmt->res->stmt = NULL;
	}
	Safefree( stmt );
}

void my_stmt_rem( MY_STMT *stmt ) {
	MY_CON *con = stmt->con;
	if( con->first_stmt == stmt )
		con->first_stmt = stmt->next;
	if( con->last_stmt == stmt )
		con->last_stmt = stmt->prev;
	refbuf_rem( stmt );
	my_stmt_free( stmt );
}

int my_stmt_exists( my_cxt_t *cxt, UPTR ptr ) {
	MY_CON *con;
	MY_STMT *s1;
	for( con = cxt->lastcon; con != NULL; con = con->prev ) {
		for( s1 = con->last_stmt; s1 != NULL; s1 = s1->prev )
			if( (UPTR) s1 == ptr ) return MY_TYPE_STMT;
	}
	my_set_error( cxt, "Unknown statement ID 0x%07X", ptr );
	return 0;
}

int my_stmt_or_result( my_cxt_t *cxt, UPTR ptr ) {
	MY_CON *con;
	MY_RES *r1;
	MY_STMT *s1;
	for( con = cxt->lastcon; con != NULL; con = con->prev ) {
		for( r1 = con->lastres; r1 != NULL; r1 = r1->prev )
			if( (UPTR) r1 == ptr ) return MY_TYPE_RES;
		for( s1 = con->last_stmt; s1 != NULL; s1 = s1->prev )
			if( (UPTR) s1 == ptr ) return MY_TYPE_STMT;
	}
	my_set_error( cxt, "Unknown result or statement ID 0x%07X", ptr );
	return 0;
}

int my_stmt_or_con( my_cxt_t *cxt, UPTR *ptr ) {
	MY_CON *con;
	MY_STMT *stmt;
	if( *ptr == 0 ) {
		*ptr = (UPTR) my_con_verify( cxt, *ptr );
		return *ptr != 0 ? MY_TYPE_CON : 0;
	}
	for( con = cxt->lastcon; con != NULL; con = con->prev ) {
		if( (UPTR) con == *ptr ) return MY_TYPE_CON;
		for( stmt = con->last_stmt; stmt != NULL; stmt = stmt->prev )
			if( (UPTR) stmt == *ptr ) return MY_TYPE_STMT;
	}
	my_set_error( cxt, "Unknown statement or connection ID 0x%07X", *ptr );
	return 0;
}

int my_stmt_bind_param( MY_STMT *stmt, DWORD p_num, SV *val, char type ) {
	STRLEN vl;
	DWORD i;
	char *str;
	if( p_num == 0 || stmt->param_count < p_num ) {
		sprintf( stmt->con->my_error,
			"Parameter %lu out of range (%lu)",
			p_num, stmt->param_count
		);
		return 0;
	}
	i = p_num - 1;
	if( type != 0 )
		stmt->param_types[i] = type;
	if( ! SvOK( val ) ) {
		if( stmt->param_values[i] != NULL )
			Safefree( stmt->param_values[i] );
		stmt->param_values[i] = NULL;
		stmt->param_lengths[i] = 0;
		return 1;
	}
	switch( stmt->param_types[i] ) {
	case 'b':
		str = SvPVbytex( val, vl );
		stmt->param_formats[i] = 1; // set binary
		Renew( stmt->param_values[i], vl, char );
		Copy( str, stmt->param_values[i], vl, char );
		stmt->param_lengths[i] = vl;
		return 1;
	}
	str = SvPVx( val, vl );
	//printf( "bind_param %d [%s]\n", p_num, str );
	Renew( stmt->param_values[i], vl + 1, char );
	Copy( str, stmt->param_values[i], vl, char );
	stmt->param_values[i][vl] = '\0';
	stmt->param_lengths[i] = vl;
	stmt->param_formats[i] = 0; // not binary
	return 1;
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

char *my_strncpy( char *dst, const char *src, DWORD len ) {
	char ch;
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
	char ch;
	while( 1 ) {
		if( ( ch = *src ++ ) == '\0' ) {
			*dst = '\0';
			return dst;
		}
		*dst ++ = ch;
	}
	*dst = '\0';
	return dst;
}

char *my_strcpyl( char *dst, const char *src ) {
	char ch;
	while( 1 ) {
		if( ( ch = *src ++ ) == '\0' ) {
			*dst = '\0';
			return dst;
		}
		*dst ++ = tolower( ch );
	}
	*dst = '\0';
	return dst;
}

int my_stricmp( const char *cs, const char *ct ) {
	register signed char __res;

	while( 1 ) {
		if( ( __res = toupper( *cs ) - toupper( *ct ++ ) ) != 0 || ! *cs ++ )
			break;
	}

	return __res;
}

char *my_stristr( const char *str1, const char *str2 ) {
	char *pptr, *sptr, *start;

	for( start = (char *) str1; *start != '\0'; start ++ ) {
		/* find start of pattern in string */
		for ( ; ( ( *start != '\0' ) && ( toupper( *start ) != toupper( *str2 ) ) ); start ++ )
		;
		if( *start == '\0' ) return NULL;
		
		pptr = (char *) str2;
		sptr = (char *) start;
		
		while( toupper( *sptr ) == toupper( *pptr ) ) {
			sptr ++;
			pptr ++;
		
			/* if end of pattern then pattern was found */
			if( *pptr == '\0' ) return start;
		}
	}
	return NULL;
}

char *my_strtolower( char *a ) {
	char *ret = a;
	while( *a != '\0' ) {
		if( isupper( *a ) ) *a = tolower( *a );
		a ++;
	}
	return ret;
}

char *my_strrev( char *str, size_t len ) {
	char *p1, *p2;
	if( ! str || ! *str ) return str;
	for( p1 = str, p2 = str + len - 1; p2 > p1; ++ p1, -- p2 ) {
		*p1 ^= *p2;
		*p2 ^= *p1;
		*p1 ^= *p2;
	}
	return str;
}

char *my_itoa( char *str, int value, int radix ) {
	int rem;
	char *ret = str;
	switch( radix ) {
	case 16:
		do {
			rem = value % 16;
			value /= 16;
			switch( rem ) {
			case 10:
				*ret ++ = 'A';
				break;
			case 11:
				*ret ++ = 'B';
				break;
			case 12:
				*ret ++ = 'C';
				break;
			case 13:
				*ret ++ = 'D';
				break;
			case 14:
				*ret ++ = 'E';
				break;
			case 15:
				*ret ++ = 'F';
				break;
			default:
				*ret ++ = (char) ( rem + 0x30 );
				break;
			}
		} while( value != 0 );
		break;
	default:
		do {
			rem = value % radix;
			value /= radix;
			*ret ++ = (char) ( rem + 0x30 );
		} while( value != 0 );
	}
	*ret = '\0' ;
	my_strrev( str, ret - str );
	return ret;
}
