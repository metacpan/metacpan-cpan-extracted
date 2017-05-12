#ifndef __INC__MY_MYSQL_H__
#define __INC__MY_MYSQL_H__ 1

#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

//#include "ppport.h"

#include <mysql.h>

#define __PACKAGE__ "PAB3::DB::Driver::Mysql"

static const my_bool MYBOOL_TRUE	= 1;
static const my_bool MYBOOL_FALSE	= 0;

#define	CLIENT_RECONNECT	16384

#define MYCF_TRANSACTION	1
#define MYCF_AUTOCOMMIT		2

#define MY_TYPE_CON		1
#define MY_TYPE_RES		2
#define MY_TYPE_STMT	3

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
#elif defined _WIN32
#	define XLONG __int64
#	define UXLONG unsigned __int64
#else
#	define XLONG long
#	define UXLONG unsigned long
#endif


typedef struct st_my_con {
	struct st_my_con	*prev, *next;
	DWORD				tid;
	MYSQL				*conid;
	struct st_my_res	*res;
	struct st_my_res	*lastres;
	struct st_my_stmt	*first_stmt;
	struct st_my_stmt	*last_stmt;
	unsigned int		port;
	char				*charset;
	char				*host;
	char				*user;
	char				*passwd;
	char				*unix_socket;
	char				*db;
	DWORD				client_flag;
	DWORD				my_flags;
	DWORD				charset_length;
	char				my_error[256];
} MY_CON;

typedef struct st_my_stmt {
	struct st_my_stmt	*prev, *next;
	MYSQL_STMT			*stmt;
	MYSQL_BIND			*params;
	char				*param_types;
	DWORD				param_count;
	MYSQL_BIND			*result;
	DWORD				field_count;
	MYSQL_RES			*meta;
	MY_CON				*con;
	DWORD				exec_count;
	XLONG				rowpos;
	XLONG				numrows;
} MY_STMT;

typedef struct st_my_res {
	struct st_my_res	*prev, *next;
	MYSQL_RES			*res;
	MY_CON				*con;
	XLONG				rowpos;
	XLONG				numrows;
} MY_RES;

#define MY_CXT_KEY __PACKAGE__ "::_guts" XS_VERSION

typedef struct st_my_cxt {
	MY_CON				*con;
	MY_CON				*lastcon;
	char				lasterror[256];
	unsigned int		lasterrno;
#ifdef USE_THREADS
	//perl_mutex			thread_lock;
#endif
} my_cxt_t;

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

char *my_strncpy( char *dst, const char *src, size_t len );
char *my_strcpy( char *dst, const char *src );
char *my_itoa( char *str, long value, int radix );
char *my_ltoa( char *str, XLONG value, int radix );

//DWORD my_crc32( const char *str, DWORD len );
DWORD get_current_thread_id();
void my_set_error( my_cxt_t *cxt, const char *tpl, ... );

#define my_verify_linkid(cxt,linkid) \
	_my_verify_linkid( (cxt), (linkid), 1 )
#define my_verify_linkid_noerror(cxt,linkid) \
	_my_verify_linkid( (cxt), (linkid), 0 )
UPTR _my_verify_linkid( my_cxt_t *cxt, UPTR linkid, int error );

int my_mysql_get_type( my_cxt_t *cxt, UPTR *ptr );

void my_mysql_cleanup( my_cxt_t *cxt );
void my_mysql_cleanup_connections( my_cxt_t *cxt );
int my_mysql_reconnect( MY_CON *con );

MY_CON *my_mysql_con_add( my_cxt_t *cxt, MYSQL *mysql, DWORD client_flag );
void my_mysql_con_rem( my_cxt_t *cxt, MY_CON *con );
MY_CON *my_mysql_con_find_by_tid( my_cxt_t *cxt, DWORD tid );
void my_mysql_con_free( MY_CON *con );
void my_mysql_con_cleanup( MY_CON *con );
int my_mysql_con_exists( my_cxt_t *cxt, MY_CON *con );

MY_RES *my_mysql_res_add( MY_CON *con, MYSQL_RES *res );
void my_mysql_res_rem( MY_RES *res );
int my_mysql_res_exists( my_cxt_t *cxt, MY_RES *res );

MY_STMT *my_mysql_stmt_init( MY_CON *con, const char *query, size_t length );
void my_mysql_stmt_free( MY_STMT *stmt );
int my_mysql_stmt_exists( my_cxt_t *cxt, MY_STMT *stmt );
void my_mysql_stmt_rem( MY_STMT *stmt );
int my_mysql_stmt_or_res( my_cxt_t *cxt, UPTR ptr );
int my_mysql_stmt_or_con( my_cxt_t *cxt, UPTR *ptr );

int my_mysql_bind_param( MY_STMT *stmt, DWORD p_num, SV *val, char type );
void my_mysql_bind_free( MYSQL_BIND *bind );

int my_mysql_handle_return( MY_CON *con, long ret );

#endif
