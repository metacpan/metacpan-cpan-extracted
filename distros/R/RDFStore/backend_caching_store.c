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
# $Id: backend_caching_store.c,v 1.13 2006/06/19 10:10:21 areggiori Exp $
*/
#include "dbms.h"
#include "dbms_compat.h"
#include "dbms_comms.h"

#include "rdfstore_flat_store.h"
#include "rdfstore_log.h"
#include "rdfstore.h"

#include "backend_store.h"
#include "backend_caching_store.h"

#include "backend_bdb_store.h"
#include "backend_dbms_store.h"

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <assert.h>

typedef struct backend_caching_struct {
	char * name;				/* name - for debugging */
	backend_store_t	 * store;		/* the real store */
	void * 		   instance;		/* instance of the real store */
	struct caching_store_rec * cache;	/* My cache */

        void (* free)(void * adr);              
        void * (* malloc)(size_t size);
	} backend_caching_t;

typedef enum { UNDEF, EXISTS, CHANGED, NOTFOUND, DELETED } cstate;

/* as refered to above as * data */
typedef struct data_rec {			/* Payload of the cache */
	DBT 		key,val;		
	cstate		state;			/* Cache positives and negatives */
} data_t;

/* forward declarations */
static int _dup(void * conf, void * from, void * * to);
static int _store(void * conf, void * data);
static int _delete(void * conf, void * data);
static int _fetch(void * conf, void * data, void ** dout);
static int _cmp(const void *a, const void *b);


/* Caching infrastructure:
 *
 * Up to maxcache keys are cached.
 *
 * --> head->*cdll_t
 * 	circular double linked list - element pointed to by head
 *	was the most recently used.
 * --> idx
 *      sorted list circular double linked list elements - sorted
 *	by their 'data's key.
 */

/* START of Fairly generic caching section.. */

#ifndef DEFAULTMAXCACHE
#define DEFAULTMAXCACHE (1000)
#endif

/* Element in a circular double linked list */
typedef struct cdll_rec {
	void * data;				/* data payload -- actual stuff we cache */

	unsigned int cnt;			/* counter - for debugging */

	struct cdll_rec * prev;
	struct cdll_rec * nxt;
} cdll_t;

typedef struct caching_store_rec {
	char * name;				/* name - for debugging */
	void * conf;				/* Callee's own book keeping */

	int hit,miss,drop;

	unsigned int 	maxcache;		/* Max numer of keys to cache. */
	unsigned int	cached;			/* Currently cached */
	cdll_t * * 	idx;			/* Sorted list (on keys) */

	struct cdll_rec * head;		/* Start of the circular double linked list. */

        void (* free)(void * adr);              
        void * (* malloc)(size_t size);

	/* Comparison functions specific to the data 
	 */
	int (*cmp)(const void * a, const void * b);	

	/* fetch/store functions specific to the data 
	 */
	int (*fetch)(void * conf, void * data, void ** out);	/* implies dup into new out */
	int (*store)(void * conf, void * data);
	int (*delete)(void * conf, void * data);

	/* Create a copy into existence, or drop it. */
	int (*dup)(void * conf, void * from, void * * to);	/* malloc and cpy */
	int (*cpy)(void * conf, void * from, void * to);	/* just copy refs */
	int (*drp)(backend_caching_t * me, void * conf, void * data);
	
	} caching_store_t;

typedef enum { BC_READ, BC_WRITE, BC_EXISTS, BC_DELETE } bc_ops;

static int cmp_pair(const void * a, const void * b);
static int cmp_key(const void * in, const void * pair);

static int init_cachingstore(
	caching_store_t *me,
	int max_cache_nelems,
	void * conf,
	char * name,
	int (*cmp)(const void * a, const void * b),
	int (*fetch)(void * conf, void * data, void ** out),
	int (*store)(void * conf, void * data),
	int (*delete)(void * conf, void * data),
	int (*dup)(void * conf, void * from, void * * to),
	int (*cpy)(void * conf, void * from, void * to),
	int (*drp)(backend_caching_t * me, void * conf, void * data),
        void (* cachingfree)(void * adr),
        void * (* cachingmalloc)(size_t size)
	)
{
	me->maxcache = max_cache_nelems ? max_cache_nelems : DEFAULTMAXCACHE;

	me->idx = (cdll_t **) (*cachingmalloc)( sizeof((*(me->idx))) * me->maxcache );
	if (me->idx == NULL)
		return -1;

	memset(me->idx, 0, sizeof((*(me->idx))) * me->maxcache );

	me->cached = 0;
	me->head = NULL;

	me->hit = me->miss = me->drop = 0;

	me->cmp = cmp;	
	me->fetch = fetch;
	me->store = store;
	me->delete = delete;
	me->dup = dup;
	me->cpy = cpy;
	me->drp = drp;
	me->name = (char *)(*cachingmalloc)( strlen(name)+1 );
	if( me->name == NULL )
		return -1;
	strcpy( me->name, name );
	me->conf = conf;

	me->free = cachingfree;
	me->malloc = cachingmalloc;

	return 0;
}

/* iswrite == 1
 *	cache key+val
 * iswrite == 0
 *	if cached - update val
 *	otherwise fetch from backend
 *		and cache - update val
 */

const char * _x(DBT v) {
	int i;
	if (v.size == 4) return "<int>";
	for(i=0;i<v.size;i++)
		if ((((char *)(v.data))[i]) && (((((char *)(v.data))[i])< 32) || ( ((((char *)(v.data))[i])>126))))
			return "<bin>";
	return (char *)(v.data);
}

int cachekey(backend_caching_t * mme, caching_store_t * me, void * data, void ** out, bc_ops op) 
{
	cdll_t * * i = NULL;
	int e = 0;

#if 0
if(0)fprintf(stderr,"Working on %s[%d,%d]\n",_x(((data_t *)data)->key),((data_t *)data)->key.size,((data_t *)data)->val.size);
#endif
	/* Check if this key is already cached */
	if (me->cached > 0)
		i = (cdll_t **)bsearch( (void *) data, me->idx, me->cached, sizeof(cdll_t *), &cmp_key);
#if  0
if (0) { int i; fprintf(stderr," PRE --- %d\n",me->cached); for(i=0;i < me->cached;i++) { data_t * p = (data_t *)(me->idx[i]->data); fprintf(stderr,"	# %d	%p %p '%s'[%d] %d\n",i,me->idx[i],p,p->key.data,p->key.size,p->state); }; fprintf(stderr,"--- end\n"); };
#endif

	/* Add this to the cache if it is a new key */
	if (!i) {
		/* Remove last key if cache is already full. */
#if 0
fprintf(stderr,"Cache miss\n");
#endif
		me->miss++;
		if (me->cached >= me->maxcache) {
			/* Remove from the tail */
			cdll_t * last = me->head->prev;
			me->head = last->nxt;
			me->head->prev = last->prev;
			me->head->prev->nxt = me->head;

			/* find the corresponding entry in the idx - as this is the slot which we will
			 * reuse (to save a malloc) for the new key.
			 */
			i = (cdll_t **)bsearch((void *)(last->data), me->idx, me->cached, sizeof(cdll_t *), &cmp_key);
			assert(i);

			/* allow the backend to store and drop it */
			me->store(me->conf,last->data);
			me->drp(mme, me->conf,last->data);
			me->drop++;
		} else {
			/* Still space - add it to the end of the IDX */
			if ((me->idx[ me->cached ] = me->malloc(sizeof(cdll_t))) == NULL) {
				return -1;
			};
			i = &(me->idx[ me->cached ]);
			me->cached ++;
		};

		switch(op) {
		case BC_WRITE: 	/* DUP our new item into it */
			me->dup(me->conf, data, &((*i)->data));
			break;
		case BC_DELETE:
			me->dup(me->conf, data, &((*i)->data));
			e = me->delete(me->conf, (*i)->data);
			break;
		case BC_READ:
		case BC_EXISTS:
			e = me->fetch(me->conf, data, &((*i)->data));
			break;
		default:
			assert(0);
			break;
		};

		/* virig item. */
		(*i)->cnt = 0;

		/* And insert our item at the head */
		if( me->head ) {
			(*i)->nxt = me->head;
			(*i)->prev = me->head->prev;
			me->head->prev->nxt = *i;
			me->head->prev = *i;
		} else {
			(*i)->nxt = *i;
			(*i)->prev= *i;
		}
		/* And update the head pointer */
		me->head = *i;
		
		/* and sort the list again  -- XXXX note this should be replaced
	 	 * by a binary search and a N-shift/insert (ordered insertion search)
		 * at some point.
		 */
		if (me->cached > 1)
			qsort(me->idx,me->cached,sizeof(cdll_t*),&cmp_pair);
	} else {
#if 0
fprintf(stderr,"Cache hit\n");
#endif
		me->hit++;
		/* if not already in front - move to the front 
		 */
		if (me->head && (me->head != *i)) {
			/* remove item from the list */
			(*i)->nxt->prev = (*i)->prev;
			(*i)->prev->nxt = (*i)->nxt;

			/* squeeze it in at head */
			(*i)->nxt = me->head;
			(*i)->prev = me->head->prev;
			me->head->prev->nxt = *i;
			me->head->prev = *i;

			/* move head to the right place */
			me->head = *i;
		}
		/* If it is a write through - update the value if it has changed.
		 */
		switch(op) {
		case BC_WRITE:
if (0) fprintf(stderr,"Write through\n");
if (0) if (((data_t *)data)->val.size == 4) fprintf(stderr,"%s == %d\n",_x(((data_t *)data)->key),*((int *)(((data_t *)data)->val.data)));

			me->drp(mme, me->conf, (*i)->data);		/* drop the old value */
			me->dup(me->conf, data, &((*i)->data));	/* replace by the new one */
			break;
		case BC_DELETE:
			me->dup(me->conf, data, &((*i)->data));
			e = me->delete(me->conf, (*i)->data);
			break;
		case BC_EXISTS:
		case BC_READ:
			break;
		default:
			assert(0);
		}
		(*i)->cnt ++;
	}

	switch(op) {
	case BC_EXISTS: 	/* exists */
		me->cpy(me->conf,me->head->data,data);
		break;
	case BC_DELETE:		/* no need to update */
	case BC_WRITE:		/* no need to update */
		break;
	case BC_READ: 		/* update data - so the callee can use it */
		me->dup(me->conf,me->head->data,out);
		break;
	default:	
		/* error really */
		assert(0);
		break;
	}
#if 0
if (0) { int i; fprintf(stderr,"POST --- %d\n",me->cached); for(i=0;i < me->cached;i++) { data_t * p = (data_t *)(me->idx[i]->data); fprintf(stderr,"	%d '%s'[%d] %d\n",i,p->key.data,p->key.size,p->state); }; fprintf(stderr,"--- end\n"); };
#endif
	return e;
}

void stats(caching_store_t *me) 
{
	fprintf(stderr,"%s: hit: %d miss: %d drop: %d\n",me->name,me->hit,me->miss,me->drop);
}

void purgecache(backend_caching_t   *me, caching_store_t *c) 
{
	cdll_t * p;
	if (c->head == NULL)
		return;

	for(p=c->head;;) {
		cdll_t * q = p;
		p=p->nxt;
		c->store(c->conf,q->data);
		c->drp(me, c->conf,q->data);
		(*(me->free))(q);
		if (p == c->head)
			break;
	}
	c->head = NULL;
	c->cached = 0;
}

static int cmp_pair(const void * a, const void * b) 
{	
	return _cmp((*(cdll_t**) a)->data,(*(cdll_t**) b)->data);
}

static int cmp_key(const void * in, const void * pair) 
{
	return _cmp(in, (*((cdll_t**) pair))->data );
}
/* END of caching code */

static int _cmp(const void *a, const void *b)
{
	DBT * k = &(((data_t *)a)->key);
	DBT * l = &(((data_t *)b)->key);

	int c;

	if ((a == NULL) || (b == NULL)) {
		if (a == NULL) 
			return (b == NULL) ? 0 : -1;
		else
			return (b == NULL) ? 0 : +1;
	};

	c = memcmp(k->data,l->data,MIN(k->size,l->size));

	if (c)
		return c;

	if (k->size < l->size)
		return -1;

	if (k->size > l->size)
		return +1;

	return 0;
}

static int _fetch(void * conf, void * data, void ** dout)
{
	backend_caching_t   *me = (backend_caching_t *) conf;
	data_t * in = (data_t *) data;
	data_t ** out = (data_t **) dout;
	int e;

	if (_dup(conf, (void *)in, (void **)out))
		return -1;

	e = (me->store->fetch)(me->instance,in->key,&((*out)->val));

	/* Cache both positives and negatives. */
	switch(e) {
	case 0:				/* found - no error */
		(*out)->state = EXISTS;
		break;
	case FLAT_STORE_E_NOTFOUND:	/* not found - but not an error */
		(*out)->state = NOTFOUND;
		e = 0;
		break;
	default:
		/* keep error code */
		fprintf(stderr,"DEBUG -- error %d\n",e);
	}
if (0) fprintf(stderr,"BE fetch %s - returning %d - and exists is %d\n",
		_x((*out)->key),e,(*out)->state);
	return e;
}

static int _store(void * conf, void * data)
{
	backend_caching_t   *me = (backend_caching_t *) conf;
	data_t * in = (data_t *) data;
	int e;

	if (in->state != CHANGED)
		return 0;

	e = (me->store->store)(me->instance,in->key,in->val);
	switch(e) {
	case 0:
		/* ignore */
		break;
	case FLAT_STORE_E_KEYEXIST:
		/* XXXXXXXXXXXXXXXXXXXXXXXXX we lose track of this ****XXXXXXXXXXXXXXXXX */
		e = 0;
		break;
	default:
		/* keep error code */
		break;
	}
	return e;
}

static int _delete(void * conf, void * data)
{
	backend_caching_t   *me = (backend_caching_t *) conf;
	data_t * in = (data_t *) data;
	int e = (me->store->delete)(me->instance,in->key);	/* xxx we could also do this on a purge.. */
	switch(e) {
	case 0:
		/* ignore */
		break;
	case FLAT_STORE_E_KEYEXIST:
		e = 0;
		break;
	default:
		/* keep error code */
		break;
	}
	in->state = NOTFOUND;	/* set to DELETE and do later on purge ?? */
	return e;
}

static int _cpy(void * conf, void * from, void * to)
{
	*(data_t *)to = *(data_t *)from;
	return 0;
}

static int _dup(void * conf, void * from, void * * to)
{
	backend_caching_t   *me = (backend_caching_t *) conf;
	data_t * p = (data_t *) from;
	data_t * q;

	if (!(q = me->malloc(sizeof(data_t))))
		return -1;
	
	memset(&(q->key),0,sizeof(q->key));
	memset(&(q->val),0,sizeof(q->val));

	if (p->key.data) {
		if (!(q->key.data = me->malloc(p->key.size)))
			return -1;
		bcopy(p->key.data,q->key.data,p->key.size);
		q->key.size = p->key.size;
	} else {
		q->key.data = NULL;
		q->key.size = 0;
	}

	if (p->val.data) {
		if (!(q->val.data = me->malloc(p->val.size)))
			return -1;
		bcopy(p->val.data,q->val.data,p->val.size);
		q->val.size = p->val.size;
	} else {
		q->val.data = NULL;
		q->val.size = 0;
	}

	q->state = p->state ;

#if 0
if (0) fprintf(stderr,"DUPed %s(%d,%d)==%s(%d,%d) exists=%d/%d\n",
		_x(p->key), p->key.size,p->val.size,
		_x(q->key), q->key.size,q->val.size,
		p->state, q->state);
#endif

	*to = q;
	return 0;
}

static int _drp(backend_caching_t * me, void * conf, void * data)
{
	data_t * p = (data_t *) data;
	if (p->key.data) 
		(*(me->free))(p->key.data);
	if (p->val.data) 
		(*(me->free))(p->val.data);
	(*(me->free))(p);
	return 0;
}

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
	fprintf(stderr, "backend_caching_ Error[%d]: %s\n", erx, err);
}

void
backend_caching_set_error(
		       void *eme,
		       char *msg,
		       rdfstore_flat_store_error_t erx)
{
	backend_caching_t   *me = (backend_caching_t *) eme;
	(me->store->set_error)(me->instance,msg,erx);
}

char           *
backend_caching_get_error(void *eme)
{
	backend_caching_t   *me = (backend_caching_t *) eme;
	return (me->store->get_error)(me->instance);
}

/* clone a key or value for older BDB */
DBT
backend_caching_kvdup(
		   void *eme,
		   DBT data)
{
	backend_caching_t  * me = (backend_caching_t *) eme;
	return (me->store->kvdup)(me->instance,data);
}

void
backend_caching_reset_debuginfo(
			     void *eme
)
{
	backend_caching_t   *me = (backend_caching_t *) eme;
	(me->store->reset_debuginfo)(me->instance);
}

/*
 * NOTE: all the functions return 0 on success and non zero value if error
 * (see above and include/backend_caching_.h for known error codes)
 */
rdfstore_flat_store_error_t
backend_caching_open(
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
	backend_caching_t   **mme = (backend_caching_t **) emme;
	backend_caching_t   *me;
	char buff[1024];
	int err;

	*mme = NULL;

	if (_my_error == NULL)
		_my_error = default_myerror;

	if (_my_malloc == NULL)
		_my_malloc = default_mymalloc;

	if (_my_free == NULL)
		_my_free = default_myfree;

	me = (backend_caching_t *) _my_malloc(sizeof(backend_caching_t));
	if (me == NULL) {
		perror("backend_caching_open");
		return FLAT_STORE_E_NOMEM;
	};

	snprintf(buff,sizeof(buff)-1,"%p@%s:%d/%s/%s",
		me,
		host ? host : "<nohost>",
		port ? port : 0,
		dir ? dir : "<nodir>",
		name ? name : "<inmemory>"
	);
	me->name = (char *)(*_my_malloc)( strlen(buff)+1 );
	if( me->name == NULL )
		return -1;
	strcpy( me->name, buff );

	me->malloc = _my_malloc;
	me->free = _my_free;

#ifdef RDFSTORE_FLAT_STORE_DEBUG
	backend_caching_reset_debuginfo(me);
#endif

        switch (remote & 0xF) {
        case 0:
                me->store = backend_bdb;
                break;
        case 1:
                me->store = backend_dbms;
                break;
        default:
                perror("Backend type is not available");
                return FLAT_STORE_E_NOMEM;
                break;
        };

	/* Map to the real backend. */
        err = (*(me->store->open)) (
                                remote & 0xF, ro, (void **) &(me->instance),
                                dir, name, local_hash_flags, host, port,
                               _my_malloc, _my_free, _my_report, _my_error,
				bt_compare_fcn_type
        );
        if (err) {
                (*_my_free) (me);
                return err;
        }
        me->free = _my_free;

	me->cache = (caching_store_t *)me->malloc(sizeof(caching_store_t));

	/* Init with default cache size */
	init_cachingstore(me->cache,0,
		/* Functions to manage 'my' data */
		me,
		buff,
		&_cmp,
		&_fetch,
		&_store,
		&_delete,
		&_dup,
		&_cpy,
		&_drp,
		me->free,
		me->malloc
	);

	* mme = me;
#ifdef RDFSTORE_FLAT_STORE_DEBUG
	if (0) fprintf(stderr, "backend_caching_open '%s'\n", me->filename);
#endif
	return 0;
}

rdfstore_flat_store_error_t
backend_caching_close(
		   void *eme
)
{
	backend_caching_t   *me = (backend_caching_t *) eme;
	int e;
if (0) fprintf(stderr,"%s: close\n",me->name);
	purgecache(me, me->cache);
	stats(me->cache);
	e = (me->store->close)(me->instance);

	me->free(me->name);
	me->free(me->cache);
	me->free(me);

	return e;
};

rdfstore_flat_store_error_t
backend_caching_fetch(
		   void *eme,
		   DBT key,
		   DBT * val
)
{
	backend_caching_t   *me = (backend_caching_t *) eme;
	data_t  d, * out = NULL;
	int e;

#if 0
fprintf(stderr,"%s: fetch %s(%d,%d)\n",me->name,_x(key),(int)key.size,(int)val->size);
#endif

	/* Build a record */
	d.key = key;
	memset(&(d.val),0,sizeof(d.val));
	d.val.data =NULL;
	d.val.size = 0;
	d.state = UNDEF;	/* unkown */

	if ((e = cachekey(me, me->cache,&d,(void **)&out, BC_READ))) {
		return e;
	}

	val->data = out->val.data;
	val->size = out->val.size;

#if 0
if (0) fprintf(stderr,"Cachekey returned e=%d and exits=%d val=%p,%d\n",e,out->state,val->data,val->size);
#endif

	if (out->state == NOTFOUND) {
		me->free(out);
		return FLAT_STORE_E_NOTFOUND;
	};

	if (out->key.data)
		me->free(out->key.data);
	me->free(out); 

	return 0;
}

rdfstore_flat_store_error_t
backend_caching_fetch_compressed(
                  void * eme,
                  void (*func_decode)(unsigned int,unsigned char*, unsigned int *, unsigned char *),
                  DBT key,
                  unsigned int * outsize_p, unsigned char * outchar
)
{
	backend_caching_t   *me = (backend_caching_t *) eme;
	return (me->store->fetch_compressed)(me->instance,func_decode,key,outsize_p,outchar);
}

rdfstore_flat_store_error_t
backend_caching_store(
		   void *eme,
		   DBT key,
		   DBT val
)
{
	backend_caching_t   *me = (backend_caching_t *) eme;
	data_t d;
	int e;

        d.key = key;
        d.val = val;
        d.state = CHANGED;   

	e = cachekey(me, me->cache,&d,NULL,BC_WRITE);
#if 0
fprintf(stderr,"%s: store %s(%d,%d) E=%d\n",me->name,_x(key),(int)key.size,(int)val.size,e);
#endif
	return e;
}

rdfstore_flat_store_error_t
backend_caching_store_compressed(
                  void * eme,
                  void (*func_decode)(unsigned int,unsigned char*, unsigned int *, unsigned char *),
                  DBT key,
                  unsigned int insize , unsigned char * inchar,
                  unsigned char * outbuff
)
{
	backend_caching_t   *me = (backend_caching_t *) eme;
	return (me->store->store_compressed)(me->instance,func_decode,key,insize,inchar,outbuff);
}

rdfstore_flat_store_error_t
backend_caching_exists(
		    void *eme,
		    DBT key
)
{
	backend_caching_t   *me = (backend_caching_t *) eme;
	data_t  d;
	int e;

	/* Build a record */
	d.key = key;
	memset(&(d.val),0,sizeof(d.val));
	d.val.data =NULL;
	d.val.size = 0;
	d.state = UNDEF;	/* unkown */

	e = cachekey(me, me->cache,&d,NULL, BC_EXISTS);

if (0) fprintf(stderr,"%s: exists %s ==> e=%d and d.exists=%d\n",me->name,_x(key),e,d.state);

	if (e) 
		return e;


	return (d.state == EXISTS || d.state == CHANGED) ? 0 : FLAT_STORE_E_NOTFOUND;
}

rdfstore_flat_store_error_t
backend_caching_delete(
		    void *eme,
		    DBT key
)
{
	backend_caching_t   *me = (backend_caching_t *) eme;
	data_t d;
if (0) fprintf(stderr,"%s: delete\n",me->name);
	
	d.key = key;
	memset(&(d.val),0,sizeof(d.val));
	d.state = UNDEF;
	
	return cachekey(me, me->cache,&d,NULL, BC_DELETE);
};

rdfstore_flat_store_error_t
backend_caching_clear(
		   void *eme
)
{
	backend_caching_t   *me = (backend_caching_t *) eme;
if (0) fprintf(stderr,"%s: clear\n",me->name);
assert(0);
	return (me->store->clear)(me->instance);
}

rdfstore_flat_store_error_t
backend_caching_from(
		   void *eme,
		   DBT closest_key,
		   DBT * key
)
{
	backend_caching_t   *me = (backend_caching_t *) eme;
if (0) fprintf(stderr,"%s: from\n",me->name);
	purgecache(me, me->cache);
	return (me->store->from)(me->instance,closest_key,key);
}

rdfstore_flat_store_error_t
backend_caching_first(
		   void *eme,
		   DBT * first_key
)
{
	backend_caching_t   *me = (backend_caching_t *) eme;
if (0) fprintf(stderr,"%s: first\n",me->name);
	purgecache(me, me->cache);
	return (me->store->first)(me->instance,first_key);
}

rdfstore_flat_store_error_t
backend_caching_next(
		  void *eme,
		  DBT previous_key,
		  DBT * next_key
)
{
	backend_caching_t   *me = (backend_caching_t *) eme;
if (0) fprintf(stderr,"%s: next\n",me->name);
	purgecache(me, me->cache);
	return (me->store->next)(me->instance,previous_key,next_key);
}

/* packed rdf_store_counter_t increment */
rdfstore_flat_store_error_t
backend_caching_inc(
		 void *eme,
		 DBT key,
		 DBT * new_value
)
{
	backend_caching_t   *me = (backend_caching_t *) eme;
        rdf_store_counter_t l = 0;
	int e;
	memset(new_value, 0, sizeof(*new_value));
#if 0
fprintf(stderr,"%s: inc %s\n",me->name,_x(key));
#endif

	e = backend_caching_fetch(eme,key,new_value);
	if (e) 
		return e;

        unpackInt(new_value->data, &l);
	l++;
        packInt(l, new_value->data);

	if ((e = backend_caching_store(eme,key,*new_value))) {
		memset(new_value, 0, sizeof(*new_value));
	} else {
		(*new_value) = backend_caching_kvdup(me, *new_value);
	}
	return e;
}

/* packed rdf_store_counter_t decrement */
rdfstore_flat_store_error_t
backend_caching_dec(
		 void *eme,
		 DBT key,
		 DBT * new_value
)
{
	backend_caching_t   *me = (backend_caching_t *) eme;
        rdf_store_counter_t l = 0;
	int e;

	memset(new_value, 0, sizeof(*new_value));

if (0) fprintf(stderr,"%s: dec\n",me->name);
	e = backend_caching_fetch(eme,key,new_value);
	if (e) 
		return e;

        unpackInt(new_value->data, &l);
	l--;
        packInt(l, new_value->data);

	if ((e = backend_caching_store(eme,key,*new_value))) {
		memset(new_value, 0, sizeof(*new_value));
	} else {
		(*new_value) = backend_caching_kvdup(me, *new_value);
	}

	return e;
}

rdfstore_flat_store_error_t
backend_caching_sync(
		  void *eme
)
{
	backend_caching_t   *me = (backend_caching_t *) eme;
if (0) fprintf(stderr,"%s: sync\n",me->name);
	purgecache(me, me->cache);
	return (me->store->sync)(me->instance);
}

int
backend_caching_isremote(
		      void *eme
)
{
	backend_caching_t   *me = (backend_caching_t *) eme;
	return (me->store->isremote)(me->instance);
}


#define CACHING_VERSION (100)
DECLARE_MODULE_BACKEND(backend_caching, "Caching", CACHING_VERSION)

