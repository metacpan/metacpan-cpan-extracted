#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include <stdlib.h>

#include "my_pab3.h"

MODULE = PAB3		PACKAGE = PAB3

BOOT:
{
	MY_CXT_INIT;
	MY_CXT.first_thread = MY_CXT.last_thread = NULL;
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
# * _new( class, ... )
# *****************************************************************************/

void
_new( class, ... )
	SV *class;
PREINIT:
	dMY_CXT;
	my_thread_var_t *tv;
	SV *sv;
	HV *hv;
	int itemp;
	STRLEN lkey, lval;
	char *key, *val;
PPCODE:
	sv = sv_2mortal( (SV*) newHV() );
	tv = my_thread_var_add( &MY_CXT, sv );
	for( itemp = 1; itemp < items - 1; itemp += 2 ) {
		if( ! SvPOK( ST(itemp) ) ) continue;
		key = SvPVx( ST(itemp), lkey );
		/*printf( "item %u %s\n", itemp, key );*/
		if( strcmp( key, "path_template" ) == 0 ) {
			val = SvPVx( ST(itemp + 1), lval );
			New( 1, tv->path_template, lval + 2, char );
			Copy( val, tv->path_template, lval, char );
			if( tv->path_template[lval - 1] != '/' )
				tv->path_template[lval ++] = '/';
			tv->path_template[lval] = '\0';
			tv->path_template_length = (WORD) lval;
		}
		else if( strcmp( key, "path_cache" ) == 0 ) {
			val = SvPVx( ST(itemp + 1), lval );
			New( 1, tv->path_cache, lval + 2, char );
			Copy( val, tv->path_cache, lval, char );
			if( tv->path_cache[lval - 1] != '/' )
				tv->path_cache[lval ++] = '/';
			tv->path_cache[lval] = '\0';
			tv->path_cache_length = (WORD) lval;
		}
		else if( strcmp( key, "prg_start" ) == 0 ) {
			val = SvPVx( ST(itemp + 1), lval );
			New( 1, tv->prg_start, lval + 1, char );
			Copy( val, tv->prg_start, lval + 1, char );
			tv->prg_start_length = (BYTE) lval;
		}
		else if( strcmp( key, "prg_end" ) == 0 ) {
			val = SvPVx( ST(itemp + 1), lval );
			New( 1, tv->prg_end, lval + 1, char );
			Copy( val, tv->prg_end, lval + 1, char );
			tv->prg_start_length = (BYTE) lval;
		}
		else if( strcmp( key, "cmd_sep" ) == 0 ) {
			val = SvPVx( ST(itemp + 1), lval );
			New( 1, tv->cmd_sep, lval + 1, char );
			Copy( val, tv->cmd_sep, lval + 1, char );
			tv->cmd_sep_length = (BYTE) lval;
		}
		else if( strcmp( key, "class_name" ) == 0 ) {
			val = SvPVx( ST(itemp + 1), lval );
			New( 1, tv->class_name, lval + 5, char );
			Copy( val, tv->class_name, lval + 1, char );
			set_var_str( tv->class_name, &lval, PAB_TYPE_SCALAR );
			tv->class_name_length = (WORD) lval;
		}
		else if( strcmp( key, "default_record" ) == 0 ) {
			val = SvPVx( ST(itemp + 1), lval );
			switch( *val ) {
			case '$': case '%': case '@': case '&':
				val ++;
				lval --;
				break;
			}
			New( 1, tv->default_record, lval + 5, char );
			Copy( val, tv->default_record, lval + 1, char );
			tv->default_record_length = (WORD) lval;
		}
	}
	hv = gv_stashpv( __PACKAGE__, 0 );
	XPUSHs( sv_bless( sv_2mortal( newRV( sv ) ), hv ) );


#/*****************************************************************************
# * reset( this )
# *****************************************************************************/

void
reset( this )
	SV *this;
PREINIT:
	dMY_CXT;
	my_thread_var_t *tv;
PPCODE:
	if( ( tv = my_thread_var_find( &MY_CXT, this ) ) != NULL ) {
		my_parser_session_cleanup( tv );
		my_loop_def_cleanup( tv );
		my_hashmap_cleanup( tv );
	}


#/*****************************************************************************
# * _parse_template( this, template )
# *****************************************************************************/

void
_parse_template( this, template )
	SV *this;
	SV *template;
PREINIT:
	dMY_CXT;
	my_thread_var_t *tv;
	STRLEN ltmp;
	char *tmp;
CODE:
	if( ( tv = my_thread_var_find( &MY_CXT, this ) ) == NULL ) goto error;
	tv->last_error[0] = '\0';
	tmp = SvPVx( template, ltmp );
	_debug( "parse_template\n" );
	if( ! parse_template( tv, tmp, ltmp, 1 ) ) goto error;
	optimize_script( tv, tv->root_item );
	_debug( "map_parsed\n" );
	if( ! map_parsed( tv, tv->root_item, 0 ) ) goto error;
	_debug( "build_script\n" );
	if( ! build_script( tv ) ) goto error;
	ST(0) = sv_2mortal( newSVpvn( tv->parser.output, tv->parser.curout - tv->parser.output ) );
	my_parser_session_cleanup( tv );
	goto exit;
error:
	ST(0) = &PL_sv_undef;
	my_parser_session_cleanup( tv );
exit:
	{}


#/*****************************************************************************
# * _make_script( this, template, cache )
# *****************************************************************************/

void
_make_script( this, template, cache )
	SV *this;
	SV *template;
	SV *cache;
PREINIT:
	dMY_CXT;
	my_thread_var_t *tv;
	STRLEN ltmp, ltpl;
	char *tmp, *p1;
	char tpl[256], cac[256];
	/*PerlIO *pfile;*/
PPCODE:
	if( (tv = my_thread_var_find( &MY_CXT, this )) == NULL )
		goto ferror;
	tv->last_error[0] = '\0';
	tmp = SvPVx( template, ltpl );
	if( ltpl + tv->path_template_length < 256 ) {
		if( tv->path_template != NULL ) {
			p1 = my_strcpy( tpl, tv->path_template );
			ltpl += tv->path_template_length;
		}
		else
			p1 = tpl;
		p1 = my_strcpy( p1, tmp );
		tmp = SvPVx( cache, ltmp );
		if( ltmp ) {
			if( tv->path_cache != NULL )
				p1 = my_strncpy( cac, tv->path_cache, 256 );
			else
				p1 = cac;
			p1 = my_strncpy( p1, tmp, 256 - ( p1 - cac ) );
		}
		else
			cac[0] = '\0';
	}
parse:	
	if( ! parse_template( tv, tpl, ltpl, 0 ) )
		goto error;
	optimize_script( tv, tv->root_item );
	if( ! map_parsed( tv, tv->root_item, 0 ) )
		goto error;
	if( ! build_script( tv ) )
		goto error;
	if( cac[0] == '\0' ) {
		XPUSHs( sv_2mortal( newSVuv( 2 ) ) );
		XPUSHs( sv_2mortal( newSVpvn(
			tv->parser.output, tv->parser.curout - tv->parser.output ) ) );
	}
	else {
		XPUSHs( sv_2mortal( newSVuv( 3 ) ) );
		XPUSHs( sv_2mortal( newSVpvn(
			tv->parser.output, tv->parser.curout - tv->parser.output ) ) );
		/*
		pfile = PerlIO_open( cac, "w" );
		if( pfile == NULL ) {
			my_set_error( tv, "Unable to open file!" );
			goto error;
		}
		flock( pfile, LOCK_EX );
		PerlIO_write( pfile,
			tv->parser.output, tv->parser.curout - tv->parser.output );
		flock( pfile, LOCK_UN );
		PerlIO_close( pfile );
		XPUSHs( sv_2mortal( newSVuv( 1 ) ) );
		*/
	}
	my_parser_session_cleanup( tv );
	goto exit;
error:
	my_parser_session_cleanup( tv );
ferror:	
	XPUSHs( &PL_sv_undef );
exit:
	{}


#/*****************************************************************************
# * register_loop( this, loopid, source, stype [, record [, rtype = 0 [, object [, arg [, fixed]]]]] )
# *****************************************************************************/

void
register_loop( this, loopid, source, stype, record = NULL, rtype = 0, object = NULL, arg = NULL, fixed = 0 )
	SV *this
	SV *loopid;
	SV *source;
	int stype;
	SV *record;
	int rtype;
	SV *object;
	SV *arg;
	int fixed;
PREINIT:
	dMY_CXT;
	STRLEN len1;
	const char *str1;
	my_thread_var_t *tv;
	my_loop_def_t *ld;
CODE:
	if( ( tv = my_thread_var_find( &MY_CXT, this ) ) == NULL ) goto error;
	str1 = SvPVx( loopid, len1 );
	ld = my_loop_def_find_by_id( tv, str1 );
	if( ld != NULL ) {
		if( ld->is_fixed ) {
			my_set_error( tv, "Loop can not be overwritten" );
			goto error;
		}
		str1 = SvPVx( source, len1 );
		Renew( ld->source, len1 + 5, char );
		Copy( str1, ld->source, len1 + 1, char );
		ld->source_length = len1;
		ld->source_type = stype;
		if( record != NULL && SvOK( record ) ) {
			str1 = SvPVx( record, len1 );
			Renew( ld->record, len1 + 5, char );
			Copy( str1, ld->record, len1 + 1, char );
			ld->record_length = len1;
			ld->record_type = rtype;
		}
		else {
			Safefree( ld->record );
			ld->record = NULL;
			ld->record_type = 0, ld->record_length = 0;
		}
		if( object != NULL && SvOK( object ) ) {
			str1 = SvPVx( object, len1 );
			Renew( ld->object, len1 + 5, char );
			Copy( str1, ld->object, len1 + 1, char );
			set_var_str( ld->object, &len1, PAB_TYPE_SCALAR );
			ld->object_length = len1;
		}
		else {
			Safefree( ld->object );
			ld->object = NULL, ld->object_length = 0;
		}
		if( arg != NULL && SvOK( arg ) ) {
			str1 = SvPVx( arg, len1 );
			New( 1, ld->argv, len1 + 1, char );
			Copy( str1, ld->argv, len1 + 1, char );
			ld->argv_length = len1;
		}
		else {
			Safefree( ld->argv );
			ld->argv = NULL, ld->argv_length = 0;
		}
		ld->is_fixed = fixed;
	}
	else {
		if( my_stristr( str1, "for" ) == str1 ||
			my_stristr( str1, "while" ) == str1 ||
			my_stristr( str1, "do" ) == str1 ||
			my_stristr( str1, "array" ) == str1 ||
			my_stristr( str1, "hash" ) == str1 )
		{
			my_set_error( tv, "Loop identifier [%s] is not allowed", str1 );
			goto error;
		}
		ld = my_loop_def_add( tv );
		New( 1, ld->id, len1 + 1, char );
		Copy( str1, ld->id, len1 + 1, char );
		str1 = SvPVx( source, len1 );
		New( 1, ld->source, len1 + 5, char );
		Copy( str1, ld->source, len1 + 1, char );
		ld->source_length = len1;
		ld->source_type = stype;
		if( record != NULL && SvOK( record ) ) {
			str1 = SvPVx( record, len1 );
			New( 1, ld->record, len1 + 5, char );
			Copy( str1, ld->record, len1 + 1, char );
			ld->record_length = len1;
			ld->record_type = rtype;
		}
		if( object != NULL && SvOK( object ) ) {
			str1 = SvPVx( object, len1 );
			New( 1, ld->object, len1 + 5, char );
			Copy( str1, ld->object, len1 + 1, char );
			set_var_str( ld->object, &len1, PAB_TYPE_SCALAR );
			ld->object_length = len1;
		}
		if( arg != NULL && SvOK( arg ) ) {
			str1 = SvPVx( arg, len1 );
			New( 1, ld->argv, len1 + 1, char );
			Copy( str1, ld->argv, len1 + 1, char );
			ld->argv_length = len1;
		}
		ld->is_fixed = fixed;
	}
	ST(0) = sv_2mortal( newSVuv( 1 ) );
	goto exit;
error:
	ST(0) = &PL_sv_undef;
exit:
	{}


#/*****************************************************************************
# * _add_hashmap( this, loopid, record, fieldmap )
# *****************************************************************************/

void
_add_hashmap( this, loopid, record, fieldmap )
	SV* this;
	SV *loopid;
	SV *record;
	SV *fieldmap;
PREINIT:
	dMY_CXT;
	my_thread_var_t *tv;
	HV *hv;
	AV *av;
	int len, i;
	SV **psv, *sv;
	char *s1;
	STRLEN l1;
	my_hashmap_def_t *hd = NULL;
	HE *he;
	I32 l2;
CODE:
	if( ( tv = my_thread_var_find( &MY_CXT, this ) ) == NULL ) goto error;
	hd = my_hashmap_add( tv );
	if( SvOK( loopid ) && SvPOK( loopid ) ) {
		s1 = SvPVx( loopid, l1 );
		New( 1, hd->loopid, l1 + 1, char );
		Copy( s1, hd->loopid, l1 + 1, char );
	}
	if( SvOK( record ) && SvPOK( record ) ) {
		s1 = SvPVx( record, l1 );
		if( l1 > 0 ) {
			New( 1, hd->record, l1 + 5, char );
			Copy( s1, hd->record, l1 + 1, char );
			set_var_str( hd->record, &l1, PAB_TYPE_SCALAR );
			hd->record_length = l1;
		}
	}
	if( hd->record == NULL ) {
		my_set_error( tv, "Parameter record is invalid" );
		goto error;
	}
	if( SvROK( fieldmap ) && SvTYPE( SvRV( fieldmap ) ) == SVt_PVHV ) {
	    hv = (HV*) SvRV( fieldmap );
	    hd->field_count = len = hv_iterinit( hv );
		Newz( 1, hd->fields, len, char* );
		while( ( he = hv_iternext( hv ) ) != NULL ) {
			s1 = hv_iterkey( he, &l2 );
			sv = hv_iterval( hv, he );
			if( ! SvOK( sv ) || ! SvIOK( sv ) ) goto error_fm;
			i = (int) SvIV( sv );
			if( i < 0 || i >= len ) goto error_fm;
			New( 1, hd->fields[i], l2 + 1, char );
			Copy( s1, hd->fields[i], l2 + 1, char );
		}
		for( i = 0; i < len; i ++ ) {
			if( hd->fields[i] == NULL ) goto error_fm;
		}
	}
	else if( SvROK( fieldmap ) && SvTYPE( SvRV( fieldmap ) ) == SVt_PVAV ) {
		av = (AV*) SvRV( fieldmap );
		hd->field_count = len = av_len( av ) + 1;
		Newz( 1, hd->fields, len, char* );
		for( i = 0; i < len; i ++ ) {
			psv = av_fetch( av, i, 0 );
			if( psv == NULL || ! SvPOK( *psv ) ) goto error_fm;
			s1 = SvPVx( *psv, l1 );
			if( l1 == 0 ) goto error_fm;
			New( 1, hd->fields[i], l1 + 1, char );
			Copy( s1, hd->fields[i], l1 + 1, char );
		}
	}
	else goto error_fm;
	ST(0) = sv_2mortal( newSVuv( 1 ) );
	goto exit;
error_fm:
	my_set_error( tv, "Parameter fieldmap is invalid" );
error:
	if( hd != NULL ) my_hashmap_rem( tv, hd );
	ST(0) = &PL_sv_undef;
exit:
	{}


#/*****************************************************************************
# * error( this )
# *****************************************************************************/

void
error( this )
	SV *this;
PREINIT:
	dMY_CXT;
	my_thread_var_t *tv;
PPCODE:
	if( ( tv = my_thread_var_find( &MY_CXT, this ) ) == NULL ) goto error;
	if( tv->last_error[0] != '\0' ) {
		XPUSHs( sv_2mortal( newSVpvn( tv->last_error, strlen( tv->last_error ) ) ) );
	}
	goto exit;
error:
	XPUSHs( &PL_sv_undef );
exit:
	{}


#/******************************************************************************
# * set_error( this, msg )
# ******************************************************************************/

void
set_error( this, msg )
	SV *this;
	char *msg;
PREINIT:
	dMY_CXT;
	my_thread_var_t *tv;
PPCODE:
	if( ( tv = my_thread_var_find( &MY_CXT, this ) ) == NULL ) return;
	my_strncpy( tv->last_error, msg, sizeof( tv->last_error ) );


#/*****************************************************************************
# * DESTROY( this )
# *****************************************************************************/

void
DESTROY( this )
	SV *this;
PREINIT:
	dMY_CXT;
	my_thread_var_t *tv;
PPCODE:
	if( ( tv = my_thread_var_find( &MY_CXT, this ) ) == NULL ) return;
	_debug( __PACKAGE__ " destroying tv: 0x%08X\n", tv );
	my_thread_var_rem( &MY_CXT, tv );


#/*****************************************************************************
# * _cleanup()
# *****************************************************************************/

void
_cleanup()
PREINIT:
	dMY_CXT;
	my_thread_var_t *tv1, *tv2;
CODE:
	_debug( __PACKAGE__ " _cleanup\n" );
	tv1 = MY_CXT.first_thread;
	while( tv1 != NULL ) {
		tv2 = tv1->next;
		my_thread_var_free( tv1 );
		tv1 = tv2;
	}
	MY_CXT.first_thread = MY_CXT.last_thread = NULL;
