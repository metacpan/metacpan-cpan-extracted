#ifndef __INCLUDE_MY_POSTGRES_H__
#define __INCLUDE_MY_POSTGRES_H__ 1

#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

//#include "ppport.h"

#include <libpq-fe.h>

#define __PACKAGE__ "PAB3::DB::Driver::Postgres"

#define	CLIENT_RECONNECT	16384

#define MYCF_TRANSACTION	1
#define MYCF_AUTOCOMMIT		2

#undef DWORD
#define DWORD unsigned long

#undef UPTR
#define UPTR void *

#undef HAS_UV64
#if UVSIZE == 8
#	define HAS_UV64 1
#endif

#undef XLONG
#undef UXLONG
#if defined __unix__
#	define XLONG long long
#	define UXLONG unsigned long long
#elif defined __WIN__
#	define XLONG __int64
#	define UXLONG unsigned __int64
#else
#	define XLONG long
#	define UXLONG unsigned long
#endif

#define MY_TYPE_CON		1
#define MY_TYPE_RES		2
#define MY_TYPE_STMT	3

typedef struct st_my_res {
	struct st_my_res			*prev, *next;
	struct st_my_con			*con;
	PGresult					*res;
	DWORD						numrows;
	DWORD						numfields;
	DWORD						rowpos;
	DWORD						fieldpos;
	struct st_my_stmt			*stmt;
	char						bound;
} MY_RES;

typedef struct st_my_stmt {
	struct st_my_stmt			*prev, *next;
	struct st_my_con			*con;
	char						*id;
	DWORD						param_count;
	char						**param_values;
	int							*param_lengths;
	int							*param_formats;
	char						*param_types;
	struct st_my_res			*res;
//	DWORD						affected_rows;
} MY_STMT;

typedef struct st_my_con {
	struct st_my_con			*prev, *next;
	PGconn						*con;
	DWORD						tid;
	char						*db;
	struct st_my_res			*firstres;
	struct st_my_res			*lastres;
	struct st_my_stmt			*first_stmt;
	struct st_my_stmt			*last_stmt;
	char						*charset;
	DWORD						charset_length;
	DWORD						my_flags;
	DWORD						client_flag;
	DWORD						affected_rows;
	char						my_error[256];
	DWORD						stmt_counter;
} MY_CON;

typedef struct st_my_cxt {
	MY_CON						*firstcon, *lastcon;
	char						lasterror[256];
} my_cxt_t;

#define MY_CXT_KEY __PACKAGE__ "::_guts" XS_VERSION

START_MY_CXT

#define STR_CREATEANDCOPYN( src, dst, len ) \
	if( (src) && (len) ) { \
		New( 1, (dst), (len) + 1, char ); \
		Copy( (src), (dst), (len) + 1, char ); \
	} \
	else { \
		(dst) = NULL; \
	}

#define STR_CREATEANDCOPY( src, dst ) \
	STR_CREATEANDCOPYN( (src), (dst), (src) ? strlen( (src) ) : 0 )

char *my_strcpy( char *dst, const char *src );
char *my_strcpyl( char *dst, const char *src );
char *my_strncpy( char *dst, const char *src, DWORD len );
int my_stricmp( const char *cs, const char *ct );
char *my_stristr( const char *str1, const char *str2 );
char *my_itoa( char *str, int value, int radix );
char *my_strtolower( char *a );
DWORD get_current_thread_id();

void my_cleanup( my_cxt_t *cxt );
void my_cleanup_session( my_cxt_t *cxt );
int my_get_type( my_cxt_t *cxt, UPTR *ptr );

MY_CON *my_con_add( my_cxt_t *cxt, PGconn *conn );
void my_con_cleanup( MY_CON *con );
void my_con_free( MY_CON *con );
void my_con_rem( my_cxt_t *cxt, MY_CON *con );
int my_con_exists( my_cxt_t *cxt, UPTR ptr );
MY_CON *my_con_find_by_tid( my_cxt_t *cxt, DWORD tid );
MY_CON *_my_con_verify( my_cxt_t *cxt, UPTR linkid, int error );
#define my_con_verify(cxt,linkid)	_my_con_verify( (cxt), (linkid), 1 )
#define my_con_verify_noerror(cxt,linkid)	_my_con_verify( (cxt), (linkid), 0 )

MY_RES *my_result_add( MY_CON *con, PGresult *pres );
void my_result_free( MY_RES *res );
void my_result_rem( MY_RES *res );
int my_result_exists( my_cxt_t *cxt, UPTR ptr );

char *my_stmt_convert( const char *sql, DWORD sqllen, DWORD *plen, DWORD *slen );
MY_STMT *my_stmt_add( MY_CON *con, char *stmtname, DWORD plen );
void my_stmt_free( MY_STMT *stmt );
void my_stmt_rem( MY_STMT *stmt );
int my_stmt_exists( my_cxt_t *cxt, UPTR ptr );
int my_stmt_or_result( my_cxt_t *cxt, UPTR ptr );
int my_stmt_or_con( my_cxt_t *cxt, UPTR *ptr );
int my_stmt_bind_param( MY_STMT *stmt, DWORD p_num, SV *val, char type );

#endif
