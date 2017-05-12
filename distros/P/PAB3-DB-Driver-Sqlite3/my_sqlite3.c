#include "my_sqlite3.h"

struct st_refbuf {
	struct st_refbuf *prev, *next;
};

void _refbuf_add( struct st_refbuf *rbs, struct st_refbuf *rbd );
void _refbuf_rem( struct st_refbuf *rb );

#define refbuf_add(rbs,rbd)     _refbuf_add( (struct st_refbuf *) (rbs), (struct st_refbuf *) (rbd) )
#define refbuf_rem(rb)          _refbuf_rem( (struct st_refbuf *) (rb) )


void my_init( my_cxt_t *cxt ) {
	cxt->firstcon = cxt->lastcon = NULL;
	cxt->last_errno = 0;
	cxt->last_error[0] = '\0';
}

void my_cleanup( my_cxt_t *cxt ) {
	MY_CON *c1, *c2;
	c1 = cxt->firstcon;
	while( c1 ) {
		c2 = c1->next;
		my_con_free( c1 );
		c1 = c2;
	}
	cxt->firstcon = cxt->lastcon = NULL;
}

void my_session_cleanup( my_cxt_t *cxt ) {
	MY_CON *c1 = cxt->firstcon;
	while( c1 ) {
		my_con_cleanup( c1 );
		c1 = c1->next;
	}
}

void my_set_error( my_cxt_t *cxt, const char *tpl, ... ) {
	va_list ap;
	MY_CON *con = my_con_find_by_tid( cxt, get_current_thread_id() );
	va_start( ap, tpl );
	if( con != NULL )
		vsprintf( con->my_error, tpl, ap );
	else
		vsprintf( cxt->last_error, tpl, ap );
	va_end( ap );
}

UPTR my_verify_linkid( my_cxt_t *cxt, UPTR linkid ) {
	if( linkid ) {
		return my_con_exists( cxt, (MY_CON *) linkid ) ? linkid : 0;
	}
#ifdef USE_THREADS
	else {
		if( ( linkid = (UPTR) my_con_find_by_tid( cxt, get_current_thread_id() ) ) )
			return linkid;
		return 0;
	}
#endif
	return cxt->lastcon ? (UPTR) cxt->lastcon : 0;
}

int my_get_type( my_cxt_t *cxt, UPTR *ptr ) {
	dMY_CXT;
	MY_STMT *s1;
	MY_CON *c1;
	MY_RES *r1;
	if( ! *ptr ) {
		*ptr = my_verify_linkid( cxt, *ptr );
		return *ptr != 0 ? MY_TYPE_CON : 0;
	}
	for( c1 = cxt->firstcon; c1 != NULL; c1 = c1->next ) {
		if( (UPTR) c1 == *ptr ) return MY_TYPE_CON;
		for( r1 = c1->firstres; r1 != NULL; r1 = r1->next )
			if( (UPTR) r1 == *ptr ) return MY_TYPE_RES;
		for( s1 = c1->first_stmt; s1 != NULL; s1 = s1->next )
			if( (UPTR) s1 == *ptr ) return MY_TYPE_STMT;
	}
	my_set_error( cxt, "Unknown link ID 0x%07X", *ptr );
	return 0;
}

MY_CON *my_con_add( my_cxt_t *cxt, sqlite3 *con, DWORD tid ) {
	int i, l;
	MY_CON *rcon;
	Newz( 1, rcon, 1, MY_CON );
	rcon->con = con;
	rcon->tid = tid;
	rcon->my_flags |= MYCF_AUTOCOMMIT;
	if( cxt->firstcon == NULL )
		cxt->firstcon = rcon;
	else
		refbuf_add( cxt->lastcon, rcon );
	cxt->lastcon = rcon;
	return rcon;
}

void my_con_rem( my_cxt_t *cxt, MY_CON *con ) {
	if( con == cxt->firstcon )
		cxt->firstcon = con->next;
	if( con == cxt->lastcon )
		cxt->lastcon = con->next;
	refbuf_rem( con );
	my_con_free( con );
}

void my_con_free( MY_CON *con ) {
	my_con_cleanup( con );
	sqlite3_close( con->con );
	Safefree( con->db );
	Safefree( con );
}

int my_con_exists( my_cxt_t *cxt, MY_CON *con ) {
	MY_CON *c1 = cxt->firstcon;
	while( c1 ) {
		if( c1 == con ) return 1;
		c1 = c1->next;
	}
	return 0;
}

MY_CON *my_con_find_by_tid( my_cxt_t *cxt, DWORD tid ) {
	MY_CON *c1, *c2 = NULL;
	c1 = cxt->firstcon;
	while( c1 ) {
		if( c1->tid == tid ) return c1;
		c1 = c1->next;
	}
	return c2;
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

int my_callback( void *arg, int columns, char **data, char **names ) {
	MY_RES *res = (MY_RES *) arg;
	int i, l;
	MY_ROWS *row;
	New( 1, row, 1, MY_ROWS );
	if( ! res->numrows ) {
		MY_FIELD *fields;
		New( 1, fields, columns, MY_FIELD );
		for( i = 0; i < columns; i ++ ) {
			l = strlen( names[i] );
			New( 1, fields[i].name, l + 1, char );
			Copy( names[i], fields[i].name, l + 1, char );
			fields[i].name_length = l;
		}
		res->numfields = columns;
		res->fields = fields;
		row->prev = row->next = NULL;
		res->data_cursor = row;
		res->current_row = row;
		res->is_valid = 1;
	}
	else {
		res->current_row->next = row;
		row->prev = res->current_row;
		row->next = NULL;
		res->current_row = row;
	}
	l = 0;
	New( 1, row->data, columns, char* );
	New( 1, row->lengths, columns, DWORD );
	New( 1, row->types, columns, char );
	for( i = 0; i < columns; i ++ ) {
		if( data[i] ) {
			l = strlen( data[i] );
			New( 1, row->data[i], l + 1, char );
			Copy( data[i], row->data[i], l + 1, char );
			row->lengths[i] = l;
			row->types[i] = SQLITE_TEXT;
		}
		else {
			row->data[i] = NULL;
			row->lengths[i] = 0;
			row->types[i] = SQLITE_NULL;
		}
	}
	res->numrows ++;
	return 0;
}

void my_result_free( MY_RES *res ) {
	int i;
	MY_ROWS *row, *nrow;
	if( ! res ) return;
	for( i = 0; i < res->numfields; i ++ ) Safefree( res->fields[i].name );
	Safefree( res->fields );
	row = res->data_cursor;
	while( row ) {
		for( i = 0; i < res->numfields; i ++ ) Safefree( row->data[i] );
		Safefree( row->data );
		Safefree( row->lengths );
		if( row->types != NULL )
			Safefree( row->types );
		nrow = row->next;
		Safefree( row );
		row = nrow;
	}
	if( res->stmt != NULL )
		res->stmt->res = NULL;
	Safefree( res );
}

MY_RES *my_result_add( MY_CON *con ) {
	MY_RES *res;
	Newz( 1, res, 1, MY_RES );
	res->con = con;
	if( con->firstres == NULL )
		con->firstres = res;
	else
		refbuf_add( con->lastres, res );
	con->lastres = res;
	return res;
}

void my_result_rem( MY_RES *res ) {
	MY_CON *con = res->con;
	if( con->firstres == res )
		con->firstres = res->next;
	if( con->lastres == res )
		con->lastres = res->prev;
	refbuf_rem( res );
	my_result_free( res );
}

int my_result_exists( my_cxt_t *cxt, MY_RES *res ) {
	MY_CON *c1;
	MY_RES *r1;
	if( ! res ) return 0;
	for( c1 = cxt->lastcon; c1 != NULL; c1 = c1->prev ) {
		for( r1 = c1->lastres; r1 != NULL; r1 = r1->prev ) {
			if( r1 == res ) return MY_TYPE_RES;
		}
	}
	return 0;
}

MY_STMT *my_stmt_add( MY_CON *con, sqlite3_stmt *pStmt ) {
	MY_STMT *stmt;
	Newz( 1, stmt, 1, MY_STMT );
	stmt->stmt = pStmt;
	stmt->con = con;
	stmt->param_count = sqlite3_bind_parameter_count( pStmt );
	if( stmt->param_count > 0 )
		New( 1, stmt->param_types, stmt->param_count, char );
	if( con->first_stmt == NULL )
		con->first_stmt = stmt;
	else
		refbuf_add( con->last_stmt, stmt );
	con->last_stmt = stmt;
	return stmt;
}

void my_stmt_rem( MY_STMT *stmt ) {
	MY_CON *con;
	if( stmt == NULL ) return;
	con = stmt->con;
	if( con->first_stmt == stmt )
		con->first_stmt = stmt->next;
	if( con->last_stmt == stmt )
		con->last_stmt = stmt->prev;
	refbuf_rem( stmt );
	my_stmt_free( stmt );
}

void my_stmt_free( MY_STMT *stmt ) {
	if( stmt == NULL ) return;
	sqlite3_finalize( stmt->stmt );
	if( stmt->res != NULL ) {
		if( stmt->res->is_valid == 2 )
			my_result_rem( stmt->res );
		else
			stmt->res->stmt = NULL;
	}
	Safefree( stmt->param_types );
	Safefree( stmt );
}

int my_stmt_exists( my_cxt_t *cxt, UPTR ptr ) {
	MY_CON *con;
	MY_STMT *stmt;
	for( con = cxt->lastcon; con != NULL; con = con->prev ) {
		for( stmt = con->last_stmt; stmt != NULL; stmt = stmt->prev ) {
			if( (UPTR) stmt == ptr ) return MY_TYPE_STMT;
		}
	}
	return 0;
}

int my_stmt_or_res( my_cxt_t *cxt, UPTR ptr ) {
	MY_CON *con;
	MY_STMT *stmt;
	MY_RES *res;
	for( con = cxt->lastcon; con != NULL; con = con->prev ) {
		for( res = con->lastres; res != NULL; res = res->prev )
			if( (UPTR) res == ptr ) return MY_TYPE_RES;
		for( stmt = con->last_stmt; stmt != NULL; stmt = stmt->prev )
			if( (UPTR) stmt == ptr ) return MY_TYPE_STMT;
	}
	return 0;
}

int my_stmt_or_con( my_cxt_t *cxt, UPTR *ptr ) {
	MY_CON *con;
	MY_STMT *stmt;
	if( *ptr == 0 ) {
		*ptr = my_verify_linkid( cxt, *ptr );
		return *ptr != 0 ? MY_TYPE_CON : 0;
	}
	for( con = cxt->lastcon; con != NULL; con = con->prev ) {
		if( (UPTR) con == *ptr ) return MY_TYPE_CON;
		for( stmt = con->last_stmt; stmt != NULL; stmt = stmt->prev )
			if( (UPTR) stmt == *ptr ) return MY_TYPE_STMT;
	}
	return 0;
}

int my_stmt_bind_param( MY_STMT *stmt, int p_num, SV *val, char type ) {
	STRLEN svlen;
	if( stmt->stmt == NULL ) return 0;
	if( p_num == 0 || stmt->param_count < p_num ) {
		sprintf( stmt->con->my_error,
			"Parameter %lu is not in range (%lu)",
			p_num, stmt->param_count
		);
		return SQLITE_RANGE;
	}
	if( type != 0 )
		stmt->param_types[p_num - 1] = type;
	if( ! SvOK( val ) ) {
		return sqlite3_bind_null( stmt->stmt, p_num );
	}
	switch( stmt->param_types[p_num - 1] ) {
	case 'i':
		return sqlite3_bind_int( stmt->stmt, p_num, SvIV( val ) );
	case 'd':
		return sqlite3_bind_double( stmt->stmt, p_num, SvNV( val ) );
	case 's':
		svlen = SvLEN( val );
		return sqlite3_bind_text(
			stmt->stmt, p_num, SvPVx( val, svlen ), svlen, SQLITE_TRANSIENT
		);
	case 'b':
		svlen = SvLEN( val );
		return sqlite3_bind_blob(
			stmt->stmt, p_num, SvPVbytex( val, svlen ), svlen, SQLITE_TRANSIENT
		);
	}
	if( SvIOK( val ) )
		return sqlite3_bind_int( stmt->stmt, p_num, SvIV( val ) );
	else if( SvNOK( val ) )
		return sqlite3_bind_double( stmt->stmt, p_num, SvNV( val ) );
	svlen = SvLEN( val );
	return sqlite3_bind_text(
		stmt->stmt, p_num, SvPVx( val, svlen ), svlen, SQLITE_TRANSIENT
	);
}

unsigned long get_current_thread_id() {
#ifdef USE_THREADS
#ifdef _WIN32
	return GetCurrentThreadId();
#else
	return (unsigned long) pthread_self();
#endif
#else
	return 0;
#endif
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

char *my_itoa( char *str, long value, int radix ) {
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

char *my_ltoa( char *str, XLONG value, int radix ) {
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
