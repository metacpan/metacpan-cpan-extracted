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
# $Id: rdfstore_flat_store.h,v 1.8 2006/06/19 10:10:23 areggiori Exp $
#
*/

#ifndef _H_RDFSTORE_FLATSTORE
#define _H_RDFSTORE_FLATSTORE

/* Note that this structure is private */
typedef struct __flatdb FLATDB;

/* flat_store error management */
typedef int rdfstore_flat_store_error_t;

/* error codes */
#define FLAT_STORE_E_UNDEF            2000
#define FLAT_STORE_E_NONNUL           2001
#define FLAT_STORE_E_NOMEM            2002
#define FLAT_STORE_E_NOPE             2003
#define FLAT_STORE_E_KEYEMPTY         2004
#define FLAT_STORE_E_KEYEXIST         2005
#define FLAT_STORE_E_NOTFOUND         2006
#define FLAT_STORE_E_OLD_VERSION      2007
#define FLAT_STORE_E_DBMS             2008
#define FLAT_STORE_E_CANNOTOPEN       2009
#define FLAT_STORE_E_BUG              2010

#define FLAT_STORE_BT_COMP_INT	      7000
#define FLAT_STORE_BT_COMP_DOUBLE     7001
#define FLAT_STORE_BT_COMP_DATE	      7002 /* not implemented yet */

#ifdef RDFSTORE_FLAT_STORE_DEBUG
void rdfstore_flat_store_reset_debuginfo( FLATDB * me );
#endif

void rdfstore_flat_store_set_error(FLATDB * me,  char * msg, rdfstore_flat_store_error_t erx);
char * rdfstore_flat_store_get_error(FLATDB * me);

DBT rdfstore_flat_store_kvdup( FLATDB * me, DBT data );

rdfstore_flat_store_error_t
rdfstore_flat_store_open ( 
	int remote,
	int ro,
	FLATDB * * mme,
	char * dir,
	char * name,
	unsigned int local_hash_flags,
	char *          host,
        int             port,
	/* OPTIONAL functions to pass free/malloc and
	 * a warning/error report 
    	 */
        void *(*_my_malloc)( size_t size),
        void(*_my_free)(void *),
        void(*_my_report)(dbms_cause_t cause, int count),
        void(*_my_error)(char * err, int erx),
	int bt_compare_fcn_type
	);

rdfstore_flat_store_error_t
rdfstore_flat_store_close ( 
	FLATDB * me
	);

rdfstore_flat_store_error_t
rdfstore_flat_store_fetch (
	FLATDB * me,
	DBT 	key,
	DBT    * val
	);

rdfstore_flat_store_error_t
rdfstore_flat_store_fetch_compressed (
	FLATDB * me,
        void(*func_decode)(unsigned int,unsigned char*, unsigned int *, unsigned char *),
	DBT 	key,
	unsigned int * outsize, unsigned char * outchar
	);

rdfstore_flat_store_error_t
rdfstore_flat_store_store (
	FLATDB * me,
	DBT 	key,
	DBT 	val
	);

rdfstore_flat_store_error_t
rdfstore_flat_store_store_compressed (
	FLATDB * me,
        void(*func_encode)(unsigned int,unsigned char*, unsigned int *, unsigned char *),
	DBT 	key,
	unsigned int insize, unsigned char * inchar,
	unsigned char * buff
	);

rdfstore_flat_store_error_t
rdfstore_flat_store_exists (
	FLATDB * me,
	DBT 	key
	);

rdfstore_flat_store_error_t
rdfstore_flat_store_delete (
	FLATDB * me,
	DBT 	key
	);

rdfstore_flat_store_error_t
rdfstore_flat_store_sync (
	FLATDB * me
	);

rdfstore_flat_store_error_t
rdfstore_flat_store_clear (
	FLATDB * me
	);

rdfstore_flat_store_error_t
rdfstore_flat_store_from(
	FLATDB * me,
	DBT closest_key,
	DBT * key
	);

rdfstore_flat_store_error_t
rdfstore_flat_store_first (
	FLATDB * me,
	DBT    * first_key
	);

rdfstore_flat_store_error_t
rdfstore_flat_store_next (
	FLATDB * me,
	DBT 	previous_key,
	DBT    * next_key
	);

rdfstore_flat_store_error_t
rdfstore_flat_store_inc (
	FLATDB * me,
	DBT 	key,
	DBT    * new_value
	);

rdfstore_flat_store_error_t
rdfstore_flat_store_dec (
	FLATDB * me,
	DBT 	key,
	DBT    * new_value
	);
#endif

int
rdfstore_flat_store_isremote(
	FLATDB * me
);

#ifndef MIN
#define MIN(a,b) ( (a)>(b) ? (b) : (a) )
#endif
