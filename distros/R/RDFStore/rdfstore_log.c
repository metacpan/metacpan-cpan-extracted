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
# $Id: rdfstore_log.c,v 1.7 2006/06/19 10:10:22 areggiori Exp $
#
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
#include <sys/time.h>

#include "rdfstore_log.h"

/* the following code must be integrated with dbms/deamon/mymalloc.[ch] */
#ifdef RDFSTORE_DEBUG_MALLOC
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

void * rdfstore_log_debug_malloc( size_t len, char * file, int line ) {
	struct mp * p = malloc( sizeof( mp ) );
	if (p==NULL)
		return NULL;
	p->data = malloc( len );
	if (p->data==NULL)
		return NULL;
#ifdef RDFSTORE_DEBUG
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

void rdfstore_log_debug_free( void * addr, char * file, int line ) {
        struct mp *q, * * p;

	for( p=&mfirst; *p; p=&((*p)->nxt)) 
		if ((*p)->data == addr) 
			break;

	if (!*p) {
		fprintf(stderr,"Unanticipated Free from %s:%d\n",file,line);
#ifdef RDFSTORE_DEBUG
		abort();
#endif
		};
	q = *p; 
	*p=(*p)->nxt;

#ifdef RDFSTORE_DEBUG
	bzero(q->data,q->len);
#endif

	free(q->data);
	free(q->file);
	free(q);
	mpfree++;
	}

void rdfstore_log_debug_malloc_dump() {
        struct mp * p; 
	TIMESPEC now=time(NULL);

	fprintf(stderr,"Memory==malloc %d == %d free\n",mpalloc,mpfree);
        for( p = mfirst; p; p=p->nxt)
                fprintf(stderr,"%s %d size %d age %f\n", p->file,p->line,p->len, difftime(now,p->tal) );
        }

#endif
