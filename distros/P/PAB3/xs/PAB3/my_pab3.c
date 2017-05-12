#include "my_pab3.h"

struct st_refbuf {
	struct st_refbuf *prev, *next;
};

#define refbuf_add(rbs,rbd)     _refbuf_add( (struct st_refbuf *) (rbs), (struct st_refbuf *) (rbd) )
#define refbuf_rem(rb)          _refbuf_rem( (struct st_refbuf *) (rb) )

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

char *my_strncpy( char *dst, const char *src, size_t len ) {
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

char *_my_strcpy( char *dst, const char *src ) {
	char ch;
	while( 1 ) {
		if( ( ch = *src ++ ) == '\0' ) {
			break;
		}
		*dst ++ = ch;
	}
	*dst = '\0';
	return dst;
}

#ifdef DEBUG
char *_my_strcpy_dbg( char *dst, const char *src, const char *file, int line ) {
	_debug( "0x%08x my_strcpy from 0x%08x at %s:%d\n", dst, src, file, line );
	char ch;
	while( 1 ) {
		if( ( ch = *src ++ ) == '\0' ) {
			break;
		}
		*dst ++ = ch;
	}
	*dst = '\0';
	return dst;
}
#endif

char *my_strncpyu( char *dst, const char *src, size_t len ) {
	char ch;
	for( ; len > 0; len -- ) {
		if( ( ch = *src ++ ) == '\0' ) {
			*dst = '\0';
			return dst;
		}
		*dst ++ = toupper( ch );
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

/***********************************************
 * original by cryus imap @ darwin opensource
 ***********************************************/
const char *my_stristr( const char *str, const char *pattern ) {
	const char *pptr, *sptr, *start;
	size_t slen, plen;

	for( start = str,
		pptr  = pattern,
		slen  = strlen( str ),
		plen  = strlen( pattern );
		/* while string length not shorter than pattern length */
		slen >= plen;
		start ++, slen -- )
	{
		/* find start of pattern in string */
		while( toupper( *start ) != toupper( *pattern ) ) {
			start ++;
			slen --;
	
			/* if pattern longer than string */
			if( slen < plen )
				return NULL;
		}
		sptr = start;
		pptr = pattern;
		while( toupper( *sptr ) == toupper( *pptr ) ) {
			sptr ++;
			pptr ++;
			/* if end of pattern then pattern was found */
			if( '\0' == *pptr )
				return start;
		}
	}
	return NULL;
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
	long rem;
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

char *str_replace( out, lout, str, lstr, search, lsch, replace, lrep )
	char **out;
	size_t *lout;
	const char *str;
	size_t lstr;
	const char *search;
	size_t lsch;
	const char *replace;
	size_t lrep;
{
	size_t istr, isch, irep, lmax;
	char *sz = NULL;
	if( str == NULL ) return NULL;
	if( search == NULL || replace == NULL ) {
		if( *out == NULL || *lout < lstr ) {
			Renew( *out, lstr, char );
			*lout = lstr;
		}
		return my_strncpy( *out, str, lstr );
	}
	if( lrep > lsch )
		lmax = ( lstr / lsch + 1 ) * lrep + lrep + 1;
	else
		lmax = lstr + 1;
	if( *out == NULL || *lout < lmax ) {
		Renew( *out, lmax, char );
		*lout = lmax;
	}
	sz = *out;
	isch = 0;
	for( istr = 0; istr < lstr; istr ++ ) {
		if( str[istr] == search[isch] ) {
			if( ++ isch == lsch ) {
				for( irep = 0; irep < lrep; irep ++ )
					*sz ++ = replace[irep];
				isch = 0;
				continue;
			}
		}
		else {
			for( ; isch > 0; isch -- )
				*sz ++ = str[istr - isch];
			*sz ++ = str[istr];
		}
	}
	*sz = '\0';
	return sz;
}

my_thread_var_t *my_thread_var_add( my_cxt_t *cxt, SV *sv ) {
	my_thread_var_t *tv;
	Newx( tv, 1, my_thread_var_t );
	Copy( &THREADVAR_DEFAULT, tv, 1, my_thread_var_t );
	tv->id = sv;
	if( cxt->first_thread == NULL )
		cxt->first_thread = tv;
	else
		refbuf_add( cxt->last_thread, tv );
	cxt->last_thread = tv;
	return tv;
}

void my_thread_var_free( my_thread_var_t *tv ) {
	if( tv->prg_start != THREADVAR_DEFAULT.prg_start )
		Safefree( tv->prg_start );
	if( tv->prg_end != THREADVAR_DEFAULT.prg_end )
		Safefree( tv->prg_end );
	if( tv->cmd_sep != THREADVAR_DEFAULT.cmd_sep )
		Safefree( tv->cmd_sep );
	if( tv->path_cache != THREADVAR_DEFAULT.path_cache )
		Safefree( tv->path_cache );
	if( tv->path_template != THREADVAR_DEFAULT.path_template )
		Safefree( tv->path_template );
	if( tv->class_name != THREADVAR_DEFAULT.class_name )
		Safefree( tv->class_name );
	if( tv->default_record != THREADVAR_DEFAULT.default_record )
		Safefree( tv->default_record );
	my_parser_session_cleanup( tv );
	my_loop_def_cleanup( tv );
	my_hashmap_cleanup( tv );
	Safefree( tv->str1 );
	Safefree( tv );
}

void my_thread_var_rem( my_cxt_t *cxt, my_thread_var_t *tv ) {
	if( tv == cxt->last_thread )
		cxt->last_thread = tv->prev;
	if( tv == cxt->first_thread )
		cxt->first_thread = tv->next;
	refbuf_rem( tv );
	my_thread_var_free( tv );
}

my_thread_var_t *my_thread_var_find( my_cxt_t *cxt, SV *sv ) {
	my_thread_var_t *tv;
	if( ! SvROK( sv ) || ! ( sv = SvRV( sv ) ) ) return NULL;
	for( tv = cxt->last_thread; tv != NULL; tv = tv->prev ) {
		if( tv->id == sv ) return tv;
	}
	return NULL;
}

int my_set_error( my_thread_var_t *tv, const char *tpl, ... ) {
	va_list ap;
	va_start( ap, tpl );
	vsnprintf( tv->last_error, sizeof( tv->last_error ), tpl, ap );
	va_end( ap );
	return 0;
}

#define my_parser_set_error(tv,msg) \
	my_set_error( \
		(tv), "Syntax error: %s (at %s line %d)", (msg), (tv)->parser.file, \
			(tv)->parser.row \
	)

void my_parser_session_cleanup( my_thread_var_t *tv ) {
	my_parser_item_cleanup( tv );
	Safefree( tv->parser.output );
	memset( &tv->parser, 0, sizeof( my_parser_session_t ) );
}

#define my_parser_item_error(tv,pi,msg) \
	my_set_error( \
		(tv), "Syntax error: %s (at %s line %d)", (msg), (tv)->parser.file,\
			(pi)->row \
	)

#define my_parser_error(tv,pi,msg) \
	my_set_error( \
		(tv), "Parser error: %s (at %s line %d)", (msg), (tv)->parser.file,\
			(pi)->row \
	)

void my_parser_item_free( my_parser_item_t *pi ) {
	my_parser_item_t *p1, *p2;
	p1 = pi;
	while( p1 ) {
		p2 = p1->next;
		if( p1->child != NULL )
			my_parser_item_free( p1->child );
		_debug( "destroying item 0x%08X parent 0x%08X\n", p1, p1->parent );
		Safefree( p1->content );
		Safefree( p1->val1 );
		Safefree( p1->val2 );
		Safefree( p1 );
		p1 = p2;
	}
}

my_loop_def_t *my_loop_def_add( my_thread_var_t *tv ) {
	my_loop_def_t *ld;
	Newz( 1, ld, 1, my_loop_def_t );
	if( tv->first_loop == NULL )
		tv->first_loop = ld;
	else
		refbuf_add( tv->last_loop, ld );
	tv->last_loop = ld;
	return ld;
}

void my_loop_def_rem( my_thread_var_t *tv, my_loop_def_t *ld ) {
	if( tv->first_loop == ld )
		tv->first_loop = ld->next;
	if( tv->last_loop == ld )
		tv->last_loop = ld->prev;
	refbuf_rem( ld );
	my_loop_def_free( ld );	
}

void my_loop_def_free( my_loop_def_t *ld ) {
	Safefree( ld->id );
	Safefree( ld->source );
	Safefree( ld->record );
	Safefree( ld->object );
	Safefree( ld->argv );
	Safefree( ld );
}

void my_loop_def_cleanup( my_thread_var_t *tv ) {
	my_loop_def_t *ld1, *ld2;
	ld1 = tv->first_loop;
	while( ld1 != NULL ) {
		ld2 = ld1->next;
		if( ld1->is_fixed < 2 ) {
			my_loop_def_free( ld1 );
		}
		ld1 = ld2;
	}
	tv->first_loop = tv->last_loop = NULL;
}

my_loop_def_t *my_loop_def_find_by_id( my_thread_var_t *tv, const char *id ) {
	my_loop_def_t *ld;
	for( ld = tv->first_loop; ld != NULL; ld = ld->next )
		if( my_stricmp( ld->id, id ) == 0 )
			return ld;
	return NULL;
}

my_hashmap_def_t *my_hashmap_add( my_thread_var_t *tv ) {
	my_hashmap_def_t *hd;
	Newz( 1, hd, 1, my_hashmap_def_t );
	if( tv->first_hm == NULL )
		tv->first_hm = hd;
	else
		refbuf_add( tv->last_hm, hd );
	tv->last_hm = hd;
	return hd;
}

void my_hashmap_rem( my_thread_var_t *tv, my_hashmap_def_t *hd ) {
	if( tv->first_hm == hd )
		tv->first_hm = hd->next;
	if( tv->last_hm == hd )
		tv->last_hm = hd->prev;
	refbuf_rem( hd );
	my_hashmap_free( hd );	
}

void my_hashmap_free( my_hashmap_def_t *hd ) {
	DWORD i;
	Safefree( hd->loopid );
	Safefree( hd->record );
	for( i = 0; i < hd->field_count; i ++ )
		Safefree( hd->fields[i] );
	Safefree( hd->fields );
	Safefree( hd );
}

void my_hashmap_cleanup( my_thread_var_t *tv ) {
	my_hashmap_def_t *hd1, *hd2;
	hd1 = tv->first_hm;
	while( hd1 != NULL ) {
		hd2 = hd1->next;
		my_hashmap_free( hd1 );
		hd1 = hd2;
	}
	tv->first_hm = tv->last_hm = NULL;
}

void my_parser_item_cleanup( my_thread_var_t *tv ) {
	my_parser_item_free( tv->root_item );
	tv->root_item = NULL;
}

void set_var_str( char *str, size_t *str_len, char type ) {
	char *p1, *p2;
	size_t d1;
	switch( type ) {
	case PAB_TYPE_NONE:
		//printf( "none (%d)[%s]\n", *str_len, str );
		for( p1 = str, p2 = str + *str_len; p1 < p2; p1 ++ )
			if( *p1 != '$' && *p1 != '%' && *p1 != '@' && *p1 != '&' )
				break;
		if( p1 == str ) return;
		d1 = p1 - str;
		for( ; p1 < p2; p1 ++ ) *(p1 - d1) = *p1;
		*str_len -= d1;
		str[*str_len] = '\0';
		break;
	case PAB_TYPE_SCALAR:
		if( *str == '$' ) return;
		for( p1 = str + *str_len; p1 > str; p1 -- ) *p1 = *(p1 - 1);
		(*str_len) ++;
		*str = '$';
		str[*str_len] = '\0';
		//_debug( "scalar (%d)[%s]\n", *str_len, str );
		break;
	case PAB_TYPE_ARRAY:
		if( *str == '@' ) return;
		if( *str == '$' ) {
			for( p1 = str + (*str_len) + 1; p1 > str + 1; p1 -- )
				*p1 = *(p1 - 2);
			str[0] = '@';
			str[1] = '{';
			str[(*str_len) + 2] = '}';
			(*str_len) += 3;
			str[*str_len] = '\0';
			//_debug( "array (%d)[%s]\n", *str_len, str );
		}
		else {
			for( p1 = str + *str_len; p1 > str; p1 -- ) *p1 = *(p1 - 1);
			(*str_len) ++;
			*str = '@';
			str[*str_len] = '\0';
		}
		break;
	case PAB_TYPE_HASH:
		if( *str == '%' ) return;
		if( *str == '$' ) {
			for( p1 = str + (*str_len) + 1; p1 > str + 1; p1 -- )
				*p1 = *(p1 - 2);
			str[0] = '%';
			str[1] = '{';
			str[(*str_len) + 2] = '}';
			(*str_len) += 3;
			str[*str_len] = '\0';
			//_debug( "hash (%d)[%s]\n", *str_len, str );
		}
		else {
			for( p1 = str + *str_len; p1 > str; p1 -- ) *p1 = *(p1 - 1);
			(*str_len) ++;
			*str = '%';
			str[*str_len] = '\0';
		}
		break;
	case PAB_TYPE_FUNC:
		if( *str == '&' ) return;
		if( *str == '$' ) {
			for( p1 = str + (*str_len) + 1; p1 > str + 1; p1 -- )
				*p1 = *(p1 - 2);
			str[0] = '&';
			str[1] = '{';
			str[(*str_len) + 2] = '}';
			(*str_len) += 3;
			str[*str_len] = '\0';
			//_debug( "sub (%d)[%s]\n", *str_len, str );
		}
		else {
			for( p1 = str + *str_len; p1 > str; p1 -- ) *p1 = *(p1 - 1);
			(*str_len) ++;
			*str = '&';
			str[*str_len] = '\0';
			//_debug( "sub (%d)[%s]\n", *str_len, str );
		}
		break;
	}
}

void optimize_script( my_thread_var_t *tv, my_parser_item_t *parent ) {
	my_parser_item_t *pi, *pf = NULL, *pi1, *pi2;
	char *buf1 = NULL, *buf2 = NULL, *p1, *p2, *str = NULL, sc = 0;
	size_t lbuf1 = 0, lbuf2 = 0, found = 0, size, str_len = 0, str_pos = 0;

	_debug( "optimize_script parent 0x%08x\n", parent );
	for( pi = parent->child; pi != NULL; pi = pi->next ) {
		_debug( "item type %d\n", pi->id );
		switch( pi->id ) {
		case PARSER_ITEM_TEXT:
			p1 = str_replace( &buf1, &lbuf1, pi->content, pi->content_length,
				"\\", 1, "\\\\", 2 );
			p1 = str_replace( &buf2, &lbuf2, buf1, p1 - buf1,
				"{", 1, "\\{", 2 );
			p1 = str_replace( &buf1, &lbuf1, buf2, p1 - buf2,
				"}", 1, "\\}", 2 );
			p1 = str_replace( &buf2, &lbuf2, buf1, p1 - buf1,
				"$", 1, "\\$", 2 );
			p1 = str_replace( &buf1, &lbuf1, buf2, p1 - buf2,
				"@", 1, "\\@", 2 );
			p1 = str_replace( &buf2, &lbuf2, buf1, p1 - buf1,
				"\n", 1, "\\n", 2 );
			p1 = str_replace( &buf1, &lbuf1, buf2, p1 - buf2,
				"\n__END__\n", 9, "\n\\__END__\n", 10 );
			p1 = str_replace( &buf2, &lbuf2, buf1, p1 - buf1,
				"\n__DATA__\n", 10, "\n\\__DATA__\n", 11 );
			p1 = str_replace( &buf1, &lbuf1, buf2, p1 - buf2,
				"\t", 1, "\\t", 2 );
			p2 = buf1;
			size = p1 - buf1;
			goto item_print;
		case PARSER_ITEM_PRINT:
			p2 = pi->content;
			size = pi->content_length;
item_print:
			_debug( "optimize_script item 0x%08x parent 0x%08x\n", pi, parent );
			found ++;
			if( str_pos + size + 20 > str_len ) {
				str_len = str_pos + size + 256;
				Renew( str, str_len, char );
			}
			if( pf == NULL ) pf = pi;
			if( str_pos > 0 ) {
				if( pi->id == PARSER_ITEM_TEXT ) {
					if( sc ) {
						Copy( ", qq{", &str[str_pos], 5, char );
						str_pos += 5;
						sc = 0;
					}
					else {
						Copy( " . qq{", &str[str_pos], 6, char );
						str_pos += 6;
					}
					Copy( p2, &str[str_pos], size, char );
					str_pos += size;
					str[str_pos ++] = '}';
				}
				else if( strchr( p2, ',' ) == NULL ) {
					if( sc ) {
						Copy( ", ", &str[str_pos], 2, char );
						str_pos += 2;
						sc = 0;
					}
					else {
						Copy( " . ", &str[str_pos], 3, char );
						str_pos += 3;
					}
					Copy( p2, &str[str_pos], size, char );
					str_pos += size;
				}
				else {
					sc = 1;
					Copy( ", ( ", &str[str_pos], 4, char );
					str_pos += 4;
					Copy( p2, &str[str_pos], size, char );
					str_pos += size;
					str[str_pos ++] = ' ';
					str[str_pos ++] = ')';
				}
			}
			else if( pi->id == PARSER_ITEM_TEXT ) {
				Copy( "qq{", &str[str_pos], 3, char );
				str_pos += 3;
				Copy( p2, &str[str_pos], size, char );
				str_pos += size;
				str[str_pos ++] = '}';
			}
			else if( strchr( p2, ',' ) == NULL ) {
				Copy( p2, &str[str_pos], size, char );
				str_pos += size;
			}
			else {
				str[str_pos ++] = '(';
				str[str_pos ++] = ' ';
				Copy( p2, &str[str_pos], size, char );
				str_pos += size;
				str[str_pos ++] = ' ';
				str[str_pos ++] = ')';
				sc = 1;
			}
			break;
		default:
			if( found >= 1 ) {
				str[str_pos] = '\0';
				pf->id = PARSER_ITEM_PRINT;
				pf->content_length = str_pos;
				Renew( pf->content, str_pos + 1, char );
				Copy( str, pf->content, str_pos + 1, char );
				//_debug( "found: (%u) [%s]\n[%s]\n", strlen(str), str, pf->content );
				pi1 = pf->next;
				while( pi1 != pi ) {
					pi2 = pi1->next;
					Safefree( pi1->content );
					Safefree( pi1->val1 );
					Safefree( pi1->val2 );
					Safefree( pi1 );
					pi1 = pi2;
				}
				pf->next = pi;
			}
			found = 0;
			str_pos = 0;
			pf = NULL;
			if( pi->child != NULL )
				optimize_script( tv, pi );
			break;
		}
	}
	if( found >= 1 ) {
		str[str_pos] = '\0';
		pf->id = PARSER_ITEM_PRINT;
		pf->content_length = str_pos;
		Renew( pf->content, str_pos + 1, char );
		Copy( str, pf->content, str_pos + 1, char );
		//_debug( "found: (%u) [%s]\n[%s]\n", strlen(str), str, pf->content );
		pi1 = pf->next;
		while( pi1 != NULL ) {
			pi2 = pi1->next;
			Safefree( pi1->content );
			Safefree( pi1->val1 );
			Safefree( pi1->val2 );
			Safefree( pi1 );
			pi1 = pi2;
		}
		pf->next = NULL;
	}
	Safefree( buf1 );
	Safefree( buf2 );
	Safefree( str );
}

#define OUTPUT_ADD_SIZE 1024

#define OUTPUT_ENSURE(tv,len) \
	if( (DWORD) ((tv)->parser.curout - (tv)->parser.output) + (DWORD) (len) > (tv)->parser.output_length ) { \
		(tv)->parser.output_length += (len) + OUTPUT_ADD_SIZE; \
		(tv)->parser.output_pos = (tv)->parser.curout - (tv)->parser.output; \
		Renew( (tv)->parser.output, (tv)->parser.output_length + 1, char ); \
		(tv)->parser.curout = (tv)->parser.output + (tv)->parser.output_pos; \
	}

int build_script_int( my_thread_var_t *tv, my_parser_item_t *parent, DWORD level ) {
	my_parser_item_t *pi, *pl = NULL;
	char *buf1 = NULL, *buf2 = NULL, *p1, tvar1[20], *sr, *sa, *co;
	size_t lbuf1 = 0, lbuf2 = 0, i, *lr, *la;
	my_loop_def_t *ld;
	
	for( pi = parent->child; pi != NULL; pi = pi->next ) {
		switch( pi->id ) {
		case PARSER_ITEM_TEXT:
			p1 = str_replace( &buf1, &lbuf1,
				pi->content, pi->content_length, "\\", 1, "\\\\", 2 );
			p1 = str_replace( &buf2, &lbuf2, buf1, p1 - buf1,
				"{", 1, "\\{", 2 );
			p1 = str_replace( &buf1, &lbuf1, buf2, p1 - buf2,
				"}", 1, "\\}", 2 );
			p1 = str_replace( &buf2, &lbuf2, buf1, p1 - buf1,
				"$", 1, "\\$", 2 );
			p1 = str_replace( &buf1, &lbuf1, buf2, p1 - buf2,
				"@", 1, "\\@", 2 );
			p1 = str_replace( &buf2, &lbuf2, buf1, p1 - buf1,
				"\n", 1, "\\n", 2 );
			p1 = str_replace( &buf1, &lbuf1, buf2, p1 - buf2,
				"\n__END__\n", 9, "\n\\__END__\n", 10 );
			p1 = str_replace( &buf2, &lbuf2, buf1, p1 - buf1,
				"\n__DATA__\n", 10, "\n\\__DATA__\n", 11 );
			p1 = str_replace( &buf1, &lbuf1, buf2, p1 - buf2,
				"\t", 1, "\\t", 2 );
			OUTPUT_ENSURE( tv, p1 - buf1 + level + 20 );
			for( i = level; i > 0; i -- ) *(tv->parser.curout ++) = '\t';
			tv->parser.curout = my_strcpy( tv->parser.curout, "print qq{" );
			tv->parser.curout = my_strcpy( tv->parser.curout, buf1 );
			tv->parser.curout = my_strcpy( tv->parser.curout, "};\n" );
			break;
		case PARSER_ITEM_PRINT:
			OUTPUT_ENSURE( tv, 10 + pi->content_length + level );
			for( i = level; i > 0; i -- ) *(tv->parser.curout ++) = '\t';
			tv->parser.curout = my_strcpy( tv->parser.curout, "print " );
			tv->parser.curout = my_strcpy( tv->parser.curout, pi->content );
			tv->parser.curout = my_strcpy( tv->parser.curout, ";\n" );
			break;
		case PARSER_ITEM_CON:
			if( pi->next == NULL || pi->next->id < PARSER_ITEM_ELCO
				|| pi->next->id > PARSER_ITEM_ECON )
					return my_parser_item_error(
						tv, pi, "[IF] unclosed condition"
					);
			OUTPUT_ENSURE( tv, 10 + pi->content_length + level );
			for( i = level; i > 0; i -- ) *(tv->parser.curout ++) = '\t';
			tv->parser.curout = my_strcpy( tv->parser.curout, "if( " );
			tv->parser.curout = my_strcpy( tv->parser.curout, pi->content );
			tv->parser.curout = my_strcpy( tv->parser.curout, " ) {\n" );
			if( pi->child != NULL )
				if( ! build_script_int( tv, pi, level + 1 ) ) return 0;
			break;
		case PARSER_ITEM_ELCO:
			if( pi->next == NULL || pi->next->id < PARSER_ITEM_ELCO
				|| pi->next->id > PARSER_ITEM_ECON )
					return my_parser_item_error(
						tv, pi, "[ELSIF] unclosed condition"
					);
			OUTPUT_ENSURE( tv, 20 + pi->content_length + level * 2 );
			for( i = level; i > 0; i -- ) *(tv->parser.curout ++) = '\t';
			tv->parser.curout = my_strcpy( tv->parser.curout, "}\n" );
			for( i = level; i > 0; i -- ) *(tv->parser.curout ++) = '\t';
			tv->parser.curout = my_strcpy( tv->parser.curout, "elsif( " );
			tv->parser.curout = my_strcpy( tv->parser.curout, pi->content );
			tv->parser.curout = my_strcpy( tv->parser.curout, " ) {\n" );
			if( pi->child != NULL )
				if( ! build_script_int( tv, pi, level + 1 ) ) return 0;
			break;
		case PARSER_ITEM_ELSE:
			if( pi->next == NULL || pi->next->id != PARSER_ITEM_ECON )
				return my_parser_item_error(
					tv, pi, "[ELSE] unclosed condition"
				);
			OUTPUT_ENSURE( tv, 20 + level * 2 );
			for( i = level; i > 0; i -- ) *(tv->parser.curout ++) = '\t';
			tv->parser.curout = my_strcpy( tv->parser.curout, "}\n" );
			for( i = level; i > 0; i -- ) *(tv->parser.curout ++) = '\t';
			tv->parser.curout = my_strcpy( tv->parser.curout, "else {\n" );
			if( pi->child != NULL )
				if( ! build_script_int( tv, pi, level + 1 ) ) return 0;
			break;
		case PARSER_ITEM_ECON:
			OUTPUT_ENSURE( tv, 10 + level );
			for( i = level; i > 0; i -- ) *(tv->parser.curout ++) = '\t';
			tv->parser.curout = my_strcpy( tv->parser.curout, "}\n" );
			break;
		case PARSER_ITEM_ELOOP:
			OUTPUT_ENSURE( tv, 10 + level + pi->content_length + pi->len1 );
			for( i = level; i > 0; i -- ) *(tv->parser.curout ++) = '\t';
			if( pi->content != NULL &&
				my_stristr( pi->content, "while" ) == pi->content )
			{
				*(tv->parser.curout ++) = '}';
				*(tv->parser.curout ++) = ' ';
				tv->parser.curout =
					my_strcpy( tv->parser.curout, pi->content );
				if( pi->val1 != NULL ) {
					*(tv->parser.curout ++) = ' ';
					tv->parser.curout =
						my_strcpy( tv->parser.curout, pi->val1 );
				}
				tv->parser.curout = my_strcpy( tv->parser.curout, ";\n" );
			}
			else if( pi->val1 != NULL &&
				my_stristr( pi->val1, "while" ) == pi->val1 )
			{
				*(tv->parser.curout ++) = '}';
				*(tv->parser.curout ++) = ' ';
				tv->parser.curout = my_strcpy( tv->parser.curout, pi->val1 );
				tv->parser.curout = my_strcpy( tv->parser.curout, ";\n" );
			}
			else {
				tv->parser.curout = my_strcpy( tv->parser.curout, "};\n" );
			}
			break;
		case PARSER_ITEM_ESUB:
			OUTPUT_ENSURE( tv, 10 + level );
			for( i = level; i > 0; i -- ) *(tv->parser.curout ++) = '\t';
			tv->parser.curout = my_strcpy( tv->parser.curout, "};\n" );
			break;
		case PARSER_ITEM_DO:
			OUTPUT_ENSURE( tv, 10 + pi->content_length + level );
			for( i = level; i > 0; i -- ) *(tv->parser.curout ++) = '\t';
			tv->parser.curout = my_strcpy( tv->parser.curout, pi->content );
			tv->parser.curout = my_strcpy( tv->parser.curout, ";\n" );
			break;
		case PARSER_ITEM_ASIS:
			OUTPUT_ENSURE( tv, pi->content_length + level );
			for( i = level; i > 0; i -- ) *(tv->parser.curout ++) = '\t';
			tv->parser.curout = my_strcpy( tv->parser.curout, pi->content );
			break;
		case PARSER_ITEM_XX:
			p1 = str_replace( &buf1, &lbuf1, pi->content, pi->content_length,
				"\"", 1, "\\\"", 2 );
			OUTPUT_ENSURE( tv,
				10 + ( p1 - buf1 ) + level + tv->prg_start_length * 2
					+ tv->prg_end_length * 2
			);
			p1 = str_replace(
				&buf2, &lbuf2, tv->prg_start, tv->prg_start_length,
				"\"", 1, "\\\"", 2
			);
			for( i = level; i > 0; i -- ) *(tv->parser.curout ++) = '\t';
			tv->parser.curout = my_strcpy( tv->parser.curout, "print \"" );
			tv->parser.curout = my_strcpy( tv->parser.curout, buf2 );
			*(tv->parser.curout ++) = ' ';
			tv->parser.curout = my_strcpy( tv->parser.curout, buf1 );
			*(tv->parser.curout ++) = ' ';
			p1 = str_replace( &buf2, &lbuf2, tv->prg_end, tv->prg_end_length,
				"\"", 1, "\\\"", 2 );
			tv->parser.curout = my_strcpy( tv->parser.curout, buf2 );
			tv->parser.curout = my_strcpy( tv->parser.curout, "\";\n" );
			break;
		case PARSER_ITEM_LOOP:
			if( pi->next == NULL || pi->next->id != PARSER_ITEM_ELOOP )
				return my_parser_item_error(
					tv, pi, "[LOOP] without [END LOOP]" );
			co = tv->parser.curout;
			if( my_stricmp( pi->content, "ARRAY" ) == 0 ) {
				if( pi->val1 == NULL )
					return my_parser_item_error(
						tv, pi, "[LOOP ARRAY] without array" );
				set_var_str( pi->val1, &pi->len1, PAB_TYPE_ARRAY );
				if( pi->val2 == NULL ) {
					pi->len2 = tv->default_record_length;
					New( 1, pi->val2, pi->len2 + 5, char );
					Copy( tv->default_record, pi->val2, pi->len2 + 1, char );
				}
				set_var_str( pi->val2, &pi->len2, PAB_TYPE_SCALAR );
				OUTPUT_ENSURE( tv, 20 + pi->content_length + level + pi->len2 );
				for( i = level; i > 0; i -- ) *(co ++) = '\t';
				co = my_strcpy( co, "foreach " );
				co = my_strcpy( co, pi->val2 );
				co = my_strcpy( co, "( " );
				co = my_strcpy( co, pi->val1 );
				co = my_strcpy( co, " ) {\n" );
			}
			else if( my_stricmp( pi->content, "HASH" ) == 0 ) {
				if( pi->val1 == NULL )
					return my_parser_item_error(
						tv, pi, "[LOOP HASH] without hash" );
				set_var_str( pi->val1, &pi->len1, PAB_TYPE_HASH );
				if( pi->val2 == NULL ) {
					pi->len2 = tv->default_record_length;
					New( 1, pi->val2, pi->len2 + 5, char );
					Copy( tv->default_record, pi->val2, pi->len2 + 1, char );
				}
				set_var_str( pi->val2, &pi->len2, PAB_TYPE_SCALAR );
				OUTPUT_ENSURE( tv, 20 + pi->content_length + level + pi->len2 );
				for( i = level; i > 0; i -- ) *(co ++) = '\t';
				co = my_strcpy( co, "foreach " );
				co = my_strcpy( co, pi->val2 );
				co = my_strcpy( co, "( keys " );
				co = my_strcpy( co, pi->val1 );
				co = my_strcpy( co, " ) {\n" );
			}
			else if( ( ld = my_loop_def_find_by_id( tv, pi->content ) ) == NULL
				|| ld->source_type == 0 )
			{
				OUTPUT_ENSURE( tv,
					20 + level * 2 + pi->content_length * 2 + pi->len1 * 2
						+ pi->len2
				);
				for( i = level; i > 0; i -- ) *(co ++) = '\t';
				if( strstr( pi->content, "for" ) == pi->content || 
					strstr( pi->content, "while" ) == pi->content ||
					strstr( pi->content, "do" ) == pi->content )
				{
					co = my_strcpy( co, pi->content );
					if( pi->val1 != NULL ) {
						*(co ++) = ' ';
						co = my_strcpy( co, pi->val1 );
					}
				}
				else if( pi->val1 != NULL ) {
					co = my_strcpy( co, "# loop " );
					co = my_strcpy( co, pi->content );
					*(co ++) = '\n';
					for( i = level; i > 0; i -- )
						*(co ++) = '\t';
					co = my_strcpy( co, pi->val1 );
					if( *(co - 1) == '{' ) co --;
				}
				else
					co = my_strcpy( co, pi->content );
				if( pi->val2 != NULL ) {
					*(co ++) = ' ';
					co = my_strcpy( co, pi->val2 );
					if( *(co - 1) == '{' ) co --;
				}
				co = my_strcpy( co, " {\n" );
			}
			else {
				if( pi->val1 == NULL && ld->record == NULL ) {
					pi->len1 = tv->default_record_length;
					New( 1, pi->val1, pi->len1 + 5, char );
					Copy( tv->default_record, pi->val1, pi->len1 + 1, char );
				}
				if( pi->val1 != NULL ) {
					sr = pi->val1;
					lr = &pi->len1;
				}
				else {
					sr = ld->record;
					lr = &ld->record_length;
				}
				if( pi->val2 != NULL ) {
					sa = pi->val2;
					la = &pi->len2;
				}
				else if( ld->argv != NULL ) {
					sa = ld->argv;
					la = &ld->argv_length;
				}
				else {
					sa = NULL, la = NULL;
				}
				OUTPUT_ENSURE( tv,
					100 + level * 3 + pi->content_length + (*lr) * 2 + pi->len2
						+ ld->object_length + ( la != NULL ? (*la) : 0 )
				);
				for( i = level; i > 0; i -- )
					*(co ++) = '\t';
				co = my_strcpy( co, "# loop " );
				co = my_strcpy( co, pi->content );
				*(co ++) = '\n';
				for( i = level; i > 0; i -- ) *(co ++) = '\t';
				switch( ld->source_type ) {
				case PAB_TYPE_ARRAY:
					set_var_str(
						ld->source, &ld->source_length, PAB_TYPE_ARRAY );
					switch( ld->record_type ) {
					case PAB_TYPE_AUTO:
					case PAB_TYPE_SCALAR:
						set_var_str( sr, lr, PAB_TYPE_SCALAR );
						co = my_strcpy( co, "foreach " );
						co = my_strcpy( co, sr );
						co = my_strcpy( co, "( " );
						co = my_strcpy( co, ld->source );
						co = my_strcpy( co, " ) {\n" );
						break;
					case PAB_TYPE_FUNC:
						tv->parser.script_counter ++;
						p1 = my_strcpy( tvar1, "$__RR" );
						p1 = my_itoa( p1, tv->parser.script_counter, 10 );
						p1 = my_strcpy( p1, "__" );
						co = my_strcpy( co, "foreach " );
						co = my_strcpy( co, tvar1 );
						co = my_strcpy( co, "( " );
						co = my_strcpy( co, ld->source );
						co = my_strcpy( co, " ) {\n" );
						for( i = level + 1; i > 0; i -- )
							*(co ++) = '\t';
						if( ld->object != NULL ) {
							co = my_strcpy( co, ld->object );
							co = my_strcpy( co, "->" );
							set_var_str( sr, lr, PAB_TYPE_NONE );
							co = my_strcpy( co, sr );
						}
						else {
							set_var_str( sr, lr, PAB_TYPE_FUNC );
							co = my_strcpy( co, sr );
						}
						co = my_strcpy( co, "( " );
						co = my_strcpy( co, tvar1 );
						if( sa != NULL ) {
							co = my_strcpy( co, ", " );
							co = my_strcpy( co, sa );
						}
						co = my_strcpy( co, " ) or last;\n" );
						break;
					default:
						return my_parser_item_error(
							tv, pi, "[LOOP] unsupported type of record"
						);
					}
					break;
				case PAB_TYPE_HASH:
					set_var_str(
						ld->source, &ld->source_length, PAB_TYPE_HASH );
					switch( ld->record_type ) {
					case PAB_TYPE_AUTO:
					case PAB_TYPE_SCALAR:
						set_var_str( sr, lr, PAB_TYPE_SCALAR );
						co = my_strcpy( co, "foreach " );
						co = my_strcpy( co, sr );
						co = my_strcpy( co, "( keys " );
						co = my_strcpy( co, ld->source );
						co = my_strcpy( co, " ) {\n" );
						break;
					case PAB_TYPE_FUNC:
						tv->parser.script_counter ++;
						p1 = my_strcpy( tvar1, "$__RR" );
						p1 = my_itoa( p1, tv->parser.script_counter, 10 );
						p1 = my_strcpy( p1, "__" );
						co = my_strcpy( co, "foreach " );
						co = my_strcpy( co, tvar1 );
						co = my_strcpy( co, "( keys " );
						co = my_strcpy( co, ld->source );
						co = my_strcpy( co, " ) {\n" );
						for( i = level + 1; i > 0; i -- )
							*(co ++) = '\t';
						if( ld->object != NULL ) {
							co = my_strcpy( co, ld->object );
							co = my_strcpy( co, "->" );
							set_var_str( sr, lr, PAB_TYPE_NONE );
							co = my_strcpy( co, sr );
						}
						else {
							set_var_str( sr, lr, PAB_TYPE_FUNC );
							co = my_strcpy( co, sr );
						}
						co = my_strcpy( co, "( " );
						co = my_strcpy( co, tvar1 );
						if( sa != NULL ) {
							co = my_strcpy( co, ", " );
							co = my_strcpy( co, sa );
						}
						co = my_strcpy( co, " ) or last;\n" );
						break;
					default:
						return my_parser_item_error(
							tv, pi, "[LOOP] unsupported type of record"
						);
					}
					break;
				case PAB_TYPE_FUNC:
					switch( ld->record_type ) {
					case PAB_TYPE_AUTO:
					case PAB_TYPE_SCALAR:
					case PAB_TYPE_HASH:
					case PAB_TYPE_ARRAY:
						// --> while( [$@%]record = [$object->][&]source( $arg ) ) {
						set_var_str( sr, lr,
							PAB_TYPE_AUTO ? PAB_TYPE_SCALAR : ld->record_type );
						co = my_strcpy( co, "while( " );
						co = my_strcpy( co, sr );
						co = my_strcpy( co, " = " );
						if( ld->object != NULL ) {
							co = my_strcpy( co, ld->object );
							co = my_strcpy( co, "->" );
							set_var_str(
								ld->source, &ld->source_length, PAB_TYPE_NONE );
						}
						else {
							set_var_str(
								ld->source, &ld->source_length, PAB_TYPE_FUNC );
						}
						co = my_strcpy( co, ld->source );
						*co ++ = '(';
						if( sa != NULL ) {
							*co ++ = ' ';
							co = my_strcpy( co, sa );
							*co ++ = ' ';
						}
						co = my_strcpy( co, ") ) {\n" );
						break;
					case PAB_TYPE_FUNC:	
						// --> while( $__RR__ = [$object->][&]source( $arg ) ) {
						// --> [$object->][&]record( [ $object, ] $__RR__ );
						tv->parser.script_counter ++;
						p1 = my_strcpy( tvar1, "$__RR" );
						p1 = my_itoa( p1, tv->parser.script_counter, 10 );
						p1 = my_strcpy( p1, "__" );
						co = my_strcpy( co, "while( " );
						co = my_strcpy( co, tvar1 );
						co = my_strcpy( co, " = " );
						if( ld->object != NULL ) {
							co = my_strcpy( co, ld->object );
							co = my_strcpy( co, "->" );
							set_var_str(
								ld->source, &ld->source_length, PAB_TYPE_NONE );
						}
						else {
							set_var_str(
								ld->source, &ld->source_length, PAB_TYPE_FUNC );
						}
						co = my_strcpy( co, ld->source );
						*co ++ = '(';
						if( sa != NULL ) {
							*co ++ = ' ';
							co = my_strcpy( co, sa );
							*co ++ = ' ';
						}
						co = my_strcpy( co, ") ) {\n" );
						for( i = level + 1; i > 0; i -- )
							*(co ++) = '\t';
						if( ld->object != NULL ) {
							co = my_strcpy( co, ld->object );
							co = my_strcpy( co, "->" );
							set_var_str( sr, lr, PAB_TYPE_NONE );
						}
						else {
							set_var_str( sr, lr, PAB_TYPE_FUNC );
						}
						co = my_strcpy( co, sr );
						co = my_strcpy( co, "( " );
						co = my_strcpy( co, tvar1 );
						if( sa != NULL ) {
							co = my_strcpy( co, ", " );
							co = my_strcpy( co, sa );
						}
						co = my_strcpy( co, " );\n" );
						break;
					default:
						return my_parser_item_error( tv, pi,
							"[LOOP] unsupported type of record" );
					}
					break;
				default:
					return my_parser_item_error( tv, pi,
						"[LOOP] unsupported type of source" );
				}
			}
			tv->parser.curout = co;
			if( ! build_script_int( tv, pi, level + 1 ) ) return 0;
			break;
		case PARSER_ITEM_SUB:
			if( pi->next == NULL || pi->next->id != PARSER_ITEM_ESUB )
				return my_parser_item_error( tv, pi,
					"[SUB] without [END SUB]" );
			OUTPUT_ENSURE( tv, 20 + pi->content_length + level );
			for( i = level; i > 0; i -- ) *(tv->parser.curout ++) = '\t';
			tv->parser.curout = my_strcpy( tv->parser.curout, pi->content );
			tv->parser.curout = my_strcpy( tv->parser.curout, " = sub {\n" );
			if( ! build_script_int( tv, pi, level + 1 ) ) return 0;
			break;
		}
		pl = pi;
	}
	Safefree( buf1 );
	Safefree( buf2 );
	return 1;
}

int build_script( my_thread_var_t *tv ) {
	tv->parser.output_length = OUTPUT_ADD_SIZE;
	New( 1, tv->parser.output, tv->parser.output_length + 1, char );
	tv->parser.curout = my_strcpy( tv->parser.output, "{\n" );
	tv->parser.script_counter = 0;
	if( ! build_script_int( tv, tv->root_item, 1 ) ) return 0;
	OUTPUT_ENSURE( tv, 6 );
	tv->parser.curout = my_strcpy( tv->parser.curout, "}\n\n1;\n" );
	_debug( "script:\n%s\n", tv->parser.output );
	return 1;
}

int map_hash(
	my_thread_var_t *tv, my_parser_item_t *parent, my_hashmap_def_t *hd,
	char rtype
) {
	my_parser_item_t *pi;
	char *p1, *p2, *p3, *p4, *pk1, *str = NULL;
	size_t len = 0, pos, resize;
	DWORD i;
	int ret;
	for( pi = parent->child; pi != NULL; pi = pi->next ) {
		if( pi->content == NULL )
			goto mh_next;
		pos = 0;
		p1 = pi->content;
		p4 = p1 + pi->content_length + 1;
		while( (p2 = strstr( p1, hd->record )) != NULL ) {
			resize = MAX(
				MAX( pi->content_length - len, 0 ),
				len - pos + hd->record_length + 20
			);
			if( resize > len ) {
				len += resize + 1024;
				Renew( str, len + 40, char );
			}
			if( p1 < p2 ) {
				Copy( p1, str + pos, p2 - p1, char );
				pos += (p2 - p1);
			}
			p2 += hd->record_length;
			if( rtype == PAB_TYPE_SCALAR || rtype == PAB_TYPE_AUTO ) {
				// $record->{'key'} => $record->[num]
				p3 = p2;
				if( p3 >= p4 || *p3 ++ != '-' ) goto mh_cont1;
				if( p3 >= p4 || *p3 ++ != '>' ) goto mh_cont1;
				if( p3 >= p4 || *p3 ++ != '{' ) goto mh_cont1;
				if( p3 < p4 && (*p3 == '\'' || *p3 == '"') ) p3 ++;
				pk1 = p3;
				for( ; p3 < p4 && *p3 != '\'' && *p3 != '"' && *p3 != '}'; p3 ++ );
				if( p3 == pk1 )
					goto mh_cont1;
				*p3 = '\0';
				if( p3 < p4 && *p3 != '}' )
					p3 ++;
				for( i = 0; i < hd->field_count; i ++ )
					if( strcmp( hd->fields[i], pk1 ) == 0 )
						goto mh_found1;
				sprintf( str, "hashmap field [%s] ist not defined", pk1 );
				my_parser_error( tv, pi, str );
				goto error;
mh_found1:
				Copy( hd->record, &str[pos], hd->record_length, char );
				pos += hd->record_length;
				str[pos ++] = '-';
				str[pos ++] = '>';
				str[pos ++] = '[';
				p2 = my_itoa( &str[pos], i, 10 );
				pos += ( p2 - &str[pos] );
				str[pos ++] = ']';
				p1 = p3 + 1;
				goto mh_cont3;
			}
mh_cont1:
			if( rtype == PAB_TYPE_ARRAY || rtype == PAB_TYPE_AUTO ) {
				// $record{'key'} => $record[num]
				p3 = p2;
				if( p3 >= p4 || *p3 ++ != '{' )
					goto mh_cont2;
				if( p3 < p4 && ( *p3 == '\'' || *p3 == '"' ) )
					p3 ++;
				if( p3 < p4 && ( *p3 == '\'' || *p3 == '"' ) )
					p3 ++;
				pk1 = p3;
				for( ; p3 < p4 && *p3 != '\'' && *p3 != '"' && *p3 != '}'; p3 ++ );
				if( p3 == pk1 )
					goto mh_cont2;
				*p3 = '\0';
				if( p3 < p4 && *p3 != '}' )
					p3 ++;
				for( i = 0; i < hd->field_count; i ++ )
					if( strcmp( hd->fields[i], pk1 ) == 0 )
						goto mh_found2;
				sprintf( str, "hashmap field [%s] ist not defined", pk1 );
				my_parser_error( tv, pi, str );
				goto error;
mh_found2:
				Copy( hd->record, &str[pos], hd->record_length, char );
				pos += hd->record_length;
				str[pos ++] = '[';
				p2 = my_itoa( str + pos, (long) i, 10 );
				pos += (p2 - str + pos);
				str[pos ++] = ']';
				p1 = p3 + 1;
				goto mh_cont3;
			}
mh_cont2:
			p1 = p2;
			Copy( hd->record, &str[pos], hd->record_length, char );
			pos += hd->record_length;
mh_cont3:
			{}
		}
		if( p1 > pi->content ) {
			if( p1 < p4 ) {
				Copy( p1, str + pos, p4 - p1, char );
				pos += (p4 - p1);
			}
			str[pos] = '\0';
			Renew( pi->content, pos + 1, char );
			Copy( str, pi->content, pos + 1, char );
			pi->content_length = pos;
			_debug( "mapped string [%s]\n", pi->content );
		}
mh_next:
		if( pi->child != NULL )
			if( ! map_hash( tv, pi, hd, rtype ) )
				goto error;
	}
	ret = 1;
	goto exit;
error:
	ret = 0;
exit:
	Safefree( str );
	return ret;
}

int map_parsed( my_thread_var_t *tv, my_parser_item_t *parent, int level ) {
	my_parser_item_t *pi;
	my_hashmap_def_t *hd;
	my_loop_def_t *ld;
	if( level == 0 ) {
		// map global hashes
		for( hd = tv->first_hm; hd != NULL; hd = hd->next ) {
			if( hd->loopid == NULL ) {
				if( ! map_hash( tv, parent, hd, PAB_TYPE_SCALAR ) )
					return 0;
			}
		}
	}
	for( pi = parent->child; pi != NULL; pi = pi->next ) {
		if( pi->id == PARSER_ITEM_LOOP ) {
			for( hd = tv->first_hm; hd != NULL; hd = hd->next ) {
				if( hd->loopid == NULL )
					continue;
				if( my_stricmp( hd->loopid, pi->content ) != 0 )
					continue;
				ld = my_loop_def_find_by_id( tv, hd->loopid );
				if( ! map_hash( tv, pi, hd, ld ? ld->record_type : PAB_TYPE_AUTO ) )
					return 0;
			}
		}
		if( pi->child != NULL )
			if( ! map_parsed( tv, pi, level + 1 ) )
				return 0;
	}
	return 1;
}

#define ADD_ITEM(tv,item) \
{ \
	if( *((tv)->parser.ppi) == NULL ) \
		*((tv)->parser.ppi) = (item); \
	if( (item)->parent->child_last ) \
		(item)->parent->child_last->next = (item); \
	(item)->parent->child_last = (item); \
	(item)->row = (tv)->parser.row; \
}

int add_template_item_text( my_thread_var_t *tv, char *str, size_t len ) {
	my_parser_item_t *item;
	Newxz( item, 1, my_parser_item_t );
	item->id = PARSER_ITEM_TEXT;
	item->content_length = len;
	Newx( item->content, len + 1, char );
	Copy( str, item->content, len, char );
	item->content[len] = '\0';
	item->parent = tv->parser.last_parent;
	ADD_ITEM( tv, item );
	_debug( "TEXT %u [%s] item 0x%08X parent 0x%08X\n",
		len, item->content, item, item->parent );
	return 1;
}

int add_template_item( my_thread_var_t *tv, char *str, size_t len, char *rlb ) {
	char *p1, *p2, *key = NULL, *p3, *p4;
	my_parser_item_t *item;
	p1 = str;
	p2 = str + len;
	while( ! ISWHITECHAR( *p1 ) && p1 < p2 ) p1 ++;
	Newx( key, p1 - str + 1, char );
	my_strncpyu( key, str, p1 - str );
	while( ISWHITECHAR( *p1 ) && p1 < p2 ) p1 ++;
	Newxz( item, 1, my_parser_item_t );
	switch( *key ++ ) {
	case '=':
		item->id = PARSER_ITEM_PRINT;
		item->content_length = p2 - p1;
		Newx( item->content, item->content_length + 1, char );
		Copy( p1, item->content, item->content_length + 1, char );
		item->parent = tv->parser.last_parent;
		ADD_ITEM( tv, item );
		_debug( "PRINT (%d)[%s] item 0x%07X parent 0x%07X\n",
			p2 - p1, p1, item, item->parent );
		*rlb = 1;
		break;
	case 'P':
		if( strcmp( key, "RINT" ) == 0 ) {
			item->id = PARSER_ITEM_PRINT;
			item->content_length = p2 - p1;
			Newx( item->content, item->content_length + 1, char );
			Copy( p1, item->content, item->content_length + 1, char );
			item->parent = tv->parser.last_parent;
			ADD_ITEM( tv, item );
			_debug( "PRINT (%d)[%s] item 0x%07X parent 0x%07X\n",
				p2 - p1, p1, item, item->parent );
			*rlb = 1;
		}
		else
			goto default_action;
		break;
	case 'I':
		if( *key == 'F' ) {
			item->id = PARSER_ITEM_CON;
			item->content_length = p2 - p1;
			Newx( item->content, item->content_length + 1, char );
			Copy( p1, item->content, item->content_length + 1, char );
			item->parent = tv->parser.last_parent;
			ADD_ITEM( tv, item );
			tv->parser.last_parent = item;
			tv->parser.ppi = &item->child;
			_debug( "IF [%s] item 0x%07X parent 0x%07X\n",
				p1, item, item->parent );
			*rlb = 1;
		}
		else if( strcmp( key, "NCLUDE" ) == 0 ) {
			item->id = PARSER_ITEM_ASIS;
			item->content_length = ( p2 - p1 ) * 2 + tv->class_name_length + 200;
			Newx( item->content, item->content_length + 1, char );
			p3 = my_strcpy( item->content, tv->class_name );
			p3 = my_strcpy( p3, "->make_script_and_run( \"" );
			p3 = my_strcpy( p3, p1 );
			if( tv->path_cache != NULL ) {
				p3 = my_strcpy( p3, "\", \"" );
				p3 = my_strcpy( p3, "_auto." );
				p4 = my_strcpy( p3, p1 );
				for( ; p3 < p4; p3 ++ ) {
					switch( *p3 ) {
					case '/': case '\\': *p3 = '.';
					}
				}
				p3 = my_strcpy( p3, ".pl\" );\n" );
			}
			else {
				p3 = my_strcpy( p3, "\" );\n" );
			}
			item->content_length = p3 - item->content;
			item->parent = tv->parser.last_parent;
			ADD_ITEM( tv, item );
			_debug( "INCLUDE [%s] item 0x%07X parent 0x%07X\n",
				p1, item, item->parent );
			*rlb = 1;
		}
		else
			goto default_action;
		break;
	case 'E':
		if( strcmp( key, "ND" ) == 0 ) {
			if( my_stristr( p1, "IF" ) == p1 ) {
				if( tv->parser.last_parent->parent == NULL
					|| tv->parser.last_parent->id < PARSER_ITEM_CON
					|| tv->parser.last_parent->id > PARSER_ITEM_ELSE )
						return my_parser_set_error( tv, "[END IF] outside condition" );
				item->id = PARSER_ITEM_ECON;
				tv->parser.last_parent = tv->parser.last_parent->parent;
				tv->parser.ppi = &tv->parser.last_parent->child_last;
				item->parent = tv->parser.last_parent;
				ADD_ITEM( tv, item );
				_debug( "END IF item 0x%07X parent 0x%07X\n", item, item->parent );
			}
			else if( my_stristr( p1, "LOOP" ) == p1 ) {
				if( tv->parser.last_parent->parent == NULL
					|| tv->parser.last_parent->id != PARSER_ITEM_LOOP )
						return my_parser_set_error( tv, "[END LOOP] without [LOOP]" );
				item->id = PARSER_ITEM_ELOOP;
				p1 += 4;
				while( p1 < p2 && ISWHITECHAR( *p1 ) ) p1 ++;
				if( p1 < p2 ) {
					p3 = p1;
					while( p3 < p2 && ! ISWHITECHAR( *p3 ) ) p3 ++;
					if( p3 < p2 ) {
						*p3 ++ = '\0';
						item->content_length = p3 - p1 - 1;
						while( p3 < p2 && ISWHITECHAR( *p3 ) ) p3 ++;
					}
					else
						item->content_length = p2 - p1;
					if( p3 < p2 ) {
						item->len1 = p2 - p3;
						New( 1, item->val1, item->len1 + 1, char );
						Copy( p3, item->val1, item->len1 + 1, char );
					}
					New( 1, item->content, item->content_length + 1, char );
					Copy( p1, item->content, item->content_length + 1, char );
				}
				tv->parser.last_parent = tv->parser.last_parent->parent;
				tv->parser.ppi = &tv->parser.last_parent->child_last;
				item->parent = tv->parser.last_parent;
				ADD_ITEM( tv, item );
				_debug( "END LOOP [%s] [%s] item 0x%07X parent 0x%07X\n",
					item->content, item->val1, item, item->parent );
			}
			else if( my_stristr( p1, "SUB" ) == p1 ) {
				if( tv->parser.last_parent->parent == NULL
					|| tv->parser.last_parent->id != PARSER_ITEM_SUB )
						return my_parser_set_error( tv,
							"[END SUB] without [SUB]" );
				item->id = PARSER_ITEM_ESUB;
				tv->parser.last_parent = tv->parser.last_parent->parent;
				tv->parser.ppi = &tv->parser.last_parent->child_last;
				item->parent = tv->parser.last_parent;
				ADD_ITEM( tv, item );
				_debug( "END SUB item 0x%07X parent 0x%07X\n",
					item, item->parent );
			}
			else {
				return my_parser_set_error( tv,
					"[END] without valid identifier" );
				_debug( "END [%s]\n", p1 );
			}
			*rlb = 1;
		}
		else if( strcmp( key, "LSE" ) == 0 ) {
			item->id = PARSER_ITEM_ELSE;
			if( tv->parser.last_parent->parent == NULL
				|| ( tv->parser.last_parent->id != PARSER_ITEM_CON
				&& tv->parser.last_parent->id != PARSER_ITEM_ELCO ) )
					return my_parser_set_error( tv,
						"[ELSE] outside condition" );
			item->parent = tv->parser.last_parent->parent;
			ADD_ITEM( tv, item );
			tv->parser.last_parent = item;
			tv->parser.ppi = &item->child;
			_debug( "ELSE item 0x%07X parent 0x%07X\n", item, item->parent );
			*rlb = 1;
		}
		else if( strcmp( key, "LSIF" ) == 0 ) {
			item->id = PARSER_ITEM_ELCO;
			if( tv->parser.last_parent->parent == NULL
				|| ( tv->parser.last_parent->id != PARSER_ITEM_CON
				&& tv->parser.last_parent->id != PARSER_ITEM_ELCO ) )
					return my_parser_set_error( tv,
						"[ELSIF] outside condition" );
			item->content_length = p2 - p1;
			Newx( item->content, item->content_length + 1, char );
			Copy( p1, item->content, item->content_length + 1, char );
			item->parent = tv->parser.last_parent->parent;
			ADD_ITEM( tv, item );
			tv->parser.last_parent = item;
			tv->parser.ppi = &item->child;
			_debug( "ELSIF [%s] item 0x%07X parent 0x%07X\n",
				p1, item, item->parent );
			*rlb = 1;
		}
		else
			goto default_action;
		break;
	case 'L':
		if( strcmp( key, "OOP" ) == 0 ) {
			item->id = PARSER_ITEM_LOOP;
			for( p3 = p1; p3 < p2 && ! ISWHITECHAR( *p3 ); p3 ++ );
			if( p3 < p2 ) *p3 ++ = '\0';
			item->content_length = p3 - p1;
			Newx( item->content, item->content_length + 1, char );
			Copy( p1, item->content, item->content_length + 1, char );
			while( p3 < p2 && ISWHITECHAR( *p3 ) ) p3 ++;
			p1 = p3;
			while( p3 < p2 && ! ISWHITECHAR( *p3 ) ) p3 ++;
			if( p3 < p2 ) *p3 = '\0';
			if( p1 < p3 ) {
				item->len1 = p3 - p1;
				Newx( item->val1, item->len1 + 5, char );
				Copy( p1, item->val1, item->len1 + 1, char );
				while( p3 < p2 && ISWHITECHAR( *p3 ) ) p3 ++;
				if( p3 < p2 ) {
					item->len2 = p2 - p3;
					Newx( item->val2, item->len2 + 5, char );
					Copy( p3, item->val2, item->len2 + 1, char );
				}
			}
			item->parent = tv->parser.last_parent;
			ADD_ITEM( tv, item );
			tv->parser.last_parent = item;
			tv->parser.ppi = &item->child;
			_debug( "LOOP [%s] [%s] [%s] item 0x%07X parent 0x%07X\n",
				item->content, item->val1, item->val2, item, item->parent );
			*rlb = 1;
		}
		else
			goto default_action;
		break;
	case 'S':
		if( strcmp( key, "UB" ) == 0 ) {
			item->id = PARSER_ITEM_SUB;
			item->content_length = p2 - p1;
			Newx( item->content, item->content_length + 1, char );
			Copy( p1, item->content, item->content_length + 1, char );
			item->parent = tv->parser.last_parent;
			ADD_ITEM( tv, item );
			tv->parser.last_parent = item;
			tv->parser.ppi = &item->child;
			_debug( "SUB [%s] item 0x%07X parent 0x%07X\n",
				p1, item, item->parent );
			*rlb = 1;
		}
		else
			goto default_action;
		break;
	case '#':
		item->id = PARSER_ITEM_COMMENT;
		item->content_length = p2 - p1;
		Newx( item->content, item->content_length + 1, char );
		Copy( p1, item->content, item->content_length + 1, char );
		item->parent = tv->parser.last_parent;
		ADD_ITEM( tv, item );
		_debug( "COMMENT [%s] item 0x%07X parent 0x%07X\n",
			p1, item, item->parent );
		*rlb = 1;
		break;
	case '!':
		if( *key == 'X' ) {
			_debug( "!X [%s]\n", p1 );
			item->id = PARSER_ITEM_XX;
			item->content_length = p2 - p1;
			Newx( item->content, item->content_length + 1, char );
			Copy( p1, item->content, item->content_length + 1, char );
			item->parent = tv->parser.last_parent;
			ADD_ITEM( tv, item );
			*rlb = 1;
		}
		else
			goto default_action;
		break;
	case ':':
		str = p1;
	default:
default_action:
		_debug( "DO [%s]\n", str );
		item->id = PARSER_ITEM_DO;
		item->content_length = p2 - str;
		Newx( item->content, item->content_length + 1, char );
		Copy( str, item->content, item->content_length + 1, char );
		item->parent = tv->parser.last_parent;
		ADD_ITEM( tv, item );
		*rlb = 1;
	}
	Safefree( key - 1 );
	return 1;
}

int parse_template( my_thread_var_t *tv, const char *tpl, int len, int setpath ) {
	PerlIO *pfile = NULL;
	int step = 0, ret = 0;
	char *path = NULL, *buf, rlb = 0, *s1, *s2, *s3, *bufe;
	const char *prgsb, *prgsf, *prgsp, *prgeb, *prgef, *prgep, *cmdsb, *cmdse, *cmdsp;
	Newxz( tv->root_item, 1, my_parser_item_t );
	tv->parser.last_parent = tv->root_item;
	tv->parser.ppi = &tv->root_item->child;
	_debug( "creating item 0x%07X parent 0x%07X\n",
		tv->root_item, tv->root_item->parent );
	if( len <= 256 ) {
		if( setpath && tv->path_template != NULL ) {
			Newx( path, tv->path_template_length + len + 1, char );
			len = my_strcpy( my_strcpy( path, tv->path_template ), tpl ) - path;
			tpl = path;
			pfile = PerlIO_open( path, "r" );
		}
		else
			pfile = PerlIO_open( tpl, "r" );
	}
	if( pfile != NULL ) {
		PerlIO_seek( pfile, 0, SEEK_END );
		len = PerlIO_tell( pfile );
		PerlIO_seek( pfile, 0, SEEK_SET );
		Newx( buf, len + 1, char );
		len = PerlIO_read( pfile, buf, len );
		buf[len] = '\0';
		PerlIO_close( pfile );
		my_strncpy( tv->parser.file, tpl, sizeof( tv->parser.file ) );
	}
	else {
		my_strcpy( tv->parser.file, "ANON" );
		Newx( buf, len + 1, char );
		Copy( tpl, buf, len + 1, char );
		buf[len] = '\0';
	}
	bufe = buf + len;
	prgsp = prgsb = tv->prg_start;
	prgsf = tv->prg_start + tv->prg_start_length;
	prgep = prgeb = tv->prg_end;
	prgef = tv->prg_end + tv->prg_end_length;
	cmdsp = cmdsb = tv->cmd_sep;
	cmdse = tv->cmd_sep + tv->cmd_sep_length;
	//_debug( "prg start: %s\n", prgsb );
	tv->parser.column = 0;
	tv->parser.row = 1;
	for( s2 = s1 = buf; s1 < bufe; s1 ++ ) {
		switch( *s1 ) {
		case '\n':
			tv->parser.row ++;
			tv->parser.column = 1;
			prgsp = prgsb;
			break;
		case '\r':
			continue;
		default:
			tv->parser.column ++;
		}
		//_debug( "char %c\n", *s1 );
		switch( step ) {
		case 0:
			if( *s1 == *prgsp ) {
				if( ++ prgsp == prgsf ) {
					s1 += 1 - tv->prg_start_length;
					step = 1;
					//_debug( "prg start\n" );
					if( rlb ) {
						if( *s2 == '\r' && s2 < s1 ) s2 ++;
						if( *s2 == '\n' && s2 < s1 ) s2 ++;
					}
					if( s2 < s1 ) {
						//_debug( "found text %s\n", s1 );
						*s1 = '\0';
						if( ! add_template_item_text( tv, s2, s1 - s2 ) )
							goto error;
					}
					s2 = s1 + tv->prg_start_length;
					prgsp = prgsb;
				}
			}
			else {
				prgsp = prgsb;
			}
			break;
		case 1:
			if( *s1 == *prgep ) {
				if( ++ prgep == prgef ) {
					s1 += 1 - tv->prg_end_length;
					step = 0;
					//_debug( "prg end\n" );
					for( s3 = s1; s3 > s2 && ISWHITECHAR( s3[-1] ) ; s3 -- );
					for( ; s2 <= s3 && ISWHITECHAR( *s2 ) ; s2 ++ );
					if( s2 < s3 ) {
						*s3 = '\0';
						_debug( "found item %u %s\n", s3 - s2, s2 );
						if( ! add_template_item( tv, s2, s3 - s2, &rlb ) )
							goto error;
					}
					s2 = s1 + tv->prg_end_length;
					prgep = prgeb;
				}
			}
			else if( *s1 == *cmdsp ) {
				if( ++ cmdsp == cmdse ) {
					s1 += 1 - tv->cmd_sep_length;
					for( s3 = s1; s3 > s2 && ISWHITECHAR( s3[-1] ) ; s3 -- );
					for( ; s2 <= s3 && ISWHITECHAR( *s2 ) ; s2 ++ );
					if( s2 < s3 ) {
						*s3 = '\0';
						if( ! add_template_item( tv, s2, s3 - s2, &rlb ) )
							goto error;
					}
					s2 = s1 + tv->cmd_sep_length;
					cmdsp = cmdsb;
				}
			}
			else {
				prgep = prgeb;
				cmdsp = cmdsb;
			}
			break;
		}
	}
	//_debug( "s2 %u s1 %u\n", s2, s1 );
	if( s2 < s1 ) {
		if( step == 0 ) {
			if( ! add_template_item_text( tv, s2, s1 - s2 ) )
				goto error;
		}
		else {
			sprintf(
				tv->last_error, "syntax error on line %d", tv->parser.row );
			goto error;
		}
	}
	else if( s1 == buf ) {
		if( ! add_template_item_text( tv, "", 0 ) )
			goto error;
	}
	ret = 1;
	goto exit;
error:
	ret = 0;
exit:
	Safefree( path );
	Safefree( buf );
	return ret;
}
