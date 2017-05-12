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
# $Id: rdfstore_serializer.h,v 1.4 2006/06/19 10:10:23 areggiori Exp $
#
*/

#ifndef _H_RDFSTORE_SERIALIZER
#define _H_RDFSTORE_SERIALIZER

#include "rdfstore.h"

/* some RDF concepts */
#define RDF_SYNTAX_NS "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
#define RDF_SCHEMA_NS "http://www.w3.org/2000/01/rdf-schema#"
#define XMLSCHEMA_prefix "xml"
#define XMLSCHEMA "http://www.w3.org/XML/1998/namespace"
#define XMLNS "xmlns"
#define RDFMS_type "http://www.w3.org/1999/02/22-rdf-syntax-ns#type"
#define RDFMS_predicate "http://www.w3.org/1999/02/22-rdf-syntax-ns#predicate"
#define RDFMS_subject "http://www.w3.org/1999/02/22-rdf-syntax-ns#subject"
#define RDFMS_object "http://www.w3.org/1999/02/22-rdf-syntax-ns#object"
#define RDFMS_Statement "http://www.w3.org/1999/02/22-rdf-syntax-ns#Statement"

char * rdfstore_get_localname( char * uri );

int rdfstore_get_namespace( char * uri ); /* returns the size of the namespace part (0 is empty) */

int rdfstore_is_xml_name( char * name_char );

int rdfstore_statement_getLabel(
	RDF_Statement   * statement,
	char * label
	);

char * rdfstore_ntriples_statement (
        RDF_Statement   * statement,
        RDF_Node	* given_context
	);

char * rdfstore_ntriples_node ( 
        RDF_Node	* node
	);

#endif
