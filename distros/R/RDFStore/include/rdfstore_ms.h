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
*/

#ifndef _H_RDFSTORE_MS
#define _H_RDFSTORE_MS

typedef enum {
  RDFSTORE_MS_RDF,
  RDFSTORE_MS_RDFS,
  RDFSTORE_MS_RSS,
  RDFSTORE_MS_DAML,
  RDFSTORE_MS_FOAF,
  RDFSTORE_MS_OWL,
  RDFSTORE_MS_DC,
  RDFSTORE_MS_DCQ,
  RDFSTORE_MS_XSD,
  RDFSTORE_MS_RDFSTORE_CONTEXTS,

  RDFSTORE_MS_LAST = RDFSTORE_MS_RDFSTORE_CONTEXTS
} rdfstore_ms_xmlns;

static const char* rdfstore_ms_prefix[RDFSTORE_MS_LAST+1]={
	"rdf",
	"rdfs",
	"rss",
	"daml",
	"foaf",
	"owl",
	"dc",
	"dcq",
	"xsd",
	"rdfstore"
};

static const char* rdfstore_ms_uri[RDFSTORE_MS_LAST+1]={
	"http://www.w3.org/1999/02/22-rdf-syntax-ns#",
	"http://www.w3.org/2000/01/rdf-schema#",
	"http://purl.org/rss/1.0/",
	"http://www.daml.org/2001/03/daml+oil#",
	"http://xmlns.com/foaf/0.1/",
	"http://www.w3.org/2002/07/owl#",
	"http://purl.org/dc/elements/1.1/",
	"http://purl.org/dc/terms/",
	"http://www.w3.org/2001/XMLSchema#",
	"http://rdfstore.sourceforge.net/contexts/",
};

#define RDFSTORE_MS_RDF_PREFIX rdfstore_ms_prefix[RDFSTORE_MS_RDF]
#define RDFSTORE_MS_RDFS_PREFIX rdfstore_ms_prefix[RDFSTORE_MS_RDFS]
#define RDFSTORE_MS_RSS_PREFIX rdfstore_ms_prefix[RDFSTORE_MS_RSS]
#define RDFSTORE_MS_DAML_PREFIX rdfstore_ms_prefix[RDFSTORE_MS_DAML]
#define RDFSTORE_MS_FOAF_PREFIX rdfstore_ms_prefix[RDFSTORE_MS_FOAF]
#define RDFSTORE_MS_OWL_PREFIX rdfstore_ms_prefix[RDFSTORE_MS_OWL]
#define RDFSTORE_MS_DC_PREFIX rdfstore_ms_prefix[RDFSTORE_MS_DC]
#define RDFSTORE_MS_DCQ_PREFIX rdfstore_ms_prefix[RDFSTORE_MS_DCQ]
#define RDFSTORE_MS_XSD_PREFIX rdfstore_ms_prefix[RDFSTORE_MS_XSD]
#define RDFSTORE_MS_RDFSTORE_CONTEXTS_PREFIX rdfstore_ms_prefix[RDFSTORE_MS_RDFSTORE_CONTEXTS]

#define RDFSTORE_MS_RDF_URI rdfstore_ms_uri[RDFSTORE_MS_RDF]
#define RDFSTORE_MS_RDFS_URI rdfstore_ms_uri[RDFSTORE_MS_RDFS]
#define RDFSTORE_MS_RSS_URI rdfstore_ms_uri[RDFSTORE_MS_RSS]
#define RDFSTORE_MS_DAML_URI rdfstore_ms_uri[RDFSTORE_MS_DAML]
#define RDFSTORE_MS_FOAF_URI rdfstore_ms_uri[RDFSTORE_MS_FOAF]
#define RDFSTORE_MS_OWL_URI rdfstore_ms_uri[RDFSTORE_MS_OWL]
#define RDFSTORE_MS_DC_URI rdfstore_ms_uri[RDFSTORE_MS_DC]
#define RDFSTORE_MS_DCQ_URI rdfstore_ms_uri[RDFSTORE_MS_DCQ]
#define RDFSTORE_MS_XSD_URI rdfstore_ms_uri[RDFSTORE_MS_XSD]
#define RDFSTORE_MS_RDFSTORE_CONTEXTS_URI rdfstore_ms_uri[RDFSTORE_MS_RDFSTORE_CONTEXTS]

#define RDFSTORE_MS_XSD_STRING     "http://www.w3.org/2001/XMLSchema#string"
#define RDFSTORE_MS_XSD_INTEGER    "http://www.w3.org/2001/XMLSchema#integer"
#define RDFSTORE_MS_XSD_DECIMAL    "http://www.w3.org/2001/XMLSchema#decimal"
#define RDFSTORE_MS_XSD_FLOAT      "http://www.w3.org/2001/XMLSchema#float"
#define RDFSTORE_MS_XSD_DOUBLE     "http://www.w3.org/2001/XMLSchema#double"
#define RDFSTORE_MS_XSD_DATE       "http://www.w3.org/2001/XMLSchema#date"
#define RDFSTORE_MS_XSD_DATETIME   "http://www.w3.org/2001/XMLSchema#dateTime"

#endif
