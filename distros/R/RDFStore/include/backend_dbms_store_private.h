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
# $Id: backend_dbms_store_private.h,v 1.4 2006/06/19 10:10:23 areggiori Exp $
#
*/

#ifndef _H_BDB_STORE_PRIVATE
#define _H_BDB_STORE_PRIVATE

#include <sys/types.h>

#if !defined(WIN32)
#include <sys/param.h>
#ifndef RDFSTORE_PLATFORM_SOLARIS	/* for SOLARIS */
#include <sys/cdefs.h>
#endif
#endif

#include <limits.h>

#include <fcntl.h>

#include "dbms.h"
#include "dbms_compat.h"

#define _flock( d,op ) {  \
        int a=flock( (d->fd)(d),op | LOCK_NB ); \
        if ((a<0) && ( errno == EWOULDBLOCK )) { \
                /* printf("Wait..%d \n",getpid()); */ \
                flock( (d->fd)(d),op); \
                } else  \
        if (a<0) {  \
                perror("Locking trouble"); \
                }; \
        }

#define lock_ro( d ) _flock( d, LOCK_SH )
#define ulock_ro( d ) _flock( d, LOCK_UN )
#define lock_rw( d ) _flock( d, LOCK_EX )
#define ulock_rw( d ) _flock( d, LOCK_UN )

#ifdef RDFSTORE_DEBUG
#define D { printf("Me %s:%d\n",__FILE__,__LINE__); }
#else
#define D /* nope */
#endif

typedef struct dbms_store_rec {
	dbms	* dbms;
#ifdef DB_VERSION_MAJOR
        DBC *   cursor ;
#endif
	char filename[ MAXPATHLEN ];

	/* current error code */
	char		err[256*2]; /* we will also have DBMS errors to include sometimes */

	void * (* malloc)(size_t s);
        void (* free)(void * adr);
        void (* callback)(dbms_cause_t cause, int cnt);
        void (* error)(char * err, int erx);
#ifdef RDFSTORE_FLAT_STORE_DEBUG
	int	num_store; /* some debug info */
	int	num_fetch;
	int	num_inc;
	int	num_dec;
	int	num_sync;
	int	num_next;
	int	num_from;
	int	num_first;
	int	num_delete;
	int	num_clear;
	int	num_exists;
#endif
} dbms_store_t;

#endif

