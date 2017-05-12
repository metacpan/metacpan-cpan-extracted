/*
 * Copyright (c) 2000-2006 All rights reserved,
 *       Alberto Reggiori <areggiori@webweaving.org>,
 *       Dirk-Willem van Gulik <dirkx@webweaving.org>.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 * 
 * 1. Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 * 
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 * 
 * 3. The end-user documentation included with the redistribution, if any, must
 * include the following acknowledgment: "This product includes software
 * developed by Alberto Reggiori <areggiori@webweaving.org> and Dirk-Willem
 * van Gulik <dirkx@webweaving.org>." Alternately, this acknowledgment may
 * appear in the software itself, if and wherever such third-party
 * acknowledgments normally appear.
 * 
 * 4. All advertising materials mentioning features or use of this software must
 * display the following acknowledgement: This product includes software
 * developed by the University of California, Berkeley and its contributors.
 * 
 * 5. Neither the name of the University nor the names of its contributors may
 * be used to endorse or promote products derived from this software without
 * specific prior written permission.
 * 
 * 6. Products derived from this software may not be called "RDFStore" nor may
 * "RDFStore" appear in their names without prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND ANY
 * EXPRESSED OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 * 
 * ====================================================================
 * 
 * This software consists of work developed by Alberto Reggiori and Dirk-Willem
 * van Gulik. The RDF specific part is based based on public domain software
 * written at the Stanford University Database Group by Sergey Melnik. For
 * more information on the RDF API Draft work, please see
 * <http://www-db.stanford.edu/~melnik/rdf/api.html> The DBMS TCP/IP server
 * part is based on software originally written by Dirk-Willem van Gulik for
 * Web Weaving Internet Engineering m/v Enschede, The Netherlands.
 * 
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

#include <time.h>
#include <sys/stat.h>

#include "rdfstore_log.h"
#include "rdfstore_xsd.h"

/*
#define MX	{ printf(" MX %s:%d - %p\n",__FILE__,__LINE__,me->nindex->free); }
*/

/*
 * #define RDFSTORE_XSD_DEBUG
 */

time_t _rdfstore_xsd_mktime(const struct tm * t);

void rdfstore_xsd_serialize_decimal( const double value, char * result ) {
	sprintf( result, RDFSTORE_XSD_DECIMAL_FORMAT, value );
	};

int rdfstore_xsd_deserialize_decimal( const char * string, double * val ) {
	return rdfstore_xsd_deserialize_double( string, (double *) val );
	};

void rdfstore_xsd_serialize_float( const float value, char * result ) {
	sprintf( result, RDFSTORE_XSD_FLOAT_FORMAT, value );
	};

int rdfstore_xsd_deserialize_float( const char * string, float * val ) {
	return rdfstore_xsd_deserialize_double( string, (double *) val );
	};

void rdfstore_xsd_serialize_double( const double value, char * result ) {
	sprintf( result, RDFSTORE_XSD_DOUBLE_FORMAT, value );
	};

/* 
   parse a char string as double/float if possible and returns it

   NOTEs:
		strings like <foo:prop>   123.333344477 foo bar</foo:prop> are not considered numbers while
	 	strings like <foo:prop>
				123.333344477
					</foo:prop> are valid numbers
*/
int rdfstore_xsd_deserialize_double( const char * string, double * val ) {
	char *endptr;

	if (string == NULL) {
		return 0;
		};

	*val = (double) strtod(string, &endptr);

	if (endptr > string) { /* if a conversion was made */
		/* check if we really got a number or a literal/string... */
		while ( *endptr ) {
			if ( isspace(*endptr) == 0 )
				return 0;
			endptr++;
			};

		if( errno == ERANGE )
			return 0;

		return 1;
		};

	return 0;
	};

void rdfstore_xsd_serialize_integer( const long value, char * result ) {
	sprintf( result, RDFSTORE_XSD_INTEGER_FORMAT, value );
	};

int rdfstore_xsd_deserialize_integer( const char * string, long * val ) {
	char *endptr;

	if (string == NULL) {
		return 0;
		};

	/* strtod should trim the string itself... */
	*val = (long) strtol(string, &endptr, 10); /* base 10 or should be any base '0' ? */

	if (endptr > string) { /* if a conversion was made */
		/* check if we really got a number or a literal/string... */
		while ( *endptr ) {
			if ( isspace(*endptr) == 0 )
				return 0;
			endptr++;
			};

		if( errno == ERANGE )
			return 0;

		return 1;
		};

	return 0;
	};

void rdfstore_xsd_serialize_date( const struct tm value, char * result ) {
	strftime( result, RDFSTORE_XSD_DATE_FORMAT_SIZE, "%Y-%m-%dZ", &value );

#ifdef RDFSTORE_XSD_DEBUG
	printf("PROCESSED SUCCESSFULY DATE '%s'\n", result);
#endif
	};

int rdfstore_xsd_deserialize_date( const char * string, struct tm * val ) {
	char * ptr=(char*)string;
	char * ptr1=(char*)(string+strlen(string)-1);
	char * tzsign;
	char * temp;
	char * temp2;
	int status=0;
        unsigned int len;
	time_t now;
	time_t timestamp;
	struct tm* ptm;
	struct tm t1;
	struct tm t2;
	time_t d;

	bzero(val, sizeof( struct tm ) );

	if (string == NULL) {
		return 0;
		};

	time(&now);

	ptm = gmtime(&now);
	memcpy(&t1, ptm, sizeof(struct tm));

	ptm = localtime(&now);
	memcpy(&t2, ptm, sizeof(struct tm));

	d = _rdfstore_xsd_mktime(&t1) - _rdfstore_xsd_mktime(&t2); /* carry out the difference in second between local and UTC */

        if (d == -1) {
		return 0;
		};

	/* trim the value */
	while(	( ptr <= (string + strlen(string) ) ) &&
		( (*ptr == ' ' ) || ( *ptr == '\n' ) || ( *ptr == '\r' ) || ( *ptr == '\f' ) || ( *ptr == '\t' ) ) ) {
		ptr++;
		};
	while(	( ptr1 > ptr ) &&
		( (*ptr1 == ' ' ) || ( *ptr1 == '\n' ) || ( *ptr1 == '\r' ) || ( *ptr1 == '\f' ) || ( *ptr1 == '\t' ) ) ) {
		ptr1--;
		};

	/* primitive date parsing... */

	/* this expression should cover xsd:date and xsd:dateTime - see http://www.w3.org/TR/xmlschema-2/#date and http://www.w3.org/TR/xmlschema-2/#dateTime */
	/* date ::= '-'? yyyy '-' mm '-' dd ((('+' | '-') hh ':' mm) | 'Z')? */

	if(	sscanf( ptr, "%d-%02d-%02d", &val->tm_year,
				&val->tm_mon, &val->tm_mday ) != 3 ) {
		return 0;
                };

	val->tm_year -= 1900;
        val->tm_mon--;
	val->tm_hour = 0;
        val->tm_min = 0;
        val->tm_sec = 0;
        val->tm_isdst = -1;
#if !defined(WIN32) && !defined(AIX) && !defined( __OS400__ ) && !defined(__sun)
	val->tm_zone = NULL;
	val->tm_gmtoff = -1;
#endif

	temp2 = strpbrk(ptr, ":");

        if( ( temp = strpbrk( ptr, "Z") ) != NULL ) { /* got canonical UTC date */
		time_t tt = _rdfstore_xsd_mktime(val);
		if( temp != ptr1 ) {
			return 0;
			};

		if (tt == -1) {
			return 0;
			};
		ptm = localtime (&tt);
	} else if( temp2 != NULL ) { /* ok now we need to normalize +/-hh:mm timezone to UTC - hehheee! */
            	int hours = 0;
		int minutes = 0;
		int secs;
		time_t t;

		tzsign = strrchr(ptr, '+');

		if (tzsign == NULL) {
			tzsign = strrchr(ptr, '-');
			};

		if( *(tzsign-3) != '-' ) {
			return 0;
			};

		timestamp = _rdfstore_xsd_mktime(val);
		if ( timestamp == -1 ) {
			return 0;
            		};

		if( sscanf( tzsign+1, "%02d:%02d", &hours, &minutes) != 2 ) {
			return 0;
			};

		secs = hours * 60 * 60 + minutes * 60;
		if( (temp = strpbrk(tzsign, "+")) != NULL ) {
			timestamp += secs;
		} else {
			timestamp -= secs;
			};
	
		ptm = localtime(&timestamp);
		memcpy(val, ptm, sizeof(struct tm));
		t = _rdfstore_xsd_mktime(val);
		if( t == -1 ) {
			return 0;
			};

		t = labs(t - d);
		ptm = gmtime(&t);
	} else { /*else it is assumed that the sent time is localtime */
		if(	( *ptr1 < 48 ) ||
			( *ptr1 > 57 ) ||
			( *(ptr1-2) != '-' ) ) {
			return 0;
			};

		timestamp = _rdfstore_xsd_mktime(val);
		if( timestamp == -1 ) {
			return 0;
			};

		ptm = gmtime(&timestamp);
		};

	if( ptm!= NULL ) {
#ifdef RDFSTORE_XSD_DEBUG
		printf("rdfstore_xsd_deserialize_date( '%s' ) is a valid date\n", ptr);
#endif

		return 1;
	} else {
#ifdef RDFSTORE_XSD_DEBUG
		printf("rdfstore_xsd_deserialize_date( '%s' ) is NOT a valid date\n", ptr);
#endif

		return 0;
		};
	};

void rdfstore_xsd_serialize_dateTime( const struct tm value, char * result ) {
	strftime( result, RDFSTORE_XSD_DATETIME_FORMAT_SIZE, "%Y-%m-%dT%H:%M:%SZ", &value );

#ifdef RDFSTORE_XSD_DEBUG
	printf("PROCESSED SUCCESSFULY DATETIME '%s'\n", result);
#endif
	};

int rdfstore_xsd_deserialize_dateTime( const char * string, struct tm * val ) {
	char * ptr=(char*)string;
	char * ptr1=(char*)(string+strlen(string)-1);
	char * tzsign;
	char * temp;
	char * temp2;
	char * temp3;
	int status=0;
        unsigned int len;
	time_t now;
	time_t timestamp;
	struct tm* ptm;
	struct tm t1;
	struct tm t2;
	time_t d;

	bzero(val, sizeof( struct tm ) );

	if (string == NULL) {
		return 0;
		};

	time(&now);

	ptm = gmtime(&now);
	memcpy(&t1, ptm, sizeof(struct tm));

	ptm = localtime(&now);
	memcpy(&t2, ptm, sizeof(struct tm));

	d = _rdfstore_xsd_mktime(&t1) - _rdfstore_xsd_mktime(&t2); /* carry out the difference in second between local and UTC */

        if (d == -1) {
		return 0;
		};

	/* trim the value */
	while(	( ptr <= (string + strlen(string) ) ) &&
		( (*ptr == ' ' ) || ( *ptr == '\n' ) || ( *ptr == '\r' ) || ( *ptr == '\f' ) || ( *ptr == '\t' ) ) ) {
		ptr++;
		};
	while(	( ptr1 > ptr ) &&
		( (*ptr1 == ' ' ) || ( *ptr1 == '\n' ) || ( *ptr1 == '\r' ) || ( *ptr1 == '\f' ) || ( *ptr1 == '\t' ) ) ) {
		ptr1--;
		};

	/* primitive date parsing... */

	/* this expression should cover xsd:date and xsd:dateTime - see http://www.w3.org/TR/xmlschema-2/#date and http://www.w3.org/TR/xmlschema-2/#dateTime */
	/* date ::= '-'? yyyy '-' mm '-' dd 'T' hh ':' mm ':' ss ('.' s+)? ((('+' | '-') hh ':' mm) | 'Z')? */

	if(	sscanf( ptr, "%d-%02d-%02dT%02d:%02d:%02d", &val->tm_year,
				&val->tm_mon, &val->tm_mday, &val->tm_hour, &val->tm_min, &val->tm_sec) != 6 ) {
		return 0;
                };

	val->tm_year -= 1900;
        val->tm_mon--;
        val->tm_isdst = -1;
#if !defined(WIN32) && !defined(AIX) && !defined( __OS400__ ) && !defined(__sun)
	val->tm_zone = NULL;
	val->tm_gmtoff = -1;
#endif

	temp2 = strpbrk(ptr, "T");
        temp3 = strrchr(temp2, ':');
        temp3[0] = '\0';
        len = strlen(temp2);
        temp3[0] = ':';

        if( ( temp = strpbrk( ptr, "Z") ) != NULL ) { /* got canonical UTC date */
		time_t tt = _rdfstore_xsd_mktime(val);
		if( temp != ptr1 ) {
			return 0;
			};

		if (tt == -1) {
			return 0;
			};
		ptm = localtime (&tt);
	} else if( len > (sizeof(char) * 6) ) { /* ok now we need to normalize +/-hh:mm timezone to UTC - hehheee! */
            	int hours = 0;
		int minutes = 0;
		int secs;
		time_t t;

		tzsign = strpbrk (temp2, "+");

		if (tzsign == NULL) {
			tzsign = strpbrk (temp2, "-");
			};

		timestamp = _rdfstore_xsd_mktime(val);
		if ( timestamp == -1 ) {
			return 0;
            		};

		if( sscanf( tzsign+1, "%02d:%02d", &hours, &minutes) != 2 ) {
			return 0;
			};

		secs = hours * 60 * 60 + minutes * 60;
		if( (temp = strpbrk(tzsign, "+")) != NULL ) {
			timestamp += secs;
		} else {
			timestamp -= secs;
			};
	
		ptm = localtime(&timestamp);
		memcpy(val, ptm, sizeof(struct tm));
		t = _rdfstore_xsd_mktime(val);
		if( t == -1 ) {
			return 0;
			};

		t = labs(t - d);
		ptm = gmtime(&t);
	} else { /*else it is assumed that the sent time is localtime */
		if(	( *ptr1 < 48 ) ||
			( *ptr1 > 57 ) ||
			( *(ptr1-2) != ':' ) ) {
			return 0;
			};

		timestamp = _rdfstore_xsd_mktime(val);
		if( timestamp == -1 ) {
			return 0;
			};

		ptm = gmtime(&timestamp);
		};

	if( ptm!= NULL ) {
#ifdef RDFSTORE_XSD_DEBUG
		printf("rdfstore_xsd_deserialize_dateTime( '%s' ) is a valid date\n", ptr);
#endif

		return 1;
	} else {
#ifdef RDFSTORE_XSD_DEBUG
		printf("rdfstore_xsd_deserialize_dateTime( '%s' ) is NOT a valid date\n", ptr);
#endif

		return 0;
		};
	};

void rdfstore_xsd_serialize_string( const char * value, char * result ) {
	};

int rdfstore_xsd_deserialize_string( const char * string, char * val );

/* this routine is faster than standard mktime() */
time_t _rdfstore_xsd_mktime(const struct tm * t) {
	int year;
	time_t days;
	static const int dayoffset[12] = {306, 337, 0, 31, 61, 92, 122, 153, 184, 214, 245, 275};

	year = t->tm_year;

	if (year < 70 || ((sizeof(time_t) <= 4) && (year >= 138)))
		return RDFSTORE_XSD_BAD_DATE;
    
	/* shift new year to 1st March in order to make leap year calc easy */

	if (t->tm_mon < 2)
		year--;

	/* Find number of days since 1st March 1900 (in the Gregorian calendar). */

	days = year * 365 + year / 4 - year / 100 + (year / 100 + 3) / 4;
	days += dayoffset[t->tm_mon] + t->tm_mday - 1;
	days -= 25508;              /* 1 jan 1970 is 25508 days since 1 mar 1900 */

	days = ((days * 24 + t->tm_hour) * 60 + t->tm_min) * 60 + t->tm_sec;

	if (days < 0)
        	return RDFSTORE_XSD_BAD_DATE;        /* must have overflowed */
    	else
        	return days;            /* must be a valid time */
	};

