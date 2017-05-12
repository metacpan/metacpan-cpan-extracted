#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include <math.h>
#include <stdlib.h>

#include "my_utils.h"

MODULE = PAB3::Utils		PACKAGE = PAB3::Utils


BOOT:
{
	MY_CXT_INIT;
	MY_CXT.threads = MY_CXT.last_thread = NULL;
	MY_CXT.locale_alias = NULL;
	MY_CXT.state = 1;
#ifdef USE_ITHREADS
	MUTEX_INIT( &MY_CXT.thread_lock );
	MY_CXT.perl = aTHX;
#endif
}


#/*****************************************************************************
# * _cleanup()
# *****************************************************************************/

void
_cleanup( ... )
PREINIT:
	dMY_CXT;
CODE:
	(void) items; /* avoid compiler warning */
#ifdef USE_ITHREADS
	if( MY_CXT.perl != aTHX )
		XSRETURN_EMPTY;
#endif
	cleanup_my_utils( &MY_CXT );
#ifdef USE_ITHREADS
	MUTEX_DESTROY( &MY_CXT.thread_lock );
#endif
	MY_CXT.state = 0;
	


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
# * _get_address( var )
# *****************************************************************************/

void *
_get_address( var )
	SV *var;
CODE:
	if( SvROK( var ) )
		RETVAL = SvRV( var );
	else
		RETVAL = var;
OUTPUT:
	RETVAL


#/*****************************************************************************
# * _get_current_thread_id()
# *****************************************************************************/

unsigned long
_get_current_thread_id()
CODE:
	RETVAL = get_current_thread_id();
OUTPUT:
	RETVAL


#/*****************************************************************************
# * _set_module_path( path )
# *****************************************************************************/

void
_set_module_path( mpath )
	SV *mpath;
PREINIT:
	dMY_CXT;
	STRLEN i, len;
	char *path, *s1, *s2;
CODE:
	path = SvPVx( mpath, len );
	//fprintf( stderr, "set module path [%s]\n", path );
	MY_CXT_LOCK;
	s1 = MY_CXT.locale_path;
	s2 = MY_CXT.zoneinfo_path;
	for( i = len; i > 0; i -- ) {
		*s1 ++ = *path;
		*s2 ++ = *path;
		path ++;
	}
	Copy( "locale/", s1, 7, char );
	Copy( "zoneinfo/", s2, 9, char );
	*( s1 += 7 ) = '\0';
	*( s2 += 9 ) = '\0';
	MY_CXT.locale_path_length = (int) ( s1 - MY_CXT.locale_path );
	MY_CXT.zoneinfo_path_length = (int) ( s2 - MY_CXT.zoneinfo_path );
	read_locale_alias( &MY_CXT );
	MY_CXT_UNLOCK;


#/*****************************************************************************
# * new( class, ... )
# *****************************************************************************/

void
new( class, ... )
	SV *class;
PREINIT:
	dMY_CXT;
	SV *sv;
	HV *hv;
PPCODE:
	sv = sv_2mortal( newSVuv( 0 ) );
	SvUV_set( sv, (size_t) sv );
	hv = gv_stashpv( SvPVX( class ), FALSE );
	XPUSHs( sv_bless( sv_2mortal( newRV( sv ) ), hv ) );


#/*****************************************************************************
# * str_trim( string )
# *****************************************************************************/

void
str_trim( string )
	SV *string;
PREINIT:
	STRLEN lstr, p1, p2;
	char *sstr, ch;
CODE:
	sstr = SvPVx( string, lstr );
	for( p1 = 0; p1 < lstr; p1 ++ ) {
		ch = sstr[p1];
		if( ! ISWHITECHAR( ch ) ) break;
	}
	for( p2 = lstr - 1; p2 >= 0; p2 -- ) {
		ch = sstr[p2];
		if( ! ISWHITECHAR( ch ) ) break;
	}
	ST(0) = sv_2mortal( newSVpvn( &sstr[p1], p2 - p1 + 1 ) );


#/*****************************************************************************
# * round( num, ... )
# *****************************************************************************/

double
round( num, ... )
	double num;
PREINIT:
	int prec;
CODE:
	if( items < 2 )
		prec = 0;
	else {
		prec = (int) SvIV( ST(1) );
		if( prec > ROUND_PREC_MAX )
			prec = ROUND_PREC_MAX;
		else if( prec < 0 )
			prec = 0;
	}
	RETVAL = floor( num * ROUND_PREC[prec] + (num < 0.0 ? -0.5 : 0.5) ) / ROUND_PREC[prec];
OUTPUT:
	RETVAL


#/*****************************************************************************
# * _set_locale( tid, ... )
# *****************************************************************************/

char *
_set_locale( tid, ... )
	UV tid;
PREINIT:
	dMY_CXT;
	my_thread_var_t *tv;
	int i;
	const char *str;
CODE:
	find_or_create_tv( &MY_CXT, tv, tid );
	for( i = 1; i < items; i ++ ) {
		str = SvPV_nolen( ST(i) );
		if( (str = get_locale_format_settings( &MY_CXT, str, &tv->locale )) ) {
			RETVAL = (char *) str;
			goto exit;
		}
	}
	RETVAL = NULL;
exit:
OUTPUT:
	RETVAL


#/*****************************************************************************
# * _set_user_locale( tid, hash_ref )
# *****************************************************************************/

void
_set_user_locale( tid, hash_ref )
	UV tid;
	HV *hash_ref;
PREINIT:
	dMY_CXT;
	my_thread_var_t *tv;
	my_locale_t *loc;
	AV *av;
	SV *sv, **psv;
	I32 rlen, i;
	char *key;
CODE:
	find_or_create_tv( &MY_CXT, tv, tid );
	loc = &tv->locale;
	loc->name[0] = '\0';
	hv_iterinit( hash_ref );
	while( (sv = hv_iternextsv( hash_ref, &key, &rlen )) != NULL ) {
		switch( toupper( *key ) ) {
		case 'A':
			if( my_stricmp( key, "AMU" ) == 0 ||
				my_stricmp( key, "AM_UPPER" ) == 0
			) {
				strncpy( loc->time_am_upper,
					SvPV_nolen( sv ), sizeof( loc->time_am_upper ) );
			}
			else if( my_stricmp( key, "AML" ) == 0 ||
				my_stricmp( key, "AM_LOWER" ) == 0
			) {
				strncpy( loc->time_am_lower,
					SvPV_nolen( sv ), sizeof( loc->time_am_lower ) );
			}
			else if( my_stricmp( key, "APF" ) == 0 ||
				my_stricmp( key, "AMPM_FORMAT" ) == 0
			) {
				strncpy( loc->ampm_format,
					SvPV_nolen( sv ), sizeof( loc->ampm_format ) );
			}
			else
				goto _unknown;
			break;
		case 'C':
			if( my_stricmp( key, "CS" ) == 0 ||
				my_stricmp( key, "CURRENCY_SYMBOL" ) == 0
			) {
				strncpy( loc->currency_symbol,
					SvPV_nolen( sv ), sizeof( loc->currency_symbol ) );
			}
			else if( my_stricmp( key, "CSA" ) == 0 ||
				my_stricmp( key, "CURR_SYMB_ALIGN" ) == 0
			) {
				loc->curr_symb_align = (SvPV_nolen( sv ))[0];
			}
			else if( my_stricmp( key, "CSS" ) == 0 ||
				my_stricmp( key, "CURR_SYMB_SPACE" ) == 0
			) {
				loc->curr_symb_align = (char) SvIV( sv );
			}
			else
				goto _unknown;
			break;
		case 'D':
			if( my_stricmp( key, "DP" ) == 0 ||
				my_stricmp( key, "DECIMAL_POINT" ) == 0
			) {
				loc->decimal_point = (SvPV_nolen( sv ))[0];
			}
			else if( my_stricmp( key, "DF" ) == 0 ||
				my_stricmp( key, "DATE_FORMAT" ) == 0
			) {
				strncpy( loc->date_format,
					SvPV_nolen( sv ), sizeof( loc->date_format ) );
			}
			else if( my_stricmp( key, "DTF" ) == 0 ||
				my_stricmp( key, "DATETIME_FORMAT" ) == 0
			) {
				strncpy( loc->datetime_format,
					SvPV_nolen( sv ), sizeof( loc->datetime_format ) );
			}
			else
				goto _unknown;
			break;
		case 'F':
			if( my_stricmp( key, "FD" ) == 0 ||
				my_stricmp( key, "FRAC_DIGITS" ) == 0
			) {
				loc->frac_digits = (char) SvIV( sv );
			}
			else
				goto _unknown;
			break;
		case 'G':
			if( my_stricmp( key, "GRP" ) == 0 ||
				my_stricmp( key, "GROUPING" ) == 0
			) {
				if( SvROK(sv) && (sv = SvRV(sv)) &&
					SvTYPE(sv) == SVt_PVAV
				) {
					for( i = 0; i < 3; i++ ) {
						if( (psv = av_fetch( (AV*) sv, i, 0 )) == NULL )
							break;
						loc->grouping[i] = (char) SvIV( *psv );
					}
					loc->grouping[i] = -2;
				}
				else {
					loc->grouping[0] = (char) SvIV( sv );
					loc->grouping[1] = -2;
				}
			}
			else
				goto _unknown;
			break;
		case 'I':
			if( my_stricmp( key, "IFD" ) == 0 ||
				my_stricmp( key, "INT_FRAC_DIGITS" ) == 0
			) {
				loc->int_frac_digits = (char) SvIV( sv );
			}
			else if( my_stricmp( key, "ICS" ) == 0 ||
				my_stricmp( key, "INT_CURR_SYMBOL" ) == 0
			) {
				strncpy( loc->int_curr_symbol,
					SvPV_nolen( sv ), sizeof( loc->int_curr_symbol ) );
			}
			else
				goto _unknown;
			break;
		case 'L':
			if( my_stricmp( key, "LDN" ) == 0 ||
				my_stricmp( key, "LONG_DAY_NAMES" ) == 0
			) {
				if( SvROK(sv) && (sv = SvRV(sv)) &&
					SvTYPE(sv) == SVt_PVAV
				) {
					av = (AV*) sv;
					for( i = 0; i < 7; i ++ ) {
						if( (psv = av_fetch( av, i, 0 )) == NULL )
							continue;
						strncpy(
							loc->long_day_names[i],
							SvPV_nolen( *psv ),
							sizeof( loc->long_day_names[i] )
						);
					}
				}
				else {
					warn( "Parameter 'long_day_names'"
						" must be a reference to an array" );
				}
			}
			else if( my_stricmp( key, "LMN" ) == 0 ||
				my_stricmp( key, "LONG_MONTH_NAMES" ) == 0
			) {
				if( SvROK(sv) && (sv = SvRV(sv)) &&
					SvTYPE(sv) == SVt_PVAV
				) {
					av = (AV*) sv;
					for( i = 0; i < 12; i ++ ) {
						if( (psv = av_fetch( av, i, 0 )) == NULL )
							continue;
						strncpy(
							loc->long_month_names[i],
							SvPV_nolen( *psv ),
							sizeof( loc->long_month_names[i] )
						);
					}
				}
				else {
					warn( "Parameter 'long_month_names'"
						" must be a reference to an array" );
				}
			}
			else
				goto _unknown;
			break;
		case 'N':
			if( my_stricmp( key, "NS" ) == 0 ||
				my_stricmp( key, "NEGATIVE_SIGN" ) == 0
			) {
				loc->negative_sign = (SvPV_nolen( sv ))[0];
			}
			else
				goto _unknown;
			break;
		case 'P':
			if( my_stricmp( key, "PS" ) == 0 ||
				my_stricmp( key, "POSITIVE_SIGN" ) == 0
			) {
				loc->positive_sign = (SvPV_nolen( sv ))[0];
			}
			else if( my_stricmp( key, "PMU" ) == 0 ||
				my_stricmp( key, "PM_UPPER" ) == 0
			) {
				strncpy( loc->time_pm_upper,
					SvPV_nolen( sv ), sizeof( loc->time_pm_upper ) );
			}
			else if( my_stricmp( key, "PML" ) == 0 ||
				my_stricmp( key, "PM_LOWER" ) == 0
			) {
				strncpy( loc->time_pm_lower,
					SvPV_nolen( sv ), sizeof( loc->time_pm_lower ) );
			}
			else
				goto _unknown;
			break;
		case 'S':
			if( my_stricmp( key, "SDN" ) == 0 ||
				my_stricmp( key, "SHORT_DAY_NAMES" ) == 0
			) {
				if( SvROK(sv) && (sv = SvRV(sv)) &&
					SvTYPE(sv) == SVt_PVAV
				) {
					av = (AV*) sv;
					for( i = 0; i < 7; i ++ ) {
						if( (psv = av_fetch( av, i, 0 )) == NULL )
							continue;
						strncpy(
							loc->short_day_names[i],
							SvPV_nolen( *psv ),
							sizeof( loc->short_day_names[i] )
						);
					}
				}
				else {
					warn( "Parameter 'short_day_names'"
						" must be a reference to an array" );
				}
			}
			else if( my_stricmp( key, "SDN" ) == 0 ||
				my_stricmp( key, "SHORT_MONTH_NAMES" ) == 0
			) {
				if( SvROK(sv) && (sv = SvRV(sv)) &&
					SvTYPE(sv) == SVt_PVAV
				) {
					av = (AV*) sv;
					for( i = 0; i < 12; i ++ ) {
						if( (psv = av_fetch( av, i, 0 )) == NULL )
							continue;
						strncpy(
							loc->short_month_names[i],
							SvPV_nolen( *psv ),
							sizeof( loc->short_month_names[i] )
						);
					}
				}
				else {
					warn( "Parameter 'short_month_names'"
						" must be a reference to an array" );
				}
			}
			else
				goto _unknown;
			break;
		case 'T':
			if( my_stricmp( key, "TS" ) == 0 ||
				my_stricmp( key, "THOUSANDS_SEP" ) == 0
			) {
				loc->thousands_sep = (SvPV_nolen( sv ))[0];
			}
			else if( my_stricmp( key, "TF" ) == 0 ||
				my_stricmp( key, "TIME_FORMAT" ) == 0
			) {
				strncpy( loc->time_format,
					SvPV_nolen( sv ), sizeof( loc->time_format ) );
			}
			else
				goto _unknown;
			break;
		default:
_unknown:
			warn( "Unknown locale setting '%s'", key );
			break;
		}
	}


#/*****************************************************************************
# * _number_format(
# *     tid, value [, dec [, pnt [, thou [, neg [, pos [, zerofill [, fillchar]]]]]]]
# * )
# *****************************************************************************/

void
_number_format( tid, value, dec = 0, pnt = 0, thou = 0, neg = 0, pos = 0, zerofill = 0, fillchar = 0 )
	UV tid;
	double value;
	int dec;
	char pnt;
	SV *thou;
	char neg;
	SV *pos;
	int zerofill;
	char fillchar;
PREINIT:
	dMY_CXT;
	char thousep;
	char pos2;
	my_thread_var_t *tv;
	char str[256];
CODE:
	find_or_create_tv( &MY_CXT, tv, tid );
	if( pnt == 0 ) pnt = tv->locale.decimal_point;
	if( thou == 0 || ! SvOK( thou ) )
		thousep = tv->locale.thousands_sep;
	else if( SvPOK( thou ) )
		thousep = (char)* SvPV_nolen( thou );
	else
		thousep = 0;
	if( neg == 0 ) neg = tv->locale.negative_sign;
	if( pos == 0 || ! SvOK( pos ) )
		pos2 = 0;
	else if( SvPOK( pos ) )
		pos2 = (char)* SvPV_nolen( pos );
	else
		pos2 = tv->locale.positive_sign;
	_int_number_format(
		value, str, 255, dec, pnt, thousep, neg, pos2, zerofill, fillchar
	);
	ST(0) = sv_2mortal( newSVpv( str, 0 ) );


#/*****************************************************************************
# * _set_timezone( tid, tz )
# *****************************************************************************/

int
_set_timezone( tid, tz )
	UV tid;
	char *tz;
PREINIT:
	dMY_CXT;
	my_thread_var_t *tv;
CODE:
	find_or_create_tv( &MY_CXT, tv, tid );
	if(
		!tv->timezone.id[0]
		|| strcmp( tv->timezone.id, tz ) != 0
	) {
		Zero( &tv->timezone, 1, my_vtimezone_t );
		RETVAL = read_timezone( &MY_CXT, tz, &tv->timezone );
	}
	else {
		RETVAL = 1;
	}
OUTPUT:
	RETVAL


#/*****************************************************************************
# * _localtime( tid, ... )
# *****************************************************************************/

void
_localtime( tid, ... )
	UV tid;
PREINIT:
	dMY_CXT;
	time_t timer;
	my_vdatetime_t *tim;
	my_thread_var_t *tv;
PPCODE:
	find_or_create_tv( &MY_CXT, tv, tid );
	if( items < 2 )
		timer = time( 0 );
	else
		timer = (time_t) SvUV( ST(1) );
	tim = apply_timezone( tv, &timer );
	EXTEND( SP, 9 );
	XPUSHs( sv_2mortal( newSVuv( tim->tm_sec ) ) );
	XPUSHs( sv_2mortal( newSVuv( tim->tm_min ) ) );
	XPUSHs( sv_2mortal( newSVuv( tim->tm_hour ) ) );
	XPUSHs( sv_2mortal( newSVuv( tim->tm_mday ) ) );
	XPUSHs( sv_2mortal( newSVuv( tim->tm_mon ) ) );
	XPUSHs( sv_2mortal( newSVuv( tim->tm_year ) ) );
	XPUSHs( sv_2mortal( newSVuv( tim->tm_wday ) ) );
	XPUSHs( sv_2mortal( newSVuv( tim->tm_yday ) ) );
	XPUSHs( sv_2mortal( newSVuv( tim->tm_isdst ) ) );


#/*****************************************************************************
# * _strftime( format, ... )
# *****************************************************************************/

void
_strftime( tid, format, ... )
	UV tid;
	SV *format;
PREINIT:
	dMY_CXT;
	my_thread_var_t *tv;
	STRLEN len;
	int gmt;
	my_vdatetime_t *tim;
	time_t timestamp;
	char *tmp, *fmt;
CODE:
	find_or_create_tv( &MY_CXT, tv, tid );
	fmt = SvPVx( format, len );
	if( ! len ) {
		ST(0) = &PL_sv_undef;
		goto exit;
	}
	len = 64 + len * 4;
	New( 1, tmp, len, char );
	if( items < 3 )
		timestamp = time( 0 );
	else
		timestamp = (time_t) SvUV( ST(2) );
	if( items < 4 )
		gmt = 0;
	else
		gmt = (long) SvIV( ST(3) );
	if( ! gmt )
		tim = apply_timezone( tv, &timestamp );
	else {
		copy_tm_to_vdatetime( gmtime( &timestamp ), &tv->time_struct );
		tim = &tv->time_struct;
		tim->tm_gmtoff = 0;
		tim->tm_zone = DEFAULT_ZONE;
	}
	len = _int_strftime( tv, tmp, len, fmt, tim );
	ST(0) = sv_2mortal( newSVpv( tmp, len ) );
	Safefree( tmp );
exit:
	{}


#/*****************************************************************************
# * _strfmon( tid, format, number )
# *****************************************************************************/

void
_strfmon( tid, format, number )
	UV tid;
	char *format;
	double number;
PREINIT:
	dMY_CXT;
	my_thread_var_t *tv;
	size_t len;
	char tmp[64];
CODE:
	find_or_create_tv( &MY_CXT, tv, tid );
	len = _int_strfmon( tv, tmp, 64, format, number );
	ST(0) = sv_2mortal( newSVpvn( tmp, len ) );


#/*****************************************************************************
# * _cleanup_class( tid )
# *****************************************************************************/

void
_cleanup_class( tid )
	UV tid;
PREINIT:
	dMY_CXT;
	my_thread_var_t *tv;
CODE:
	find_or_create_tv( &MY_CXT, tv, tid );
	if( tv ) {
		MY_CXT_LOCK;
		remove_thread_var( &MY_CXT, tv );
		MY_CXT_UNLOCK;
	}
