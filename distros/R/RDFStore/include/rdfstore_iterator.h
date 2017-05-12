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
# $Id: rdfstore_iterator.h,v 1.6 2006/06/19 10:10:23 areggiori Exp $
#
*/

#ifndef _H_RDFSTORE_ITERATOR
#define _H_RDFSTORE_ITERATOR

#include "rdfstore.h"
#include "rdfstore_compress.h"

typedef struct rdfstore_iterator {
        struct rdfstore * store;
        unsigned int size; /* num of statements i.e. number of bits set in ids[] below */
        unsigned char ids[RDFSTORE_MAXRECORDS_BYTES_SIZE]; /* keep the set of statements for search iterators i.e. bit vector 1 bit per statement */
        unsigned int ids_size; /* its size in bytes also */
        unsigned int remove_holes;
        unsigned int st_counter;
        unsigned int    pos;
        } rdfstore_iterator;

typedef rdfstore_iterator * RDFStore_Iterator;

/* dispose iterator */
int rdfstore_iterator_close (
	rdfstore_iterator * me
        );

int rdfstore_iterator_hasnext (
        rdfstore_iterator       * me
        );

RDF_Statement   *
rdfstore_iterator_next (
        rdfstore_iterator       * me
        );

RDF_Node   *
rdfstore_iterator_next_subject (
        rdfstore_iterator       * me
        );

RDF_Node   *
rdfstore_iterator_next_predicate (
        rdfstore_iterator       * me
        );

RDF_Node   *
rdfstore_iterator_next_object (
        rdfstore_iterator       * me
        );

RDF_Node   *
rdfstore_iterator_next_context (
        rdfstore_iterator       * me
        );

RDF_Statement   *
rdfstore_iterator_current (
        rdfstore_iterator       * me
        );

RDF_Node   *
rdfstore_iterator_current_subject (
        rdfstore_iterator       * me
        );

RDF_Node   *
rdfstore_iterator_current_predicate (
        rdfstore_iterator       * me
        );

RDF_Node   *
rdfstore_iterator_current_object (
        rdfstore_iterator       * me
        );

RDF_Node   *
rdfstore_iterator_current_context (
        rdfstore_iterator       * me
        );

RDF_Statement   *
rdfstore_iterator_first (
        rdfstore_iterator       * me
        );

RDF_Node   *
rdfstore_iterator_first_subject (
        rdfstore_iterator       * me
        );

RDF_Node   *
rdfstore_iterator_first_predicate (
        rdfstore_iterator       * me
        );

RDF_Node   *
rdfstore_iterator_first_object (
        rdfstore_iterator       * me
        );

RDF_Node   *
rdfstore_iterator_first_context (
        rdfstore_iterator       * me
        );

RDF_Statement   *
rdfstore_iterator_each (
        rdfstore_iterator       * me
        );

RDF_Node   *
rdfstore_iterator_each_subject (
        rdfstore_iterator       * me
        );

RDF_Node   *
rdfstore_iterator_each_predicate (
        rdfstore_iterator       * me
        );

RDF_Node   *
rdfstore_iterator_each_object (
        rdfstore_iterator       * me
        );

RDF_Node   *
rdfstore_iterator_each_context (
        rdfstore_iterator       * me
        );

int rdfstore_iterator_remove (
        rdfstore_iterator       * me
        );

int rdfstore_iterator_contains ( 
        rdfstore_iterator       * me,   
        RDF_Statement           * statement,
        RDF_Node		* given_context
        );

rdfstore_iterator *
rdfstore_iterator_intersect (
        rdfstore_iterator       * me,	
        rdfstore_iterator       * you
        );

rdfstore_iterator *
rdfstore_iterator_unite (
        rdfstore_iterator       * me,	
        rdfstore_iterator       * you
        );

rdfstore_iterator *
rdfstore_iterator_subtract (
        rdfstore_iterator       * me,	
        rdfstore_iterator       * you
        );

rdfstore_iterator *
rdfstore_iterator_complement (
        rdfstore_iterator       * me
        );

rdfstore_iterator *
rdfstore_iterator_exor (
        rdfstore_iterator       * me,	
        rdfstore_iterator       * you
        );

rdfstore_iterator *
rdfstore_iterator_duplicate (
        rdfstore_iterator       * me
        );

unsigned int rdfstore_iterator_size (
        rdfstore_iterator       * me
        );

#endif
