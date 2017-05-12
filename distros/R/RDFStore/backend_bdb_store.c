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
# $Id: backend_bdb_store.c,v 1.21 2006/06/19 10:10:21 areggiori Exp $
*/

#include "dbms.h"
#include "dbms_compat.h"
#include "dbms_comms.h"

#include "rdfstore_flat_store.h"
#include "rdfstore_log.h"
#include "rdfstore.h"

#include "backend_store.h"

#include "backend_bdb_store.h"
#include "backend_bdb_store_private.h"

#include <sys/stat.h>

static char    *mkpath(char *base, char *infile);

/*
 * Some default call back functions.
 */
static void
default_myfree(void *adr)
{
	RDFSTORE_FREE(adr);
}
static void    *
default_mymalloc(size_t x)
{
	return RDFSTORE_MALLOC(x);
}
static void
default_myerror(char *err, int erx)
{
	fprintf(stderr, "backend_bdb Error[%d]: %s\n", erx, err);
}

/* backend_bdb error management */
static char     _backend_bdb_erm[256] = "\0";

/* human-readable error codes */
static char    *backend_bdb_error[] = {
	/* FLAT_STORE_E_UNDEF         2000 */
	"Not defined",
	/* FLAT_STORE_E_NONNUL        2001 */
	"Undefined Error",
	/* FLAT_STORE_E_NOMEM         2002 */
	"Out of memory",
	/* FLAT_STORE_E_NOPE          2003 */
	"No such database",
	/* FLAT_STORE_E_KEYEMPTY      2004 */
	"Key/data deleted or never created",
	/* FLAT_STORE_E_KEYEXIST      2005 */
	"The key/data pair already exists",
	/* FLAT_STORE_E_NOTFOUND      2006 */
	"Key/data pair not found",
	/* FLAT_STORE_E_OLD_VERSION   2007 */
	"Out-of-date version",
	/* FLAT_STORE_E_DBMS          2008 */
	"DBMS error",
	/* FLAT_STORE_E_CANNOTOPEN    2009 */
	"Cannot open database",
	/* FLAT_STORE_E_BUG           2010 */
	"Conceptual error"
};

void
backend_bdb_set_error(void *eme, char *msg, rdfstore_flat_store_error_t erx)
{
	backend_bdb_t  *me = (backend_bdb_t *) eme;
	bzero(me->err, sizeof(me->err));
	if (erx == FLAT_STORE_E_DBMS) {
		snprintf(me->err, sizeof(me->err), "DBMS Error %s: %s\n", msg,
			 errno == 0 ? "" : (strlen(strerror(errno)) <= sizeof(me->err)) ? strerror(errno) : "");	/* not enough... */
	} else {
		if ((erx > FLAT_STORE_E_UNDEF) && (erx <= FLAT_STORE_E_BUG)) {
			strcpy(me->err, backend_bdb_error[erx - FLAT_STORE_E_UNDEF]);
		} else {
			if (strlen(strerror(erx)) <= sizeof(me->err))
				strcpy(me->err, strerror(erx));
		};
	};
	if (strlen(me->err) <= sizeof(_backend_bdb_erm))
		strcpy(_backend_bdb_erm, me->err);

#ifdef VERBOSE
	if (me->error)
		(*(me->error)) (me->err, erx);
#endif
}


char           *
backend_bdb_get_error(void *eme)
{
	backend_bdb_t  *me = (backend_bdb_t *) eme;
	if (me == NULL)
		return _backend_bdb_erm;
	else
		return me->err;
};

/* clone a key or value for older BDB */
DBT
backend_bdb_kvdup(void *eme, DBT data)
{
	backend_bdb_t  *me = (backend_bdb_t *) eme;
	DBT             dup;

	memset(&dup, 0, sizeof(dup));

	if (data.size == 0) {
		dup.data = NULL;
		return dup;
	};

	dup.size = data.size;

	if ((dup.data = (char *) me->malloc(data.size + 1)) == NULL) {
		perror("Out of memory");
		exit(1);
	}; 	


	memcpy(dup.data, data.data, data.size);
	memcpy(dup.data + data.size, "\0", 1);

	return dup;
};

void
backend_bdb_reset_debuginfo(
			    void *eme
)
{
#ifdef RDFSTORE_FLAT_STORE_DEBUG
	backend_bdb_t  *me = (backend_bdb_t *) eme;
	me->num_store = 0;
	me->num_fetch = 0;
	me->num_inc = 0;
	me->num_dec = 0;
	me->num_sync = 0;
	me->num_next = 0;
	me->num_from = 0;
	me->num_first = 0;
	me->num_delete = 0;
	me->num_clear = 0;
	me->num_exists = 0;
#endif
};

#ifdef BERKELEY_DB_1_OR_2
static int rdfstore_backend_bdb_compare_int(
        const DBT *a,
        const DBT *b );
#else
static int rdfstore_backend_bdb_compare_int(
        DB *file,
        const DBT *a,
        const DBT *b );
#endif

#ifdef BERKELEY_DB_1_OR_2
static int rdfstore_backend_bdb_compare_double(
        const DBT *a,
        const DBT *b );
#else
static int rdfstore_backend_bdb_compare_double(
        DB *file,
        const DBT *a,
        const DBT *b );
#endif

/*
 * NOTE: all the functions return 0 on success and non zero value if error
 * (see above and include/backend_bdb.h for known error codes)
 */
rdfstore_flat_store_error_t
backend_bdb_open(
		 int remote,
		 int ro,
		 void **emme,
		 char *dir,
		 char *name,
		 unsigned int local_hash_flags,
		 char *host,
		 int port,
		 void *(*_my_malloc) (size_t size),
		 void (*_my_free) (void *),
		 void (*_my_report) (dbms_cause_t cause, int count),
		 void (*_my_error) (char *err, int erx),
		 int bt_compare_fcn_type
)
{
	backend_bdb_t **mme = (backend_bdb_t **) emme;
	backend_bdb_t  *me;
	char           *buff;
	struct stat s;
#if 0
	HASHINFO        priv = {
		16 * 1024,	/* bsize; hash bucked size */
		8,		/* ffactor, # keys/bucket */
		3000,		/* nelements, guestimate */
		512 * 1024,	/* cache size */
		NULL,		/* hash function */
		0		/* use current host order */
	};
#endif

#ifdef BERKELEY_DB_1_OR_2 /* Berkeley DB Version 1  or 2 */
#ifdef DB_VERSION_MAJOR
	DB_INFO       btreeinfo;
	memset(&btreeinfo, 0, sizeof(btreeinfo));
	btreeinfo.bt_compare = ( bt_compare_fcn_type == FLAT_STORE_BT_COMP_INT ) ? rdfstore_backend_bdb_compare_int : ( bt_compare_fcn_type == FLAT_STORE_BT_COMP_DOUBLE ) ? rdfstore_backend_bdb_compare_double : NULL ;
#else
	BTREEINFO       btreeinfo;
	memset(&btreeinfo, 0, sizeof(btreeinfo));
	btreeinfo.compare = ( bt_compare_fcn_type == FLAT_STORE_BT_COMP_INT ) ? rdfstore_backend_bdb_compare_int : ( bt_compare_fcn_type == FLAT_STORE_BT_COMP_DOUBLE ) ? rdfstore_backend_bdb_compare_double : NULL ;
#endif
#endif

	*mme = NULL;

	if (_my_error == NULL)
		_my_error = default_myerror;

	if (_my_malloc == NULL)
		_my_malloc = default_mymalloc;

	if (_my_free == NULL)
		_my_free = default_myfree;

	me = (backend_bdb_t *) _my_malloc(sizeof(backend_bdb_t));
	if (me == NULL) {
		perror("backend_bdb_open");
		return FLAT_STORE_E_NOMEM;
	};

	me->error = _my_error;
	me->malloc = _my_malloc;
	me->free = _my_free;

	me->bt_compare_fcn_type = bt_compare_fcn_type;

	bzero(me->err, sizeof(me->err));

	if (_my_report != NULL)
		me->callback = _my_report;

	backend_bdb_reset_debuginfo(me);

	if (remote) {
		backend_bdb_set_error(me, "BDB backend does not do remote storage", FLAT_STORE_E_DBMS);
		perror("backend_bdb_open");
		_my_free(me);
		return FLAT_STORE_E_CANNOTOPEN;
	};

	/* use local Berkeley DB either in-memory or physical files on disk */
	if ((dir) &&
	    (name)) {
		if(ro==1) { /* do not even try to go further if open read-only */
			if (	(stat(dir, &s) != 0) ||
				((s.st_mode & S_IFDIR) == 0) ) {
				backend_bdb_set_error(me, "Could not open database", FLAT_STORE_E_NOPE);
				perror("backend_bdb_open");
				fprintf(stderr, "Could not open database'%s'\n", dir);
				_my_free(me);
				return FLAT_STORE_E_CANNOTOPEN;
				};
			};
		/* make path */
		if (!(buff = mkpath(dir, name))) {
			backend_bdb_set_error(me, "Could not create or open database", FLAT_STORE_E_NOPE);
			perror("backend_bdb_open");
			fprintf(stderr, "Could not create or open database'%s'\n", dir);
			_my_free(me);
			return FLAT_STORE_E_CANNOTOPEN;
		};
		strcpy(me->filename, buff);
		umask(0);
	} else {
		strcpy(me->filename, "\0");
		buff = NULL;
	};

	/* something strange with BDB - it gives 'Bus error' if DB file not there and open in DB_RDONLY - why seg fault? must be DB_ENV stuff... */
	if(	(buff!=NULL) &&
		(ro==1) ) {
		if (	(stat(buff, &s) != 0) ||
			((s.st_mode & S_IFREG) == 0) ) {
			backend_bdb_set_error(me, "Could not open database", FLAT_STORE_E_NOPE);
			perror("backend_bdb_open");
			fprintf(stderr, "Could not open database '%s'\n", dir);
			_my_free(me);
			return FLAT_STORE_E_CANNOTOPEN;
			};
		};

#ifdef BERKELEY_DB_1_OR_2 /* Berkeley DB Version 1  or 2 */

#ifdef DB_VERSION_MAJOR
		if ( 	(db_open( buff, 
					DB_BTREE, ((ro==0 || buff==NULL) ? ( DB_CREATE ) : ( DB_RDONLY ) ),
					0666, NULL, &btreeinfo, &me->bdb )) ||
#if DB_VERSION_MAJOR == 2 && DB_VERSION_MINOR < 6
            		((me->bdb->cursor)(me->bdb, NULL, &me->cursor))
#else
            		((me->bdb->cursor)(me->bdb, NULL, &me->cursor, 0))
#endif
			) {
#else

#if defined(DB_LIBRARY_COMPATIBILITY_API) && DB_VERSION_MAJOR > 2
		if (!(me->bdb = (DB *)__db185_open(	buff, 
						((ro==0 || buff==NULL) ? (O_RDWR | O_CREAT) : ( O_RDONLY ) ),
						0666, DB_BTREE, &btreeinfo ))) {
#else
		/* for unpatched db-1.85 when use in-memory DB_BTREE due to mkstemp() call in hash/hash_page.c open_temp() 
		   i.e. HASHVERSION==2 we use DB_BTREE instead in CGI/mod_perl environments to avoid problems with errors
		   like 'Permission denied' due the Web server running in a different user under a different directory */

#if DIRKX_DEBUG
BTREEINFO openinfo = {
	0,
	32 * 1024 * 1024,
	0,
	atoi(getenv("PSIZE")),
	64 * 1024,
	NULL, NULL, 0
};
#endif
		if (!(me->bdb = (DB *)dbopen(	buff, 
						((ro==0 || buff==NULL) ? (O_RDWR | O_CREAT) : ( O_RDONLY ) ),
						0666,
#if HASHVERSION == 2
						( ( (buff==NULL) && (getenv("GATEWAY_INTERFACE") != NULL) ) ? DB_BTREE : DB_BTREE ),
#else
						DB_BTREE,
#endif
#if DIRKX_DEBUG
						&openinfo))) {
#else
						&btreeinfo ))) {
#endif

#endif /* DB_LIBRARY_COMPATIBILITY_API */

#endif

#else /* Berkeley DB Version > 2 */
		if (db_create(&me->bdb, NULL,0)) {
			rdfstore_flat_store_set_error((void*)me,"Could not create environment",FLAT_STORE_E_CANNOTOPEN);
			perror("rdfstore_flat_store_open");
                	fprintf(stderr,"Could not open/create '%s':\n",buff); 
			_my_free(me);
                	return FLAT_STORE_E_CANNOTOPEN;
			};

		/* set the b-tree comparinson function to the one passed */
		if( bt_compare_fcn_type != 0 ) {
			me->bdb->set_bt_compare(me->bdb, ( bt_compare_fcn_type == FLAT_STORE_BT_COMP_INT ) ? 
							rdfstore_backend_bdb_compare_int : ( bt_compare_fcn_type == FLAT_STORE_BT_COMP_DOUBLE ) ? 
												rdfstore_backend_bdb_compare_double : NULL );
			};

		me->bdb->set_errfile(me->bdb,stderr);
		me->bdb->set_errpfx(me->bdb,"BerkelyDB");
#if DB_VERSION_MAJOR == 3 && DB_VERSION_MINOR < 3
		me->bdb->set_malloc( me->bdb, me->malloc );
#elif DB_VERSION_MAJOR > 3 || DB_VERSION_MINOR >= 3
        	/* This interface appeared in 3.3 */
        	me->bdb->set_alloc( me->bdb, me->malloc, NULL, NULL ); /* could also pass me->free as 4th param but not sure how memoeyr is managed still */
#endif

#if DB_VERSION_MAJOR >= 4 && DB_VERSION_MINOR > 0 && DB_VERSION_PATCH >= 17
		if ( 	(me->bdb->open( me->bdb,
					NULL, 
					buff,
					NULL,
					DB_BTREE, ((ro==0 || buff==NULL) ? ( DB_CREATE ) : ( DB_RDONLY ) ),
					0666 )) ||
#else
		if ( 	(me->bdb->open( me->bdb,
					buff, 
					NULL,
					DB_BTREE, ((ro==0 || buff==NULL) ? ( DB_CREATE ) : ( DB_RDONLY ) ),
					0666 )) ||
#endif
			((me->bdb->cursor)(me->bdb, NULL, &me->cursor, 0)) ) {
#endif /* Berkeley DB Version > 2 */

			rdfstore_flat_store_set_error((void*)me,"Could not open/create database",FLAT_STORE_E_CANNOTOPEN);
			perror("rdfstore_flat_store_open");
                	fprintf(stderr,"Could not open/create '%s':\n",buff); 
			_my_free(me);
                	return FLAT_STORE_E_CANNOTOPEN;
			};

#ifndef BERKELEY_DB_1_OR_2 /* Berkeley DB Version > 2 */
/*
		(void)me->bdb->set_h_ffactor(me->bdb, 1024);
		(void)me->bdb->set_h_nelem(me->bdb, (u_int32_t)6000);
*/
#endif

#ifdef RDFSTORE_FLAT_STORE_DEBUG
        fprintf(stderr,"rdfstore_flat_store_open '%s'\n",me->filename);
#endif

	*mme = me;
	return 0;
}

rdfstore_flat_store_error_t
backend_bdb_close(
		  void *eme
)
{
	backend_bdb_t  *me = (backend_bdb_t *) eme;
	void            (*_my_free) (void *) = me->free;
	int             retval = 0;

#ifdef DB_VERSION_MAJOR
	me->cursor->c_close(me->cursor);
	(me->bdb->close) (me->bdb, 0);
#else
	(me->bdb->close) (me->bdb);
#endif
	_my_free(me);

#ifdef RDFSTORE_FLAT_STORE_DEBUG
	fprintf(stderr, "backend_bdb_close '%s'\n", me->filename);
#endif

	return retval;
};

rdfstore_flat_store_error_t
backend_bdb_fetch(
		  void * eme,
		  DBT key,
		  DBT * val
)
{
	backend_bdb_t  * me = (backend_bdb_t *) eme;
	int             retval = 0;

#ifdef RDFSTORE_FLAT_STORE_DEBUG
	fprintf(stderr, "backend_bdb_fetch num=%d from '%s'\n", ++(me->num_fetch), me->filename);
#endif

#if DB_VERSION_MAJOR >= 2
	memset(val, 0, sizeof(*val));
	(*val).flags = DB_DBT_MALLOC;
	retval = ((me->bdb)->get) (me->bdb, NULL, &key, val, 0);
#else
	retval = ((me->bdb)->get) (me->bdb, &key, val, 0);
#endif

	/* need to add proper client side BDB error management */
	if (retval != 0) {
#if DB_VERSION_MAJOR >= 2
		if ((*val).data && (*val).size)
			me->free((*val).data);
#endif
		memset(val, 0, sizeof(*val));
		(*val).data = NULL;

#ifdef DB_VERSION_MAJOR
		if (retval == DB_NOTFOUND) 
#else
		if (retval == 1) 
#endif	
		{
			backend_bdb_set_error(me, "Could not fetch key/value", FLAT_STORE_E_NOTFOUND);
			return FLAT_STORE_E_NOTFOUND;
		} else {
			backend_bdb_set_error(me, "Could not fetch key/value", FLAT_STORE_E_NOTFOUND);
			perror("backend_bdb_fetch");
			fprintf(stderr, "Could not fetch '%s': %s\n", me->filename, (char *) key.data);
			return FLAT_STORE_E_NOTFOUND;
		};
	} else {
#if DB_VERSION_MAJOR < 2
		/*
		 * Berkeley DB 1.85 don't malloc the data for the caller
		 * application duplicate the returned value to ensure
		 * reentrancy
		 */
		(*val) = backend_bdb_kvdup(me, *val);
#endif
		return retval;
	};
}

rdfstore_flat_store_error_t
backend_bdb_fetch_compressed(
		  void * eme,
        	  void (*func_decode)(unsigned int,unsigned char*, unsigned int *, unsigned char *),
		  DBT key,
		  unsigned int * outsize_p, unsigned char * outchar
)
{
	backend_bdb_t  *me = (backend_bdb_t *) eme;
	int             retval = 0;
	DBT 		val;
	memset(&val,0,sizeof(val));

	if ((retval = backend_bdb_fetch(eme,key,&val)))
		return retval;

	(*func_decode)(val.size,val.data,outsize_p,outchar);
	(me->free)(val.data);

	return retval;
}

rdfstore_flat_store_error_t
backend_bdb_store(
		  void *eme,
		  DBT key,
		  DBT val
)
{
	backend_bdb_t  *me = (backend_bdb_t *) eme;
	int             retval = 0;

#ifdef RDFSTORE_FLAT_STORE_DEBUG
	fprintf(stderr, "backend_bdb_store num=%d in '%s'\n", ++(me->num_store), me->filename);
#endif

#ifdef DB_VERSION_MAJOR
	retval = ((me->bdb)->put) (me->bdb, NULL, &key, &val, 0);
#else
	retval = ((me->bdb)->put) (me->bdb, &key, &val, 0);
#endif
	if (retval != 0) {
#ifdef DB_VERSION_MAJOR
		if (retval == DB_KEYEXIST) 
#else
		if (retval == 1) 
#endif
		{
			backend_bdb_set_error(me, "Could not store key/value", FLAT_STORE_E_KEYEXIST);
			return FLAT_STORE_E_KEYEXIST;
		};

		backend_bdb_set_error(me, "Could not store key/value", FLAT_STORE_E_NONNUL);
		fprintf(stderr, "Could not store '%s': %s(%d) = %s(%d) E=%d\n", me->filename, 
			(char *) key.data, (int)key.size,
			(char *) val.data, (int)val.size,
			retval);
		return FLAT_STORE_E_NONNUL;
	}
	return 0;
}

rdfstore_flat_store_error_t
backend_bdb_store_compressed(
		  void * eme,
        	  void (*func_encode)(unsigned int,unsigned char*, unsigned int *, unsigned char *),
		  DBT key,
		  unsigned int insize , unsigned char * inchar,
		  unsigned char * outbuff
)
{
	unsigned int	outsize;
	DBT 		val;
	memset(&val,0,sizeof(val));

	(*func_encode)(insize, inchar, &outsize, outbuff);

	val.data = outbuff;
	val.size = outsize;

	return backend_bdb_store(eme,key,val);
}

rdfstore_flat_store_error_t
backend_bdb_exists(
		   void *eme,
		   DBT key
)
{
	backend_bdb_t  *me = (backend_bdb_t *) eme;
	int             retval;
	DBT             val;
	memset(&val,0,sizeof(val));

#ifdef RDFSTORE_FLAT_STORE_DEBUG
	fprintf(stderr, "backend_bdb_exists num=%d from '%s'\n", ++(me->num_exists), me->filename);
#endif


	memset(&val, 0, sizeof(val));

	/*
	 * here we do not care about memory management due that we just want
	 * to know whether or not the given key exists
	 */

#if DB_VERSION_MAJOR >= 2
	retval = ((me->bdb)->get) (me->bdb, NULL, &key, &val, 0);
#else
	retval = ((me->bdb)->get) (me->bdb, &key, &val, 0);
#endif
	return retval;
};

rdfstore_flat_store_error_t
backend_bdb_delete(
		   void *eme,
		   DBT key
)
{
	backend_bdb_t  *me = (backend_bdb_t *) eme;
	int             retval;

#ifdef RDFSTORE_FLAT_STORE_DEBUG
	fprintf(stderr, "backend_bdb_delete num=%d from '%s'\n", ++(me->num_delete), me->filename);
#endif

#ifdef DB_VERSION_MAJOR
	retval = ((me->bdb)->del) (me->bdb, NULL, &key, 0);
	if( retval == DB_NOTFOUND )
		return FLAT_STORE_E_NOTFOUND;
#else
	retval = ((me->bdb)->del) (me->bdb, &key, 0);
	if ( retval == 1 )
		return FLAT_STORE_E_NOTFOUND;
#endif
	return retval;
};

rdfstore_flat_store_error_t
backend_bdb_clear(
		  void *eme
)
{
	backend_bdb_t  *me = (backend_bdb_t *) eme;
	char           *buff;

#ifdef BERKELEY_DB_1_OR_2 /* Berkeley DB Version 1  or 2 */
#ifdef DB_VERSION_MAJOR
        DB_INFO       btreeinfo;
        memset(&btreeinfo, 0, sizeof(btreeinfo));
        btreeinfo.bt_compare = ( me->bt_compare_fcn_type == FLAT_STORE_BT_COMP_INT ) ? rdfstore_backend_bdb_compare_int : ( me->bt_compare_fcn_type == FLAT_STORE_BT_COMP_DOUBLE ) ? rdfstore_backend_bdb_compare_double : NULL ;
#else
        BTREEINFO       btreeinfo;
        memset(&btreeinfo, 0, sizeof(btreeinfo));
        btreeinfo.compare = ( me->bt_compare_fcn_type == FLAT_STORE_BT_COMP_INT ) ? rdfstore_backend_bdb_compare_int : ( me->bt_compare_fcn_type == FLAT_STORE_BT_COMP_DOUBLE ) ? rdfstore_backend_bdb_compare_double : NULL  ;
#endif
#endif

#ifdef RDFSTORE_FLAT_STORE_DEBUG
	me->num_store = 0;
	me->num_fetch = 0;
	me->num_inc = 0;
	me->num_dec = 0;
	me->num_sync = 0;
	me->num_next = 0;
	me->num_from = 0;
	me->num_first = 0;
	me->num_delete = 0;
	me->num_exists = 0;
	fprintf(stderr, "backend_bdb_clear num=%d in '%s'\n", ++(me->num_clear), me->filename);
#endif


	/* close the database, remove the file, and repoen... ? */
	/* close */
#ifdef DB_VERSION_MAJOR
	me->cursor->c_close(me->cursor);
	(me->bdb->close) (me->bdb, 0);
#else
	(me->bdb->close) (me->bdb);
#endif

	if (strcmp(me->filename, "\0") != 0) {
		/* remove db file (not the directory!) */
		if (unlink(me->filename)) {
			perror("backend_bdb_clear");
			fprintf(stderr, "Could not remove '%s' while clearing\n", me->filename);
			return -1;
		};
		buff = me->filename;
		umask(0);
	} else {
		buff = NULL;
	};

	/* re-open */

#ifdef BERKELEY_DB_1_OR_2	/* Berkeley DB Version 1  or 2 */

#ifdef DB_VERSION_MAJOR
	if ((db_open(buff,
		     DB_BTREE, DB_CREATE,
		     0666, NULL, &btreeinfo, &me->bdb)) ||
#if DB_VERSION_MAJOR == 2 && DB_VERSION_MINOR < 6
	    ((me->bdb->cursor) (me->bdb, NULL, &me->cursor))
#else
	    ((me->bdb->cursor) (me->bdb, NULL, &me->cursor, 0))
#endif
		) {
#else

#if defined(DB_LIBRARY_COMPATIBILITY_API) && DB_VERSION_MAJOR > 2
	if (!(me->bdb = (DB *) __db185_open(buff,
					    O_RDWR | O_CREAT,
					    0666, DB_BTREE, &btreeinfo))) {
#else
	if (!(me->bdb = (DB *) dbopen(buff,
				      O_RDWR | O_CREAT,
				      0666, DB_BTREE, &btreeinfo))) {
#endif				/* DB_LIBRARY_COMPATIBILITY_API */

#endif

#else				/* Berkeley DB Version > 2 */
	if (db_create(&me->bdb, NULL, 0)) {
		backend_bdb_set_error(me, "Could not open/create database", FLAT_STORE_E_CANNOTOPEN);
		perror("backend_bdb_open");
		fprintf(stderr, "Could not open/create '%s':\n", buff);
		return FLAT_STORE_E_CANNOTOPEN;
	};

	/* set the b-tree comparinson function to the one passed */
	if( me->bt_compare_fcn_type != 0 ) {
		me->bdb->set_bt_compare(me->bdb, ( me->bt_compare_fcn_type == FLAT_STORE_BT_COMP_INT ) ? 
						rdfstore_backend_bdb_compare_int : ( me->bt_compare_fcn_type == FLAT_STORE_BT_COMP_DOUBLE ) ? 
											rdfstore_backend_bdb_compare_double : NULL );
		};

	me->bdb->set_errfile(me->bdb,stderr);
	me->bdb->set_errpfx(me->bdb,"BerkelyDB");
#if DB_VERSION_MAJOR == 3 && DB_VERSION_MINOR < 3
	me->bdb->set_malloc(me->bdb, me->malloc);
#elif DB_VERSION_MAJOR > 3 || DB_VERSION_MINOR >= 3
	/* This interface appeared in 3.3 */
	me->bdb->set_alloc(me->bdb, me->malloc, NULL, NULL);	/* could also pass
								 * me->free as 4th param
								 * but not sure how
								 * memoeyr is managed
								 * still */
#endif

#if DB_VERSION_MAJOR >= 4 && DB_VERSION_MINOR > 0 && DB_VERSION_PATCH >= 17
	if ((me->bdb->open(me->bdb,
			   NULL,
			   buff,
			   NULL,
			   DB_BTREE, DB_CREATE,
			   0666)) ||
#else
	if ((me->bdb->open(me->bdb,
			   buff,
			   NULL,
			   DB_BTREE, DB_CREATE,
			   0666)) ||
#endif
	    ((me->bdb->cursor) (me->bdb, NULL, &me->cursor, 0))) {
#endif				/* Berkeley DB Version > 2 */

		perror("backend_bdb_clear");
		fprintf(stderr, "Could not open/create '%s' while clearing\n", buff);
		return -1;
	};
	return 0;
};

rdfstore_flat_store_error_t
backend_bdb_from(
		  void *eme,
		  DBT closest_key,
		  DBT * key
)
{
	backend_bdb_t  *me = (backend_bdb_t *) eme;
	int             retval;
	DBT             val;

#ifdef RDFSTORE_FLAT_STORE_DEBUG
	fprintf(stderr, "backend_bdb_from num=%d from '%s'\n", ++(me->num_from), me->filename);
#endif

	memset(&val, 0, sizeof(val));

	/* seek to closest_key and discard val */
	memcpy(key, &closest_key, sizeof(closest_key));

#if DB_VERSION_MAJOR >= 2
	retval = (me->cursor->c_get) (me->cursor, key, &val, DB_SET_RANGE);
#else
	retval = (me->bdb->seq) (me->bdb, key, &val, R_CURSOR);
#endif

	if (retval == 0) {
                /*
                 * to ensure reentrancy we do a copy into caller space of what BDB layer returns
                 */
		(*key) = backend_bdb_kvdup(me, *key);
                };
	return retval;
};

rdfstore_flat_store_error_t
backend_bdb_first(
		  void *eme,
		  DBT * first_key
)
{
	backend_bdb_t  *me = (backend_bdb_t *) eme;
	int             retval;
	DBT             val;

#ifdef RDFSTORE_FLAT_STORE_DEBUG
	fprintf(stderr, "backend_bdb_first num=%d from '%s'\n", ++(me->num_first), me->filename);
#endif

	memset(first_key, 0, sizeof(*first_key));
	memset(&val, 0, sizeof(val));

#if DB_VERSION_MAJOR >= 2
	retval = (me->cursor->c_get) (me->cursor, first_key, &val, DB_FIRST);
#else
	retval = (me->bdb->seq) (me->bdb, first_key, &val, R_FIRST);
#endif

	if (retval == 0) {
		/*
		 * to ensure reentrancy we do a copy into caller space of what BDB layer returns
		 */
		(*first_key) = backend_bdb_kvdup(me, *first_key);
		};

	return retval;
};

rdfstore_flat_store_error_t
backend_bdb_next(
		 void *eme,
		 DBT previous_key,
		 DBT * next_key
)
{
	backend_bdb_t  *me = (backend_bdb_t *) eme;
	int             retval;
	DBT             val;

#ifdef RDFSTORE_FLAT_STORE_DEBUG
	fprintf(stderr, "backend_bdb_next num=%d from '%s'\n", ++(me->num_next), me->filename);
#endif

	memset(next_key, 0, sizeof(*next_key));
	memset(&val, 0, sizeof(val));

	/* we really do not use/consider previous_key to carry out next_key - val is discarded */

#if DB_VERSION_MAJOR >= 2
	retval = (me->cursor->c_get) (me->cursor, next_key, &val, DB_NEXT);
#else
	retval = (me->bdb->seq) (me->bdb, next_key, &val, R_NEXT);
#endif

	if (retval == 0) {
                /*
                 * to ensure reentrancy we do a copy into caller space of what BDB layer returns
                 */
		(*next_key) = backend_bdb_kvdup(me, *next_key);
                };

	return retval;
};

/* packed rdf_store_counter_t increment */
rdfstore_flat_store_error_t
backend_bdb_inc(
		void *eme,
		DBT key,
		DBT * new_value
)
{
	backend_bdb_t  *me = (backend_bdb_t *) eme;
	int             retval;
	rdf_store_counter_t l = 0;
	unsigned char   outbuf[256];

#ifdef RDFSTORE_FLAT_STORE_DEBUG
	fprintf(stderr, "backend_bdb_inc num=%d in '%s'\n", ++(me->num_inc), me->filename);
#endif


	/* it should be atomic with locking here... */
#if DB_VERSION_MAJOR >= 2
	memset(new_value, 0, sizeof(*new_value));
	(*new_value).flags = DB_DBT_MALLOC;
	if ((((me->bdb)->get) (me->bdb, NULL, &key, new_value, 0)) != 0) {
		return -1;
	};
#else
	if ((((me->bdb)->get) (me->bdb, &key, new_value, 0)) != 0) {
		return -1;
	};
#endif
	unpackInt(new_value->data, &l);
	l++;
#if DB_VERSION_MAJOR >= 2
	if ((*new_value).data && (*new_value).size)
		me->free((*new_value).data);
#endif
	(*new_value).data = outbuf;
	(*new_value).size = sizeof(rdf_store_counter_t);
	packInt(l, new_value->data);

#ifdef DB_VERSION_MAJOR
	retval = ((me->bdb)->put) (me->bdb, NULL, &key, new_value, 0);
#else
	retval = ((me->bdb)->put) (me->bdb, &key, new_value, 0);
#endif

	if (retval != 0) {
		memset(new_value, 0, sizeof(*new_value));
		(*new_value).data = NULL;
	} else {
		(*new_value) = backend_bdb_kvdup(me, *new_value);
	};
	return retval;
};

/* packed rdf_store_counter_t decrement */
rdfstore_flat_store_error_t
backend_bdb_dec(
		void *eme,
		DBT key,
		DBT * new_value
)
{
	backend_bdb_t  *me = (backend_bdb_t *) eme;
	int             retval;
	rdf_store_counter_t l = 0;
	unsigned char   outbuf[256];

#ifdef RDFSTORE_FLAT_STORE_DEBUG
	fprintf(stderr, "backend_bdb_dec num=%d from '%s'\n", ++(me->num_dec), me->filename);
#endif


	/* it should be atomic with locking here... */
#if DB_VERSION_MAJOR >= 2
	memset(new_value, 0, sizeof(*new_value));
	(*new_value).flags = DB_DBT_MALLOC;
	if ((((me->bdb)->get) (me->bdb, NULL, &key, new_value, 0)) != 0) {
		return -1;
	};
#else
	if ((((me->bdb)->get) (me->bdb, &key, new_value, 0)) != 0) {
		return -1;
	};
#endif
	unpackInt(new_value->data, &l);
	assert(l > 0);
	l--;
#if DB_VERSION_MAJOR >= 2
	if ((*new_value).data && (*new_value).size)
		me->free((*new_value).data);
#endif
	(*new_value).data = outbuf;
	(*new_value).size = sizeof(rdf_store_counter_t);
	packInt(l, new_value->data);

#ifdef DB_VERSION_MAJOR
	retval = ((me->bdb)->put) (me->bdb, NULL, &key, new_value, 0);
#else
	retval = ((me->bdb)->put) (me->bdb, &key, new_value, 0);
#endif

	if (retval != 0) {
		memset(new_value, 0, sizeof(*new_value));
		(*new_value).data = NULL;
	} else {
		(*new_value) = backend_bdb_kvdup(me, *new_value);
	};
	return retval;
};

rdfstore_flat_store_error_t
backend_bdb_sync(
		 void *eme
)
{
	backend_bdb_t  *me = (backend_bdb_t *) eme;
	int             retval;

#ifdef RDFSTORE_FLAT_STORE_DEBUG
	fprintf(stderr, "backend_bdb_sync num=%d in '%s'\n", ++(me->num_sync), me->filename);
#endif

	retval = (me->bdb->sync) (me->bdb, 0);
#ifdef DB_VERSION_MAJOR
	if (retval > 0)
		retval = -1;
#endif
	return retval;
}

int
backend_bdb_isremote(
		     void *eme
)
{
	return 0;
}

/* misc subroutines */

/*
 * The following compare function are used for btree(s) for basic
 * XML-Schema data types xsd:integer, xsd:double (and will xsd:date)
 *
 * They return:
 *      < 0 if a < b
 *      = 0 if a = b
 *      > 0 if a > b
 */
#ifdef BERKELEY_DB_1_OR_2
static int rdfstore_backend_bdb_compare_int(
        const DBT *a,
        const DBT *b ) {
#else
static int rdfstore_backend_bdb_compare_int(
        DB *file,
        const DBT *a,
        const DBT *b ) {
#endif
        long ai, bi;

        memcpy(&ai, a->data, sizeof(long));
        memcpy(&bi, b->data, sizeof(long));

        return (ai - bi);
        };

#ifdef BERKELEY_DB_1_OR_2
static int rdfstore_backend_bdb_compare_double(
        const DBT *a,
        const DBT *b ) {
#else
static int rdfstore_backend_bdb_compare_double(
        DB *file,
        const DBT *a,
        const DBT *b ) {
#endif
        double ad,bd;

        memcpy(&ad, a->data, sizeof(double));
        memcpy(&bd, b->data, sizeof(double));

        if (  ad <  bd ) {
                return -1;
        } else if (  ad  >  bd) {
                return 1;
                };

        return 0;
        };

/*
 * returns null and/or full path to a hashed directory tree. the final
 * filename is hashed out within that three. Way to complex by now. Lifted
 * from another project which needed more.
 */
static char    *
mkpath(char *base, char *infile)
{
	char           *file;
	int             i, j;
	int             last;
	struct stat     s;
	char           *slash, *dirname;
	char           *inpath;
	static char     tmp[MAXPATHLEN];
	char            tmp2[MAXPATHLEN];
#define MAXHASH 2
	static char     hash[MAXHASH + 1];

	tmp[0] = '\0';

	strcpy(inpath = tmp2, infile);

	memset(hash, '_', MAXHASH);
	hash[MAXHASH] = '\0';

	if (base == NULL)
		base = "./";

	if (inpath == NULL || inpath[0] == '\0') {
		fprintf(stderr, "No filename or path for the database specified\n");
		return NULL;
	};

	/*
	 * remove our standard docroot if present so we can work with
	 * something relative. really a legacy thing from older perl DBMS.pm
	 * versions. Can go now.
	 */
	if (!(strncmp(base, inpath, strlen(base))))
		inpath += strlen(base);

	/*
	 * fetch the last leaf name
	 */
	if ((file = strrchr(inpath, '/')) != NULL) {
		*file = '\0';
		file++;
	} else {
		file = inpath;
		inpath = "/";
	};

	if (!strlen(file)) {
		fprintf(stderr, "No filename for the database specified\n");
		return NULL;
	};

	strncpy(hash, file, MIN(strlen(file), MAXHASH));

	/*
	        strcpy(tmp,"./");
	*/
	strcat(tmp, base);
	strcat(tmp, "/");
	strcat(tmp, inpath);
	strcat(tmp, "/");
	strcat(tmp, hash);
	strcat(tmp, "/");
	strcat(tmp, file);

	if ((slash = strrchr(tmp, '.')) != NULL) {
		if ((!strcasecmp(slash + 1, "db")) ||
		    (!strcasecmp(slash + 1, "dbm")) ||
		    (!strcasecmp(slash + 1, "gdb"))
			)
			*slash = '\0';
	};

	strcat(tmp, ".db");

	for (i = 0, j = 0; tmp[i]; i++) {
		if (i && tmp[i] == '/' && tmp[i - 1] == '/')
			continue;
		if (i != j)
			tmp[j] = tmp[i];
		j++;
	};
	tmp[j] = '\0';

	dirname = tmp;

	/* Skip leading './'. */
	if (dirname[0] == '.')
		++dirname;
	if (dirname[0] == '/')
		++dirname;

	for (last = 0; !last; ++dirname) {
		if (dirname[0] == '\0')
			break;
		else if (dirname[0] != '/')
			continue;
		*dirname = '\0';
		if (dirname[1] == '\0')
			last = 1;

		/*
		 * check if tmp exists and is a directory (or a link to one..
		 * if not, create it, else give an error
		 */
		if (stat(tmp, &s) == 0) {
			/*
			 * something exists.. it must be a directory
			 */
			if ((s.st_mode & S_IFDIR) == 0) {
				fprintf(stderr, "Creation of %s failed; path element not directory\n", tmp);
				return NULL;
			};
		} else if (errno == ENOENT) {
			if ((mkdir(tmp, (S_IRWXU | S_IRWXG | S_IRWXO))) != 0) {
				fprintf(stderr, "Creation of %s failed; %s\n", tmp, strerror(errno));
				return NULL;
			};
		} else {
			fprintf(stderr, "Path creation to failed at %s:%s\n", tmp, strerror(errno));
			return NULL;
		};
		if (!last)
			*dirname = '/';
	}

	return tmp;
}

#define BDB_VERSION (100)
DECLARE_MODULE_BACKEND(backend_bdb, "BerkelyDB", BDB_VERSION)
