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

#ifndef _H_RDFSTORE_XSD
#define _H_RDFSTORE_XSD

#include <sys/types.h>
#include <sys/time.h>
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <string.h>
#include <assert.h>

/* see http://www.w3.org/TR/xmlschema-2/ */

typedef enum {
  RDFSTORE_XSD_STRING,
  RDFSTORE_XSD_INTEGER,
  RDFSTORE_XSD_DECIMAL,
  RDFSTORE_XSD_FLOAT,
  RDFSTORE_XSD_DOUBLE,
  RDFSTORE_XSD_DATE,
  RDFSTORE_XSD_DATETIME,

  RDFSTORE_XSD_LAST = RDFSTORE_XSD_DATETIME
} rdfstore_xsd;

#define RDFSTORE_XSD_BAD_DATE (time_t)0

static const char* rdfstore_xsd_format[RDFSTORE_XSD_LAST+1]={
	"%s",
	"%ld",
	"%f",
	"%f",
	"%f",
	"%Y-%m-%d",
	"%Y-%m-%dT%H:%M:%SZ"
	};

#define RDFSTORE_XSD_STRING_FORMAT     rdfstore_xsd_format[RDFSTORE_XSD_STRING]
#define RDFSTORE_XSD_INTEGER_FORMAT    rdfstore_xsd_format[RDFSTORE_XSD_INTEGER]
#define RDFSTORE_XSD_DECIMAL_FORMAT    rdfstore_xsd_format[RDFSTORE_XSD_DECIMAL]
#define RDFSTORE_XSD_FLOAT_FORMAT      rdfstore_xsd_format[RDFSTORE_XSD_FLOAT]
#define RDFSTORE_XSD_DOUBLE_FORMAT     rdfstore_xsd_format[RDFSTORE_XSD_DOUBLE]
#define RDFSTORE_XSD_DATE_FORMAT       rdfstore_xsd_format[RDFSTORE_XSD_DATE]
#define RDFSTORE_XSD_DATETIME_FORMAT   rdfstore_xsd_format[RDFSTORE_XSD_DATETIME]

#define RDFSTORE_XSD_INTEGER_FORMAT_SIZE   80
#define RDFSTORE_XSD_DECIMAL_FORMAT_SIZE   80
#define RDFSTORE_XSD_FLOAT_FORMAT_SIZE     80
#define RDFSTORE_XSD_DOUBLE_FORMAT_SIZE    80
#define RDFSTORE_XSD_DATE_FORMAT_SIZE      80
#define RDFSTORE_XSD_DATETIME_FORMAT_SIZE  80

void rdfstore_xsd_serialize_string( const char * value, char * result );
int rdfstore_xsd_deserialize_string( const char * string, char * val );

void rdfstore_xsd_serialize_integer( const long value, char * result );
int rdfstore_xsd_deserialize_integer( const char * string, long * val );

void rdfstore_xsd_serialize_decimal( const double value, char * result );
int rdfstore_xsd_deserialize_decimal( const char * string, double * val );

void rdfstore_xsd_serialize_float( const float value, char * result );
int rdfstore_xsd_deserialize_float( const char * string, float * val );

void rdfstore_xsd_serialize_double( const double value, char * result );
int rdfstore_xsd_deserialize_double( const char * string, double * val );

void rdfstore_xsd_serialize_date( const struct tm value, char * result );
int rdfstore_xsd_deserialize_date( const char * string, struct tm * val );

void rdfstore_xsd_serialize_dateTime( const struct tm value, char * result );
int rdfstore_xsd_deserialize_dateTime( const char * string, struct tm * val );

#endif
