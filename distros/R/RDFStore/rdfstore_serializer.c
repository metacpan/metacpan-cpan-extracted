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
# $Id: rdfstore_serializer.c,v 1.9 2006/06/19 10:10:22 areggiori Exp $
#
*/

#if !defined(WIN32)
#include <sys/param.h>
#endif

#include <sys/types.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <strings.h>
#include <fcntl.h>
#include <ctype.h>

#include <time.h>
#include <sys/stat.h>

#include "rdfstore_log.h"
#include "rdfstore.h"
#include "rdfstore_serializer.h"
#include "rdfstore_digest.h"
#include "rdfstore_utf8.h"

/*
#define RDFSTORE_DEBUG
*/

/*
	See also:

	o-> N-Triples http://www.w3.org/TR/rdf-testcases/#ntrip_grammar
        o-> Quads http://robustai.net/sailor/grammar/Quads.html

*/

int rdfstore_ntriples_hex2c(const char *x);
void rdfstore_ntriples_c2hex(int ch, char *x);

char *
rdfstore_get_localname ( char * uri ) {
        char * nc=NULL;
        char * localname=NULL;

	if ( uri == NULL )
		return NULL;

        /* try to get out XML QName LocalName from resource identifier */
        nc = uri + strlen(uri)-1;
        while( nc >= uri ) {
                if( rdfstore_is_xml_name( nc ) )
                        localname = nc;
                nc--;
                };

        if( !localname ) {
		localname = uri; /* we can not split it up; so we default to the whole uri - correct? */
                };

        return localname;
        };

int
rdfstore_get_namespace ( char * uri ) {
        char * nc=NULL;

	if ( uri == NULL )
		return 0;

	nc = rdfstore_get_localname( uri );
        if ( nc == NULL ) {
		return ( uri != NULL ) ? strlen(uri) : 0;
	} else {
        	return (int)( nc - uri );
		};
	};

/* see http://www.w3.org/TR/1999/REC-xml-names-19990114/#NT-NCName */
int
rdfstore_is_xml_name( char *name_char ) {

	if (	( ! isalpha((int)*name_char) ) &&
		( *name_char != '_' ) )
		return 0;

	name_char++;
	while( *name_char ) {
		if (	( ! isalnum((int)*name_char) ) &&
			( *name_char != '_' ) && 
			( *name_char != '-' ) &&
			( *name_char != '.' ) )
			return 0;
		name_char++;
		};

	return 1;
	};

int
rdfstore_statement_getLabel( RDF_Statement   * statement, char * label ) {
	if ( statement->node != NULL ) { /* use the statement as resource identifier if possible */
		/* XXX is the following copy to char * (string) correct????? */
        	memcpy( label, statement->node->value.resource.identifier, statement->node->value.resource.identifier_len );
		memcpy( label+statement->node->value.resource.identifier_len, "\0", 1);
		return statement->node->value.resource.identifier_len;
        } else {
        	int i=0,status=0;
                unsigned char dd[RDFSTORE_SHA_DIGESTSIZE];

                /* e.g. urn:rdf:SHA-1-d2619b606c7ecac3dcf9151dae104c4ae7554786 */
                sprintf( label, "urn:rdf:%s-", rdfstore_digest_get_digest_algorithm() );
                status = rdfstore_digest_get_statement_digest( statement, NULL, dd );
                if ( status != 0 )
			return 0;

                for ( i=0; i< RDFSTORE_SHA_DIGESTSIZE ; i++ ) {
			char cc[2];
                	sprintf( cc, "%02X", dd[i] );
			strncat(label, cc, 2);
                        };
		return 9 + strlen( rdfstore_digest_get_digest_algorithm() ) + (RDFSTORE_SHA_DIGESTSIZE*2);
		};
	};

char * rdfstore_ntriples_statement (
	RDF_Statement   * statement,
        RDF_Node	* given_context
	) {
	RDF_Node * context = NULL;
	int i=0;
	char * buff=NULL;
	char * buff1=NULL;
	int s_len=0,p_len=0,o_len=0,c_len=0, reification_len=0;

        buff=NULL;

        if (    ( statement             == NULL ) ||
                ( statement->subject    == NULL ) ||
                ( statement->predicate  == NULL ) ||
                ( statement->subject->value.resource.identifier   == NULL ) ||
                ( statement->predicate->value.resource.identifier   == NULL ) ||
                ( statement->object     == NULL ) ||
		(	( statement->object->type != 1 ) &&
			( statement->object->value.resource.identifier   == NULL ) ) ||
		(	( context != NULL ) &&
			( context->value.resource.identifier   == NULL ) ) ||
		(	( statement->node != NULL ) &&
			( statement->node->value.resource.identifier   == NULL ) ) )
                return NULL;

	if (given_context == NULL) {
		if (statement->context != NULL)
                	context = statement->context;
	} else {
		/* use given context instead */
		context = given_context;
		};

	/* try to allocate just the necessary - see http://www.w3.org/TR/rdf-testcases/#ntriples */
	if ( statement->subject->type == 0 ) {
		s_len = statement->subject->value.resource.identifier_len*(RDFSTORE_UTF8_MAXLEN+1+2) + 4;
	} else {
		s_len = statement->subject->value.resource.identifier_len + 4;
		};
	if ( statement->predicate->type == 0 ) {
		p_len = statement->predicate->value.resource.identifier_len*(RDFSTORE_UTF8_MAXLEN+1+2) + 4;
	} else {
		p_len = statement->predicate->value.resource.identifier_len + 4;
		};
	if ( statement->object->type == 0 ) {
		o_len = statement->object->value.resource.identifier_len*(RDFSTORE_UTF8_MAXLEN+1+2) + 4;
	} else if ( statement->object->type == 2 ) {
		o_len = statement->object->value.resource.identifier_len + 4;
	} else {
		o_len = ( statement->object->value.literal.string != NULL ) ? 
				statement->object->value.literal.string_len*(RDFSTORE_UTF8_MAXLEN+1+2) + 3 : 0;
		if (	(statement->object->value.literal.lang != NULL) && 
			(strlen(statement->object->value.literal.lang) > 0) )
			o_len += strlen(statement->object->value.literal.lang) + 1;
		/* we propably should croak or warn the user if something is fishy with the rdf:dataType property */
		if ( statement->object->value.literal.parseType == 1 )
			o_len += strlen(RDFSTORE_RDF_PARSETYPE_LITERAL) + 4;
		else if ( statement->object->value.literal.dataType != NULL )
			o_len += strlen(statement->object->value.literal.dataType) + 4;
		o_len++;
		};
	if ( context != NULL )
		c_len = context->value.resource.identifier_len + 4;

	if (    (statement->isreified) &&
                (statement->node != NULL) ) {
		reification_len = ( statement->node->value.resource.identifier_len + 4 ) * 4;
		reification_len += strlen(RDFMS_type) + 4;
		reification_len += strlen(RDFMS_Statement) + 4;
		reification_len += strlen(RDFMS_subject) + 4;
		reification_len += s_len;
		reification_len += strlen(RDFMS_predicate) + 4;
		reification_len += p_len;
		reification_len += strlen(RDFMS_object) + 4;
		reification_len += o_len;
		};

        buff = (char *) RDFSTORE_MALLOC( sizeof(char) * ( s_len + p_len + o_len + c_len + 3 + reification_len ) );

	if ( buff == NULL )
                return NULL;

        /* try to generate an N-Triples/Quads like string here */

	i=0;

	buff1=NULL;
	if( (buff1=rdfstore_ntriples_node( statement->subject )) == NULL ) {
		RDFSTORE_FREE( buff );
		return NULL;
		};
        memcpy(buff+i, buff1, strlen(buff1));
	i+=strlen(buff1);
	RDFSTORE_FREE( buff1 );
	memcpy(buff+i," ",1);
	i++;

	buff1=NULL;
	if( (buff1=rdfstore_ntriples_node( statement->predicate )) == NULL ) {
		RDFSTORE_FREE( buff );
		return NULL;
		};
        memcpy(buff+i, buff1, strlen(buff1));
	i+=strlen(buff1);
	RDFSTORE_FREE( buff1 );
	memcpy(buff+i," ",1);
	i++;

	buff1=NULL;
	if( (buff1=rdfstore_ntriples_node( statement->object )) == NULL ) {
		RDFSTORE_FREE( buff );
		return NULL;
		};
        memcpy(buff+i, buff1, strlen(buff1));
	i+=strlen(buff1);
	RDFSTORE_FREE( buff1 );
	memcpy(buff+i," ",1);
	i++;

	if ( context != NULL ) {
		buff1=NULL;
		if( (buff1=rdfstore_ntriples_node( context )) == NULL ) {
			RDFSTORE_FREE( buff );
			return NULL;
			};
        	memcpy(buff+i, buff1, strlen(buff1));
		i+=strlen(buff1);
		RDFSTORE_FREE( buff1 );
		memcpy(buff+i," ",1);
		i++;
		};

	memcpy(buff+i,". ",2); /* not cr/lf */
	i+=2;

	/* add the reification triples if necessary */
	if (	(statement->isreified) &&
		(statement->node != NULL) ) {
		memcpy(buff+i,"\n",1);
		i++;

		buff1=NULL;
		if( (buff1=rdfstore_ntriples_node( statement->node )) == NULL ) {
			RDFSTORE_FREE( buff );
			return NULL;
			};
        	memcpy(buff+i, buff1, strlen(buff1));
		i+=strlen(buff1);
		RDFSTORE_FREE( buff1 );
		memcpy(buff+i," ",1);
		i++;

		memcpy(buff+i,"<",1);
		i++;
        	memcpy(buff+i, RDFMS_type, strlen(RDFMS_type));
		i+=strlen(RDFMS_type);
		memcpy(buff+i,">",1);
		i++;
		memcpy(buff+i," ",1);
		i++;

		memcpy(buff+i,"<",1);
		i++;
        	memcpy(buff+i, RDFMS_Statement, strlen(RDFMS_Statement));
		i+=strlen(RDFMS_Statement);
		memcpy(buff+i,">",1);
		i++;
		memcpy(buff+i," ",1);
		i++;

		memcpy(buff+i,". ",2); /* not cr/lf */
		i+=2;
		memcpy(buff+i,"\n",1);
		i++;

		buff1=NULL;
		if( (buff1=rdfstore_ntriples_node( statement->node )) == NULL ) {
			RDFSTORE_FREE( buff );
			return NULL;
			};
        	memcpy(buff+i, buff1, strlen(buff1));
		i+=strlen(buff1);
		RDFSTORE_FREE( buff1 );
		memcpy(buff+i," ",1);
		i++;

		memcpy(buff+i,"<",1);
		i++;
        	memcpy(buff+i, RDFMS_subject, strlen(RDFMS_subject));
		i+=strlen(RDFMS_subject);
		memcpy(buff+i,">",1);
		i++;
		memcpy(buff+i," ",1);
		i++;

		buff1=NULL;
		if( (buff1=rdfstore_ntriples_node( statement->subject )) == NULL ) {
			RDFSTORE_FREE( buff );
			return NULL;
			};
        	memcpy(buff+i, buff1, strlen(buff1));
		i+=strlen(buff1);
		RDFSTORE_FREE( buff1 );
		memcpy(buff+i," ",1);
		i++;

		memcpy(buff+i,". ",2); /* not cr/lf */
		i+=2;
		memcpy(buff+i,"\n",1);
		i++;

		buff1=NULL;
		if( (buff1=rdfstore_ntriples_node( statement->node )) == NULL ) {
			RDFSTORE_FREE( buff );
			return NULL;
			};
        	memcpy(buff+i, buff1, strlen(buff1));
		i+=strlen(buff1);
		RDFSTORE_FREE( buff1 );
		memcpy(buff+i," ",1);
		i++;

		memcpy(buff+i,"<",1);
		i++;
        	memcpy(buff+i, RDFMS_predicate, strlen(RDFMS_predicate));
		i+=strlen(RDFMS_predicate);
		memcpy(buff+i,">",1);
		i++;
		memcpy(buff+i," ",1);
		i++;

		buff1=NULL;
		if( (buff1=rdfstore_ntriples_node( statement->predicate )) == NULL ) {
			RDFSTORE_FREE( buff );
			return NULL;
			};
        	memcpy(buff+i, buff1, strlen(buff1));
		i+=strlen(buff1);
		RDFSTORE_FREE( buff1 );
		memcpy(buff+i," ",1);
		i++;

		memcpy(buff+i,". ",2); /* not cr/lf */
		i+=2;
		memcpy(buff+i,"\n",1);
		i++;

		buff1=NULL;
		if( (buff1=rdfstore_ntriples_node( statement->node )) == NULL ) {
			RDFSTORE_FREE( buff );
			return NULL;
			};
        	memcpy(buff+i, buff1, strlen(buff1));
		i+=strlen(buff1);
		RDFSTORE_FREE( buff1 );
		memcpy(buff+i," ",1);
		i++;

		memcpy(buff+i,"<",1);
		i++;
        	memcpy(buff+i, RDFMS_object, strlen(RDFMS_object));
		i+=strlen(RDFMS_object);
		memcpy(buff+i,">",1);
		i++;
		memcpy(buff+i," ",1);
		i++;

		buff1=NULL;
		if( (buff1=rdfstore_ntriples_node( statement->object )) == NULL ) {
			RDFSTORE_FREE( buff );
			return NULL;
			};
        	memcpy(buff+i, buff1, strlen(buff1));
		i+=strlen(buff1);
		RDFSTORE_FREE( buff1 );
		memcpy(buff+i," ",1);
		i++;

		memcpy(buff+i,". ",2); /* not cr/lf */
		i+=2;
		};

	memcpy(buff+i,"\0",1);
	i++;

	return buff;
	};

char * rdfstore_ntriples_node (
	RDF_Node    * node
	) {
        int j=0,len=0;
        char * buff=NULL;
        register unsigned int i=0;
        unsigned int utf8_size=0;

        if (	( node == NULL ) ||
		(	( node->type != 1 ) &&
			( node->value.resource.identifier == NULL ) ) )
                return NULL;

	if ( node->type == 0 ) {
		len = node->value.resource.identifier_len*(RDFSTORE_UTF8_MAXLEN+1+2) + 3;
	} else if ( node->type == 2 ) {
		len = node->value.resource.identifier_len + 3;
	} else {
		len = (node->value.literal.string != NULL ) ? 
				node->value.literal.string_len*(RDFSTORE_UTF8_MAXLEN+1+2) + 3 : 0;
		if (	(node->value.literal.lang != NULL) && 
			(strlen(node->value.literal.lang) > 0) )
			len += strlen(node->value.literal.lang) + 1;
		/* we propably should croak or warn the user if something is fishy with the rdf:dataType property */
		if ( node->value.literal.parseType == 1 )
			len += strlen(RDFSTORE_RDF_PARSETYPE_LITERAL) + 4;
		else if ( node->value.literal.dataType != NULL )
			len += strlen(node->value.literal.dataType) + 4;
		};

        buff = (char *) RDFSTORE_MALLOC( sizeof(char) * len );
        if ( buff == NULL )
                return NULL;

        j=0;

	/* NOTE: we should check that all the absoluteURI generated would be properly escaped accordingly to http://www.w3.org/TR/rdf-testcases/#sec-uri-encoding */

        if ( node->type == 2 ) {
        	memcpy(buff+j,"_:",2);
        	j+=2;
        	memcpy(buff+j,node->value.resource.identifier,node->value.resource.identifier_len);
        	j+=node->value.resource.identifier_len;
        } else if ( node->type == 0 ) {
		int uri_len = 0;
        	memcpy(buff+j,"<",1);
        	j++;
		uri_len = node->value.resource.identifier_len;
        	for(i=0; i < uri_len; ) {
			if( node->value.resource.identifier[i] == 0x09 ) {
        			memcpy(buff+j,"\\t",2);
        			j+=2;
				i++;
				continue;
			} else if( node->value.resource.identifier[i] == 0x0a ) {
        			memcpy(buff+j,"\\n",2);
        			j+=2;
				i++;
				continue;
			} else if( node->value.resource.identifier[i] == 0x0d ) {
        			memcpy(buff+j,"\\r",2);
        			j+=2;
				i++;
				continue;
			} else if( node->value.resource.identifier[i] == 0x5c ) {
        			memcpy(buff+j,"\\\\",2);
        			j+=2;
				i++;
				continue;
			} else if( node->value.resource.identifier[i] == 0x22 ) {
        			memcpy(buff+j,"\\\"",2);
        			j+=2;
				i++;
				continue;
				};
                	if ( ( rdfstore_utf8_is_utf8( node->value.resource.identifier+i, &utf8_size ) ) && ( utf8_size > 1 ) ) {
				unsigned long cp=0;
				unsigned char es[8];

				if ( rdfstore_utf8_utf8_to_cp( utf8_size, node->value.resource.identifier+i, &cp ) ) {
					RDFSTORE_FREE( buff );
                               		return NULL;
                               		};

				if(utf8_size<=4) {
       					sprintf(es, "\\u%04lX", cp);
				} else {
       					sprintf(es, "\\U%08lX", cp);
					};
       				memcpy(buff+j,es,strlen(es));
       				j+=strlen(es);
				i+=utf8_size;
               		} else {
       				memcpy(buff+j,node->value.resource.identifier+i,utf8_size);
				j+=utf8_size;
				i++;
                       		};
               		};
		memcpy(buff+j,">",1);
        	j++;
        } else if ( node->type == 1 ) {
        	memcpy(buff+j,"\"",1);
        	j++;

		if ( node->value.literal.string != NULL ) {

			/* here we convert the string to RDFSTORE_UTF8 and then escape it accordingly to http://www.w3.org/TR/rdf-testcases/#ntrip_strings */
        		for(i=0; i < node->value.literal.string_len; ) {
				if( node->value.literal.string[i] == 0x09 ) {
        				memcpy(buff+j,"\\t",2);
        				j+=2;
					i++;
					continue;
				} else if( node->value.literal.string[i] == 0x0a ) {
        				memcpy(buff+j,"\\n",2);
        				j+=2;
					i++;
					continue;
				} else if( node->value.literal.string[i] == 0x0d ) {
        				memcpy(buff+j,"\\r",2);
        				j+=2;
					i++;
					continue;
				} else if( node->value.literal.string[i] == 0x5c ) {
        				memcpy(buff+j,"\\\\",2);
        				j+=2;
					i++;
					continue;
				} else if( node->value.literal.string[i] == 0x22 ) {
        				memcpy(buff+j,"\\\"",2);
        				j+=2;
					i++;
					continue;
					};
                		if ( ( rdfstore_utf8_is_utf8( node->value.literal.string+i, &utf8_size ) ) && ( utf8_size > 1 ) ) {
					unsigned long cp=0;
					unsigned char es[8];

					if ( rdfstore_utf8_utf8_to_cp( utf8_size, node->value.literal.string+i, &cp ) ) {
						RDFSTORE_FREE( buff );
                                		return NULL;
                                		};

					if(utf8_size<=4) {
        					sprintf(es, "\\u%04lX", cp);
					} else {
        					sprintf(es, "\\U%08lX", cp);
						};
        				memcpy(buff+j,es,strlen(es));
        				j+=strlen(es);
					i+=utf8_size;
                		} else {
        				memcpy(buff+j,node->value.literal.string+i,utf8_size);
					j+=utf8_size;
					i++;
                        		};
                		};
			};

        	memcpy(buff+j,"\"",1);
        	j++;

        	if(	(node->value.literal.lang != NULL) &&
			(strlen(node->value.literal.lang) > 0) ) {
        		memcpy(buff+j,"@",1);
        		j++;
        		/* we should check that the language tag is also well-formed and escaped */
        		memcpy(buff+j,node->value.literal.lang,strlen(node->value.literal.lang));
        		j+=strlen(node->value.literal.lang);
			};

        	if( node->value.literal.parseType == 1 ) {
        		memcpy(buff+j,"^^",2);
        		j+=2;
        		memcpy(buff+j,"<",1);
        		j++;
        		memcpy(buff+j,RDFSTORE_RDF_PARSETYPE_LITERAL,strlen(RDFSTORE_RDF_PARSETYPE_LITERAL));
        		j+=strlen(RDFSTORE_RDF_PARSETYPE_LITERAL);
        		memcpy(buff+j,">",1);
        		j++;
		} else if ( node->value.literal.dataType != NULL ) {
        		memcpy(buff+j,"^^",2);
        		j+=2;
        		memcpy(buff+j,"<",1);
        		j++;
        		/* we should check that the data type URI ref is a valid XMLSchema data type perhpas */
        		memcpy(buff+j,node->value.literal.dataType,strlen(node->value.literal.dataType));
        		j+=strlen(node->value.literal.dataType);
        		memcpy(buff+j,">",1);
        		j++;
			};
	} else {
		RDFSTORE_FREE( buff );
		perror("rdfstore_ntriples_node");
                fprintf(stderr,"Could not generate ntriple for node: unknown node type\n");
		return NULL;
		};

	memcpy(buff+j,"\0",1);
	j++;

	return buff;
	};

/* the following two subroutines do not consider EBCDIC codes still! */
int rdfstore_ntriples_hex2c(const char *x) {
	int i;
	int ch;

	ch = x[0];

	if (isdigit( ((unsigned char)(ch)) ))
        	i = ch - '0';
	else if (isupper( ((unsigned char)(ch)) ))
		i = ch - ('A' - 10);
	else
		i = ch - ('a' - 10);

	i <<= 4;

	ch = x[1];
	if (isdigit( ((unsigned char)(ch)) ))
        	i += ch - '0';
	else if (isupper( ((unsigned char)(ch)) ))
		i += ch - ('A' - 10);
	else
		i += ch - ('a' - 10);

	return i;
	};

void rdfstore_ntriples_c2hex(int ch, char *x) {
	int i;

	x[0] = '%';
	i = (ch & 0xF0) >> 4;

	if (i >= 10)
		x[1] = ('A' - 10) + i;
	else
		x[1] = '0' + i;

	i = ch & 0x0F;

	if (i >= 10)
		x[2] = ('A' - 10) + i;
	else
		x[2] = '0' + i;
	};
