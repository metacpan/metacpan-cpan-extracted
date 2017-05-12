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
# $Id: backend_store.h,v 1.6 2006/06/19 10:10:23 areggiori Exp $
#
*/

#ifndef _H_BACKEND_STORE
#define _H_BACKEND_STORE

typedef struct backend_store_struct {
	const int api_version;
	const char * name;
	const int version;
	rdfstore_flat_store_error_t (*open)(int remote, int ro, void * * mme, char * dir,
			char * name, unsigned int local_hash_flags, char *          host, int             port,
        		void *(*_my_malloc)( size_t size), void(*_my_free)(void *),
			void(*_my_report)(dbms_cause_t cause, int count), void(*_my_error)(char * err, int erx),
			int bt_compare_fcn_type
		);
	rdfstore_flat_store_error_t (*close) (void * me);
	rdfstore_flat_store_error_t (*fetch) (void * me, DBT key, DBT * val);
	rdfstore_flat_store_error_t (*fetch_compressed) (void * me, 
		void(*func_decode)(unsigned int,unsigned char*, unsigned int *, unsigned char *),
		DBT key, 
		unsigned int * outsize, unsigned char * outchar);
	rdfstore_flat_store_error_t (*store) (void * me, DBT key, DBT val);
	rdfstore_flat_store_error_t (*store_compressed) (void * me, 
		void(*func_encode)(unsigned int,unsigned char*, unsigned int *, unsigned char *),
		DBT key, 
		unsigned int, unsigned char *, 
		unsigned char *);
	rdfstore_flat_store_error_t (*exists) (void * me, DBT key); 
	rdfstore_flat_store_error_t (*delete) (void * me, DBT key); 
	rdfstore_flat_store_error_t (*sync) (void * me); 
	rdfstore_flat_store_error_t (*clear) (void * me);
	rdfstore_flat_store_error_t (*from) (void * me, DBT closest_key, DBT * key);
	rdfstore_flat_store_error_t (*first) (void * me, DBT * first_key);
	rdfstore_flat_store_error_t (*next) (void * me, DBT previous_key, DBT * next_key);
	rdfstore_flat_store_error_t (*inc) (void * me, DBT key, DBT * new_value);
	rdfstore_flat_store_error_t (*dec) (void * me, DBT key, DBT * new_value); 
	void (*reset_debuginfo)( void * me );
	void (*set_error)(void * me,  char * msg, rdfstore_flat_store_error_t erx);
	char *(*get_error)(void * me);
	DBT (*kvdup)( void * me, DBT data );
	int (*isremote)(void * me);
	} backend_store_t;

#define API (2004111401)

#define DECLARE_MODULE_BACKEND( prefix, name, version ) \
backend_store_t prefix ## _module = { \
	API,\
	name, \
	version, \
	&prefix ## _open, \
	&prefix ## _close, \
	&prefix ## _fetch, \
	&prefix ## _fetch_compressed, \
	&prefix ## _store, \
	&prefix ## _store_compressed, \
	&prefix ## _exists, \
	&prefix ## _delete, \
	&prefix ## _sync, \
	&prefix ## _clear, \
	&prefix ## _from, \
	&prefix ## _first, \
	&prefix ## _next, \
	&prefix ## _inc, \
	&prefix ## _dec, \
	&prefix ## _reset_debuginfo, \
	&prefix ## _set_error, \
	&prefix ## _get_error, \
	&prefix ## _kvdup, \
	&prefix ## _isremote \
	}; \
backend_store_t * prefix = & prefix ## _module;
#endif

