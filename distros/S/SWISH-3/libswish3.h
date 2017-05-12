/*
 * This file is part of libswish3
 * Copyright (C) 2007 Peter Karman
 *
 *  libswish3 is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  libswish3 is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with libswish3; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */


#ifndef __LIBSWISH3_H__
#define __LIBSWISH3_H__

#ifndef LIBSWISH3_SINGLE_FILE
#include <sys/types.h>
#include <stdint.h>
#include <inttypes.h>
#include <sys/stat.h>
#include <time.h>
#include <libxml/parser.h>
#include <libxml/hash.h>
#include <libxml/xmlstring.h>
#endif

#define SWISH_LIB_VERSION           VERSION
#define SWISH_VERSION               "3.0.0"
#define SWISH_BUFFER_CHUNK_SIZE     16384
#define SWISH_TOKEN_LIST_SIZE       1024
#define SWISH_MAXSTRLEN             2048
#define SWISH_MAX_HEADERS           6
#define SWISH_RD_BUFFER_SIZE        65536   // used ??
#define SWISH_MAX_WORD_LEN          256
#define SWISH_MIN_WORD_LEN          1
#define SWISH_STACK_SIZE            255  /* starting size for metaname/tag stack */
#define SWISH_CONTRACTIONS          1
#define SWISH_SPECIAL_ARG           1
#define SWISH_MAX_SORT_STRING_LEN   100
#define SWISH_TRUE                  1
#define SWISH_FALSE                 0

#define SWISH_DATE_FORMAT_STRING    "%Y-%m-%d %H:%M:%S %Z"
#define SWISH_URL_LENGTH            255

/* default config hash key names */
#define SWISH_HEADER_ROOT           "swish"
#define SWISH_INCLUDE_FILE          "IncludeConfigFile"
#define SWISH_CLASS_ATTRIBUTES      "XMLClassAttributes"
#define SWISH_PROP                  "PropertyNames"
#define SWISH_META                  "MetaNames"
#define SWISH_MIME                  "MIME"
#define SWISH_PARSERS               "Parsers"
#define SWISH_INDEX                 "Index"
#define SWISH_ALIAS                 "TagAlias"
#define SWISH_WORDS                 "Words"
#define SWISH_DEFAULT_PARSER        "default"
#define SWISH_PARSER_TXT            "TXT"
#define SWISH_PARSER_XML            "XML"
#define SWISH_PARSER_HTML           "HTML"
#define SWISH_DEFAULT_PARSER_TYPE   "HTML"
#define SWISH_INDEX_FORMAT          "Format"
#define SWISH_INDEX_NAME            "Name"
#define SWISH_INDEX_LOCALE          "Locale"
#define SWISH_INDEX_STEMMER_LANG    "Stemmer"
#define SWISH_DEFAULT_VALUE         "1"
#define SWISH_TOKENIZE              "Tokenize"
#define SWISH_CASCADE_META_CONTEXT  "CascadeMetaContext"
#define SWISH_IGNORE_XMLNS          "IgnoreXMLNameSpaces"
#define SWISH_FOLLOW_XINCLUDE       "FollowXInclude"
#define SWISH_UNDEFINED_METATAGS    "UndefinedMetaTags"
#define SWISH_UNDEFINED_XML_ATTRIBUTES "UndefinedXMLAttributes"

/* tags */
#define SWISH_DEFAULT_METANAME    "swishdefault"
#define SWISH_TITLE_METANAME      "swishtitle"
#define SWISH_TITLE_TAG           "title"
#define SWISH_BODY_TAG            "body"

/* mimes */
#define SWISH_DEFAULT_MIME        "text/html"

/* indexes */
#define SWISH_INDEX_FILENAME      "index.swish"
#define SWISH_XAPIAN_FORMAT       "Xapian"
#define SWISH_SWISH_FORMAT        "Native"
#define SWISH_ESTRAIER_FORMAT     "Estraier"
#define SWISH_KINOSEARCH_FORMAT   "KinoSearch"
#define SWISH_LUCY_FORMAT         "Lucy"
#define SWISH_INDEX_FILEFORMAT    "Native"
#define SWISH_HEADER_FILE         "swish.xml"

/* properties */
#define SWISH_PROP_STRING          1
#define SWISH_PROP_DATE            2
#define SWISH_PROP_INT             3

#define SWISH_PROP_RECCNT          "swishreccount"
#define SWISH_PROP_RANK            "swishrank"
#define SWISH_PROP_DOCID           "swishfilenum"
#define SWISH_PROP_DOCPATH         "swishdocpath"
#define SWISH_PROP_DBFILE          "swishdbfile"
#define SWISH_PROP_TITLE           "swishtitle"
#define SWISH_PROP_SIZE            "swishdocsize"
#define SWISH_PROP_MTIME           "swishlastmodified"
#define SWISH_PROP_DESCRIPTION     "swishdescription"
#define SWISH_PROP_MIME            "swishmime"
#define SWISH_PROP_PARSER          "swishparser"
#define SWISH_PROP_NWORDS          "swishwordnum"
#define SWISH_PROP_ENCODING        "swishencoding"
#define SWISH_TOKENPOS_BUMPER      "\3"
#define SWISH_DOT                  '.'
#define SWISH_SPACE                ' '
#define SWISH_DOM_CHAR             '/'
#define SWISH_DOM_STR              "/"
#define SWISH_XMLNS_CHAR           ':'

/* error codes */
typedef enum {
    SWISH_ERR_NO_SUCH_FILE = 1
} SWISH_ERR_CODES;

/* built-in id values */
typedef enum {
    SWISH_META_DEFAULT_ID = 0,
    SWISH_META_TITLE_ID,
    SWISH_META_THIS_MUST_COME_LAST_ID
} SWISH_META_ID;

/* special since not stored */
#define SWISH_PROP_RANK_ID  -1
typedef enum {
    SWISH_PROP_DOCID_ID = 0,
    SWISH_PROP_DOCPATH_ID,
    SWISH_PROP_DBFILE_ID,
    SWISH_PROP_TITLE_ID,
    SWISH_PROP_SIZE_ID,
    SWISH_PROP_MTIME_ID,
    SWISH_PROP_DESCRIPTION_ID,
    SWISH_PROP_NWORDS_ID,
    SWISH_PROP_MIME_ID,
    SWISH_PROP_PARSER_ID,
    SWISH_PROP_ENCODING_ID,
    SWISH_PROP_THIS_MUST_COME_LAST_ID
} SWISH_PROP_ID;

/* parser settings for undefined tags and attributes */
typedef enum {
    SWISH_UNDEF_METAS_INDEX = 0,    /* default */
    SWISH_UNDEF_METAS_ERROR,
    SWISH_UNDEF_METAS_IGNORE,
    SWISH_UNDEF_METAS_AUTO,
    SWISH_UNDEF_METAS_AUTOALL,
    SWISH_UNDEF_ATTRS_DISABLE,      /* default */
    SWISH_UNDEF_ATTRS_ERROR,
    SWISH_UNDEF_ATTRS_IGNORE,
    SWISH_UNDEF_ATTRS_INDEX,
    SWISH_UNDEF_ATTRS_AUTO,
    SWISH_UNDEF_ATTRS_AUTOALL
} SWISH_UNDEF;

/* xapian (maybe others) need string prefixes for metanames */
#define SWISH_PREFIX_URL            "U"
#define SWISH_PREFIX_MTIME          "T"


/* utils */
#define SWISH_MAX_WORD_LEN        256
#define SWISH_MAX_FILE_LEN        102400000 /* ~100 mb */

#if defined(WIN32) && !defined (__CYGWIN__)
#define SWISH_PATH_SEP             '\\'
#define SWISH_PATH_SEP_STR         "\\"
#define SWISH_EXT_SEP              "\\."
#else
#define SWISH_PATH_SEP             '/'
#define SWISH_PATH_SEP_STR         "/"
#define SWISH_EXT_SEP              "/."
#endif

#define SWISH_EXT_CH               '.'

/* encodings */
#define SWISH_DEFAULT_ENCODING    "UTF-8"
#define SWISH_LATIN1_ENCODING     "ISO8859-1"
#define SWISH_LOCALE              "en_US.UTF-8"
#define SWISH_ENCODING_ERROR      100

/* debugging levels */
typedef enum {
    SWISH_DEBUG_DOCINFO     = 1,
    SWISH_DEBUG_TOKENIZER   = 2,
    SWISH_DEBUG_TOKENLIST   = 4,
    SWISH_DEBUG_PARSER      = 8,
    SWISH_DEBUG_CONFIG      = 16,
    SWISH_DEBUG_MEMORY      = 32,
    SWISH_DEBUG_NAMEDBUFFER = 64,
    SWISH_DEBUG_IO          = 128
} SWISH_DEBUG_LEVELS;

/* the FUNCTION__ logic below first appeared in Perl 5.8.8
 * mostly it is for Win32 compat
 */
#ifndef FUNCTION__
#if (defined(__STDC_VERSION__) && __STDC_VERSION__ >= 199901L) || (defined(__SUNPRO_C))
/* C99 or close enough. */
#  define FUNCTION__ __func__
#else
#  if (defined(_MSC_VER) && _MSC_VER < 1300) || /* Pre-MSVC 7.0 has neither __func__ nor
 __FUNCTION and no good workarounds, either. */ \
      (defined(__DECC_VER)) /* Tru64 or VMS, and strict C89 being used, but not modern e
nough cc (in Tur64, -c99 not known, only -std1). */
#    define FUNCTION__ ""
#  else
#    define FUNCTION__ __FUNCTION__ /* Common extension. */
#  endif
#endif
#endif

#define SWISH_DEBUG_MSG(args...)                                    \
    swish_debug(__FILE__, __LINE__, FUNCTION__, args)

#define SWISH_CROAK(args...)                                        \
    swish_croak(__FILE__, __LINE__, FUNCTION__, args)

#define SWISH_WARN(args...)                                         \
    swish_warn(__FILE__, __LINE__, FUNCTION__, args)

#ifdef __cplusplus
extern "C" {
#endif

typedef char   boolean;
typedef struct swish_3                  swish_3;
typedef struct swish_StringList         swish_StringList;
typedef struct swish_Config             swish_Config;
typedef struct swish_ConfigFlags        swish_ConfigFlags;
typedef struct swish_ConfigValue        swish_ConfigValue;
typedef struct swish_DocInfo            swish_DocInfo;
typedef struct swish_MetaStackElement   swish_MetaStackElement;
typedef struct swish_MetaStackElement  *swish_MetaStackElementPtr;
typedef struct swish_MetaStack          swish_MetaStack;
typedef struct swish_MetaName           swish_MetaName;
typedef struct swish_Property           swish_Property;
typedef struct swish_Token              swish_Token;
typedef struct swish_TokenList          swish_TokenList;
typedef struct swish_TokenIterator      swish_TokenIterator;
typedef struct swish_ParserData         swish_ParserData;
typedef struct swish_Tag                swish_Tag;
typedef struct swish_TagStack           swish_TagStack;
typedef struct swish_Analyzer           swish_Analyzer;
typedef struct swish_Parser             swish_Parser;
typedef struct swish_NamedBuffer        swish_NamedBuffer;

/*
=head2 Data Structures
*/

struct swish_3
{
    int             ref_cnt;
    void           *stash;
    swish_Config   *config;
    swish_Analyzer *analyzer;
    swish_Parser   *parser;
};

struct swish_StringList
{
    unsigned int    n;
    unsigned int    max;
    xmlChar**       word;
};


struct swish_Config
{
    int                          ref_cnt;
    void                        *stash;      /* for bindings */
    xmlHashTablePtr              misc;
    xmlHashTablePtr              properties;
    xmlHashTablePtr              metanames;
    xmlHashTablePtr              tag_aliases;
    xmlHashTablePtr              parsers;
    xmlHashTablePtr              mimes;
    xmlHashTablePtr              index;
    xmlHashTablePtr              stringlists;
    struct swish_ConfigFlags    *flags;      /* shortcuts for parsing */
};

struct swish_ConfigFlags
{
    boolean         tokenize;
    boolean         cascade_meta_context;
    boolean         ignore_xmlns;
    boolean         follow_xinclude;
    int             undef_metas;
    int             undef_attrs;
    int             max_meta_id;
    int             max_prop_id;
    xmlHashTablePtr meta_ids;
    xmlHashTablePtr prop_ids;
    //xmlHashTablePtr contexts;
};

struct swish_NamedBuffer
{
    int             ref_cnt;    /* for bindings */
    void           *stash;      /* for bindings */
    xmlHashTablePtr hash;       /* the meat */
};

struct swish_DocInfo
{
    time_t              mtime;
    off_t               size;
    xmlChar *           mime;
    xmlChar *           encoding;
    xmlChar *           uri;
    unsigned int        nwords;
    xmlChar *           ext;
    xmlChar *           parser;
    xmlChar *           action;
    boolean             is_gzipped;
    int                 ref_cnt;
};

struct swish_MetaName
{
    int                 ref_cnt;
    int                 id;
    xmlChar            *name;
    int                 bias;
    xmlChar            *alias_for;
};

struct swish_Property
{
    int                 ref_cnt;
    int                 id;
    xmlChar            *name;
    boolean             ignore_case;
    int                 type;
    boolean             verbatim;
    xmlChar            *alias_for;
    unsigned int        max;
    boolean             sort;
    boolean             presort;
    unsigned int        sort_length;
};

struct swish_Token
{
    unsigned int        pos;            // this token's position in document
    swish_MetaName     *meta;
    xmlChar            *value;
    xmlChar            *context;
    unsigned int        offset;
    unsigned int        len;
    int                 ref_cnt;
};

struct swish_TokenList
{
    unsigned int        n;
    unsigned int        pos;            // track position in document
    xmlHashTablePtr     contexts;       // cache contexts
    xmlBufferPtr        buf;
    swish_Token**       tokens;
    int                 ref_cnt;
};

struct swish_TokenIterator
{
    swish_TokenList     *tl;
    swish_Analyzer      *a;
    unsigned int         pos;           // position in iteration
    int                  ref_cnt;
};

struct swish_Tag
{
    xmlChar            *raw;            // tag as libxml2 sees it
    xmlChar            *baked;          // tag as libswish3 sees it
    xmlChar            *context;
    struct swish_Tag   *next;
    unsigned int        n;
};

struct swish_TagStack
{
    swish_Tag         *head;
    swish_Tag         *temp;
    unsigned int       count;
    char              *name;       // debugging aid -- name of the stack
};

struct swish_Analyzer
{
    unsigned int           maxwordlen;         // max word length
    unsigned int           minwordlen;         // min word length
    boolean                tokenize;           // should we parse into TokenList
    int                  (*tokenizer) (swish_TokenIterator*, xmlChar*, swish_MetaName*, xmlChar*);
    xmlChar*             (*stemmer)   (xmlChar*);
    boolean                lc;                 // should tokens be lowercased
    void                  *stash;              // for script bindings
    void                  *regex;              // optional regex
    int                    ref_cnt;            // for script bindings
};

struct swish_Parser
{
    int                    ref_cnt;             // for script bindings
    void                 (*handler)(swish_ParserData*); // handler reference
    void                  *stash;               // for script bindings
    int                    verbosity;           
};

struct swish_ParserData
{
    swish_3               *s3;                 // main object
    xmlBufferPtr           meta_buf;           // tmp MetaName buffer
    xmlBufferPtr           prop_buf;           // tmp Property buffer
    xmlChar               *tag;                // current tag name
    swish_DocInfo         *docinfo;            // document-specific properties
    unsigned int           ignore_content;     // toggle flag. should buffer be indexed.
    boolean                is_html;            // shortcut flag for html parser
    boolean                bump_word;          // boolean for moving word position/adding space
    unsigned int           offset;             // current offset position
    swish_TagStack        *metastack;          // stacks for tracking the tag => metaname
    swish_TagStack        *propstack;          // stacks for tracking the tag => property
    swish_TagStack        *domstack;           // stacks for tracking xml/html dom tree
    xmlParserCtxtPtr       ctxt;               // so we can free at end
    swish_TokenIterator   *token_iterator;     // token container
    swish_NamedBuffer     *properties;         // buffer all properties
    swish_NamedBuffer     *metanames;          // buffer all metanames
};

/*
=cut
*/

/*
=head2 Global Functions
*/
void            swish_setup();
const char *    swish_lib_version();
const char *    swish_libxml2_version();
void            swish_setenv(char * name, char * value, int override);
/*
=cut
*/

/*
=head2 Top-Level Functions
*/
swish_3 *       swish_3_init( void (*handler) (swish_ParserData *), void *stash );
void            swish_3_free( swish_3 *s3 );
int             swish_parse_file( swish_3 * s3, xmlChar *filename );
unsigned int    swish_parse_fh( swish_3 * s3, FILE * fh );
int             swish_parse_buffer( swish_3 * s3, xmlChar * buf );
unsigned int    swish_parse_directory( swish_3 *s3, xmlChar *dir, boolean follow_symlinks );
/*
=cut
*/

/*
=head2 I/O Functions
*/
xmlChar *   swish_io_slurp_fh( FILE * fh, unsigned long flen, boolean binmode );
xmlChar *   swish_io_slurp_file_len( xmlChar *filename, off_t flen, boolean binmode );
xmlChar *   swish_io_slurp_gzfile_len( xmlChar *filename, off_t *flen, boolean binmode );
xmlChar *   swish_io_slurp_file( xmlChar *filename, off_t flen, boolean is_gzipped, boolean binmode );
long int    swish_io_count_operable_file_lines( xmlChar *filename );
boolean     swish_io_is_skippable_line( xmlChar *str );
/*
=cut
*/

/*
=head2 Filesystem Functions
*/
boolean     swish_fs_file_exists( xmlChar *filename );
boolean     swish_fs_is_dir( xmlChar *path );
boolean     swish_fs_is_file( xmlChar *path );
boolean     swish_fs_is_link( xmlChar *path );
off_t       swish_fs_get_file_size( xmlChar *path );
time_t      swish_fs_get_file_mtime( xmlChar *path );
xmlChar *   swish_fs_get_file_ext( xmlChar *url );
xmlChar *   swish_fs_get_path( xmlChar *url );
boolean     swish_fs_looks_like_gz( xmlChar *file );
/*
=cut
*/


/*
=head2 Hash Functions
*/
int         swish_hash_add( xmlHashTablePtr hash, xmlChar *key, void * value );
int         swish_hash_replace( xmlHashTablePtr hash, xmlChar *key, void *value );
int         swish_hash_delete( xmlHashTablePtr hash, xmlChar *key );
boolean     swish_hash_exists( xmlHashTablePtr hash, xmlChar *key );
int         swish_hash_exists_or_add( xmlHashTablePtr hash, xmlChar *key, xmlChar *value );
void        swish_hash_merge( xmlHashTablePtr hash1, xmlHashTablePtr hash2 );
void *      swish_hash_fetch( xmlHashTablePtr hash, xmlChar *key );
void        swish_hash_dump( xmlHashTablePtr hash, const char *label );
xmlHashTablePtr swish_hash_init(int size);
void        swish_hash_free( xmlHashTablePtr hash );
/*
=cut
*/

/*
=head2 Memory Functions
*/
void        swish_mem_init();
void *      swish_xrealloc(void *ptr, size_t size);
void *      swish_xmalloc( size_t size );
void        swish_xfree( void *ptr );
void        swish_mem_debug();
long int    swish_memcount_get();
void        swish_memcount_dec();
xmlChar *   swish_xstrdup( const xmlChar * ptr );
xmlChar *   swish_xstrndup( const xmlChar * ptr, int len );
/*
=cut
*/

/*
=head2 Time Functions
*/
double      swish_time_elapsed(void);
double      swish_time_cpu(void);
char *      swish_time_print(double time);
char *      swish_time_print_fine(double time);
char *      swish_time_format(time_t epoch);
/*
=cut
*/

/*
=head2 Error Functions
*/
void        swish_set_error_handle( FILE *where );
void        swish_croak(const char *file, int line, const char *func, const char *msg,...);
void        swish_warn(const char *file, int line, const char *func, const char *msg,...);
void        swish_debug(const char *file, int line, const char *func, const char *msg,...);
const char* swish_err_msg(int err_code);
/*
=cut
*/

/*
=head2 String Functions
*/
char *              swish_get_locale();
void                swish_verify_utf8_locale();
boolean             swish_is_ascii( xmlChar *str );
int                 swish_bytes_in_wchar( int wchar );
int                 swish_utf8_chr_len( xmlChar *utf8 );
uint32_t            swish_utf8_codepoint( xmlChar *utf8 );
int                 swish_utf8_num_chrs( xmlChar *utf8 );
void                swish_utf8_next_chr( xmlChar *s, int *i );
void                swish_utf8_prev_chr( xmlChar *s, int *i );
xmlChar *           swish_str_escape_utf8( xmlChar *utf8 );
xmlChar *           swish_str_unescape_utf8( xmlChar *ascii );
wchar_t *           swish_locale_to_wchar(xmlChar * str);
xmlChar *           swish_wchar_to_locale(wchar_t * str);
wchar_t *           swish_wstr_tolower(wchar_t *s);
xmlChar *           swish_str_tolower(xmlChar *s );
xmlChar *           swish_utf8_str_tolower(xmlChar *s);
xmlChar *           swish_ascii_str_tolower(xmlChar *s);
xmlChar *           swish_str_skip_ws(xmlChar *s);
void                swish_str_trim_ws(xmlChar *string);
void                swish_str_ctrl_to_ws(xmlChar *s);
boolean             swish_str_all_ws(xmlChar * s);
boolean             swish_str_all_ws_len(xmlChar * s, int len);
void                swish_debug_wchars( const wchar_t * widechars );
int                 swish_wchar_t_comp(const void *s1, const void *s2);
int                 swish_sort_wchar(wchar_t *s);
swish_StringList *  swish_stringlist_build(xmlChar *line);
swish_StringList *  swish_stringlist_init();
void                swish_stringlist_free(swish_StringList *sl);
unsigned int        swish_stringlist_add_string(swish_StringList *sl, xmlChar *str);
void                swish_stringlist_merge(swish_StringList *sl1, swish_StringList *sl2);
swish_StringList *  swish_stringlist_copy(swish_StringList *sl);
swish_StringList *  swish_stringlist_parse_sort_string(xmlChar *sort_string, swish_Config *cfg);
void                swish_stringlist_debug(swish_StringList *sl);
int                 swish_string_to_int( char *buf );
boolean             swish_string_to_boolean( char *buf );
xmlChar *           swish_int_to_string( int val );
xmlChar *           swish_long_to_string( long val );
xmlChar *           swish_double_to_string( double val );
xmlChar *           swish_date_to_string( int y, int m, int d );
char                swish_get_C_escaped_char(xmlChar *s, xmlChar **se);
/*
=cut
*/


/*
=head2 Configuration Functions
*/
swish_Config *      swish_config_init();
void                swish_config_set_default( swish_Config *config );
void                swish_config_merge( swish_Config *config1, swish_Config *config2 );
swish_Config *      swish_config_add( swish_Config * config, xmlChar * conf );
swish_Config *      swish_config_parse( swish_Config * config, xmlChar * conf );
void                swish_config_debug( swish_Config * config );
void                swish_config_free( swish_Config * config);
xmlHashTablePtr     swish_mime_defaults();
xmlChar *           swish_mime_get_type( swish_Config * config, xmlChar * fileext );
xmlChar *           swish_mime_get_parser( swish_Config * config, xmlChar *mime );
void                swish_config_test_alias_fors( swish_Config *c );
swish_ConfigFlags * swish_config_flags_init();
void                swish_config_flags_debug( swish_ConfigFlags *flags );
void                swish_config_flags_free( swish_ConfigFlags *flags );
void                swish_config_test_alias_fors( swish_Config *config );
void                swish_config_test_unique_ids( swish_Config *config );

/*
=cut
*/

/*
=head2 Parser Functions
*/
swish_Parser *  swish_parser_init( void (*handler) (swish_ParserData *) );
void            swish_parser_free( swish_Parser * parser );
/*
=cut
*/

/*
=head2 Token Functions 
*/
swish_TokenList *   swish_token_list_init();
void                swish_token_list_free( swish_TokenList *tl );
int                 swish_token_list_add_token(    
                                        swish_TokenList *tl, 
                                        xmlChar *token,
                                        int token_len,
                                        swish_MetaName *meta,
                                        xmlChar *context );
int                 swish_token_list_set_token(
                                        swish_TokenList *tl,
                                        xmlChar *token,
                                        int len );
swish_Token *       swish_token_init();
void                swish_token_free( swish_Token *t );
swish_TokenIterator *swish_token_iterator_init( swish_Analyzer *a );
void                swish_token_iterator_free( swish_TokenIterator *ti );
swish_Token *       swish_token_iterator_next_token( swish_TokenIterator *it );
int                 swish_tokenize(     swish_TokenIterator *ti, 
                                        xmlChar *buf, 
                                        swish_MetaName *meta,
                                        xmlChar *context );
int                 swish_tokenize_ascii(    
                                        swish_TokenIterator *ti, 
                                        xmlChar *buf, 
                                        swish_MetaName *meta,
                                        xmlChar *context );
int                 swish_tokenize_utf8(    
                                        swish_TokenIterator *ti, 
                                        xmlChar *buf, 
                                        swish_MetaName *meta,
                                        xmlChar *context );
void                swish_token_list_debug( swish_TokenIterator *it );
xmlChar *           swish_token_list_get_token_value( swish_TokenList *tl, swish_Token *t );
void                swish_token_debug( swish_Token *t );

/*
=cut
*/

/*
=head2 Analyzer Functions
*/
swish_Analyzer *    swish_analyzer_init( swish_Config * config );
void                swish_analyzer_free( swish_Analyzer * analyzer );
/*
=cut
*/

/*
=head2 DocInfo Functions
*/
swish_DocInfo *     swish_docinfo_init();
void                swish_docinfo_free( swish_DocInfo * ptr );
int                 swish_docinfo_check(swish_DocInfo * docinfo, swish_Config * config);
int                 swish_docinfo_from_filesystem(  xmlChar *filename, 
                                                    swish_DocInfo * i, 
                                                    swish_ParserData *parser_data );
void                swish_docinfo_debug( swish_DocInfo * docinfo );
/*
=cut
*/

/*
=head2 Buffer Functions
*/
swish_NamedBuffer * swish_nb_init( xmlHashTablePtr confhash );
void                swish_nb_free( swish_NamedBuffer *nb );
void                swish_nb_new( swish_NamedBuffer *nb, xmlChar *key );
void                swish_nb_debug( swish_NamedBuffer *nb, xmlChar *label );
void                swish_nb_add_buf( swish_NamedBuffer *nb, 
                                      xmlChar *name,
                                      xmlBufferPtr buf, 
                                      xmlChar *joiner,
                                      boolean cleanwsp,
                                      boolean autovivify);
void                swish_nb_add_str(   swish_NamedBuffer *nb, 
                                        xmlChar *name, 
                                        xmlChar *str,
                                        unsigned int len,
                                        xmlChar *joiner,
                                        boolean cleanwsp,
                                        boolean autovivify);
void                swish_buffer_append( xmlBufferPtr buf, xmlChar * txt, int len );
void                swish_buffer_concat( swish_NamedBuffer *nb1, swish_NamedBuffer *nb2 );
xmlChar*            swish_nb_get_value( swish_NamedBuffer* nb, xmlChar* key );
/*
=cut
*/

/*
=head2 Property Functions
*/
swish_Property *    swish_property_init( xmlChar *propname );
void                swish_property_new( xmlChar *name, swish_Config *config );
void                swish_property_free( swish_Property *prop );
void                swish_property_debug( swish_Property *prop );
int                 swish_property_get_builtin_id( xmlChar *propname );
int                 swish_property_get_id( xmlChar *propname, xmlHashTablePtr properties );
/*
=cut
*/

/*
=head2 MetaName Functions
*/
swish_MetaName *    swish_metaname_init( xmlChar *name);
void                swish_metaname_new( xmlChar *name, swish_Config *config );
void                swish_metaname_free( swish_MetaName *m );
void                swish_metaname_debug( swish_MetaName *m );
/*
=cut
*/

/*
=head2 Header Functions
*/
boolean             swish_header_validate(char *filename);
boolean             swish_header_merge(char *filename, swish_Config *c);
swish_Config *      swish_header_read(char *filename);
void                swish_header_write(char* filename, swish_Config* config);
/*
=cut
*/


#ifdef __cplusplus
}
#endif
#endif /* ! __LIBSWISH3_H__ */
