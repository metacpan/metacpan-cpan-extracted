#ifndef __INCLUDE_MY_UTILS_H__
#define __INCLUDE_MY_UTILS_H__ 1

#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#define __PACKAGE__ "PAB3::Utils"

#undef DWORD
#define DWORD unsigned int

#undef HAS_UV64
#if UVSIZE == 8
#	define HAS_UV64 1
#endif

#undef XLONG
#undef UXLONG
#if defined __GNUC__ || defined __unix__ || defined __CYGWIN__ || defined __sun
#	define XLONG long long
#	define UXLONG unsigned long long
#elif defined _WIN32
#	define XLONG __int64
#	define UXLONG unsigned __int64
#else
#	define XLONG long
#	define UXLONG unsigned long
#endif

typedef struct st_my_vdatetime {
	int tm_sec;				/* Seconds.	[0-60] (1 leap second) */
	int tm_min;				/* Minutes.	[0-59] */
	int tm_hour;			/* Hours.	[0-23] */
	int tm_mday;			/* Day.		[1-31] */
	int tm_mon;				/* Month.	[0-11] */
	int tm_year;			/* Year	- 1900.  */
    int tm_wday;    		/* days since Sunday    [0-6] */
    int tm_yday;    		/* days since January 1 [0-365] */
    int tm_isdst;   		/* daylight savings time flag */
	long tm_gmtoff;			/* Seconds east of UTC */
	const char *tm_zone;	/* Timezone abbreviation */
} my_vdatetime_t;

typedef struct st_my_weekdaynum {
	int ordwk, day;
} my_weekdaynum_t;

typedef struct st_my_vzoneinfo {
	int					tzoffsetto;
	char				tzname[6];
	my_vdatetime_t 		dtstart;
	int					isdst;
	int					rr_frequency;
	int					rr_bymonth[12];
	my_weekdaynum_t		rr_byday;
} my_vzoneinfo_t;

typedef struct st_my_vtimezone {
	my_vzoneinfo_t		zoneinfo[2];
	char				id[32];
} my_vtimezone_t;

typedef struct st_my_locale {
	char		name[16];
	char		decimal_point;
	char		thousands_sep;
	char		grouping[4];
	char		frac_digits;
	char		int_frac_digits;
	char		currency_symbol[7];
	char		int_curr_symbol[7];
	char		curr_symb_align;
	char		curr_symb_space;
	char		negative_sign;
	char		positive_sign;
	char		date_format[16];
	char		time_format[16];
	char		datetime_format[32];
	char		ampm_format[16];
	char		time_am_upper[16];
	char		time_pm_upper[16];
	char		time_am_lower[16];
	char		time_pm_lower[16];
	char		short_month_names[12][7];
	char		long_month_names[12][32];
	char		short_day_names[7][7];
	char		long_day_names[7][32];
} my_locale_t;

typedef struct st_my_locale_alias {
	struct st_my_locale_alias	*next;
	char						*alias;
	char						*locale;
} my_locale_alias_t;

typedef struct st_my_thread_var {
	struct st_my_thread_var		*prev, *next;
	UV							tid;
	my_locale_t					locale;
	my_vtimezone_t				timezone;
	my_vdatetime_t				time_struct;
} my_thread_var_t;

//#define MY_CXT_KEY __PACKAGE__ "::_guts" XS_VERSION

#ifndef MAX_PATH
#define MAX_PATH 512
#endif

#undef START_MY_CXT
#undef MY_CXT_INIT
#undef MY_CXT
#undef dMY_CXT
#undef pMY_CXT
#undef aMY_CXT
#undef MY_CXT_CLONE

#define START_MY_CXT my_cxt_t my_cxtp;
#define EXPORT_MY_CXT extern my_cxt_t my_cxtp;
#define MY_CXT my_cxtp
#define dMY_CXT dNOOP
#define pMY_CXT void
#define aMY_CXT
#define MY_CXT_INIT \
	Zero( &MY_CXT, 1, my_cxt_t )
#define MY_CXT_CLONE

typedef struct st_my_cxt {
	char						state;
	char						locale_path[MAX_PATH]; 
	char						zoneinfo_path[MAX_PATH]; 
	int							locale_path_length;
	int							zoneinfo_path_length;
	my_thread_var_t				*threads;
	my_thread_var_t				*last_thread;
	my_locale_alias_t			*locale_alias;
	int							locale_alias_count;
#ifdef USE_ITHREADS
	perl_mutex					thread_lock;
	PerlInterpreter				*perl;
#endif
} my_cxt_t;

EXPORT_MY_CXT

#ifdef USE_ITHREADS
#define MY_CXT_LOCK \
	MUTEX_LOCK( &MY_CXT.thread_lock )
#define MY_CXT_UNLOCK \
	MUTEX_UNLOCK( &MY_CXT.thread_lock )
#else
#define MY_CXT_LOCK
#define MY_CXT_UNLOCK
#endif

#define FASTSTRCPY(dst,src) \
	do { \
		register const char *__src = (src); \
		register char *__dst = (dst); \
		for( ; *__src != '\0'; *__dst ++ = *__src ++ ); \
		(dst) = __dst; \
	} while( 0 )

#define ISWHITECHAR(ch) \
	( (ch) == 32 || (ch) == 10 || (ch) == 13 || (ch) == 9 || (ch) == 0 \
	|| (ch) == 11 )

#define WKDAY_TO_NUM( wkd ) ( \
	( (wkd)[0] == 'S' && (wkd)[1] == 'U' ) ? 0 : \
	( (wkd)[0] == 'M' && (wkd)[1] == 'O' ) ? 1 : \
	( (wkd)[0] == 'T' && (wkd)[1] == 'U' ) ? 2 : \
	( (wkd)[0] == 'W' && (wkd)[1] == 'E' ) ? 3 : \
	( (wkd)[0] == 'T' && (wkd)[1] == 'H' ) ? 4 : \
	( (wkd)[0] == 'F' && (wkd)[1] == 'R' ) ? 5 : \
	( (wkd)[0] == 'S' && (wkd)[1] == 'A' ) ? 6 : \
	-1 )

#define ARRAY_LEN(x) ( sizeof( (x) ) / sizeof( (x)[0] ) )

extern const double ROUND_PREC[];
extern const int ROUND_PREC_MAX;

extern const my_locale_t DEFAULT_LOCALE;
extern const char *DEFAULT_ZONE;

char *PerlIO_fgets( char *buf, size_t max, PerlIO *stream );

char *my_strncpy( char *dst, const char *src, size_t len );
char *my_strcpy( char *dst, const char *src );
int my_stricmp( const char *cs, const char *ct );
char *my_itoa( char* str, long value, int radix );
char *my_ltoa( char* str, XLONG value, int radix );

DWORD get_current_thread_id();

#define find_or_create_tv(cxt,tv,tid) \
	if( (cxt)->state > 0 ) { \
		MY_CXT_LOCK; \
		if( ! ((tv) = find_thread_var( (cxt), (tid) )) ) \
			(tv) = create_thread_var( (cxt), (tid) ); \
		MY_CXT_UNLOCK; \
	} \
	else { \
		(tv) = NULL; \
	}

my_thread_var_t *find_thread_var( my_cxt_t *cxt, UV tid );
my_thread_var_t *create_thread_var( my_cxt_t *cxt, UV tid );
void remove_thread_var( my_cxt_t *cxt, my_thread_var_t *tv );
void cleanup_my_utils( my_cxt_t *cxt );

void copy_tm_to_vdatetime( struct tm *src, my_vdatetime_t *dst );
void free_locale_alias( my_cxt_t *cxt );
void read_locale_alias( my_cxt_t *cxt );
const char *get_locale_format_settings(
	my_cxt_t *cxt, const char *id, my_locale_t *locale
);
int _int_strftime(
	my_thread_var_t *tv, char *str, size_t maxlen, const char *format,
	my_vdatetime_t *stime
);
size_t _int_strfmon(
	my_thread_var_t *tv, char *str, size_t maxsize, const char *format, ...
);
int parse_timezone( my_cxt_t *cxt, const char *tz, my_vtimezone_t *vtz );
#define read_timezone parse_timezone
my_vdatetime_t *apply_timezone( my_thread_var_t *tv, time_t *timer );
char *_int_number_format2( double val, char *str, int fd, char dp,
	char ts, const char *grp, char ns, char ps, int zf, char fc
);
char *_int_number_format(
	double value, char *str, int maxlen, int fd, char dp, char ts, char ns,
	char ps, int zf, char fc
);
double my_round( double num, int prec );

#endif
