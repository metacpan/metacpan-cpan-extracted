#ifndef __INCLUDE_MY_PAB3_H__
#define __INCLUDE_MY_PAB3_H__ 1

#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#define __PACKAGE__ "PAB3"

#define MY_CXT_KEY __PACKAGE__ "::_guts" XS_VERSION

#ifdef _WIN32
#undef vsnprintf
#define vsnprintf _vsnprintf
#else
#undef BYTE
#define BYTE unsigned char
#undef WORD
#define WORD unsigned short
#undef DWORD
#define DWORD unsigned long
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

#undef MAX
#define MAX(x,y) ( (x) < (y) ? (y) : (x) )
#undef MIN
#define MIN(x,y) ( (x) < (y) ? (x) : (y) )

#define PARSER_ITEM_TEXT		1
#define PARSER_ITEM_PRINT		2
#define PARSER_ITEM_DO			3
#define PARSER_ITEM_CON			4
#define PARSER_ITEM_ELCO		5
#define PARSER_ITEM_ELSE		6
#define PARSER_ITEM_ECON		7
#define PARSER_ITEM_LOOP		8
#define PARSER_ITEM_ASIS		9
#define PARSER_ITEM_SUB			10
#define PARSER_ITEM_COMMENT		11
#define PARSER_ITEM_XX			12
#define PARSER_ITEM_ESUB		13
#define PARSER_ITEM_ELOOP		14

#define PAB_TYPE_NONE			0
#define PAB_TYPE_AUTO			0
#define PAB_TYPE_SCALAR			1
#define PAB_TYPE_ARRAY			2
#define PAB_TYPE_HASH			3
#define PAB_TYPE_FUNC			4

typedef struct st_my_parser_item {
	struct st_my_parser_item	*next;
	char						id;
	struct st_my_parser_item	*parent;
	struct st_my_parser_item	*child, *child_last;
	char						*content;
	size_t						content_length;
	int							row;
	char						*val1;
#define loopa1 val1
	size_t						len1;
#define loopa1_length len1
	char						*val2;
#define loopa2 val2
	size_t						len2;
#define loopa2_length len2
} my_parser_item_t;

typedef struct st_my_loop_def {
	struct st_my_loop_def		*prev, *next;
	char						*id;
	char						*source;
	size_t						source_length;
	char						source_type;
	char						*record;
	size_t						record_length;
	char						record_type;
	char						*object;
	size_t						object_length;
	char						*argv;
	size_t						argv_length;
	char						is_fixed;
} my_loop_def_t;

typedef struct st_my_hashmap_def {
	struct st_my_hashmap_def	*prev, *next;
	char						*loopid;
	char						*record;
	size_t						record_length;
	char						**fields;
	DWORD						field_count;
} my_hashmap_def_t;

typedef struct st_my_parser_session {
	char						file[256];
	int							row;
	int							column;
	my_parser_item_t			*last_parent;
	my_parser_item_t			**ppi;
	char						*output;
	size_t						output_length;
	char						*curout;
	size_t						output_pos;
	DWORD						script_counter;
} my_parser_session_t;

typedef struct st_my_thread_var {
	struct st_my_thread_var		*prev, *next;
	SV							*id;
	char						*prg_start;
	BYTE						prg_start_length;
	char						*prg_end;
	BYTE						prg_end_length;
	char						*cmd_sep;
	BYTE						cmd_sep_length;
	char						*path_template;
	WORD						path_template_length;
	char						*path_cache;
	WORD						path_cache_length;
	char						*class_name;
	WORD						class_name_length;
	char						*default_record;
	WORD						default_record_length;
	my_parser_item_t			*root_item;
	char						last_error[256];
	SV							*sv1;
	STRLEN						lsv1;
	char						*str1;
	my_loop_def_t				*first_loop;
	my_loop_def_t				*last_loop;
	my_hashmap_def_t			*first_hm;
	my_hashmap_def_t			*last_hm;
	my_parser_session_t			parser;
} my_thread_var_t;

typedef struct st_my_cxt {
	my_thread_var_t				*first_thread;
	my_thread_var_t				*last_thread;
} my_cxt_t;


START_MY_CXT

static const my_thread_var_t THREADVAR_DEFAULT = {
	NULL, NULL, NULL, "<*", 2, "*>", 2, ";;", 2, NULL, 0, NULL, 0,
	"$PAB3::_CURRENT", 15, "_", 1, NULL, "", NULL, 0, NULL,
	NULL, NULL, NULL, NULL,
	{ "", 0, 0, NULL, NULL, NULL, 0, NULL, 0, 0 }
};

#define ISWHITECHAR(ch) \
	( (ch) == 32 || (ch) == 10 || (ch) == 13 || (ch) == 9 || (ch) == 0 || (ch) == 11 )

//#define DEBUG 1
#ifdef DEBUG
#define _debug printf
#define my_strcpy(d,s) _my_strcpy_dbg( (d), (s), __FILE__, __LINE__ )
#else
#define _debug
#define my_strcpy(d,s) _my_strcpy( (d), (s) )
#endif

const char *my_stristr( const char *str, const char *pattern );
int my_stricmp( const char *cs, const char *ct );
char *my_strncpyu( char *dst, const char *src, size_t len );
char *_my_strcpy( char *dst, const char *src );
#ifdef DEBUG
char *_my_strcpy_dbg( char *dst, const char *src, const char *file, int line );
#endif
char *my_strncpy( char *dst, const char *src, size_t len );
char* my_itoa( char* str, long value, int radix );

my_thread_var_t *my_thread_var_add( my_cxt_t *cxt, SV *sv );
void my_thread_var_free( my_thread_var_t *tv );
void my_thread_var_rem( my_cxt_t *cxt, my_thread_var_t *tv );
my_thread_var_t *my_thread_var_find( my_cxt_t *cxt, SV *sv );

int my_set_error( my_thread_var_t *tv, const char *tpl, ... );
void set_var_str( char *str, size_t *str_len, char type );

my_loop_def_t *my_loop_def_add( my_thread_var_t *tv );
my_loop_def_t *my_loop_def_find_by_id( my_thread_var_t *tv, const char *id );
void my_loop_def_free( my_loop_def_t *ld );
void my_loop_def_rem( my_thread_var_t *tv, my_loop_def_t *ld );
void my_loop_def_cleanup( my_thread_var_t *tv );

my_hashmap_def_t *my_hashmap_add( my_thread_var_t *tv );
void my_hashmap_rem( my_thread_var_t *tv, my_hashmap_def_t *hd );
void my_hashmap_free( my_hashmap_def_t *hd );
void my_hashmap_cleanup( my_thread_var_t *tv );

int parse_template( my_thread_var_t *tv, const char *tpl, int len, int setpath );
void my_parser_session_cleanup( my_thread_var_t *tv );
void my_parser_item_cleanup( my_thread_var_t *tv );
void my_parser_item_free( my_parser_item_t *pi );

int map_parsed( my_thread_var_t *tv, my_parser_item_t *parent, int level );
int build_script( my_thread_var_t *tv );
void optimize_script( my_thread_var_t *tv, my_parser_item_t *parent );

#ifdef DEBUG

#undef New
#undef Newz
#undef Newx
#undef Newxz
#undef Renew
#undef Safefree
#undef Copy

#define New(x,v,n,t) \
	v = (t *) safemalloc( (size_t)((n) * sizeof(t)) ); \
	_debug( "0x%08x New(%u x %u) called at %s:%d\n", v, (n), sizeof(t), __FILE__, __LINE__ );

#define Newz(x,v,n,t) \
{ \
	v = (t *) safemalloc( (size_t)((n) * sizeof(t)) ); \
	Zero( (v), (n), t ); \
	_debug( "0x%08x Newz(%u x %u) called at %s:%d\n", v, (n), sizeof(t), __FILE__, __LINE__ ); \
}

#define Newx(v,n,t) \
	v = (t *) safemalloc( (size_t)((n) * sizeof(t)) ); \
	_debug( "0x%08x Newx(%u x %u) called at %s:%d\n", v, (n), sizeof(t), __FILE__, __LINE__ );

#define Newxz(v,n,t) \
{ \
	v = (t *) safemalloc( (size_t)((n) * sizeof(t)) ); \
	Zero( (v), (n), t ); \
	_debug( "0x%08x Newxz(%u x %u) called at %s:%d\n", v, (n), sizeof(t), __FILE__, __LINE__ ); \
}

#define Renew(v,n,t) \
	v = (t *) saferealloc( (Malloc_t)(v), (size_t)((n) * sizeof(t)) ); \
	_debug( "0x%08x Renew(%u x %u) called at %s:%d\n", v, (n), sizeof(t), __FILE__, __LINE__ );

#define Safefree(d) \
	if( (d) != NULL ) { \
		_debug( "0x%08x Safefree called at %s:%d\n", (d), __FILE__, __LINE__ ); \
		safefree( (Malloc_t)(d) ); \
	}

#define Copy(s,d,n,t) \
	memcpy( (char *)(d), (const char *)(s), (n) * sizeof(t) ); \
	_debug( "0x%08x Copy %u x %u from 0x%08x at %s:%d\n", (d), (n), sizeof(t), (s), __FILE__, __LINE__ );

#endif

#endif
