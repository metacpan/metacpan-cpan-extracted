#include <stdio.h>
#include <stdlib.h>
#ifndef _WIN32
#include <sys/stat.h>
#endif
#include <stdarg.h>

#include "my_utils.h"

START_MY_CXT

const my_locale_t DEFAULT_LOCALE = {
	"en_EN", '.', ',', { 3, -2 }, 2, 2, "$", "USD", 'l', 0, '-', '+',
	"%m/%d/%Y", "%I:%M:%S %p", "%a %b %d %Y %I:%M:%S %p %Z", "%I:%M:%S %p",
	"AM", "PM", "am", "pm",
	{
		"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep",
		"Oct", "Nov", "Dec"
	},
	{
		"January", "February", "March", "April", "May", "June", "July",
		"August", "September", "October", "November", "December"
	},
	{ "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" },
	{
		"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday",
		"Friday", "Saturday"
	},
};

const char *DEFAULT_ZONE = "GMT";

const static int mday_array[] =
	{ 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };


void parse_vdatetime( const char *str, my_vdatetime_t *tms );

void copy_tm_to_vdatetime( struct tm *src, my_vdatetime_t *dst ) {
	dst->tm_sec = src->tm_sec;
	dst->tm_min = src->tm_min;
	dst->tm_hour = src->tm_hour;
	dst->tm_mday = src->tm_mday;
	dst->tm_mon = src->tm_mon;
	dst->tm_year = src->tm_year;
	dst->tm_wday = src->tm_wday;
	dst->tm_yday = src->tm_yday;
	dst->tm_isdst = src->tm_isdst;
}

char *PerlIO_fgets( char *buf, size_t max, PerlIO *stream ) {
	int val;
	size_t pos = max + 1;
	char *tmp;
	tmp = buf;
	while( pos > 0 ) {
		val = PerlIO_getc( stream );
		if( val == -1 ) {
			if( pos == max + 1 )
				return NULL;
			break;
		}
		else if( val == '\n' )
			break;
		else if( val == '\r' )
			continue;
		*tmp ++ = (char) val;
		pos --;
	}
	*tmp = '\0';
	return tmp;
}

my_thread_var_t *find_thread_var( my_cxt_t *cxt, UV tid ) {
	my_thread_var_t *tv1;
	for( tv1 = cxt->threads; tv1 != NULL; tv1 = tv1->next ) {
		if( tv1->tid == tid )
			return tv1;
	}
	return NULL;
}

my_thread_var_t *create_thread_var( my_cxt_t *cxt, UV tid ) {
	my_thread_var_t *tv;
	Newz( 1, tv, 1, my_thread_var_t );
	if( ! tv ) {
		/* out of memory! */
		Perl_croak( aTHX_ "PANIC: running out of memory!" );
	}
	tv->tid = tid;
	Copy( &DEFAULT_LOCALE, &tv->locale, 1, my_locale_t );
	if( cxt->threads == NULL )
		cxt->threads = tv;
	else {
		cxt->last_thread->next = tv;
		tv->prev = cxt->last_thread;
	}
	cxt->last_thread = tv;
	return tv;
}

void remove_thread_var( my_cxt_t *cxt, my_thread_var_t *tv ) {
	my_thread_var_t *tvp, *tvn;
	if( ! tv ) return;
	tvp = tv->prev;
	tvn = tv->next;
	if( tv == cxt->threads )
		cxt->threads = tvn;
	if( tv == cxt->last_thread )
		cxt->last_thread = tvp;
	if( tvp )
		tvp->next = tvn;
	if( tvn )
		tvn->prev = tvp;
	Safefree( tv );
}

void cleanup_my_utils( my_cxt_t *cxt ) {
	my_thread_var_t *tv1, *tv2;
	tv1 = cxt->threads;
	while( tv1 ) {
		tv2 = tv1->next;
		Safefree( tv1 );
		tv1 = tv2;
	}
	cxt->threads = cxt->last_thread = NULL;
	if( cxt->locale_alias_count > 0 )
		free_locale_alias( cxt );
}

void free_locale_alias( my_cxt_t *cxt ) {
	int i;
	for( i = cxt->locale_alias_count - 1; i >= 0; i -- ) {
		Safefree( cxt->locale_alias[i].alias );
		Safefree( cxt->locale_alias[i].locale );
	}
	Safefree( cxt->locale_alias );
	cxt->locale_alias_count = 0;
	cxt->locale_alias = NULL;
}

void read_locale_alias( my_cxt_t *cxt ) {
	char path[MAX_PATH], *buffer, *s1, *key, *val, *s2;
	PerlIO *file;
	struct stat stat_p;
	int bsize, lc = 0;
	if( cxt->locale_alias_count )
		free_locale_alias( cxt );
	s1 = path;
	FASTSTRCPY( s1, cxt->locale_path );
	FASTSTRCPY( s1, "#alias" );
	*s1 = '\0';
	if( stat( path, &stat_p ) != 0 )
		return;
	if( (file = PerlIO_open( path, "r" )) == NULL )
		return;
	Newx( buffer, stat_p.st_size + 2, char );
	bsize = PerlIO_read( file, buffer, stat_p.st_size );
	PerlIO_close( file );
	buffer[bsize] = '\0';
	buffer[bsize + 1] = '\0';
	for( s1 = buffer; ; s1 ++ ) {
next_char:
		switch( *s1 ) {
		case '\0':
			goto parse_finish;
		case '\n':
		case '\r':
		case '\t':
		case ' ':
			continue;
		case '#':
			for( s1 ++; *s1 != '\0' && *s1 != '\n'; s1 ++ );
			goto next_char;
		default:
			key = s1;
			/* search end of key */
			for( s1 ++; ; s1 ++ ) {
				if( *s1 == '\0' )
					goto parse_finish;
				else if( *s1 == '\n' || *s1 == '#' )
					goto next_char;
				else if( *s1 == '\t' || *s1 == ' ' ) {
					s2 = s1;
					*s2 = '\0';
					break;
				}
			}
			/* search begin of val */
			for( s1 ++; ; s1 ++ ) {
				if( *s1 == '\0' )
					goto parse_finish;
				else if( *s1 == '\n' || *s1 == '#' )
					goto next_char;
				else if( *s1 == '\t' || *s1 == ' ' )
					continue;
				else {
					val = s1;
					break;
				}
			}
			/* search end of val */
			for( s1 ++; ; s1 ++ ) {
				if( *s1 == '\0' || *s1 == '\n' || *s1 == '\t'
					|| *s1 == ' ' || *s1 == '#'
				) {
					*s1 = '\0';
					break;
				}
			}
			/*printf( "alias found %d [%s] -> [%s]\n", lc, key, val );*/
			if( (lc % 7) == 0 )
				Renew( cxt->locale_alias, lc + 7, my_locale_alias_t );
			Newx( cxt->locale_alias[lc].alias, s2 - key + 1, char );
			Copy( key, cxt->locale_alias[lc].alias, s2 - key + 1, char );
			Newx( cxt->locale_alias[lc].locale, s1 - val + 1, char );
			Copy( val, cxt->locale_alias[lc].locale, s1 - val + 1, char );
			lc ++;
			break;
		}
	}
parse_finish:
	cxt->locale_alias_count = lc;
	Safefree( buffer );
}

const char *get_locale_alias( my_cxt_t *cxt, const char *id ) {
	int i;
	for( i = cxt->locale_alias_count - 1; i >= 0; i -- ) {
		if( strcmp( cxt->locale_alias[i].alias, id ) == 0 ) {
			return cxt->locale_alias[i].locale;
		}
	}
	return id;
}

const char *get_locale_format_settings( cxt, id, locale )
	my_cxt_t *cxt;
	const char *id;
	my_locale_t *locale;
{
	char str[256], *key, *val, *p1;
	PerlIO *pfile;
	int i;
	if( locale == NULL )
		return NULL;
	key = my_strncpy( str, cxt->locale_path, cxt->locale_path_length );
	id = get_locale_alias( cxt, id );
	my_strcpy( key, id );
	pfile = PerlIO_open( str, "r" );
	if( !pfile )
		return NULL;
	while( (p1 = PerlIO_fgets( str, sizeof( str ), pfile )) ) {
		if( p1 == str || str[0] == '#' )
			continue;
		val = strchr( str, ':' );
		if( !val )
			continue;
		*val ++ = '\0';
		key = str;
		switch( *key ) {
		case 'a':
			if( strcmp( key, "amu" ) == 0 )
				strncpy( locale->time_am_upper,
					val, sizeof( locale->time_am_upper ) );
			else if( strcmp( key, "aml" ) == 0 )
				strncpy( locale->time_am_lower,
					val, sizeof( locale->time_am_lower ) );
			else if( strcmp( key, "apf" ) == 0 )
				strncpy( locale->ampm_format,
					val, sizeof( locale->ampm_format ) );
			break;
		case 'c':
			if( strcmp( key, "cs" ) == 0 )
				strncpy( locale->currency_symbol,
					val, sizeof( locale->currency_symbol ) );
			else if( strcmp( key, "csa" ) == 0 )
				locale->curr_symb_align = val[0];
			else if( strcmp( key, "css" ) == 0 )
				locale->curr_symb_space = val[0] - '0';
			break;
		case 'd':
			if( strcmp( key, "dp" ) == 0 )
				locale->decimal_point = val[0];
			else if( strcmp( key, "df" ) == 0 )
				strncpy( locale->date_format,
					val, sizeof( locale->date_format ) );
			else if( strcmp( key, "dtf" ) == 0 )
				strncpy( locale->datetime_format,
					val, sizeof( locale->datetime_format ) );
			break;
		case 'f':
			if( strcmp( key, "fd" ) == 0 )
				locale->frac_digits = (char) atoi( val );
			break;
		case 'g':
			if( strcmp( key, "grp" ) == 0 ) {
				/* 3;2 */
				for( i = 0; *val != '\0'; i ++ ) {
					locale->grouping[i] = *val - '0';
					if( val[1] == '\0' || i == 2 ) {
						i ++;
						break;
					}
					val += 2;
				}
				locale->grouping[i] = -2;
			}
			break;
		case 'i':
			if( strcmp( key, "ics" ) == 0 )
				strncpy( locale->int_curr_symbol,
					val, sizeof( locale->int_curr_symbol ) );
			break;
		case 'l':
			if( strstr( key, "lm" ) == key ) {
				key += 2;
				i = atoi( key );
				if( i < 1 || i > 12 )
					continue;
				strncpy(
					locale->long_month_names[i - 1],
					val,
					sizeof( locale->long_month_names[0] )
				);
			}
			else if( strstr( key, "ld" ) == key ) {
				key += 2;
				i = atoi( key );
				if( i < 1 || i > 7 )
					continue;
				strncpy(
					locale->long_day_names[i - 1],
					val,
					sizeof( locale->long_day_names[0] )
				);
			}
			break;
		case 'n':
			if( strcmp( key, "ns" ) == 0 )
				locale->negative_sign = val[0];
			break;
		case 'p':
			if( strcmp( key, "ps" ) == 0 )
				locale->positive_sign = val[0];
			else if( strcmp( key, "pml" ) == 0 )
				strncpy( locale->time_pm_lower,
					val, sizeof( locale->time_pm_lower ) );
			else if( strcmp( key, "pmu" ) == 0 )
				strncpy( locale->time_pm_upper,
					val, sizeof( locale->time_pm_upper ) );
			break;
		case 's':
			if( strstr( key, "sm" ) == key ) {
				key += 2;
				i = atoi( key );
				if( i < 1 || i > 12 )
					continue;
				strncpy(
					locale->short_month_names[i - 1],
					val,
					sizeof( locale->short_month_names[0] )
				);
			}
			else if( strstr( key, "sd" ) == key ) {
				key += 2;
				i = atoi( key );
				if( i < 1 || i > 7 )
					continue;
				strncpy(
					locale->short_day_names[i - 1],
					val,
					sizeof( locale->short_day_names[0] )
				);
			}
			break;
		case 't':
			if( strcmp( key, "ts" ) == 0 )
				locale->thousands_sep = val[0];
			else if( strcmp( key, "tf" ) == 0 )
				strncpy( locale->time_format,
					val, sizeof( locale->time_format ) );
			break;
		}
	}
	PerlIO_close( pfile );
	return id;
}

time_t seconds_since_epoch( my_vdatetime_t *tim ) {
	int i, year;
	time_t days = 0;
	/* calc days of years starting at 1970-01-01 */
	year = tim->tm_year + 1900;
	for( i = year - 1; i >= 1970; i -- )
		days += 365 + ((i % 4 == 0 && i % 100 != 0) || i % 400 == 0);
	/* add days of full months */
	for( i = tim->tm_mon - 2; i >= 0; i -- )
		days += mday_array[i];
	/* add day in leapyear after February */
	if( tim->tm_mon > 1 )
		days += ((year % 4 == 0 && year % 100 != 0) || year % 400 == 0);
	/* add days in the current month */
	days += tim->tm_mday - 1;
	return
		days * 86400 + tim->tm_hour * 3600 + tim->tm_min * 60 + tim->tm_sec
			- (tim->tm_gmtoff / 100) * 3600 + (tim->tm_gmtoff % 100) * 60;
}

int get_week_number( my_vdatetime_t *tim, int dayoffset, int iso ) {
	int weeknum, offset;
	int year = tim->tm_year + 1900;
	int yday = tim->tm_yday + 1;
	int wd0101 = tim->tm_wday - (tim->tm_yday % 7);
	if( wd0101 < 0 )
		wd0101 += 7;
	else if( wd0101 > 6 )
		wd0101 -= 7;
	if( iso ) {
		if( dayoffset ) {
			if( wd0101 == 0 )
				wd0101 = 6;
			else
				wd0101 --;
		}
		weeknum = ( yday + wd0101 - 1 ) / 7;
		if( wd0101 < 4 )
			return weeknum + 1;
		if( weeknum != 0 )
			return weeknum;
		year --;
		wd0101 -= ((year % 4 == 0 && year % 100 != 0) || year % 400 == 0) + 1;
		if( dayoffset ) {
			if( wd0101 == 0 )
				wd0101 = 6;
			else
				wd0101 --;
		}
		return (wd0101 < 4) ? 53 : 52;
	}
	offset = 7 + 1 - wd0101 + dayoffset;
	if( offset == 8 )
		offset = 1;
	return (yday - offset + 7) / 7;
}

int get_iso8601_year( my_vdatetime_t *tim, int full ) {
	int year = tim->tm_year - 100;
	int wd0101 = tim->tm_wday - (tim->tm_yday % 7);
	if( wd0101 < 0 )
		wd0101 += 7;
	else if( wd0101 > 6 )
		wd0101 -= 7;
	if( wd0101 == 0 )
		wd0101 = 6;
	else
		wd0101--;
	if( wd0101 >= 4 )
		year--;
	if( full )
		return year + 2000;
	if( year < 0 )
		return year + 100;
	while( year > 100 )
		year -= 100;
	return year;
}

int is_short_year( my_vdatetime_t *tim ) {
	int y = tim->tm_year + 1900;
	y = y + y / 4 - y / 100 + y / 400;
	if( (y % 7) == 4 )
		return 0;
	if( ((y - 1) % 7) == 3 )
		return 0;
	return 1;
}

/*
strtime..
almost posix compatible
*/

int _int_strftime( tv, str, maxlen, format, stime )
	my_thread_var_t *tv;
	char *str;
	size_t maxlen;
	const char *format;
	my_vdatetime_t *stime;
{
	int val, l;
	char *ret, *ml, ch;
	const char *sval;
	time_t uval;
	if( str == NULL || format == NULL )
		return 0;
	if( stime == NULL )
		stime = apply_timezone( tv, 0 );

	ml = str + maxlen;
	ret = str;
	while( ret < ml ) {
		if( (ch = *format++) != '%' ) {
			if( ch == '\0' )
				goto exit;
			*ret++ = ch;
			continue;
		}
		if( ret >= ml )
			goto exit;
		switch( (ch = *format++) ) {
		case '\0':
			*ret++ = '%';
			goto exit;
		case '%':
			*ret++ = '%';
			break;
		case 'I':
			val = stime->tm_hour;
			if( val == 0 )
				val = 12;
			else if( val > 12 )
				val -= 12;
			goto setval_2digits;
		case 'H':
			val = stime->tm_hour;
			goto setval_2digits;
		case 'M':
			val = stime->tm_min;
			goto setval_2digits;
		case 'S':
			val = stime->tm_sec;
			goto setval_2digits;
		case 'm':
			val = stime->tm_mon + 1;
			goto setval_2digits;
		case 'd':
			val = stime->tm_mday;
			goto setval_2digits;
		case 'C':
			val = (1900 + stime->tm_year) / 100;
			while( val > 100 )
				val -= 100;
			goto setval_2digits;
		case 'g':
			val = get_iso8601_year( stime, 0 );
			goto setval_2digits;
		case 'U':
			val = get_week_number( stime, 0, 0 );
			goto setval_2digits;
		case 'V':
			val = get_week_number( stime, 1, 1 );
			goto setval_2digits;
		case 'W':
			val = get_week_number( stime, 1, 0 );
			goto setval_2digits;
		case 'y':
			val = stime->tm_year;
			while( val >= 100 )
				val -= 100;
setval_2digits:
			if( ret >= ml )
				goto exit;
			*ret ++= val >= 10 ? '0' + (val / 10) : '0';
			if( ret >= ml )
				goto exit;
			*ret ++= '0' + (val % 10);
			break;
		case 'e':
			val = stime->tm_mday;
			goto setval_2digits_space;
		case 'l':
			val = stime->tm_hour;
			if( val == 0 )
				val = 12;
			else
			if( val > 12 )
				val -= 12;
			goto setval_2digits_space;
		case 'k':
			val = stime->tm_hour;
setval_2digits_space:
			if( ret >= ml )
				goto exit;
			*ret ++= val >= 10 ? '0' + (val / 10) : ' ';
			if( ret >= ml )
				goto exit;
			*ret ++= '0' + (val % 10);
			break;
		case 'n':
			*ret ++ = '\n';
		case 't':
			*ret ++ = '\t';
			break;
		case 'a':
			sval = tv->locale.short_day_names[stime->tm_wday];
			goto setval_str;
		case 'A':
			sval = tv->locale.long_day_names[stime->tm_wday];
			goto setval_str;
		case 'b':
		case 'h':
			sval = tv->locale.short_month_names[stime->tm_mon];
			goto setval_str;
		case 'B':
			sval = tv->locale.long_month_names[stime->tm_mon];
			goto setval_str;
		case 'Z':
			sval = stime->tm_zone;
			goto setval_str;
		case 'p':
			if( stime->tm_hour >= 12 )
				sval = tv->locale.time_pm_upper;
			else
				sval = tv->locale.time_am_upper;
			goto setval_str;
		case 'P':
			if( stime->tm_hour >= 12 )
				sval = tv->locale.time_pm_lower;
			else
				sval = tv->locale.time_am_lower;
setval_str:
			while( 1 ) {
				if( ret >= ml )
					goto exit;
				if( *sval == '\0' )
					break;
				*ret ++ = *sval ++;
			}
			break;
		case 'G':
			val = get_iso8601_year( stime, 1 );
			if( ret >= ml - 3 )
				goto exit;
			ret = my_itoa( ret, val, 10 );
			break;
		case 'Y':
			val = stime->tm_year + 1900;
			if( ret >= ml - 3 )
				goto exit;
			ret = my_itoa( ret, val, 10 );
			break;
		case 'w':
			if( ret >= ml )
				goto exit;
			ret = my_itoa( ret, stime->tm_wday, 10 );
			break;
		case 'u':
			if( ret >= ml )
				goto exit;
			ret = my_itoa(
				ret, stime->tm_wday == 0 ? 7 : stime->tm_wday, 10 );
			break;
		case 'j':
			if( ret >= ml - 2 )
				goto exit;
			my_itoa( ret, stime->tm_yday + 1, 10 );
			if( ! ret[1] ) {
				ret[2] = ret[0];
				ret[0] = ret[1] = '0';
			}
			else if( ! ret[2] ) {
				ret[2] = ret[1];
				ret[1] = ret[0];
				ret[0] = '0';
			}
			ret += 3;
			break;
		case 'o':
		case 'O':
			if( ret >= ml - 6 )
				goto exit;
			val = stime->tm_gmtoff;
			val = (val / 100) * 3600 + (val % 100) * 60;
			ret = my_itoa( ret, val, 10 );
			break;
		case 'z':
			if( ret >= ml - 5 )
				goto exit;
			val = stime->tm_gmtoff;
			if( val < 0 ) {
				*ret ++ = '-';
				val *= -1;
			}
			else if( val == 0 ) {
				FASTSTRCPY( ret, "+0000" );
				break;
			}
			else
				*ret ++ = '+';
			if( val < 1000 )
				*ret ++ = '0';
			ret = my_itoa( ret, val, 10 );
			break;
		case 's':
			if( ret >= ml - 10 )
				goto exit;
			uval = seconds_since_epoch( stime );
			l = sprintf( ret, "%lu", uval );
			ret += l;
			break;
		case 'D':
			l = _int_strftime( tv, ret, ml - ret, "%m/%d/%y", stime );
			ret += l;
			break;
		case 'F':
			l = _int_strftime( tv, ret, ml - ret, "%Y-%m-%d", stime );
			ret += l;
			break;
		case 'R':
			l = _int_strftime( tv, ret, ml - ret, "%H:%M", stime );
			ret += l;
			break;
		case 'T':
			l = _int_strftime( tv, ret, ml - ret, "%H:%M:%S", stime );
			ret += l;
			break;
		case 'r':
			l = _int_strftime( tv, ret, ml - ret, tv->locale.ampm_format, stime );
			ret += l;
			break;
		case 'x':
			l = _int_strftime( tv, ret, ml - ret, tv->locale.date_format, stime );
			ret += l;
			break;
		case 'X':
			l = _int_strftime(
				tv, ret, ml - ret, tv->locale.time_format, stime );
			ret += l;
			break;
		case 'v':
			l = _int_strftime( tv, ret, ml - ret, "%e-%b-%Y", stime );
			ret += l;
			break;
		case 'c':
		case '+':
			l = _int_strftime(
				tv, ret, ml - ret, tv->locale.datetime_format, stime );
			ret += l;
			break;
		default:
			*ret++ = '%';
			if( ret >= ml )
				goto exit;
			*ret++ = ch;
		}
	}
exit:
	*ret = '\0';
	return (int) (ret - str);
}

/*
strfmon..
almost posix compatible
*/

size_t _int_strfmon(
	my_thread_var_t *tv,
	char *str,
	size_t maxsize,
	const char *format,
	...
) {
	my_locale_t *loc = &tv->locale;
	int step = 0, grouping = 0, plus = 0, currency = 0, justify = 0, width;
	int swp = 0, lpp = 0, rpp = 0, lprec, rprec, j, fmt;
	size_t fml, i;
	char *ret, chf, *ml, fill = 0, swidth[16], slprec[16], srprec[16];
	char *cptr, *cpt2;
	double darg;
	va_list ap;
	va_start( ap, format );
	fml = strlen( format );
	ml = str + maxsize;
	ret = str;
	for( i = 0; i < fml && ret < ml; i ++ ) {
		chf = format[i];
		switch( step ) {
		case 0:
			if( chf == '%' ) {
				grouping = 1;
				plus = 0;
				currency = 1;
				justify = 2;
				swp = lpp = rpp = 0;
				fmt = 0;
				step = 1;
				fill = ' ';
			}
			else {
				*ret ++ = chf;
			}
			break;
		case 1:
			switch( chf ) {
			case '%':
				*ret ++ = '%';
				break;
			case '=':
				if( i ++ >= fml - 1 ) break;
				fill = format[i];
				break;
			case '^':
				grouping = 0;
				break;
			case '+':
				plus = 1;
				break;
			case '(':
				plus = 2;
				break;
			case '!':
				currency = 0;
				break;
			case '-':
				justify = 1;
				break;
			case '#':
				step = 2;
				break;
			case '.':
				step = 3;
				break;
			case 'n':
				fmt = 1;
				goto calcmon;
			case 'i':
				fmt = 2;
				goto calcmon;
			case '0': case '1': case '2': case '3': case '4':
			case '5': case '6': case '7': case '8': case '9':
				if( swp < sizeof( swidth ) )
					swidth[swp ++] = chf;
				break;
			default:
				*ret ++ = '%';
				if( ret >= ml ) goto exit;
				*ret ++ = chf;
				break;
			}
			break;
		case 2: /* left precision */
			switch( chf ) {
			case '0': case '1': case '2': case '3': case '4':
			case '5': case '6': case '7': case '8': case '9':
				if( lpp < sizeof( slprec ) )
					slprec[lpp ++] = chf;
				break;
			default:
				step = 1;
				i --;
				break;
			}
			break;
		case 3: /* right precision */
			switch( chf ) {
			case '0': case '1': case '2': case '3': case '4':
			case '5': case '6': case '7': case '8': case '9':
				if( rpp < sizeof( srprec ) )
					srprec[rpp ++] = chf;
				break;
			default:
				step = 1;
				i --;
				break;
			}
			break;
		}
		continue;
calcmon:
		if( swp > 0 ) {
			swidth[swp] = '\0';
			width = atoi( swidth );
		}
		else
			width = 0;
		if( lpp > 0 ) {
			slprec[lpp] = '\0';
			lprec = atoi( slprec );
		}
		else
			lprec = 0;
		if( rpp > 0 ) {
			srprec[rpp] = '\0';
			rprec = atoi( srprec );
		}
		else
			rprec = ( fmt == 1 ) ? loc->frac_digits : loc->int_frac_digits;
		darg = va_arg( ap, double );
		cptr = ret;
		if( darg < 0 ) {
			if( plus == 2 )
				*cptr ++ = '(';
			else
				*cptr ++ = loc->negative_sign;
		}
		else if( plus == 1 )
			*cptr ++ = loc->positive_sign;
		else if( plus == 2 || (currency && lprec > 0) )
			*cptr ++ = ' ';
		if( currency ) {
			if( fmt == 1 ) {
				if( loc->curr_symb_align == 'l' )
					for( j = 0; loc->currency_symbol[j] != '\0'; j ++ )
						*cptr ++ = loc->currency_symbol[j];
			}
			else {
				if( loc->curr_symb_align == 'l' ) {
					for( j = 0; loc->int_curr_symbol[j] != '\0'; j ++ )
						*cptr ++ = loc->int_curr_symbol[j];
					*cptr ++ = ' ';
				}
			}
		}
		cptr = _int_number_format2(
			darg < 0 ? -darg : darg,
			cptr,
			rprec,
			loc->decimal_point,
			grouping ? loc->thousands_sep : '\0',
			loc->grouping,
			'\0',
			'\0',
			lprec,
			fill
		);
		if( currency ) {
			if( fmt == 1 ) {
				if( loc->curr_symb_align == 'r' ) {
					*cptr ++ = ' ';
					for( j = 0; loc->currency_symbol[j] != '\0'; j ++ )
						*cptr ++ = loc->currency_symbol[j];
				}
			}
			else {
				if( loc->curr_symb_align == 'r' ) {
					*cptr ++ = ' ';
					for( j = 0; loc->int_curr_symbol[j] != '\0'; j ++ )
						*cptr ++ = loc->int_curr_symbol[j];
				}
			}
		}
		if( width > cptr - ret ) {
			if( justify == 2 ) {
				cpt2 = ret + width;
				while( cptr >= ret )
					*cpt2 -- = *cptr --;
				while( cpt2 >= ret )
					*cpt2 -- = fill;
				ret += width;
			}
			else {
				ret += width;
				while( cptr < ret )
					*cptr ++ = fill;
			}
		}
		else
			ret = cptr;
		if( plus == 2 ) {
			if( darg < 0 )
				*ret ++ = ')';
			else
				*ret ++ = ' ';
		}
		step = 0;
	}
exit:
	va_end( ap );
	*ret = '\0';
	return (size_t) ( ret - str );
}

int parse_timezone( my_cxt_t *cxt, const char *tz, my_vtimezone_t *vtz ) {

	char zfile[256], str[256], *key, *val, *val2, *key2;
	char *key3, *val3;
	PerlIO *pfile;
	int level = 0, itmp2, vzip;
	size_t len;
	
	my_vzoneinfo_t *vzi = 0;
	my_weekdaynum_t *wdn;
	if( vtz == 0 ) return 0;
	len = strlen( tz );
	key = my_strncpy( zfile, cxt->zoneinfo_path, cxt->zoneinfo_path_length );
	key = my_strncpy( key, tz, len );
	key = my_strncpy( key, ".ics", 4 );
	pfile = PerlIO_open( zfile, "r" );
	if( ! pfile ) {
		Perl_croak( aTHX_ "Timezone not found: %s", tz );
		return 0;
	}
	Copy( tz, vtz->id, len, char );
	while( PerlIO_fgets( str, sizeof( str ), pfile ) ) {
		val = strchr( str, ':' );
		if( ! val ) continue;
		*val ++ = 0;
		key = str;
		switch( level ) {
		case 0: /* ROOT */
			if( strcmp( key, "BEGIN" ) == 0 ) {
				if( strcmp( val, "VTIMEZONE" ) == 0 ) {
					level = 1;
					continue;
				}
			}
			break;
		case 1: /* VTIMEZONE */
			if( strcmp( key, "END" ) == 0 ) {
				if( strcmp( val, "VTIMEZONE" ) == 0 ) {
					level = 0;
					continue;
				}
			}
			if( strcmp( key, "BEGIN" ) == 0 ) {
				level = 2;
				vzip = strcmp( val, "DAYLIGHT" ) == 0 ? 1 : 0;
				vzi = &vtz->zoneinfo[vzip];
				vzi->isdst = vzip;
				continue;
			}
			break;
		case 2: /* DAYLIGHT/STANDARD */
			if( strcmp( key, "END" ) == 0 ) {
				if( strcmp( val, "DAYLIGHT" ) == 0
					|| strcmp( val, "STANDARD" ) == 0
				) {
					level = 1;
					continue;
				}
			}
			if( strcmp( key, "TZOFFSETTO" ) == 0 ) {
				vzi->tzoffsetto = atoi( val );
			}
			else if( strcmp( key, "TZNAME" ) == 0 ) {
				len = strlen( val );
				Copy( val, vzi->tzname, len, char );
			}
			else if( strcmp( key, "DTSTART" ) == 0 ) {
				parse_vdatetime( val, &vzi->dtstart );
			}
			else if( strcmp( key, "RRULE" ) == 0 ) {
				while( 1 ) {
					key = strchr( val, ';' );
					if( key ) *key = 0;
					val2 = strchr( val, '=' );
					if( ! val2 ) break;
					*val2 ++ = 0;
					key2 = val;
					if( strcmp( key2, "FREQ" ) == 0 ) {
						if( strcmp( val2, "YEARLY" ) == 0 )
							vzi->rr_frequency = 1;
						else if( strcmp( val2, "MONTHLY" ) == 0 )
							vzi->rr_frequency = 2;
						else if( strcmp( val2, "WEEKLY" ) == 0 )
							vzi->rr_frequency = 3;
						else if( strcmp( val2, "DAILY" ) == 0 )
							vzi->rr_frequency = 4;
						else if( strcmp( val2, "HOURLY" ) == 0 )
							vzi->rr_frequency = 5;
						else if( strcmp( val2, "MINUTELY" ) == 0 )
							vzi->rr_frequency = 6;
						else if( strcmp( val2, "SECONDLY" ) == 0 )
							vzi->rr_frequency = 7;
					}
					else if( strcmp( key2, "BYMONTH" ) == 0 ) {
						while( 1 ) {
							val3 = strchr( val2, ',' );
							if( val3 ) *val3 = 0;
							vzi->rr_bymonth[atoi( val2 ) - 1] = 1;
							if( ! val3 ) break;
							val2 = val3 + 1;
						}
					}
					else if( strcmp( key2, "BYDAY" ) == 0 ) {
						while( 1 ) {
							val3 = strchr( val2, ',' );
							if( val3 ) *val3 = 0;
							wdn = &vzi->rr_byday;
							if( val2[0] == '-' || val2[0] == '+' )
								itmp2 = strlen( val2 ) == 5 ? 3 : 2; 
							else if( val2[0] >= '0' && val2[0] <= '9' )
								itmp2 = strlen( val2 ) == 4 ? 2 : 1;
							else
								itmp2 = 0;
							key3 = val2 + itmp2;
							wdn->day = WKDAY_TO_NUM( key3 );
							if( itmp2 ) {
								val2[itmp2] = 0;
								wdn->ordwk = atoi( val2 );
							}
							if( ! val3 ) break;
							val2 = val3 + 1;
						}
					}
					else {
						/*printf( "Unknown item: %s -> %s\n", key2, val2 );*/
					}
					if( ! key ) break;
					val = key + 1;
				}
			}
			break;
		}
	}
	PerlIO_close( pfile );
	return 1;
}

void parse_vdatetime( const char *str, my_vdatetime_t *tms ) {
	char stmp[5];
	const char *val = str;
	memcpy( stmp, val, 4 );
	stmp[4] = 0;
	tms->tm_year = atoi( stmp ) - 1900;
	val = &val[4];
	memcpy( stmp, val, 2 );
	stmp[2] = 0;
	tms->tm_mon = atoi( stmp ) - 1;
	val = &val[2];
	memcpy( stmp, val, 2 );
	stmp[2] = 0;
	tms->tm_mday = atoi( stmp );
	if( strlen( str ) > 8 ) {
		val = &val[3];
		memcpy( stmp, val, 2 );
		stmp[2] = 0;
		tms->tm_hour = atoi( stmp );
		val = &val[2];
		memcpy( stmp, val, 2 );
		stmp[2] = 0;
		tms->tm_min = atoi( stmp );
		val = &val[2];
		memcpy( stmp, val, 2 );
		stmp[2] = 0;
		tms->tm_sec = atoi( stmp );
	}
	else {
		tms->tm_hour = tms->tm_min = tms->tm_sec = -1;
	}
}

my_vdatetime_t *apply_timezone( my_thread_var_t *tv, time_t *timer ) {

	my_vtimezone_t *vtz;
	my_vzoneinfo_t *vzi;
	my_vdatetime_t *vdt;
	my_weekdaynum_t *vwdn;
	time_t tt1, tt2, tt3;
	my_vdatetime_t *tim, tmz[2], *ctmz1, *ctmz2;
	int i, leapyear, year, tmz_pos = 0;
	long days1, days2, days, wday, mday;

	if( timer == 0 ) {
		tt1 = time( 0 );
		timer = &tt1;
	}
	vtz = &tv->timezone;
	copy_tm_to_vdatetime( gmtime( timer ), &tv->time_struct );
	tim = &tv->time_struct;
	tim->tm_gmtoff = 0;
	tim->tm_zone = DEFAULT_ZONE;
	if( vtz == 0 || vtz->id[0] == 0 ) {
		return tim;
	}

	year = tim->tm_year + 1900;
	days = 0;
	for( i = 1970; i < year; i ++ )
		days += ((i % 4 == 0 && i % 100 != 0) || i % 400 == 0) + 365;
	leapyear = ((year % 4 == 0 && year % 100 != 0) || year % 400 == 0);

	for( tmz_pos = 0; tmz_pos < 2; tmz_pos ++ ) {
		vzi = &vtz->zoneinfo[tmz_pos];
		ctmz1 = &tmz[tmz_pos];
		vdt = &vzi->dtstart;
		ctmz1->tm_mon = vdt->tm_mon;
		ctmz1->tm_mday = vdt->tm_mday;
		ctmz1->tm_hour = vdt->tm_hour;
		ctmz1->tm_min = vdt->tm_min;
		ctmz1->tm_sec = vdt->tm_sec;
		ctmz1->tm_isdst = vzi->isdst;
		ctmz1->tm_gmtoff = vzi->tzoffsetto;
		ctmz1->tm_zone = vzi->tzname;
		switch( vzi->rr_frequency ) {
		case 0:
			break;
		case 1: /* FREQ::YEARLY */
			/* BYMONTH */
			days1 = days;
			for( i = 0; i < 12; i ++ ) {
				mday = ( i == 1 && leapyear ) ? 29 : mday_array[i];
				days2 = days1 + mday - 1;
				if( ! vzi->rr_bymonth[i] || tim->tm_mon < i )
				    goto rrbymonthnext;
				ctmz1->tm_mon = i;
				/* BYDAY */
				vwdn = &vzi->rr_byday;
				if( vwdn ) {
					if( vwdn->ordwk < 0 ) {
						wday = ( days2 % 7 ) + 4;
						if( wday > 6 ) wday -= 7;
						while( wday != vwdn->day ) {
							mday --;
							wday --;
							if( wday < 0 ) wday = 6;
						}
						if( vwdn->ordwk < -1 )
							mday += ( vwdn->ordwk + 1 ) * 7;
					}
					else {
						wday = ( days1 % 7 ) + 4;
						if( wday > 6 ) wday -= 7;
						if( vwdn->day < wday )
							mday = 1 + vwdn->day + 7 - wday;
						else
							mday = 1 + vwdn->day - wday;
						if( vwdn->ordwk > 1 )
							mday += ( vwdn->ordwk - 1 ) * 7;
					}
					ctmz1->tm_mday = mday;
					break;
				}
rrbymonthnext:
				days1 = days2 + 1;
			}
			break;
		}
	}
	if( tmz_pos < 2 ) ctmz1 = &tmz[0];
	else {
		if( tmz[0].tm_mon < tmz[1].tm_mon ) {
			ctmz1 = &tmz[0];
			ctmz2 = &tmz[1];
		}
		else {
			ctmz1 = &tmz[1];
			ctmz2 = &tmz[0];
		}
		tt1 = ctmz1->tm_sec + ctmz1->tm_min * 60 + ctmz1->tm_hour * 3600
			+ ctmz1->tm_mday * 86400 + ctmz1->tm_mon * 2678400;
		tt2 = ctmz2->tm_sec + ctmz2->tm_min * 60 + ctmz2->tm_hour * 3600
			+ ctmz2->tm_mday * 86400 + ctmz2->tm_mon * 2678400;
		tt3 = tim->tm_sec + tim->tm_min * 60 + tim->tm_hour * 3600
			+ tim->tm_mday * 86400 + tim->tm_mon * 2678400;
		if( tt3 < tt1 || tt3 > tt2 ) goto usetmz2;
		goto calczone;
usetmz2:
		ctmz1 = ctmz2;
	}
calczone:
	tim->tm_gmtoff = ctmz1->tm_gmtoff;
	tim->tm_zone = ctmz1->tm_zone;
	if( (i = tim->tm_gmtoff) == 0 )
		goto exit;
	tim->tm_min += i % 100;
	tim->tm_hour += i / 100;
	if( i < 0 ) {
		if( tim->tm_min < 0 ) {
			tim->tm_min += 60;
			tim->tm_hour --;
		}
		if( tim->tm_hour < 0 ) {
			tim->tm_hour += 24;
			tim->tm_mday --;
			tim->tm_yday --;
			if( tim->tm_wday == 0 )
				tim->tm_wday = 6;
			else
				tim->tm_wday --;
		}
		if( tim->tm_mday < 0 ) {
			if( tim->tm_mon == 0 ) {
				tim->tm_mon = 11;
				tim->tm_year --;
				tim->tm_yday = ((tim->tm_year % 4 == 0 && tim->tm_year % 100 != 0) || tim->tm_year % 400 == 0) + 364;
			}
			else {
				tim->tm_mon --;
			}
			tim->tm_mday = mday_array[tim->tm_mon];
		}
	}
	else {
		if( tim->tm_min > 59 ) {
			tim->tm_min -= 60;
			tim->tm_hour ++;
		}
		if( tim->tm_hour > 23 ) {
			tim->tm_hour -= 24;
			tim->tm_mday ++;
			tim->tm_yday ++;
			if( tim->tm_wday == 6 )
				tim->tm_wday = 0;
			else
				tim->tm_wday ++;
		}
		i = tim->tm_mon == 1
			&& ((tim->tm_year % 4 == 0 && tim->tm_year % 100 != 0) || tim->tm_year % 400 == 0)
				? 29 : mday_array[tim->tm_mon];
		if( tim->tm_mday > i ) {
			if( tim->tm_mon == 11 ) {
				tim->tm_mon = 0;
				tim->tm_year ++;
				tim->tm_yday = 0;
			}
			else
				tim->tm_mon ++;
			tim->tm_mday = 1;
		}
	}
exit:
	return tim;
}

char *_int_number_format2( double val, char *str, int fd, char dp,
	char ts, const char *grp, char ns, char ps, int zf, char fc
) {
	long a, b, i;
	char *s1, *s2, *s3;
	
	// round to fractional digits
	if( val < 0 ) {
		*str ++ = ns == 0 ? '-' : ns;
		val = my_round( -val, fd );
	}
	else {
		if( ps )
			*str ++ = ps;
		val = my_round( val, fd );
	}
	// get integer part
	a = (long) val;
	// zero fill
	if( zf != 0 ) {
		// calc length of integer value
		for( b = a, i = 1; b > 10; b /= 10, i ++ );
		// fill zero char
		if( fc == 0 )
			fc = ' ';
		for( i = zf - i; i > 0; *str ++ = fc, i -- );
	}
	// convert integer part to string
	s1 = my_itoa( str, a, 10 );
	// group digits
	if( ts != 0 && *grp > 0 ) {
		// count group chars
		s3 = (char *) grp;
		for( s2 = s1 - 1, i = *s3, b = 0; i != -1; s3 ++, i = *s3, b ++ ) {
			if( i == -2 )
				s3 --, i = *s3;
			s2 -= i;
			if( s2 < str )
				break;
		}
		// write group chars
		s2 = s1 - 1, s1 = s1 + b, s3 = s1 - 1;
		for( i = *grp; i != -1 && b > 0; grp ++, i = *grp, b -- ) {
			if( i == -2 )
				grp --, i = *grp;
			for( ; i > 0; *s3 -- = *s2 --, i -- );
			*s3 -- = ts;
		}
	}
	// write fractional digits
	if( fd > 0 ) {
		*s1 ++ = dp == 0 ? '.' : dp;
		b = (long) pow( 10, fd );
		a = (long) floor( (val - a) * (double) b + 0.5 );
		if( a > 0 ) {
			for( b /= 10; a < b; *s1 ++ = '0', b /= 10, fd -- );
			s2 = my_itoa( s1, a, 10 );
			fd -= s2 - s1, s1 = s2;
		}
		for( ; fd > 0; *s1 ++ = '0', fd -- );
	}
	*s1 = '\0';
	return s1;
}

/* original by Will Bateman (March 2005) / GPL License */

char *_int_number_format( double value, char *str, int maxlen, int fd, char dp,
	char ts, char ns, char ps, int zf, char fc
) {
	long i, j, count, k;
	double val;
	long a, b;
	char *number, *tmp, *p2;
	
	assert( fd >= 0 );
	assert( fd <= 19 );
	if( ns == 0 )
		ns = '-';
	if( dp == 0 )
		dp = ',';
	number = str;
	if( value < 0 ) {
		*number ++ = ns;
		val = my_round( -value, fd );
	}
	else {
		if( ps ) *number ++ = ps;
		val = my_round( value, fd );
	}
	
	a = (int) floor( val );
	if( zf > 0 ) {
		b = a;
		j = 1;
		while( b > 10 ) {
			b /= 10;
			j ++;
		}
		tmp = number;
		if( ( j = zf - j ) > 0 ) {
			if( fc == 0 ) fc = '0';
			while( j -- )
				*tmp ++ = fc;
		}
		p2 = tmp;
		tmp = my_itoa( tmp, a, 10 );
	}
	else {
		p2 = str;
		tmp = my_itoa( number, a, 10 );
	}
	
	if( ts != 0 ) {
		i = (long) (tmp - str - (str[0] == ns || ps != 0));
		j = ( i - 1 ) / 3;
		for( k = i + j, count = -1; k >= 0 && j > 0; k --, count ++ ) {
			if( count == 3 ) {
				number[k] = number + k > p2 ? ts : fc;
				j --;
				k --;
				count = 0;
				tmp ++;
			}
			number[k] = number[k - j];
		}
	}
	
	if( fd > 0 ) {
		*tmp ++ = dp;
		
		j = (long) pow( 10.0, fd );
		a = (long) floor( (val - a) * (double) j + 0.5 );
		
		if( a > 0 ) {
			j /= 10;
			while( a < j ) {
				*tmp ++ = '0';
				j /= 10;
			}
			tmp = my_itoa( tmp, a, 10 );
		}
		else {
			j = fd;
			while( j > 0 ) {
				*tmp ++ = '0';
				j --;
			}
		}
	}
	*tmp = '\0';
	
	return tmp;
}

DWORD get_current_thread_id() {
#ifdef USE_ITHREADS
#ifdef _WIN32
	return GetCurrentThreadId();
#else
	return (DWORD) pthread_self();
#endif
#else
	return 0;
#endif
}

const double ROUND_PREC[] = {
	1, 10, 1e2, 1e3, 1e4, 1e5, 1e6, 1e7, 1e8, 1e9, 1e10, 1e11, 1e12
	, 1e13, 1e14, 1e15, 1e16, 1e17, 1e18, 1e19
};
const int ROUND_PREC_MAX = 1 + (int) ARRAY_LEN( ROUND_PREC );

double my_round( double num, int prec ) {
	if( prec > ROUND_PREC_MAX )
		prec = ROUND_PREC_MAX;
	else
	if( prec < 0 )
		prec = 0;
	return floor( num * ROUND_PREC[prec] + 0.5 ) / ROUND_PREC[prec];
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
	register signed char res;
	while( 1 ) {
		if( (res = toupper( *cs ) - toupper( *ct ++ )) != 0 || ! *cs ++ )
			break;
	}
	return res;
}

char *_my_itoa( register char *str, long value, int radix ) {
	int rem = (int) (value % radix);
	value /= radix;
	/* output digits of val/base first */
	if( value > 0 )
		str = _my_itoa( str, value, radix );
	/* output last digit */
	*str++ = "0123456789abcdefghijklmnopqrstuvwxyz"[rem];
	return str;
}

char *my_itoa( register char *str, long value, int radix ) {
	if( radix > 36 || radix < 2 )
		radix = 10;
	if( value < 0 ) {
		*str++ = '-';
		value = -value;
	}
	str = _my_itoa( str, value, radix );
	*str = '\0';
	return str;
}

char *_my_ltoa( register char *str, XLONG value, int radix ) {
	int rem = (int) (value % radix);
	value /= radix;
	/* output digits of val/base first */
	if( value > 0 )
		str = _my_ltoa( str, value, radix );
	/* output last digit */
	*str++ = "0123456789abcdefghijklmnopqrstuvwxyz"[rem];
	return str;
}

char *my_ltoa( register char *str, XLONG value, int radix ) {
	if( radix > 36 || radix < 2 )
		radix = 10;
	if( value < 0 ) {
		*str++ = '-';
		value = -value;
	}
	str = _my_itoa( str, value, radix );
	*str = '\0';
	return str;
}
