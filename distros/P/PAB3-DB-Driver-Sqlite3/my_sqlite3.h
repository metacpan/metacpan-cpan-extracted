#ifndef __INCLUDE_MY_SQLITE3_H__
#define __INCLUDE_MY_SQLITE3_H__ 1

#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

//#include "ppport.h"

#include <sqlite3.h>

#define __PACKAGE__ "PAB3::DB::Driver::Sqlite3"

#undef DWORD
#define DWORD unsigned long

#undef UPTR
#define UPTR void *

#undef HAS_UV64
#if UVSIZE == 8
#	define HAS_UV64 1
#endif

#define MYCF_TRANSACTION	1
#define MYCF_AUTOCOMMIT		2

#define MY_TYPE_CON		1
#define MY_TYPE_RES		2
#define MY_TYPE_STMT	3

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

typedef char **MY_ROW;

typedef struct st_my_rows {
	struct st_my_rows	*prev, *next;
	MY_ROW				data;
	DWORD				*lengths;
	char				*types;
} MY_ROWS;

typedef struct st_my_field {
	char				*name;
	DWORD				name_length;
} MY_FIELD;

typedef struct st_my_res {
	struct st_my_res	*prev, *next;
	MY_ROWS				*data_cursor;
	MY_ROWS				*current_row;
	struct st_my_con	*con;
	MY_FIELD			*fields;
	DWORD				numrows, numfields, rowpos, fieldpos;
	int					is_valid;
	struct st_my_stmt	*stmt;
} MY_RES;

typedef struct st_my_stmt {
	struct st_my_stmt	*prev, *next;
	struct st_my_con	*con;
	sqlite3_stmt		*stmt;
	DWORD				param_count;
	char				*param_types;
	MY_RES				*res;
//	DWORD				affected_rows;
} MY_STMT;

typedef struct st_my_con {
	struct st_my_con	*prev, *next;
	DWORD				tid;
	sqlite3				*con;
	char				*db;
	MY_RES				*firstres;
	MY_RES				*lastres;
	MY_STMT				*first_stmt;
	MY_STMT				*last_stmt;
	DWORD				my_flags;
	char				my_error[256];
	DWORD				affected_rows;
} MY_CON;

typedef struct st_my_cxt {
	MY_CON				*lastcon;
	MY_CON				*firstcon;
	char				last_error[256];
	int					last_errno;
#ifdef USE_THREADS
	//perl_mutex			share_lock;
#endif
} my_cxt_t;

#define MY_CXT_KEY __PACKAGE__ "::_guts" XS_VERSION

START_MY_CXT

//DWORD my_crc32( const char *str, DWORD len );
unsigned long get_current_thread_id();
char *my_strcpy( char *dst, const char *src );
int my_stricmp( const char *cs, const char *ct );
char *my_stristr( const char *str1, const char *str2 );
char *my_itoa( char *str, long value, int radix );
char *my_ltoa( char *str, XLONG value, int radix );

void my_init( my_cxt_t *cxt );
void my_cleanup( my_cxt_t *cxt );
void my_session_cleanup( my_cxt_t *cxt );

UPTR my_verify_linkid( my_cxt_t *cxt, UPTR linkid );
int my_get_type( my_cxt_t *cxt, UPTR *ptr );
void my_set_error( my_cxt_t *cxt, const char *tpl, ... );

MY_CON *my_con_add( my_cxt_t *cxt, sqlite3 *con, DWORD tid );
void my_con_rem( my_cxt_t *cxt, MY_CON *con );
void my_con_free( MY_CON *con );
int my_con_exists( my_cxt_t *cxt, MY_CON *con );
MY_CON *my_con_find_by_tid( my_cxt_t *cxt, DWORD tid );
void my_con_cleanup( MY_CON *con );

int my_callback( void *arg, int columns, char **data, char **names );

void my_result_free( MY_RES *res );
MY_RES *my_result_add( MY_CON *con );
void my_result_rem( MY_RES *res );
int my_result_exists( my_cxt_t *cxt, MY_RES *res );

MY_STMT *my_stmt_add( MY_CON *con, sqlite3_stmt *pStmt );
void my_stmt_rem( MY_STMT *stmt );
void my_stmt_free( MY_STMT *stmt );
int my_stmt_exists( my_cxt_t *cxt, UPTR ptr );
int my_stmt_bind_param( MY_STMT *stmt, int p_num, SV *val, char type );
int my_stmt_or_res( my_cxt_t *cxt, UPTR ptr );
int my_stmt_or_con( my_cxt_t *cxt, UPTR *ptr );

#endif
