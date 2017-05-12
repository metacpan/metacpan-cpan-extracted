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
# $Id: rdfstore_flat_store.c,v 1.25 2006/06/19 10:10:21 areggiori Exp $
*/
#include "dbms.h"
#include "dbms_compat.h"
#include "dbms_comms.h"

/* Public API of flat store */
#include "rdfstore_flat_store.h"

/* Generic backend API */
#include "backend_store.h"

#include "rdfstore_log.h"
#include "rdfstore.h"

#include "rdfstore_flat_store_private.h"

#include "backend_bdb_store.h"
#include "backend_dbms_store.h"
#include "backend_caching_store.h"

static void     default_myfree(void *adr) {
	RDFSTORE_FREE(adr);
}
static void    *default_mymalloc(size_t x) {
	return RDFSTORE_MALLOC(x);
}
static void     default_myerror(char *err, int erx) {
	fprintf(stderr, "rdfstore_flat_store Error[%d]: %s\n", erx, err);
}

void
rdfstore_flat_store_set_error(FLATDB * me, char *msg, rdfstore_flat_store_error_t erx) {
	if ( me == NULL )
		return;

	if (me && me->store)
		(*(me->store->set_error)) (me->instance, msg, erx);
	else
		perror(msg);
	};

char *
rdfstore_flat_store_get_error(FLATDB * me) {
	if ( me == NULL )
                return NULL;

	return (*(me->store->get_error)) (me->instance);
	};

/* clone a key or value for older BDB */
DBT
rdfstore_flat_store_kvdup(FLATDB * me, DBT data) {
	return (*(me->store->kvdup)) (me->instance, data);
	};

#ifdef RDFSTORE_FLAT_STORE_DEBUG
void 
rdfstore_flat_store_reset_debuginfo(
				    FLATDB * me
) {
	if ( me == NULL )
                return;

	(*(me->store->reset_debuginfo)) (me->instance);
}
#endif

/*
 * NOTE: all the functions return 0 on success and non zero value if error
 * (see above and include/rdfstore_flat_store.h for known error codes)
 */
rdfstore_flat_store_error_t
rdfstore_flat_store_open(
			 int remote,
			 int ro,
			 FLATDB * *mme,
			 char *dir,
			 char *name,
			 unsigned int local_hash_flags,
			 char *host,
			 int port,
			 void *(*_my_malloc) (size_t size),
			 void (*_my_free) (void *),
			 void (*_my_report) (dbms_cause_t cause, int count),
			 void (*_my_error) (char *err, int erx),
			 int bt_compare_fcn_type ) {
	FLATDB         *me;
	rdfstore_flat_store_error_t err;

	if (getenv("RDFSTORE_CACHE"))
		remote |= 0x10;

	if (_my_error == NULL)
		_my_error = default_myerror;

	if (_my_malloc == NULL)
		_my_malloc = default_mymalloc;

	if (_my_free == NULL)
		_my_free = default_myfree;

	me = (FLATDB *) _my_malloc(sizeof(FLATDB));

	if (me == NULL) {
		perror("Out of memory during flat store backend creation.");
		return FLAT_STORE_E_NOMEM;
	};

	switch (remote) {
	case 0x0:
		me->store = backend_bdb;
		break;
	case 0x1:
		me->store = backend_dbms;
		break;
	case 0x10:
	case 0x11:
		me->store = backend_caching;
		break;
	default:
		perror("Backend type is not available");
		return FLAT_STORE_E_NOMEM;
		break;
	};

	
	err = (*(me->store->open)) (
	 			remote, ro, (void **) &(me->instance), 
				dir, name, local_hash_flags, host, port,
			       _my_malloc, _my_free, _my_report, _my_error,
				bt_compare_fcn_type
	);
	if (err) {
		(*_my_free) (me);
		return err;
	}
	me->free = _my_free;

#ifdef RDFSTORE_FLAT_STORE_DEBUG
	rdfstore_flat_store_reset_debuginfo(me);
#endif

	*mme = me;		/* XXX need to check with alberto what this
				 * is XXX */
	return 0;
	};

rdfstore_flat_store_error_t
rdfstore_flat_store_close(
			  FLATDB * me
) {
	void            (*_my_free) (void *) = me->free;
	int             retval = 0;

	if ( me == NULL )
                return FLAT_STORE_E_UNDEF;

	retval = (*(me->store->close)) (me->instance);
	_my_free(me);

#ifdef RDFSTORE_FLAT_STORE_DEBUG
	fprintf(stderr, "rdfstore_flat_store_close '%s'\n", me->filename);
#endif

	return retval;
	};

rdfstore_flat_store_error_t
rdfstore_flat_store_fetch(
			  FLATDB * me,
			  DBT key,
			  DBT * val
) {
	if ( me == NULL )
                return FLAT_STORE_E_UNDEF;

	return (*(me->store->fetch)) (me->instance, key, val);
	};

rdfstore_flat_store_error_t
rdfstore_flat_store_fetch_compressed (
        FLATDB * me,
        void(*func_decode)(unsigned int,unsigned char*, unsigned int *, unsigned char *),
        DBT     key,
        unsigned int * outsize, unsigned char * outchar ) {

	if ( me == NULL )
                return FLAT_STORE_E_UNDEF;

	return (*(me->store->fetch_compressed))(me->instance,func_decode,key,outsize,outchar);
	};


rdfstore_flat_store_error_t
rdfstore_flat_store_store(
			  FLATDB * me,
			  DBT key,
			  DBT val ) {
	
	if ( me == NULL )
                return FLAT_STORE_E_UNDEF;

	return (*(me->store->store)) (me->instance, key, val);
	};

rdfstore_flat_store_error_t
rdfstore_flat_store_store_compressed (
        FLATDB * me,
        void(*func_encode)(unsigned int,unsigned char*, unsigned int *, unsigned char *),
        DBT     key, 
        unsigned int insize, unsigned char * inchar,
        unsigned char * buff ) {

	if ( me == NULL )
                return FLAT_STORE_E_UNDEF;

	return (*(me->store->store_compressed))(me->instance,func_encode,key,insize,inchar,buff);
	};

rdfstore_flat_store_error_t
rdfstore_flat_store_exists(
			   FLATDB * me,
			   DBT key ) {

	if ( me == NULL )
                return FLAT_STORE_E_UNDEF;

	return (*(me->store->exists)) (me->instance, key);
	};

rdfstore_flat_store_error_t
rdfstore_flat_store_delete(
			   FLATDB * me,
			   DBT key ) {

	if ( me == NULL )
                return FLAT_STORE_E_UNDEF;

	return (*(me->store->delete)) (me->instance, key);
	};

rdfstore_flat_store_error_t
rdfstore_flat_store_clear(
			  FLATDB * me ) {
	
	if ( me == NULL )
                return FLAT_STORE_E_UNDEF;

	return (*(me->store->clear)) (me->instance);
	};

rdfstore_flat_store_error_t
rdfstore_flat_store_from(
			  FLATDB * me,
			  DBT closest_key,
			  DBT * key ) {
	
	if ( me == NULL )
                return FLAT_STORE_E_UNDEF;

	return (*(me->store->from)) (me->instance, closest_key, key);
	};

rdfstore_flat_store_error_t
rdfstore_flat_store_first(
			  FLATDB * me,
			  DBT * key ) {
	
	if ( me == NULL )
                return FLAT_STORE_E_UNDEF;

	return (*(me->store->first)) (me->instance, key);
	};

rdfstore_flat_store_error_t
rdfstore_flat_store_next(
			 FLATDB * me,
			 DBT previous_key,
			 DBT * next_key ) {

	if ( me == NULL )
                return FLAT_STORE_E_UNDEF;

	return (*(me->store->next)) (me->instance, previous_key, next_key);
	};

rdfstore_flat_store_error_t
rdfstore_flat_store_inc(
			FLATDB * me,
			DBT key,
			DBT * new_value ) {

	if ( me == NULL )
                return FLAT_STORE_E_UNDEF;

	return (*(me->store->inc)) (me->instance, key, new_value);
	};

/* packed rdf_store_counter_t decrement */
rdfstore_flat_store_error_t
rdfstore_flat_store_dec(
			FLATDB * me,
			DBT key,
			DBT * new_value ) {

	if ( me == NULL )
                return FLAT_STORE_E_UNDEF;

	return (*(me->store->dec)) (me->instance, key, new_value);
	};

rdfstore_flat_store_error_t
rdfstore_flat_store_sync(
			 FLATDB * me ) {

	if ( me == NULL )
                return FLAT_STORE_E_UNDEF;

	return (*(me->store->sync)) (me->instance);
	};

int
rdfstore_flat_store_isremote(
			     FLATDB * me ) {

	if ( me == NULL )
                return -1;

	return (*(me->store->isremote)) (me->instance);
	};

