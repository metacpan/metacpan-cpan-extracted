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
# $Id: rdfstore_bits.h,v 1.9 2006/06/19 10:10:23 areggiori Exp $
#
*/

#ifndef _H_RDFSTORE_BITS
#define _H_RDFSTORE_BITS

#include <assert.h>
#include "rdfstore_compress.h"

#define MAXBITBYTE (RDFSTORE_MAXRECORDS_BYTES_SIZE)
#define STEP 16 /* bytes per increase */

typedef struct bitseq {
        int     size;
        unsigned char bits[MAXBITBYTE];
        } bitseq;

int rdfstore_bits_setmask( 
	unsigned int  * len,
	unsigned char * bits,
	unsigned int at, 
	unsigned int mask,
	unsigned int value,
	unsigned int maxlen
);

int rdfstore_bits_isanyset ( 
	unsigned int  * len,
	unsigned char * bits,
	unsigned int * at, 
	unsigned char mask
	);

unsigned int 
rdfstore_bits_getfirstrecord (
        unsigned int size,      /* in bytes */
        unsigned char * bits,   /* bit array */
        unsigned int at,        /* as record no (bits/4) */
        unsigned char mask      /* 0000 to 1111 */
);

unsigned int rdfstore_bits_getfirstsetafter (
        unsigned int size,
        unsigned char * bits,
        unsigned int at
);

unsigned int rdfstore_bits_exor (
        unsigned int la, unsigned char * ba,
        unsigned int lb, unsigned char * bb,
        unsigned char * bc
        );
unsigned int rdfstore_bits_or (
        unsigned int la, unsigned char * ba,
        unsigned int lb, unsigned char * bb,
        unsigned char * bc
        );
unsigned int rdfstore_bits_and (
        unsigned int la, unsigned char * ba,
        unsigned int lb, unsigned char * bb,
        unsigned char * bc
        );
unsigned int rdfstore_bits_not (
        unsigned int la, unsigned char * ba,
        unsigned char * bb
        );

unsigned int rdfstore_bits_shorten (
        unsigned int la, unsigned char * ba
	);

unsigned int rdfstore_bits_and2(
        int n,
        unsigned int la, unsigned char * ba,
        unsigned int lb, unsigned char * bb,
        unsigned char mask,
        unsigned char * bc
        );

unsigned int rdfstore_bits_or2( 
        int n,
        unsigned int la, unsigned char * ba,
        unsigned int lb, unsigned char * bb,
        unsigned char mask,
        unsigned char * bc
        );

#endif
