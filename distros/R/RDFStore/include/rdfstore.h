/*
##############################################################################
# 	Copyright (c) 2000-2006 All rights reserved
# 	Alberto Reggiori <areggiori@webweaving.org>
#	Dirk-Willem van Gulik <dirkx@webweaving.org>
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer. 
#
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in
#    the documentation and/or other materials provided with the
#    distribution.
#
# 3. The end-user documentation included with the redistribution,
#    if any, must include the following acknowledgment:
#       "This product includes software developed by 
#        Alberto Reggiori <areggiori@webweaving.org> and
#        Dirk-Willem van Gulik <dirkx@webweaving.org>."
#    Alternately, this acknowledgment may appear in the software itself,
#    if and wherever such third-party acknowledgments normally appear.
#
# 4. All advertising materials mentioning features or use of this software
#    must display the following acknowledgement:
#    This product includes software developed by the University of
#    California, Berkeley and its contributors. 
#
# 5. Neither the name of the University nor the names of its contributors
#    may be used to endorse or promote products derived from this software
#    without specific prior written permission.
#
# 6. Products derived from this software may not be called "RDFStore"
#    nor may "RDFStore" appear in their names without prior written
#    permission.
#
# THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESSED OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
# NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
# OF THE POSSIBILITY OF SUCH DAMAGE.
#
# ====================================================================
#
# This software consists of work developed by Alberto Reggiori and 
# Dirk-Willem van Gulik. The RDF specific part is based based on public 
# domain software written at the Stanford University Database Group by 
# Sergey Melnik. For more information on the RDF API Draft work, 
# please see <http://www-db.stanford.edu/~melnik/rdf/api.html>
# The DBMS TCP/IP server part is based on software originally written
# by Dirk-Willem van Gulik for Web Weaving Internet Engineering m/v Enschede,
# The Netherlands.
#
##############################################################################
#
# $Id: rdfstore.h,v 1.48 2006/06/19 10:10:23 areggiori Exp $
#
*/

#ifndef _H_RDFSTORE
#define _H_RDFSTORE

#include <sys/param.h>
#include <netinet/in.h>
#include <dbms.h>

#ifdef SUNOS4
double strtod();                /* SunOS needed this */
#endif

#include "rdfstore_flat_store.h"
#include "rdfstore_compress.h"

#define RDFSTORE_MAX_URI_LENGTH		MAXPATHLEN		/* not sure here - a URI can be longer probably */
#define RDFSTORE_WORD_SPLITS		"\v\f\n\r\t ,:;'\"!#$%^&*()~`_=+{}[]<>?.-/\\|"	/* for free-text stuff */
#define RDFSTORE_RDF_PARSETYPE_LITERAL	"http://www.w3.org/1999/02/22-rdf-syntax-ns#XMLLiteral"
#define RDFSTORE_MAX_LANG_LENGTH	50			/* not sure here - a URI can be longer probably */

#ifndef RDFSTORE_WORD_STEMMING
#define RDFSTORE_WORD_STEMMING		(5) /* up to 5 chars from start or end of word */
#endif

#if (! defined(RDFSTORE_MAXRECORDS)) || (RDFSTORE_MAXRECORDS < 128)
#define RDFSTORE_MAXRECORDS (2097152)
#endif

#define RDFSTORE_RECORDS_PER_BYTE	8
#define RDFSTORE_MAXRECORDS_BYTES_SIZE  ( RDFSTORE_MAXRECORDS / RDFSTORE_RECORDS_PER_BYTE ) /* one bit per statement */

#define RDFSTORE_MAX_FETCH_OBJECT_DEEPNESS	20	/* max levels to visit when return "coincise bounded description of a resource" */

#define RDFSTORE_INDEXING_VERSION	"20041222"	/* which is even more modern than the SWAD-e paper one */

/* very basic data types */

typedef uint32_t	rdf_store_digest_t;		/* Hash Code */
typedef dbms_counter	rdf_store_counter_t;		/* Counter type */

#define RDFSTORE_NODE_TYPE_RESOURCE  0
#define RDFSTORE_NODE_TYPE_LITERAL   1
#define RDFSTORE_NODE_TYPE_BNODE     2

#define RDFSTORE_PARSE_TYPE_NORMAL   0
#define RDFSTORE_PARSE_TYPE_LITERAL  1

typedef struct RDF_Node {
        int	type; /* 0=resource, 1=literal and 2=bNode */
	union { 
        	struct {
                	unsigned char    * identifier; /* uri or nodeID */
			int	identifier_len;
                	} resource;
        	struct {
                	unsigned char    * string;
			int	string_len;
                	int     parseType; /* 0=Resource 1=Literal i.e. XML */
                	unsigned char    lang[RDFSTORE_MAX_LANG_LENGTH];
                	unsigned char    * dataType; /* XMLSchema URI ref to the data type for the literal */
                	} literal;
        	} value;
	rdf_store_digest_t hashcode;  /* see digest.c for details */
	struct rdfstore	* model; /* for resource centric API ala Jena */
        } RDF_Node;

typedef struct RDF_Statement {
        RDF_Node * subject;
        RDF_Node * predicate;
        RDF_Node * object;
        RDF_Node * context;
        RDF_Node * node; /* this represent a statement which is actually an RDF resource i.e. reification stuff */
	rdf_store_digest_t	hashcode;  /* see digest.c for details */
	int	isreified;	/* 0=stated 1=quoted ( should this be related to the above value union resource thingie??? ) */
	struct rdfstore	* model; /* for resource centric API ala Jena */
        } RDF_Statement;

/* triple search pattern - quite generic with s,p,o and context (c) with free-text AND/OR/NOT words */
#define RDFSTORE_TRIPLE_PATTERN_PART_RESOURCE_NODE   2000
#define RDFSTORE_TRIPLE_PATTERN_PART_LITERAL_NODE    2001
#define RDFSTORE_TRIPLE_PATTERN_PART_STRING          2002
typedef struct RDF_Triple_Pattern_Part {
	int type; /* RDFSTORE_TRIPLE_PATTERN_PART_RESOURCE_NODE, RDFSTORE_TRIPLE_PATTERN_PART_LITERAL_NODE or RDFSTORE_TRIPLE_PATTERN_PART_STRING */
	union { 
        	RDF_Node * node;
                unsigned char * string;
        	} part;
	struct RDF_Triple_Pattern_Part * next;
	} RDF_Triple_Pattern_Part;

typedef struct RDF_Triple_Pattern {
        struct RDF_Triple_Pattern_Part * subjects; /* OR space seprated URIs */
	unsigned int subjects_operator; /* 0=OR 1=AND 2=NOT */
        struct RDF_Triple_Pattern_Part * predicates;
	unsigned int predicates_operator;
        struct RDF_Triple_Pattern_Part * objects;
	unsigned int objects_operator;
        struct RDF_Triple_Pattern_Part * contexts;
	unsigned int contexts_operator;
        struct RDF_Triple_Pattern_Part * langs;
	unsigned int langs_operator;
        struct RDF_Triple_Pattern_Part * dts;
	unsigned int dts_operator;
        struct RDF_Triple_Pattern_Part * words;
	unsigned int words_operator;
        struct RDF_Triple_Pattern_Part * ranges;
	unsigned int ranges_operator; /*	One axe ranges (considering first element from ranges linked list):
	
						1 = x <  22.34
						2 = x <= .45
						3 = x == 23.45
						4 = x != 23.45
						5 = x >= .748748
						6 = x >  .0002 

						Two axes ranges (considering first 2 elements from ranges linked list):

						7  = 21.23 < x < 22.34     i.e. x >  21.23  &&  x <  22.34
						8  = 21.23 <= x < 22.34    i.e. x >= 21.23  &&  x <  22.34
						9  = 21.23 <= x <= 22.34   i.e. x >= 21.33  &&  x <= 22.34
						10 = 21.23 < x <= 22.34    i.e. x >  21.33  &&  x <= 22.34

						Values in ranges are euristacally parsed either to a long or double; and xsd_integer or xsd_double
						special tables (b-trees) are used to answer the range question. If the RDF literal has an rdf:datatype
						of xsd:date or xsd:dateTime, such range operations can be carried out on dataes using the xsd_date table.

						*/
        } RDF_Triple_Pattern;

#include "rdfstore_digest.h"
#include "rdfstore_iterator.h"

typedef struct rdfstore {
	int	flag;
	int	freetext;
	int	sync;
	FLATDB	* model;
	FLATDB	* statements;
	FLATDB	* nodes;
	FLATDB	* subjects;
	FLATDB	* predicates;
	FLATDB	* objects;
	FLATDB	* contexts;
	FLATDB	* languages; /* not used: but would index xml:lang into literals */
	FLATDB	* datatypes; /* not used: but would index rdf:dataType into literals */
	FLATDB	* s_connections;
	FLATDB	* p_connections;
	FLATDB	* o_connections;
	FLATDB	* windex;
	FLATDB	* xsd_integer; /* xsd:integer */
	FLATDB	* xsd_double; /* xsd:float or xsd:double special one */
	FLATDB	* xsd_date; /* xsd:date or xsd:dateTime */
	int	remote;
	int	port;
	RDF_Node * context; /* default context/statement-group stuff */
        struct rdfstore_iterator * cursor;
	int	attached; /* the number of items (cursors) currenlty attached */
	int	tobeclosed; /* set to 1 means that the iterator attached has to close the storage itself */
	char	version[10];

	char	host[ MAXPATHLEN ];
        char	uri[ RDFSTORE_MAX_URI_LENGTH ]; /* source URI */
	char	name[ MAXPATHLEN ];

	unsigned char bits_encode[RDFSTORE_MAXRECORDS_BYTES_SIZE]; /* buffers for compression and decompression */
        unsigned char bits_decode[RDFSTORE_MAXRECORDS_BYTES_SIZE];

	/* Functions for encoding/decoding - MUST match */
        void(*func_encode)(unsigned int,unsigned char*, unsigned int *, unsigned char *);
        void(*func_decode)(unsigned int,unsigned char*, unsigned int *, unsigned char *);
	/* special ones for o_connections table - generally different compression algorithm from the above default one */
        void(*func_encode_connections)(unsigned int,unsigned char*, unsigned int *, unsigned char *);
        void(*func_decode_connections)(unsigned int,unsigned char*, unsigned int *, unsigned char *);
	FLATDB	* prefixes; /* prefix mapping stuff - generally in-memory and default loaded on creation, otherwise could be persistent too */
	} rdfstore;


/* RDFStore core types API */

RDF_Node * rdfstore_node_new();
RDF_Node * rdfstore_node_clone( RDF_Node * node );
int rdfstore_node_set_type( RDF_Node * node, int type );
int rdfstore_node_get_type( RDF_Node * node );
unsigned char * rdfstore_node_get_label( RDF_Node * node, int * len );
unsigned char * rdfstore_node_to_string( RDF_Node * node, int * len );
unsigned char * rdfstore_node_get_digest( RDF_Node * node, int * len );
int rdfstore_node_equals( RDF_Node * node1, RDF_Node * node2 );
int rdfstore_node_free( RDF_Node * node );
void rdfstore_node_dump( RDF_Node * node );
int rdfstore_node_set_model( RDF_Node * node, rdfstore * model ); /* for resource centric API ala Jena */
int rdfstore_node_reset_model( RDF_Node * node );
rdfstore * rdfstore_node_get_model( RDF_Node * node );

/* RDF literals */

RDF_Node * rdfstore_literal_new( unsigned char * string, int len, int parseType, unsigned char * lang, unsigned char * dt );
RDF_Node * rdfstore_literal_clone( RDF_Node * node );
unsigned char *  rdfstore_literal_get_label( RDF_Node * node, int * len );
unsigned char * rdfstore_literal_to_string( RDF_Node * node, int * len );
unsigned char * rdfstore_literal_get_digest( RDF_Node * node, int * len );
int rdfstore_literal_equals( RDF_Node * node1, RDF_Node * node2 );
int rdfstore_literal_set_string( RDF_Node * node, unsigned char * string, int len );
int rdfstore_literal_set_lang( RDF_Node * node, unsigned char * lang );
unsigned char * rdfstore_literal_get_lang( RDF_Node * node );
int rdfstore_literal_set_datatype( RDF_Node * node, unsigned char * dt );
unsigned char * rdfstore_literal_get_datatype( RDF_Node * node );
int rdfstore_literal_set_parsetype( RDF_Node * node, int parseType );
int rdfstore_literal_get_parsetype( RDF_Node * node );
int rdfstore_literal_free( RDF_Node * node );
void rdfstore_literal_dump( RDF_Node * node );
int rdfstore_literal_set_model( RDF_Node * node, rdfstore * model ); /* for resource centric API ala Jena */
int rdfstore_literal_reset_model( RDF_Node * node );
rdfstore * rdfstore_literal_get_model( RDF_Node * node );

/* RDF resources (URIs and bNodes) */

RDF_Node * rdfstore_resource_new( unsigned char * identifier, int len, int type );
RDF_Node * rdfstore_resource_new_from_qname( unsigned char * namespace, int nsl, unsigned char * localname, int lnl, int type );
RDF_Node * rdfstore_resource_clone( RDF_Node * node );
unsigned char * rdfstore_resource_get_label( RDF_Node * node, int * len );
unsigned char * rdfstore_resource_to_string( RDF_Node * node, int * len );
unsigned char * rdfstore_resource_get_digest( RDF_Node * node, int * len );
int rdfstore_resource_equals( RDF_Node * node1, RDF_Node * node2 );
int rdfstore_resource_set_uri( RDF_Node * node, unsigned char * identifier, int len );
unsigned char * rdfstore_resource_get_uri( RDF_Node * node, int * len );
int rdfstore_resource_is_anonymous( RDF_Node * node );
int rdfstore_resource_is_bnode( RDF_Node * node );
unsigned char * rdfstore_resource_get_namespace( RDF_Node * node, int * len );
unsigned char * rdfstore_resource_get_localname( RDF_Node * node, int * len );
unsigned char * rdfstore_resource_get_bnode( RDF_Node * node, int * len );
unsigned char * rdfstore_resource_get_nodeid( RDF_Node * node, int * len );
int rdfstore_resource_free( RDF_Node * node );
void rdfstore_resource_dump( RDF_Node * node );
int rdfstore_resource_set_model( RDF_Node * node, rdfstore * model ); /* for resource centric API ala Jena */
int rdfstore_resource_reset_model( RDF_Node * node );
rdfstore * rdfstore_resource_get_model( RDF_Node * node );

/* RDF statements */

RDF_Statement * rdfstore_statement_new( RDF_Node * s, RDF_Node * p, RDF_Node * o, RDF_Node * c, RDF_Node * node, int isreified );
RDF_Statement * rdfstore_statement_clone( RDF_Statement * st );
unsigned char * rdfstore_statement_get_label( RDF_Statement * st, int * len );
unsigned char * rdfstore_statement_to_string( RDF_Statement * st, int * len );
unsigned char * rdfstore_statement_get_digest( RDF_Statement * st, int * len );
int rdfstore_statement_equals( RDF_Statement * st1, RDF_Statement * st2 );
int rdfstore_statement_isreified( RDF_Statement * st );
RDF_Node * rdfstore_statement_get_subject( RDF_Statement * st );
int rdfstore_statement_set_subject( RDF_Statement * st, RDF_Node * s );
RDF_Node * rdfstore_statement_get_predicate( RDF_Statement * st );
int rdfstore_statement_set_predicate( RDF_Statement * st, RDF_Node * p );
RDF_Node * rdfstore_statement_get_object( RDF_Statement * st );
int rdfstore_statement_set_object( RDF_Statement * st, RDF_Node * o );
RDF_Node * rdfstore_statement_get_context( RDF_Statement * st );
int rdfstore_statement_set_context( RDF_Statement * st, RDF_Node * c );
RDF_Node * rdfstore_statement_get_node( RDF_Statement * st );
int rdfstore_statement_set_node( RDF_Statement * st, RDF_Node * node );
int rdfstore_statement_free( RDF_Statement * st );
void rdfstore_statement_dump( RDF_Statement * st );
int rdfstore_statement_set_model( RDF_Statement * st, rdfstore * model ); /* for resource centric API ala Jena */
int rdfstore_statement_reset_model( RDF_Statement * st );
rdfstore * rdfstore_statement_get_model( RDF_Statement * st );

/* RDF_Triple_Pattern related */
RDF_Triple_Pattern * rdfstore_triple_pattern_new();
RDF_Triple_Pattern_Part * rdfstore_triple_pattern_add_subject( RDF_Triple_Pattern * tp, RDF_Node * node );
int rdfstore_triple_pattern_set_subjects_operator( RDF_Triple_Pattern * tp, int op );
RDF_Triple_Pattern_Part * rdfstore_triple_pattern_add_predicate( RDF_Triple_Pattern * tp, RDF_Node * node );
int rdfstore_triple_pattern_set_predicates_operator( RDF_Triple_Pattern * tp, int op );
RDF_Triple_Pattern_Part * rdfstore_triple_pattern_add_object( RDF_Triple_Pattern * tp, RDF_Node * node );
int rdfstore_triple_pattern_set_objects_operator( RDF_Triple_Pattern * tp, int op );
RDF_Triple_Pattern_Part * rdfstore_triple_pattern_add_context( RDF_Triple_Pattern * tp, RDF_Node * node );
int rdfstore_triple_pattern_set_contexts_operator( RDF_Triple_Pattern * tp, int op );
RDF_Triple_Pattern_Part * rdfstore_triple_pattern_add_lang( RDF_Triple_Pattern * tp, char * lang );
int rdfstore_triple_pattern_set_langs_operator( RDF_Triple_Pattern * tp, int op );
RDF_Triple_Pattern_Part * rdfstore_triple_pattern_add_datatype( RDF_Triple_Pattern * tp, char * dt, int len );
int rdfstore_triple_pattern_set_datatypes_operator( RDF_Triple_Pattern * tp, int op );
RDF_Triple_Pattern_Part * rdfstore_triple_pattern_add_word( RDF_Triple_Pattern * tp, unsigned char * word, int len );
int rdfstore_triple_pattern_set_words_operator( RDF_Triple_Pattern * tp, int op );
RDF_Triple_Pattern_Part * rdfstore_triple_pattern_add_ranges( RDF_Triple_Pattern * tp, char * num, int len ); /* always do strtol() or strtod() on it */
int rdfstore_triple_pattern_set_ranges_operator( RDF_Triple_Pattern * tp, int op );
int rdfstore_triple_pattern_free( RDF_Triple_Pattern * tp );
void rdfstore_triple_pattern_dump( RDF_Triple_Pattern * tp );

/* RDFStore itself API */
int
rdfstore_connect (
	rdfstore * *	me,
        char *          name,
        int             flags,
	int             freetext,
        int             sync,
        int             remote,
        char *          host,
        int             port,
	/* Callbacks for memory management and error handling. */
	void * (* malloc)(size_t s),
        void (* free)(void * adr),
        void (* callback)(dbms_cause_t cause, int cnt),
        void (* error)(char * err, int erx)
	);

char * rdfstore_get_version (
	rdfstore * me
	);

int rdfstore_disconnect (
	rdfstore * me
	);

int rdfstore_isconnected (
	rdfstore * me
	);

int rdfstore_isremote (
	rdfstore * me
	);

int rdfstore_if_modified_since (
        char * name,
        char * since,
        /* Callbacks for memory management and error handling. */
        void *(*_mmalloc) (size_t s),
        void (*_mfree) (void *adr),
        void (*_mcallback) (dbms_cause_t cause, int cnt),
        void (*_merror) (char *err, int erx) 
        );

int rdfstore_size ( 
	rdfstore 	* me,
	unsigned int	* size
	);

int rdfstore_contains ( 
        rdfstore        * me,
        RDF_Statement   * statement,
	RDF_Node	* given_context
        );

int rdfstore_insert ( 
        rdfstore        * me,
        RDF_Statement   * statement,
	RDF_Node	* given_context
        );

int rdfstore_remove ( 
        rdfstore        * me,
        RDF_Statement   * statement,
	RDF_Node	* given_context
        );

int rdfstore_set_context ( 
        rdfstore        * me,
	RDF_Node	* given_context
        );

int rdfstore_reset_context ( 
        rdfstore        * me
        );

RDF_Node *
rdfstore_get_context (
        rdfstore        * me
        );

int rdfstore_set_source_uri (
        rdfstore        * me,
        char            * uri
        );

int rdfstore_get_source_uri (
        rdfstore        * me,
        char            * uri
        );

int rdfstore_is_empty (
        rdfstore        * me
        );

/* return iterator over the result set (even empty if no results) */
rdfstore_iterator *
rdfstore_search (
        rdfstore        * me,
	RDF_Triple_Pattern * tp,
	int	search_type /*	0=main indexes (subjects, predicates, objects tables)
				1=RDQL indexes (s_connections, p_connections, o_connections tables) */
        );

rdfstore_iterator *
rdfstore_fetch_object(
	rdfstore * me,
        RDF_Node * resource,
        RDF_Node * given_context
	);

/* return iterator over the whole model content - we could eventually specify a context then it becomes a search in context.... */
rdfstore_iterator *
rdfstore_elements (
        rdfstore        * me
        );

/* Special keys with a special meaning.  - should be longer than 4 bytes to
 * make sure they do not match a unsigned int.
 */
#define RDFSTORE_INDEXING_VERSION_KEY 	("indexing_version")
#define RDFSTORE_COUNTER_KEY 		("counter")
#define RDFSTORE_COUNTER_REMOVED_KEY 	("counter_removed")
#define RDFSTORE_FREETEXT_KEY 		("freetext")
#define RDFSTORE_NAME_KEY 		("name")
#define RDFSTORE_COMPRESSION_KEY 	("compression")
#define RDFSTORE_COMPRESSION_CONNECTIONS_KEY 	("compression_connections")
#define RDFSTORE_LASTMODIFIED_KEY 	("last_modified")

#if 0
void packInt(uint32_t value, unsigned char *lookup);
void unpackInt(unsigned char *value, uint32_t *lookup);
#else
#define packInt(value,buffer) { assert(sizeof((value)) == sizeof(uint32_t)); *(uint32_t *)(buffer)=htonl((value)); }
#define unpackInt(buffer,value) { *(value) = ntohl(*(uint32_t *)(buffer)); }
#endif
#endif
