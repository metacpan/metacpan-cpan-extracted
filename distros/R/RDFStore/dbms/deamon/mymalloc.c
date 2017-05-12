/*
 *     Copyright (c) 2000-2006 Alberto Reggiori <areggiori@webweaving.org>
 *                        Dirk-Willem van Gulik <dirkx@webweaving.org>
 *
 * NOTICE
 *
 * This product is distributed under a BSD/ASF like license as described in the 'LICENSE'
 * file you should have received together with this source code. If you did not get a
 * a copy of such a license agreement you can pick up one at:
 *
 *     http://rdfstore.sourceforge.net/LICENSE
 *
 * Simple debugging malloc, when/if needed 
 *
 * $Id: mymalloc.c,v 1.11 2006/06/19 10:10:22 areggiori Exp $
 */
#include "dbms.h"
#include "dbms_compat.h"
#include "dbms_comms.h"

#include "dbmsd.h"

#include "deamon.h"
#include "mymalloc.h" 	/* to keep us honest */

char * memdup( void * data, size_t size ) {
        void * out = mymalloc( size );
        if (out == NULL)
                return NULL;
        memcpy(out, data, size );
        return out;
        }  


#ifdef RDFSTORE_DBMS_DEBUG_MALLOC
struct mp {
	void * data;
	int line;
	int len;
	char * file;
	TIMESPEC tal;
	struct mp * nxt;
	} mp;

struct mp * mfirst=NULL;
int mpfree=0,mpalloc=0;

void * debug_malloc( size_t len, char * file, int line ) {
	struct mp * p = malloc( sizeof( mp ) );
	if (p==NULL)
		return NULL;
	p->data = malloc( len );
	if (p->data==NULL)
		return NULL;
#ifdef RDFSTORE_DBMS_DEBUG
	bzero(p->data,len);
#endif
	p->tal = time(NULL);
	p->file = strdup( file );
	p->line = line;
	p->len = len;
	p->nxt = mfirst;
	mfirst = p;
	mpalloc++;
	return p->data;
	}

void debug_free( void * addr, char * file, int line ) {
        struct mp *q, * * p;

	for( p=&mfirst; *p; p=&((*p)->nxt)) 
		if ((*p)->data == addr) 
			break;

	if (!*p) {
		dbms_log(L_ERROR,"Unanticipated Free from %s:%d",file,line);
#ifdef RDFSTORE_DBMS_DEBUG
		abort();
#endif
		};
	q = *p; 
	*p=(*p)->nxt;
#ifdef RDFSTORE_DBMS_DEBUG
	bzero(q->data,q->len);
#endif
	free(q->data);
	free(q->file);
	free(q);

	mpfree++;
	}

void debug_malloc_dump(FILE * f) {
        struct mp * p; 
	TIMESPEC now=time(NULL);
	unsigned int t = 0;

        fprintf(f,"Memory==malloc %d == %d free\n",mpalloc,mpfree);
        for( p = mfirst; p; p=p->nxt) {
                fprintf(f,"%05d(%s) %12s %5d size %9d age %.0f at %p\n",
			getpid(),mum_pid ? "Chd" : "Mum",
                        p->file,p->line,p->len,
                        difftime(now,p->tal),
			p->data
                        );
		t+=p->len;
	}
        fprintf(f,"Total %u bytes\n",t);
}
#endif
