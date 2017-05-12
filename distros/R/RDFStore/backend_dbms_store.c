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
# $Id: backend_dbms_store.c,v 1.10 2006/06/19 10:10:21 areggiori Exp $
*/
#include "dbms.h"
#include "dbms_compat.h"
#include "dbms_comms.h"

#include "db.h"

#include "rdfstore_flat_store.h"
#include "rdfstore_log.h"
#include "rdfstore.h"

#include "backend_store.h"
#include "backend_dbms_store.h"
#include "backend_dbms_store_private.h"

/* dbms_store error management */
static char     _dbms_store_erm[256] = "\0";

/* human-readable error codes */
static char    *dbms_store_error[] = {
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
	fprintf(stderr, "backend_dbms_ Error[%d]: %s\n", erx, err);
}

void
backend_dbms_set_error(
		       void *eme,
		       char *msg,
		       rdfstore_flat_store_error_t erx)
{
	dbms_store_t   *me = (dbms_store_t *) eme;
	bzero(me->err, sizeof(me->err));
	if (erx == FLAT_STORE_E_DBMS) {
		snprintf(me->err, sizeof(me->err), "DBMS Error %s: %s\n", msg,
			 errno == 0 ? "" : (strlen(strerror(errno)) <= sizeof(me->err)) ? strerror(errno) : "");	/* not enough... */
	} else {
		if ((erx > FLAT_STORE_E_UNDEF) && (erx <= FLAT_STORE_E_BUG)) {
			strcpy(me->err, dbms_store_error[erx - FLAT_STORE_E_UNDEF]);
		} else {
			if (strlen(strerror(erx)) <= sizeof(me->err))
				strcpy(me->err, strerror(erx));
		};
	};
	if (strlen(me->err) <= sizeof(_dbms_store_erm))
		strcpy(_dbms_store_erm, me->err);

#ifdef VERBOSE
	if (me->error)
		(*(me->error)) (me->err, erx);
#endif
}


char           *
backend_dbms_get_error(void *eme)
{
	dbms_store_t   *me = (dbms_store_t *) eme;
	if (me == NULL)
		return _dbms_store_erm;
	else
		return me->err;
}

/* clone a key or value for older BDB */
DBT
backend_dbms_kvdup(
		   void *eme,
		   DBT data)
{
	dbms_store_t   *me = (dbms_store_t *) eme;
	DBT             dup;
	memset(&dup, 0, sizeof(dup));

	if (data.size == 0) {
		dup.data = NULL;
		return dup;
	};

	dup.size = data.size;

	if ((dup.data = (char *) me->malloc(data.size + 1)) != NULL) {
		memcpy(dup.data, data.data, data.size);
		memcpy(dup.data + data.size, "\0", 1);
	};

	return dup;
};

void
backend_dbms_reset_debuginfo(
			     void *eme
)
{
#ifdef RDFSTORE_FLAT_STORE_DEBUG
	dbms_store_t   *me = (dbms_store_t *) eme;
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
}

/*
 * NOTE: all the functions return 0 on success and non zero value if error
 * (see above and include/backend_dbms_.h for known error codes)
 */
rdfstore_flat_store_error_t
backend_dbms_open(
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
	dbms_store_t   **mme = (dbms_store_t **) emme;
	dbms_store_t   *me;
	char           *buff;

	*mme = NULL;

	if (_my_error == NULL)
		_my_error = default_myerror;

	if (_my_malloc == NULL)
		_my_malloc = default_mymalloc;

	if (_my_free == NULL)
		_my_free = default_myfree;

	me = (dbms_store_t *) _my_malloc(sizeof(dbms_store_t));
	if (me == NULL) {
		perror("backend_dbms_open");
		return FLAT_STORE_E_NOMEM;
	};

	me->error = _my_error;
	bzero(me->err, sizeof(me->err));
	me->malloc = _my_malloc;
	me->free = _my_free;

	if (_my_report != NULL)
		me->callback = _my_report;

#ifdef RDFSTORE_FLAT_STORE_DEBUG
	backend_dbms_reset_debuginfo(me);
#endif

	if (!remote) {
		backend_dbms_set_error(me, "DBMS can only be remote", FLAT_STORE_E_CANNOTOPEN);
		perror("backend_dbms_open");
		_my_free(me);
		return FLAT_STORE_E_CANNOTOPEN;
	};

	if ((dir) &&
	    (name)) {
		strcpy(me->filename, dir);
		strcat(me->filename, "/");
		strcat(me->filename, name);
	} else {
		strcpy(me->filename, "\0");
		buff = NULL;
	};

	if (((me->dbms = dbms_connect(
				      me->filename,
				      host, port,
		   ((ro == 0) ? (DBMS_XSMODE_CREAT) : (DBMS_XSMODE_RDONLY)),
				      _my_malloc, _my_free,	/* malloc/free to use */
				      _my_report,	/* Callback for warnings */
				      _my_error,	/* Calllback to set error(variables) */
				      bt_compare_fcn_type
				      ))) == NULL) {
		backend_dbms_set_error(me, "Could not open/create database", FLAT_STORE_E_CANNOTOPEN);
		perror("backend_dbms_open");
		fprintf(stderr, "Could not open/create '%s': %s\n", me->filename, backend_dbms_get_error(me));
		_my_free(me);
		return FLAT_STORE_E_CANNOTOPEN;
	};

#ifdef RDFSTORE_FLAT_STORE_DEBUG
	fprintf(stderr, "backend_dbms_open '%s'\n", me->filename);
#endif

	*mme = me;
	return 0;
}

rdfstore_flat_store_error_t
backend_dbms_close(
		   void *eme
)
{
	dbms_store_t   *me = (dbms_store_t *) eme;
	void            (*_my_free) (void *) = me->free;
	int             retval = 0;

	dbms_disconnect(me->dbms);
	_my_free(me);

#ifdef RDFSTORE_FLAT_STORE_DEBUG
	fprintf(stderr, "backend_dbms_close '%s'\n", me->filename);
#endif

	return retval;
};

rdfstore_flat_store_error_t
backend_dbms_fetch(
		   void *eme,
		   DBT key,
		   DBT * val
)
{
	dbms_store_t   *me = (dbms_store_t *) eme;
	int             retval = 0;

#ifdef RDFSTORE_FLAT_STORE_DEBUG
	fprintf(stderr, "backend_dbms_fetch num=%d from '%s'\n", ++(me->num_fetch), me->filename);
#endif

	if (dbms_comms(me->dbms, TOKEN_FETCH, &retval, &key, NULL, NULL, val)) {
		backend_dbms_set_error(me, dbms_get_error(me->dbms), FLAT_STORE_E_DBMS);
		perror("backend_dbms_fetch");
		fprintf(stderr, "Could not fetch '%s': %s\n", me->filename, (char *) key.data);
		return FLAT_STORE_E_DBMS;
	};

	if (retval == 1) {
		backend_dbms_set_error(me, dbms_get_error(me->dbms), FLAT_STORE_E_NOTFOUND);
		return FLAT_STORE_E_NOTFOUND;
		};

	/* to duplicate rertun value */

	return retval;
}

rdfstore_flat_store_error_t
backend_dbms_fetch_compressed(
                  void * eme,
                  void (*func_decode)(unsigned int,unsigned char*, unsigned int *, unsigned char *),
                  DBT key,
                  unsigned int * outsize_p, unsigned char * outchar
)
{
	dbms_store_t   *me = (dbms_store_t *) eme;
        int             retval = 0;
        DBT             val;
	memset(&val, 0, sizeof(val));

        if ((retval = backend_dbms_fetch(eme,key,&val)))
                return retval;

        (*func_decode)(val.size,val.data,outsize_p,outchar);
	(me->free)(val.data);

        return retval;
}

rdfstore_flat_store_error_t
backend_dbms_store(
		   void *eme,
		   DBT key,
		   DBT val
)
{
	dbms_store_t   *me = (dbms_store_t *) eme;
	int             retval = 0;

#ifdef RDFSTORE_FLAT_STORE_DEBUG
	fprintf(stderr, "backend_dbms_store num=%d in '%s'\n", ++(me->num_store), me->filename);
#endif

	if (dbms_comms(me->dbms, TOKEN_STORE, &retval, &key, &val, NULL, NULL)) {
		backend_dbms_set_error(me, dbms_get_error(me->dbms), FLAT_STORE_E_DBMS);
		perror("backend_dbms_store");
		fprintf(stderr, "Could not store '%s': %s = %s\n", me->filename, (char *) key.data, (char *) val.data);
		return FLAT_STORE_E_DBMS;
	};
	if (retval != 0) {
		if (retval == 1) {
			backend_dbms_set_error(me, dbms_get_error(me->dbms), FLAT_STORE_E_KEYEXIST);
			return FLAT_STORE_E_KEYEXIST;
		} else {
			backend_dbms_set_error(me, dbms_get_error(me->dbms), FLAT_STORE_E_NOTFOUND);
			perror("backend_dbms_store");
			fprintf(stderr, "Could not store '%s': %s = %s\n", me->filename, (char *) key.data, (char *) val.data);
			return FLAT_STORE_E_NOTFOUND;
		};
	};

	return retval;
}

rdfstore_flat_store_error_t
backend_dbms_store_compressed(
                  void * eme,
                  void (*func_decode)(unsigned int,unsigned char*, unsigned int *, unsigned char *),
                  DBT key,
                  unsigned int insize , unsigned char * inchar,
                  unsigned char * outbuff
)
{
        int             outsize;
        DBT             val;

        (*func_decode)(insize,inchar, &outsize, outbuff);

	memset(&val, 0, sizeof(val));
        val.data = outbuff;
        val.size = outsize;

        return backend_dbms_store(eme,key,val);
}

rdfstore_flat_store_error_t
backend_dbms_exists(
		    void *eme,
		    DBT key
)
{
	dbms_store_t   *me = (dbms_store_t *) eme;
	int             retval;

#ifdef RDFSTORE_FLAT_STORE_DEBUG
	fprintf(stderr, "backend_dbms_exists num=%d from '%s'\n", ++(me->num_exists), me->filename);
#endif

	if (dbms_comms(me->dbms, TOKEN_EXISTS, &retval, &key, NULL, NULL, NULL)) {
		backend_dbms_set_error(me, dbms_get_error(me->dbms), FLAT_STORE_E_DBMS);
		perror("backend_dbms_exists");
		fprintf(stderr, "Could not exists '%s': %s\n", me->filename, (char *) key.data);
		return FLAT_STORE_E_DBMS;
	};
	if (retval == 1) {
		backend_dbms_set_error(me, dbms_get_error(me->dbms), FLAT_STORE_E_NOTFOUND);
		return FLAT_STORE_E_NOTFOUND;
		};
	return retval;
};

rdfstore_flat_store_error_t
backend_dbms_delete(
		    void *eme,
		    DBT key
)
{
	dbms_store_t   *me = (dbms_store_t *) eme;
	int             retval;

#ifdef RDFSTORE_FLAT_STORE_DEBUG
	fprintf(stderr, "backend_dbms_delete num=%d from '%s'\n", ++(me->num_delete), me->filename);
#endif

	if (dbms_comms(me->dbms, TOKEN_DELETE, &retval, &key, NULL, NULL, NULL)) {
		backend_dbms_set_error(me, dbms_get_error(me->dbms), FLAT_STORE_E_DBMS);
		perror("backend_dbms_delete");
		fprintf(stderr, "Could not delete '%s': %s\n", me->filename, (char *) key.data);
		return FLAT_STORE_E_DBMS;
	};

	if (retval != 0) {
		backend_dbms_set_error(me, dbms_get_error(me->dbms), FLAT_STORE_E_NOTFOUND);
		return FLAT_STORE_E_NOTFOUND;
		};
	return retval;
};

rdfstore_flat_store_error_t
backend_dbms_clear(
		   void *eme
)
{
	dbms_store_t   *me = (dbms_store_t *) eme;

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
	fprintf(stderr, "backend_dbms_clear num=%d in '%s'\n", ++(me->num_clear), me->filename);
#endif

	int             retval;

	if (dbms_comms(me->dbms, TOKEN_CLEAR, &retval, NULL, NULL, NULL, NULL)) {
		backend_dbms_set_error(me, dbms_get_error(me->dbms), FLAT_STORE_E_DBMS);
		perror("backend_dbms_clear");
		fprintf(stderr, "Could not clear '%s'\n", me->filename);
		return FLAT_STORE_E_DBMS;
	};
	return retval;
};

rdfstore_flat_store_error_t
backend_dbms_from(
		   void *eme,
		   DBT   closest_key,
		   DBT * key
)
{
	dbms_store_t   *me = (dbms_store_t *) eme;
	int             retval;

#ifdef RDFSTORE_FLAT_STORE_DEBUG
	fprintf(stderr, "backend_dbms_from num=%d from '%s'\n", ++(me->num_from), me->filename);
#endif

	if (dbms_comms(me->dbms, TOKEN_FROM, &retval, &closest_key, NULL, key, NULL)) {
		backend_dbms_set_error(me, dbms_get_error(me->dbms), FLAT_STORE_E_DBMS);
		perror("backend_dbms_from");
		fprintf(stderr, "Could not from '%s'\n", me->filename);
		return FLAT_STORE_E_DBMS;
	};

	if (retval == 1) {
		backend_dbms_set_error(me, dbms_get_error(me->dbms), FLAT_STORE_E_NOTFOUND);
		return FLAT_STORE_E_NOTFOUND;
		};
	return retval;
};

rdfstore_flat_store_error_t
backend_dbms_first(
		   void *eme,
		   DBT * first_key
)
{
	dbms_store_t   *me = (dbms_store_t *) eme;
	int             retval;

#ifdef RDFSTORE_FLAT_STORE_DEBUG
	fprintf(stderr, "backend_dbms_first num=%d from '%s'\n", ++(me->num_first), me->filename);
#endif

	if (dbms_comms(me->dbms, TOKEN_FIRSTKEY, &retval, NULL, NULL, first_key, NULL)) {
		backend_dbms_set_error(me, dbms_get_error(me->dbms), FLAT_STORE_E_DBMS);
		perror("backend_dbms_first");
		fprintf(stderr, "Could not first '%s'\n", me->filename);
		return FLAT_STORE_E_DBMS;
	};

	if (retval == 1) {
		backend_dbms_set_error(me, dbms_get_error(me->dbms), FLAT_STORE_E_NOTFOUND);
		return FLAT_STORE_E_NOTFOUND;
		};
	return retval;
};

rdfstore_flat_store_error_t
backend_dbms_next(
		  void *eme,
		  DBT previous_key,
		  DBT * next_key
)
{
	dbms_store_t   *me = (dbms_store_t *) eme;
	int             retval;

#ifdef RDFSTORE_FLAT_STORE_DEBUG
	fprintf(stderr, "backend_dbms_next num=%d from '%s'\n", ++(me->num_next), me->filename);
#endif

	if (dbms_comms(me->dbms, TOKEN_NEXTKEY, &retval, &previous_key, NULL, next_key, NULL)) {
		backend_dbms_set_error(me, dbms_get_error(me->dbms), FLAT_STORE_E_DBMS);
		perror("backend_dbms_next");
		fprintf(stderr, "Could not next '%s': %s\n", me->filename, (char *) previous_key.data);
		return FLAT_STORE_E_DBMS;
	};

	if (retval == 1) {
		backend_dbms_set_error(me, dbms_get_error(me->dbms), FLAT_STORE_E_NOTFOUND);
		return FLAT_STORE_E_NOTFOUND;
		};
	return retval;
};

/* packed rdf_store_counter_t increment */
rdfstore_flat_store_error_t
backend_dbms_inc(
		 void *eme,
		 DBT key,
		 DBT * new_value
)
{
	dbms_store_t   *me = (dbms_store_t *) eme;
	int             retval;

#ifdef RDFSTORE_FLAT_STORE_DEBUG
	fprintf(stderr, "backend_dbms_inc num=%d in '%s'\n", ++(me->num_inc), me->filename);
#endif

	if (dbms_comms(me->dbms, TOKEN_PACKINC, &retval, &key, NULL, NULL, new_value)) {
		backend_dbms_set_error(me, dbms_get_error(me->dbms), FLAT_STORE_E_DBMS);
		perror("backend_dbms_inc");
		fprintf(stderr, "Could not inc '%s': %s\n", me->filename, (char *) key.data);
		return FLAT_STORE_E_DBMS;
	};

	if (retval == 1) {
		backend_dbms_set_error(me, dbms_get_error(me->dbms), FLAT_STORE_E_NOTFOUND);
		return FLAT_STORE_E_NOTFOUND;
		};
	return retval;
}

/* packed rdf_store_counter_t decrement */
rdfstore_flat_store_error_t
backend_dbms_dec(
		 void *eme,
		 DBT key,
		 DBT * new_value
)
{
	dbms_store_t   *me = (dbms_store_t *) eme;
	int             retval;

#ifdef RDFSTORE_FLAT_STORE_DEBUG
	fprintf(stderr, "backend_dbms_dec num=%d from '%s'\n", ++(me->num_dec), me->filename);
#endif

	if (dbms_comms(me->dbms, TOKEN_PACKDEC, &retval, &key, NULL, NULL, new_value)) {
		backend_dbms_set_error(me, dbms_get_error(me->dbms), FLAT_STORE_E_DBMS);
		perror("backend_dbms_dec");
		fprintf(stderr, "Could not dec '%s': %s\n", me->filename, (char *) key.data);
		return FLAT_STORE_E_DBMS;
	};

	if (retval == 1) {
		backend_dbms_set_error(me, dbms_get_error(me->dbms), FLAT_STORE_E_NOTFOUND);
		return FLAT_STORE_E_NOTFOUND;
		};
	return retval;
}

rdfstore_flat_store_error_t
backend_dbms_sync(
		  void *eme
)
{
	dbms_store_t   *me = (dbms_store_t *) eme;
	int             retval;

#ifdef RDFSTORE_FLAT_STORE_DEBUG
	fprintf(stderr, "backend_dbms_sync num=%d in '%s'\n", ++(me->num_sync), me->filename);
#endif

	if (dbms_comms(me->dbms, TOKEN_SYNC, &retval, NULL, NULL, NULL, NULL)) {
		backend_dbms_set_error(me, dbms_get_error(me->dbms), FLAT_STORE_E_DBMS);
		perror("backend_dbms_sync");
		fprintf(stderr, "Could not sync '%s'\n", me->filename);
		return FLAT_STORE_E_DBMS;
	}
	return retval;
}

int
backend_dbms_isremote(
		      void *eme
)
{
	/* dbms_store_t * me = (dbms_store_t *)eme; */
	return 1;
}

#define DBMS_VERSION (100)
DECLARE_MODULE_BACKEND(backend_dbms, "DBMS", DBMS_VERSION);
