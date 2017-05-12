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
# $Id: rdfstore_iterator.c,v 1.16 2006/06/19 10:10:21 areggiori Exp $
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

#include "rdfstore_log.h"
#include "rdfstore.h"
#include "rdfstore_iterator.h"
#include "rdfstore_serializer.h"
#include "rdfstore_digest.h"
#include "rdfstore_bits.h"
#include "rdfstore_utf8.h"

/*
#define RDFSTORE_DEBUG
*/

RDF_Statement   *
rdfstore_iterator_fetch_statement (
rdfstore_iterator       * me
);

int rdfstore_iterator_close (
rdfstore_iterator * me
) {
	if (	( me != NULL ) &&
		( me->store != NULL ) &&
		( me->store->cursor != NULL ) &&
		( me != me->store->cursor ) ) { /* do not touch internal cursors - still needed????!!??! */
                me->store->attached--; /* detach myself from the storage */

		/* dispose the storage (if possible) */
		if ( me->store->tobeclosed ) {
#ifdef RDFSTORE_DEBUG
                        printf(">>>>>>>>>>>>>>>>>>>>%p GOING TO CLOSE\n",me->store);
#endif
                        rdfstore_disconnect( me->store );
                        };

		RDFSTORE_FREE( me );
		me = NULL;

		return 1;
	} else {
		return 0;
	};
}; 

int rdfstore_iterator_hasnext (
rdfstore_iterator       * me
) {
if ( me == NULL )
	return 0;
#ifdef RDFSTORE_DEBUG
printf("HASNEXT %d < %d\n",me->st_counter, me->size);
#endif
if ( me->st_counter < me->size ) {
	return 1;
} else {
	return 0;
	};
};

RDF_Statement   *
rdfstore_iterator_next (
rdfstore_iterator       * me  
) {
	RDF_Statement   * s=NULL;

	if ( me == NULL )
		return NULL;

	/* advance to the next item */
	me->st_counter++;

	/* get the next one if any */
	me->pos++;
	if ( (me->pos = rdfstore_bits_getfirstsetafter(me->ids_size, me->ids, me->pos)) >= 8*(me->ids_size) )
		return NULL;

#ifdef RDFSTORE_DEBUG
printf("rdfstore_iterator_next( st_counter=%d pos=%d )\n",me->st_counter,me->pos);
#endif

	s =  rdfstore_iterator_fetch_statement ( me );
	
#ifdef RDFSTORE_DEBUG
	if (s != NULL ){
		fprintf(stderr,"\tS='%s'\n",s->subject->value.resource.identifier);
                fprintf(stderr,"\tP='%s'\n",s->predicate->value.resource.identifier);
                if ( s->object->type != 1 ) {
                	fprintf(stderr,"\tO='%s'\n",s->object->value.resource.identifier);
                } else { 
                	fprintf(stderr,"\tOLIT='%s'\n",s->object->value.literal.string);
                	};
                if ( s->context != NULL )
                	fprintf(stderr,"\tC='%s'\n",s->context->value.resource.identifier);
                if ( s->node != NULL )
			fprintf(stderr,"\tSRES='%s'\n",s->node->value.resource.identifier);
		};
#endif

	return s;
	};

RDF_Node   *
rdfstore_iterator_next_subject (
        rdfstore_iterator       * me  
        ) {
	RDF_Statement   * s=NULL;
	RDF_Node    * r=NULL;

	if ( me == NULL )
		return NULL;
	/* advance to the next item */
	me->st_counter++;

	/* get the next one if any */
	me->pos++;
	if ( (me->pos = rdfstore_bits_getfirstsetafter(me->ids_size, me->ids, me->pos)) >= 8*(me->ids_size) )
                return NULL;

	s =  rdfstore_iterator_fetch_statement ( me );

	if ( s != NULL ) {
        	r = s->subject;

        	RDFSTORE_FREE( s->predicate->value.resource.identifier );
        	RDFSTORE_FREE( s->predicate );
        	if ( s->object->type == 1 ) {
			if ( s->object->value.literal.dataType != NULL )
				RDFSTORE_FREE( s->object->value.literal.dataType );
        		RDFSTORE_FREE( s->object->value.literal.string );
        	} else {
        		RDFSTORE_FREE( s->object->value.resource.identifier );
        		};
        	RDFSTORE_FREE( s->object );
		if ( s->context != NULL ) {
        		RDFSTORE_FREE( s->context->value.resource.identifier );
        		RDFSTORE_FREE( s->context );
			};
		if ( s->node != NULL ) {
        		RDFSTORE_FREE( s->node->value.resource.identifier );
        		RDFSTORE_FREE( s->node );
			};
        	RDFSTORE_FREE( s );
		};

	return r;
	};

RDF_Node   *
rdfstore_iterator_next_predicate (
        rdfstore_iterator       * me  
        ) {
	RDF_Statement   * s=NULL;
        RDF_Node    * r=NULL;

	if ( me == NULL )
		return NULL;

	/* advance to the next item */
	me->st_counter++;

	/* get the next one if any */
	me->pos++;
	if ( (me->pos = rdfstore_bits_getfirstsetafter(me->ids_size, me->ids, me->pos)) >= 8*(me->ids_size) )
                return NULL;

	s =  rdfstore_iterator_fetch_statement ( me );

	if ( s != NULL ) {
		RDFSTORE_FREE( s->subject->value.resource.identifier );
        	RDFSTORE_FREE( s->subject );

        	r = s->predicate;

        	if ( s->object->type == 1 ) {
			if ( s->object->value.literal.dataType != NULL )
                        	RDFSTORE_FREE( s->object->value.literal.dataType );
                	RDFSTORE_FREE( s->object->value.literal.string );
        	} else {
                	RDFSTORE_FREE( s->object->value.resource.identifier );
                	};
        	RDFSTORE_FREE( s->object );
        	if ( s->context != NULL ) {
                	RDFSTORE_FREE( s->context->value.resource.identifier );
                	RDFSTORE_FREE( s->context );
                	};
		if ( s->node != NULL ) {   
                	RDFSTORE_FREE( s->node->value.resource.identifier );   
                	RDFSTORE_FREE( s->node );   
                	};
        	RDFSTORE_FREE( s );
		};

        return r;
	};

RDF_Node   *
rdfstore_iterator_next_object (
        rdfstore_iterator       * me  
        ) {
	RDF_Statement   * s=NULL;
        RDF_Node    * p=NULL;

	if ( me == NULL )
		return NULL;

	/* advance to the next item */
	me->st_counter++;

	/* get the next one if any */
	me->pos++;
	if ( (me->pos = rdfstore_bits_getfirstsetafter(me->ids_size, me->ids, me->pos)) >= 8*(me->ids_size) )
                return NULL;

	s =  rdfstore_iterator_fetch_statement ( me );

	if ( s != NULL ) {
		RDFSTORE_FREE( s->subject->value.resource.identifier );
        	RDFSTORE_FREE( s->subject );
		RDFSTORE_FREE( s->predicate->value.resource.identifier );
        	RDFSTORE_FREE( s->predicate );

        	p = s->object;

        	if ( s->context != NULL ) {
                	RDFSTORE_FREE( s->context->value.resource.identifier );
                	RDFSTORE_FREE( s->context );
                	};
		if ( s->node != NULL ) {   
                	RDFSTORE_FREE( s->node->value.resource.identifier );   
                	RDFSTORE_FREE( s->node );   
                	};
        	RDFSTORE_FREE( s );
		};

        return p;
	};

RDF_Node   *
rdfstore_iterator_next_context (
        rdfstore_iterator       * me  
        ) {
	RDF_Statement   * s=NULL;
        RDF_Node    * r=NULL;

	if ( me == NULL )
		return NULL;

	/* advance to the next item */
	me->st_counter++;

	/* get the next one if any */
	me->pos++;
	if ( (me->pos = rdfstore_bits_getfirstsetafter(me->ids_size, me->ids, me->pos)) >= 8*(me->ids_size) )
                return NULL;

	s =  rdfstore_iterator_fetch_statement ( me );

	if ( s != NULL ) {
		RDFSTORE_FREE( s->subject->value.resource.identifier );
        	RDFSTORE_FREE( s->subject );
		RDFSTORE_FREE( s->predicate->value.resource.identifier );
        	RDFSTORE_FREE( s->predicate );
        	if ( s->object->type == 1 ) {
			if ( s->object->value.literal.dataType != NULL )
                        	RDFSTORE_FREE( s->object->value.literal.dataType );
                	RDFSTORE_FREE( s->object->value.literal.string );
        	} else {
                	RDFSTORE_FREE( s->object->value.resource.identifier );
                	};
        	RDFSTORE_FREE( s->object );

        	r = s->context;

		if ( s->node != NULL ) {   
                	RDFSTORE_FREE( s->node->value.resource.identifier );   
                	RDFSTORE_FREE( s->node );   
                	};
        	RDFSTORE_FREE( s );
		};

        return r;
	};

RDF_Statement   *
rdfstore_iterator_current (
        rdfstore_iterator       * me  
        ) {
	if ( me == NULL )
		return NULL;
	return rdfstore_iterator_fetch_statement ( me );
	};

RDF_Node   *
rdfstore_iterator_current_subject (
        rdfstore_iterator       * me  
        ) {
	RDF_Statement   * s=NULL;
        RDF_Node    * r=NULL;

	if ( me == NULL )
		return NULL;

	s =  rdfstore_iterator_fetch_statement ( me );

	if ( s != NULL ) {
        	r = s->subject;

		RDFSTORE_FREE( s->predicate->value.resource.identifier );
        	RDFSTORE_FREE( s->predicate );
        	if ( s->object->type == 1 ) {
			if ( s->object->value.literal.dataType != NULL )
                        	RDFSTORE_FREE( s->object->value.literal.dataType );
                	RDFSTORE_FREE( s->object->value.literal.string );
        	} else {
                	RDFSTORE_FREE( s->object->value.resource.identifier );
                	};
        	RDFSTORE_FREE( s->object );
        	if ( s->context != NULL ) {
                	RDFSTORE_FREE( s->context->value.resource.identifier );
                	RDFSTORE_FREE( s->context );
                	};
		if ( s->node != NULL ) {   
                	RDFSTORE_FREE( s->node->value.resource.identifier );   
                	RDFSTORE_FREE( s->node );   
                	};
        	RDFSTORE_FREE( s );
		};

        return r;
	};

RDF_Node   *
rdfstore_iterator_current_predicate (
        rdfstore_iterator       * me  
        ) {
	RDF_Statement   * s=NULL;
        RDF_Node    * r=NULL;

	if ( me == NULL )
		return NULL;

	s =  rdfstore_iterator_fetch_statement ( me );

	if ( s != NULL ) {
		RDFSTORE_FREE( s->subject->value.resource.identifier );
        	RDFSTORE_FREE( s->subject );

        	r = s->predicate;

        	if ( s->object->type == 1 ) {
			if ( s->object->value.literal.dataType != NULL )
                        	RDFSTORE_FREE( s->object->value.literal.dataType );
                	RDFSTORE_FREE( s->object->value.literal.string );
        	} else {
                	RDFSTORE_FREE( s->object->value.resource.identifier );
                	};
        	RDFSTORE_FREE( s->object );
        	if ( s->context != NULL ) {
                	RDFSTORE_FREE( s->context->value.resource.identifier );
                	RDFSTORE_FREE( s->context );
                	};
		if ( s->node != NULL ) {   
                	RDFSTORE_FREE( s->node->value.resource.identifier );   
                	RDFSTORE_FREE( s->node );   
                	};
        	RDFSTORE_FREE( s );
		};

        return r;
	};

RDF_Node   *
rdfstore_iterator_current_object (
        rdfstore_iterator       * me  
        ) {
	RDF_Statement   * s=NULL;
        RDF_Node    * p=NULL;

	if ( me == NULL )
		return NULL;

	s =  rdfstore_iterator_fetch_statement ( me );

	if ( s != NULL ) {
		RDFSTORE_FREE( s->subject->value.resource.identifier );
        	RDFSTORE_FREE( s->subject );
        	RDFSTORE_FREE( s->predicate->value.resource.identifier );
        	RDFSTORE_FREE( s->predicate );

        	p = s->object;

        	if ( s->context != NULL ) {
                	RDFSTORE_FREE( s->context->value.resource.identifier );
                	RDFSTORE_FREE( s->context );
                	};
		if ( s->node != NULL ) {   
                	RDFSTORE_FREE( s->node->value.resource.identifier );   
                	RDFSTORE_FREE( s->node );   
                	};
        	RDFSTORE_FREE( s );
		};

        return p;
	};

RDF_Node   *
rdfstore_iterator_current_context (
        rdfstore_iterator       * me  
        ) {
	RDF_Statement   * s=NULL;
        RDF_Node    * r=NULL;

	if ( me == NULL )
		return NULL;

	s =  rdfstore_iterator_fetch_statement ( me );

	if ( s != NULL ) {
		RDFSTORE_FREE( s->subject->value.resource.identifier );
        	RDFSTORE_FREE( s->subject );
		RDFSTORE_FREE( s->predicate->value.resource.identifier );
        	RDFSTORE_FREE( s->predicate );
        	if ( s->object->type == 1 ) {
			if ( s->object->value.literal.dataType != NULL )
                        	RDFSTORE_FREE( s->object->value.literal.dataType );
                	RDFSTORE_FREE( s->object->value.literal.string );
        	} else {
                	RDFSTORE_FREE( s->object->value.resource.identifier );
                	};
        	RDFSTORE_FREE( s->object );

        	r = s->context;

		if ( s->node != NULL ) {   
                	RDFSTORE_FREE( s->node->value.resource.identifier );   
                	RDFSTORE_FREE( s->node );   
                	};
        	RDFSTORE_FREE( s );
		};

        return r;
	};

/* the following 4 methods reset the iterator and return the first item in the list */
RDF_Statement   *
rdfstore_iterator_first (
        rdfstore_iterator       * me
        ) {
	RDF_Statement   * s=NULL;
	if ( me == NULL )
		return NULL;

	/* reset iterator */
	me->st_counter = 0;

	/* get the first one if any */
	me->pos = 0;
	if ( (me->pos = rdfstore_bits_getfirstsetafter(me->ids_size, me->ids, me->pos)) >= 8*(me->ids_size) )
		return NULL;

#ifdef RDFSTORE_DEBUG
printf("rdfstore_iterator_first( st_counter=%d pos=%d )\n",me->st_counter,me->pos);
#endif

	s = rdfstore_iterator_current ( me );

#ifdef RDFSTORE_DEBUG
	if (s != NULL ){
		fprintf(stderr,"\tS='%s'\n",s->subject->value.resource.identifier);
                fprintf(stderr,"\tP='%s'\n",s->predicate->value.resource.identifier);
                if ( s->object->type != 1 ) {
                	fprintf(stderr,"\tO='%s'\n",s->object->value.resource.identifier);
                } else { 
                	fprintf(stderr,"\tOLIT='%s'\n",s->object->value.literal.string);
                	};
                if ( s->context != NULL )
                	fprintf(stderr,"\tC='%s'\n",s->context->value.resource.identifier);
                if ( s->node != NULL )
			fprintf(stderr,"\tSRES='%s'\n",s->node->value.resource.identifier);
		};
#endif

	return s;
	};

RDF_Node   *
rdfstore_iterator_first_subject (
        rdfstore_iterator       * me
        ) {
	if ( me == NULL )
		return NULL;

	/* reset iterator */
	me->st_counter = 0;

	/* get the first one if any */
	me->pos = 0;
	if ( (me->pos = rdfstore_bits_getfirstsetafter(me->ids_size, me->ids, me->pos)) >= 8*(me->ids_size) )
		return NULL;

	return rdfstore_iterator_current_subject ( me );
	};

RDF_Node   *
rdfstore_iterator_first_predicate (
        rdfstore_iterator       * me
        ) {
	if ( me == NULL )
		return NULL;

	/* reset iterator */
	me->st_counter = 0;

	/* get the first one if any */
	me->pos = 0;
	if ( (me->pos = rdfstore_bits_getfirstsetafter(me->ids_size, me->ids, me->pos)) >= 8*(me->ids_size) )
		return NULL;

	return rdfstore_iterator_current_predicate ( me );
	};

RDF_Node   *
rdfstore_iterator_first_object (
        rdfstore_iterator       * me
        ) {
	if ( me == NULL )
		return NULL;

	/* reset iterator */
	me->st_counter = 0;

	/* get the first one if any */
	me->pos = 0;
	if ( (me->pos = rdfstore_bits_getfirstsetafter(me->ids_size, me->ids, me->pos)) >= 8*(me->ids_size) )
		return NULL;

	return rdfstore_iterator_current_object ( me );
	};

RDF_Node   *
rdfstore_iterator_first_context (
        rdfstore_iterator       * me
        ) {
	if ( me == NULL )
		return NULL;

	/* reset iterator */
	me->st_counter = 0;

	/* get the first one if any */
	me->pos = 0;
	if ( (me->pos = rdfstore_bits_getfirstsetafter(me->ids_size, me->ids, me->pos)) >= 8*(me->ids_size) )
		return NULL;

	return rdfstore_iterator_current_context ( me );
	};

/* return items one by one till the end; then reset and return undef i.e. while( s = rdfstore_iterator_each(me) ) { ..... }; */
RDF_Statement   *
rdfstore_iterator_each (
rdfstore_iterator       * me  
) {
	RDF_Statement   * s=NULL;

	if ( me == NULL )
		return NULL;

	if (! rdfstore_iterator_hasnext( me ) ) {
		/* reset and return undef */
		me->st_counter = 0;
		me->pos = 0;
		return NULL;
		};

	/* set pos to the current one */
	if ( (me->pos = rdfstore_bits_getfirstsetafter(me->ids_size, me->ids, me->pos)) >= 8*(me->ids_size) ) {
		/* reset and return undef */
		me->st_counter = 0;
		me->pos = 0;
		return NULL; /* but this is an error not end of iteration! */
		};

#ifdef RDFSTORE_DEBUG
printf("rdfstore_iterator_each( st_counter=%d pos=%d )\n",me->st_counter,me->pos);
#endif

	s =  rdfstore_iterator_fetch_statement ( me );
	
	if ( s == NULL ) {
		/* reset and return undef */
		me->st_counter = 0;
		me->pos = 0;
		return NULL; /* but this is an error not end of iteration! */
		};

	/* hop to the next one if any */
	me->st_counter++;
	me->pos++;

#ifdef RDFSTORE_DEBUG
	if (s != NULL ){
		fprintf(stderr,"\tS='%s'\n",s->subject->value.resource.identifier);
                fprintf(stderr,"\tP='%s'\n",s->predicate->value.resource.identifier);
                if ( s->object->type != 1 ) {
                	fprintf(stderr,"\tO='%s'\n",s->object->value.resource.identifier);
                } else { 
                	fprintf(stderr,"\tOLIT='%s'\n",s->object->value.literal.string);
                	};
                if ( s->context != NULL )
                	fprintf(stderr,"\tC='%s'\n",s->context->value.resource.identifier);
                if ( s->node != NULL )
			fprintf(stderr,"\tSRES='%s'\n",s->node->value.resource.identifier);
		};
#endif

	return s;
	};

RDF_Node   *
rdfstore_iterator_each_subject (
        rdfstore_iterator       * me  
        ) {
	RDF_Statement   * s=NULL;
        RDF_Node    * r=NULL;

	if ( me == NULL )
		return NULL;

	if (! rdfstore_iterator_hasnext( me ) ) {
                /* reset and return undef */
                me->st_counter = 0;
                me->pos = 0;
                return NULL;
                };

        /* set pos to the current one */
        if ( (me->pos = rdfstore_bits_getfirstsetafter(me->ids_size, me->ids, me->pos)) >= 8*(me->ids_size) ) {
                /* reset and return undef */
                me->st_counter = 0;
                me->pos = 0;
                return NULL; /* but this is an error not end of iteration! */
                };

	s =  rdfstore_iterator_fetch_statement ( me );

	if ( s != NULL ) {
        	r = s->subject;

		RDFSTORE_FREE( s->predicate->value.resource.identifier );
        	RDFSTORE_FREE( s->predicate );
        	if ( s->object->type == 1 ) {
			if ( s->object->value.literal.dataType != NULL )
                        	RDFSTORE_FREE( s->object->value.literal.dataType );
                	RDFSTORE_FREE( s->object->value.literal.string );
        	} else {
                	RDFSTORE_FREE( s->object->value.resource.identifier );
                	};
        	RDFSTORE_FREE( s->object );
        	if ( s->context != NULL ) {
                	RDFSTORE_FREE( s->context->value.resource.identifier );
                	RDFSTORE_FREE( s->context );
                	};       
		if ( s->node != NULL ) {   
                	RDFSTORE_FREE( s->node->value.resource.identifier );   
                	RDFSTORE_FREE( s->node );   
                	};
        	RDFSTORE_FREE( s );
		};

        if ( r == NULL ) {
                /* reset and return undef */
                me->st_counter = 0;
                me->pos = 0;
                return NULL; /* but this is an error not end of iteration! */
                };

        /* hop to the next one if any */
        me->st_counter++;
        me->pos++;

	return r;
	};

RDF_Node   *
rdfstore_iterator_each_predicate (
        rdfstore_iterator       * me  
        ) {
	RDF_Statement   * s=NULL;
        RDF_Node    * r=NULL;

        if ( me == NULL )
                return NULL;
        
        if (! rdfstore_iterator_hasnext( me ) ) {
                /* reset and return undef */
                me->st_counter = 0;
                me->pos = 0;
                return NULL;
                };

        /* set pos to the current one */
        if ( (me->pos = rdfstore_bits_getfirstsetafter(me->ids_size, me->ids, me->pos)) >= 8*(me->ids_size) ) {
                /* reset and return undef */
                me->st_counter = 0;
                me->pos = 0;
                return NULL; /* but this is an error not end of iteration! */
                };

	s =  rdfstore_iterator_fetch_statement ( me );

	if ( s != NULL ) {
		RDFSTORE_FREE( s->subject->value.resource.identifier );
        	RDFSTORE_FREE( s->subject );

        	r = s->predicate;

        	if ( s->object->type == 1 ) {
			if ( s->object->value.literal.dataType != NULL )
                        	RDFSTORE_FREE( s->object->value.literal.dataType );
                	RDFSTORE_FREE( s->object->value.literal.string );
        	} else {
                	RDFSTORE_FREE( s->object->value.resource.identifier );
                	};    
        	RDFSTORE_FREE( s->object );
        	if ( s->context != NULL ) {
                	RDFSTORE_FREE( s->context->value.resource.identifier );
                	RDFSTORE_FREE( s->context );
                	};
		if ( s->node != NULL ) {   
                	RDFSTORE_FREE( s->node->value.resource.identifier );   
                	RDFSTORE_FREE( s->node );   
                	};
        	RDFSTORE_FREE( s );
		};

        if ( r == NULL ) {
                /* reset and return undef */
                me->st_counter = 0;
                me->pos = 0;
                return NULL; /* but this is an error not end of iteration! */
                };

        /* hop to the next one if any */
        me->st_counter++;
        me->pos++;

        return r;
	};

RDF_Node   *
rdfstore_iterator_each_object (
        rdfstore_iterator       * me  
        ) {
	RDF_Statement   * s=NULL;
        RDF_Node    * p=NULL;

        if ( me == NULL )
                return NULL;
        
        if (! rdfstore_iterator_hasnext( me ) ) {
                /* reset and return undef */
                me->st_counter = 0;
                me->pos = 0;
                return NULL;
                };

        /* set pos to the current one */
        if ( (me->pos = rdfstore_bits_getfirstsetafter(me->ids_size, me->ids, me->pos)) >= 8*(me->ids_size) ) {
                /* reset and return undef */
                me->st_counter = 0;
                me->pos = 0;
                return NULL; /* but this is an error not end of iteration! */
                };

	s =  rdfstore_iterator_fetch_statement ( me );

	if ( s != NULL ) {
		RDFSTORE_FREE( s->subject->value.resource.identifier );
        	RDFSTORE_FREE( s->subject );
        	RDFSTORE_FREE( s->predicate->value.resource.identifier );
        	RDFSTORE_FREE( s->predicate );

        	p = s->object;

        	if ( s->context != NULL ) {
                	RDFSTORE_FREE( s->context->value.resource.identifier );
                	RDFSTORE_FREE( s->context );
                	};
		if ( s->node != NULL ) {   
                	RDFSTORE_FREE( s->node->value.resource.identifier );   
                	RDFSTORE_FREE( s->node );   
                	};
        	RDFSTORE_FREE( s );
		};

        if ( p == NULL ) {
                /* reset and return undef */
                me->st_counter = 0;
                me->pos = 0;
                return NULL; /* but this is an error not end of iteration! */
                };

        /* hop to the next one if any */
        me->st_counter++;
        me->pos++;

        return p;
	};

RDF_Node   *
rdfstore_iterator_each_context (
        rdfstore_iterator       * me  
        ) {
	RDF_Statement   * s=NULL;
        RDF_Node    * r=NULL;

	if ( me == NULL )
		return NULL;

	if (! rdfstore_iterator_hasnext( me ) ) {
                /* reset and return undef */
                me->st_counter = 0;
                me->pos = 0;
                return NULL;
                };

        /* set pos to the current one */
        if ( (me->pos = rdfstore_bits_getfirstsetafter(me->ids_size, me->ids, me->pos)) >= 8*(me->ids_size) ) {
                /* reset and return undef */
                me->st_counter = 0;
                me->pos = 0;
                return NULL; /* but this is an error not end of iteration! */
                };

	s =  rdfstore_iterator_fetch_statement ( me );

	if ( s != NULL ) {
		RDFSTORE_FREE( s->subject->value.resource.identifier );
        	RDFSTORE_FREE( s->subject );
        	RDFSTORE_FREE( s->predicate->value.resource.identifier );
        	RDFSTORE_FREE( s->predicate );
        	if ( s->object->type == 1 ) {
			if ( s->object->value.literal.dataType != NULL )
                        	RDFSTORE_FREE( s->object->value.literal.dataType );
                	RDFSTORE_FREE( s->object->value.literal.string );
        	} else {
                	RDFSTORE_FREE( s->object->value.resource.identifier );
                	};
        	RDFSTORE_FREE( s->object );

        	r = s->context;

		if ( s->node != NULL ) {   
                	RDFSTORE_FREE( s->node->value.resource.identifier );   
                	RDFSTORE_FREE( s->node );   
                	};
        	RDFSTORE_FREE( s );
		};

        if ( r == NULL ) {
                /* reset and return undef */
                me->st_counter = 0;
                me->pos = 0;
                return NULL; /* but this is an error not end of iteration! */
                };

        /* hop to the next one if any */
        me->st_counter++;
        me->pos++;

	return r;
	};

int rdfstore_iterator_remove (
        rdfstore_iterator       * me
        ) {

#ifdef RDFSTORE_DEBUG
	{
	int i=0;
        printf("iterator remove ACTUAL (BEFORE remove):\n");
        for ( i=0; i<me->ids_size; i++) {
		printf("%02X",me->ids[i]);
       		};
	printf("' (%d)\n",me->ids_size);
	}
#endif

	/* zap current pos - we do not check whether is zero already or not....yet :) */
	if( ! rdfstore_bits_setmask(& me->ids_size, me->ids, me->pos, 1, 0, sizeof(me->ids)) )
		return 0;

#ifdef RDFSTORE_DEBUG
	{
	int i=0;
        printf("iterator remove ACTUAL (AFTER remove):\n");
        for ( i=0; i<me->ids_size; i++) {
		printf("%02X",me->ids[i]);
       		};
	printf("' (%d)\n",me->ids_size);
	}
#endif

	me->size--;
	me->ids_size = rdfstore_bits_shorten( me->ids_size, me->ids );

	return 1;
	};

int
rdfstore_iterator_contains (  
        rdfstore_iterator       * me,
        RDF_Statement           * statement,
        RDF_Node            * given_context
        ) {
        RDF_Node * context = NULL;
        unsigned char outbuf[256];
        DBT key, data;
        unsigned int pos=0,err=0;
        unsigned int st_id=0;
	int hc=0;

	if (    ( statement             == NULL ) ||
        	( statement->subject    == NULL ) ||
        	( statement->predicate  == NULL ) ||
        	( statement->subject->value.resource.identifier   == NULL ) ||
        	( statement->predicate->value.resource.identifier   == NULL ) ||
        	( statement->object     == NULL ) ||
        	(       ( statement->object->type != 1 ) &&
                	( statement->object->value.resource.identifier   == NULL ) ) ||
        	(       ( given_context != NULL ) && 
                	( given_context->value.resource.identifier   == NULL ) ) ||
        	(       ( statement->node != NULL ) &&
                	( statement->node->value.resource.identifier   == NULL ) ) )
        	return -1;

        if (given_context == NULL) {
		if (statement->context != NULL)
                        context = statement->context;
                /* we do not use the default context of the store because an iterator could contain different contexts and it would mess everything up */
        } else {
                /* use given context instead */
                context = given_context;
                };

	/* compute statement hashcode */
	hc = rdfstore_digest_get_statement_hashCode( statement, context );

	/* cache the hashcode if the statement has a "proper" identity */
	if ( given_context == NULL )
		statement->hashcode = hc;

	memset(&key, 0, sizeof(key));
	memset(&data, 0, sizeof(data));

#ifdef RDFSTORE_DEBUG
{
char * buff;
fprintf(stderr,"ITERATOR CONTAINS:\n");
fprintf(stderr,"\tS='%s'\n",statement->subject->value.resource.identifier);
fprintf(stderr,"\tP='%s'\n",statement->predicate->value.resource.identifier);
if ( statement->object->type != 1 ) {
        fprintf(stderr,"\tO='%s'\n",statement->object->value.resource.identifier);
} else {
        fprintf(stderr,"\tOLIT='%s'\n",statement->object->value.literal.string);  
        };
if ( context != NULL ) {
        fprintf(stderr,"\tC='%s'\n",context->value.resource.identifier);              
        };
if ( statement->node != NULL )
	fprintf(stderr,"\tSRES='%s'\n",statement->node->value.resource.identifier);
if( (buff=rdfstore_ntriples_statement( statement, context )) != NULL ) {
        fprintf(stderr," N-triples: %s\n", buff );
        RDFSTORE_FREE( buff );
        };
};
#endif

        /* look for the statement internal identifier */
        bzero(outbuf,sizeof(int));
        packInt( hc, outbuf );
        key.data = outbuf;
        key.size = sizeof(int);
        err = rdfstore_flat_store_fetch( me->store->statements, key, &data );
        if(err!=0) {
                if (err!=FLAT_STORE_E_NOTFOUND) {
                        perror("rdfstore_iterator_contains");
                        fprintf(stderr,"Could not fetch key '%s' in statements for store '%s': %s\n",(char *)key.data,(me->store->name != NULL) ? me->store->name : "(in-memory)", rdfstore_flat_store_get_error( me->store->statements ) );
                        return -1;
                } else {
                        return 0;
                        };
        } else {
                unpackInt( data.data, &st_id);
                RDFSTORE_FREE( data.data );
                pos = st_id;
                return (        ( rdfstore_bits_isanyset(&me->ids_size,me->ids,&pos,1) != 0 ) && /* are we sure that rdfstore_bits_isanyset() work here??!?! */
                                ( pos == st_id ) ) ? 1 : 0;
                };
	};

rdfstore_iterator *
rdfstore_iterator_intersect (
        rdfstore_iterator       * me,
        rdfstore_iterator       * you
        ) {
	rdfstore_iterator * results;

	if (	( me == NULL ) ||
		( you == NULL ) )
		return NULL;

	if ( me->store != you->store ) {
               	perror("rdfstore_iterator_intersect");
               	fprintf(stderr,"Cannot intersect cursors from different stores\n");
		return NULL;
		};
	
        results = NULL;
        results = (rdfstore_iterator *) RDFSTORE_MALLOC( sizeof(rdfstore_iterator) );
        if ( results == NULL ) {
               	perror("rdfstore_iterator_intersect");
               	fprintf(stderr,"Cannot create internal results cursor/iterator for store '%s'\n",(me->store->name != NULL) ? me->store->name : "(in-memory)" );
               	return NULL;
               	};
        results->store = me->store;
	me->store->attached++;
        results->remove_holes = 0;
        results->st_counter = 0;

#ifdef RDFSTORE_DEBUG
	{
	int j;
	printf("rdfstore_iterator_intersect (ME bits only) '");
        for ( j=0; j<me->ids_size; j++) {
        	printf("%02X",me->ids[j]);
       		};
        printf("'\n");
	}
	{
	int j;
	printf("rdfstore_iterator_intersect (YOU bits only) '");
        for ( j=0; j<you->ids_size; j++) {
        	printf("%02X",you->ids[j]);
       		};
        printf("'\n");
	}
#endif

	/* A & B */
	results->ids_size = rdfstore_bits_and( me->ids_size, me->ids, you->ids_size, you->ids, results->ids );
	results->ids_size = rdfstore_bits_shorten( results->ids_size, results->ids);

#ifdef RDFSTORE_DEBUG
	{
	int j;
	printf("rdfstore_iterator_intersect (RESULTS bits only) '");
        for ( j=0; j<results->ids_size; j++) {
        	printf("%02X",results->ids[j]);
       		};
        printf("'\n");
	}
#endif

	results->size = 0;
        results->pos = 0;
	while ( (results->pos = rdfstore_bits_getfirstsetafter(results->ids_size, results->ids, results->pos)) < 8*(results->ids_size) ) {
		results->pos++;
		results->size++;
		};
        results->pos = 0;

	return results;
	};

rdfstore_iterator *
rdfstore_iterator_unite (
        rdfstore_iterator       * me,
        rdfstore_iterator       * you
        ) {
	rdfstore_iterator * results;

	if (	( me == NULL ) ||
		( you == NULL ) )
		return NULL;

	if ( me->store != you->store ) {
               	perror("rdfstore_iterator_unite");
               	fprintf(stderr,"Cannot unite cursors from different stores\n");
		return NULL;
		};
	
        results = NULL;
        results = (rdfstore_iterator *) RDFSTORE_MALLOC( sizeof(rdfstore_iterator) );
        if ( results == NULL ) {
               	perror("rdfstore_iterator_unite");
               	fprintf(stderr,"Cannot create internal results cursor/iterator for store '%s'\n",(me->store->name != NULL) ? me->store->name : "(in-memory)" );
               	return NULL;
               	};
        results->store = me->store;
	me->store->attached++;
        results->remove_holes = 0;
        results->st_counter = 0;

#ifdef RDFSTORE_DEBUG
	{
	int j;
	printf("rdfstore_iterator_unite (ME bits only) '");
        for ( j=0; j<me->ids_size; j++) {
        	printf("%02X",me->ids[j]);
       		};
        printf("'\n");
	}
	{
	int j;
	printf("rdfstore_iterator_unite (YOU bits only) '");
        for ( j=0; j<you->ids_size; j++) {
        	printf("%02X",you->ids[j]);
       		};
        printf("'\n");
	}
#endif

	/* A | B */
	results->ids_size = rdfstore_bits_or( me->ids_size, me->ids, you->ids_size, you->ids, results->ids );
	results->ids_size = rdfstore_bits_shorten( results->ids_size, results->ids);

#ifdef RDFSTORE_DEBUG
	{
	int j;
	printf("rdfstore_iterator_unite (RESULTS bits only) '");
        for ( j=0; j<results->ids_size; j++) {
        	printf("%02X",results->ids[j]);
       		};
        printf("'\n");
	}
#endif

	results->size = 0;
        results->pos = 0;
	while ( (results->pos = rdfstore_bits_getfirstsetafter(results->ids_size, results->ids, results->pos)) < 8*(results->ids_size) ) {
		results->pos++;
		results->size++;
		};
        results->pos = 0;

	return results;
	};

rdfstore_iterator *
rdfstore_iterator_subtract (
        rdfstore_iterator       * me,
        rdfstore_iterator       * you
        ) {
	rdfstore_iterator * results;
	register int i=0;
	unsigned char not[RDFSTORE_MAXRECORDS_BYTES_SIZE];

	if (	( me == NULL ) ||
		( you == NULL ) )
		return NULL;

	if ( me->store != you->store ) {
               	perror("rdfstore_iterator_subtract");
               	fprintf(stderr,"Cannot subtract cursors from different stores\n");
		return NULL;
		};
	
        results = NULL;
        results = (rdfstore_iterator *) RDFSTORE_MALLOC( sizeof(rdfstore_iterator) );
        if ( results == NULL ) {
               	perror("rdfstore_iterator_subtract");
               	fprintf(stderr,"Cannot create internal results cursor/iterator for store '%s'\n",(me->store->name != NULL) ? me->store->name : "(in-memory)" );
               	return NULL;
               	};
        results->store = me->store;
	me->store->attached++;
        results->remove_holes = 0;
        results->st_counter = 0;

#ifdef RDFSTORE_DEBUG
	{
	int j;
	printf("rdfstore_iterator_subtract (ME bits only) '");
        for ( j=0; j<me->ids_size; j++) {
        	printf("%02X",me->ids[j]);
       		};
        printf("'\n");
	}
	{
	int j;
	printf("rdfstore_iterator_subtract (YOU bits only) '");
        for ( j=0; j<you->ids_size; j++) {
        	printf("%02X",you->ids[j]);
       		};
        printf("'\n");
	}
#endif

	/* A & (~B) */
	for (	i=0;
		i<you->ids_size;
		i++ ) {
		not[i] = ( ~ you->ids[i] );
		};	
#ifdef RDFSTORE_DEBUG
	{
	int j;
	printf("rdfstore_iterator_subtract ( *NOT* YOU bits only) '");
        for ( j=0; j<you->ids_size; j++) {
        	printf("%02X",not[j]);
       		};
        printf("'\n");
	}
#endif

	results->ids_size = rdfstore_bits_and( me->ids_size, me->ids, you->ids_size, not, results->ids );
	results->ids_size = rdfstore_bits_shorten( results->ids_size, results->ids);

#ifdef RDFSTORE_DEBUG
	{
	int j;
	printf("rdfstore_iterator_subtract (RESULTS bits only) '");
        for ( j=0; j<results->ids_size; j++) {
        	printf("%02X",results->ids[j]);
       		};
        printf("'\n");
	}
#endif

	results->size = 0;
        results->pos = 0;
	while ( (results->pos = rdfstore_bits_getfirstsetafter(results->ids_size, results->ids, results->pos)) < 8*(results->ids_size) ) {
		results->pos++;
		results->size++;
		};
        results->pos = 0;

	return results;
	};

rdfstore_iterator *
rdfstore_iterator_complement (
        rdfstore_iterator       * me
        ) {
	rdfstore_iterator * results;
	rdfstore_iterator * results1;
	rdfstore_iterator * results2;

	if ( me == NULL )
		return NULL;

        results = NULL;
        results = (rdfstore_iterator *) RDFSTORE_MALLOC( sizeof(rdfstore_iterator) );
        if ( results == NULL ) {
               	perror("rdfstore_iterator_complement");
               	fprintf(stderr,"Cannot create internal results cursor/iterator for store '%s'\n",(me->store->name != NULL) ? me->store->name : "(in-memory)" );
               	return NULL;
               	};
        results->store = me->store;
	me->store->attached++;
        results->remove_holes = 0;
        results->st_counter = 0;

#ifdef RDFSTORE_DEBUG
	{
	int j;
	printf("rdfstore_iterator_complement (ME bits only) '");
        for ( j=0; j<me->ids_size; j++) {
        	printf("%02X",me->ids[j]);
       		};
        printf("'\n");
	}
#endif

	results->ids_size = rdfstore_bits_not( me->ids_size, me->ids, results->ids );
	results->ids_size = rdfstore_bits_shorten( results->ids_size, results->ids);

#ifdef RDFSTORE_DEBUG
	{
	int j;
	printf("rdfstore_iterator_complement (RESULTS bits only) '");
        for ( j=0; j<results->ids_size; j++) {
        	printf("%02X",results->ids[j]);
       		};
        printf("'\n");
	}
#endif

	results->size = 0;
        results->pos = 0;
	while ( (results->pos = rdfstore_bits_getfirstsetafter(results->ids_size, results->ids, results->pos)) < 8*(results->ids_size) ) {
		results->pos++;
		results->size++;
		};
        results->pos = 0;

	results1 = rdfstore_elements ( me->store );

        if ( results1 == NULL ) {
               	perror("rdfstore_iterator_complement");
               	fprintf(stderr,"Cannot create internal results cursor/iterator for store '%s'\n",(me->store->name != NULL) ? me->store->name : "(in-memory)" );
		rdfstore_iterator_close( results );
               	return NULL;
               	};

	/* make sure that result set is sane */
	results2 = rdfstore_iterator_intersect(	results, results1 );

	rdfstore_iterator_close( results1 );
	rdfstore_iterator_close( results );

        if ( results2 == NULL ) {
               	perror("rdfstore_iterator_complement");
               	fprintf(stderr,"Cannot create internal results cursor/iterator for store '%s'\n",(me->store->name != NULL) ? me->store->name : "(in-memory)" );
               	return NULL;
               	};

	return results2;
	};

/* it returns a one when A is set and B is not set. But NOT the other way round. */
rdfstore_iterator *
rdfstore_iterator_exor (
        rdfstore_iterator       * me,
        rdfstore_iterator       * you
        ) {
	rdfstore_iterator * results;

	if (	( me == NULL ) ||
		( you == NULL ) )
		return NULL;

	if ( me->store != you->store ) {
               	perror("rdfstore_iterator_exor");
               	fprintf(stderr,"Cannot carry out exor of cursors from different stores\n");
		return NULL;
		};
	
        results = NULL;
        results = (rdfstore_iterator *) RDFSTORE_MALLOC( sizeof(rdfstore_iterator) );
        if ( results == NULL ) {
               	perror("rdfstore_iterator_exor");
               	fprintf(stderr,"Cannot create internal results cursor/iterator for store '%s'\n",(me->store->name != NULL) ? me->store->name : "(in-memory)" );
               	return NULL;
               	};
        results->store = me->store;
	me->store->attached++;
        results->remove_holes = 0;
        results->st_counter = 0;

#ifdef RDFSTORE_DEBUG
	{
	int j;
	printf("rdfstore_iterator_exor (ME bits only) '");
        for ( j=0; j<me->ids_size; j++) {
        	printf("%02X",me->ids[j]);
       		};
        printf("'\n");
	}
	{
	int j;
	printf("rdfstore_iterator_exor (YOU bits only) '");
        for ( j=0; j<you->ids_size; j++) {
        	printf("%02X",you->ids[j]);
       		};
        printf("'\n");
	}
#endif

	/* (A | B) ^ B aka Exor */
	results->ids_size = rdfstore_bits_exor( me->ids_size, me->ids, you->ids_size, you->ids, results->ids );
	results->ids_size = rdfstore_bits_shorten( results->ids_size, results->ids);

#ifdef RDFSTORE_DEBUG
	{
	int j;
	printf("rdfstore_iterator_exor (RESULTS bits only) '");
        for ( j=0; j<results->ids_size; j++) {
        	printf("%02X",results->ids[j]);
       		};
        printf("'\n");
	}
#endif

	results->size = 0;
        results->pos = 0;
	while ( (results->pos = rdfstore_bits_getfirstsetafter(results->ids_size, results->ids, results->pos)) < 8*(results->ids_size) ) {
		results->pos++;
		results->size++;
		};
        results->pos = 0;

	return results;
	};

rdfstore_iterator *
rdfstore_iterator_duplicate (
        rdfstore_iterator       * me
        ) {
	rdfstore_iterator * results;

        results = NULL;
        results = (rdfstore_iterator *) RDFSTORE_MALLOC( sizeof(rdfstore_iterator) );
        if ( results == NULL ) {
               	perror("rdfstore_iterator_duplicate");
               	fprintf(stderr,"Cannot create internal results cursor/iterator for store '%s'\n",(me->store->name != NULL) ? me->store->name : "(in-memory)" );
               	return NULL;
               	};
        results->store = me->store;
        results->store->attached++; /* one more attached I guess */
        /*bzero(results->ids,sizeof(results->ids)); */
        bcopy(me->ids,results->ids,sizeof(unsigned char)*me->ids_size);
        results->ids_size = me->ids_size;
        results->remove_holes = me->remove_holes;
        results->pos = me->pos;
        results->st_counter = me->st_counter;
	results->size = me->size;

	return results;
	};

unsigned int rdfstore_iterator_size (
        rdfstore_iterator       * me
        ) {

	if ( me == NULL )
		return -1;

	return me->size;
	};

/* return a statement given its ID; the statement structure needs to be disposed by the caller */
RDF_Statement   *
rdfstore_iterator_fetch_statement (
        rdfstore_iterator	* me
        ) {
	DBT key, data;
	unsigned char outbuf[256];	
	RDF_Statement * statement;
	unsigned int st_id;
	int length=0;
	char * p;
	char mask=0;
	int err=0;

	if ( me == NULL )
		return NULL;

	if ( me->size <= 0 )
		return NULL;

        memset(&key, 0, sizeof(key));
        memset(&data, 0, sizeof(data));

	st_id = (unsigned int)me->pos; /* this is set by other iterator methods such as first() and next() */

#ifdef RDFSTORE_DEBUG
	printf(">>>>>>>>>>>>>>>>>> rdfstore_iterator_fetch_statement: st_id=%d\n",st_id);
#endif

	/* create memory structures */
	statement = (RDF_Statement *) RDFSTORE_MALLOC(sizeof(RDF_Statement));
	if ( statement == NULL ) {
		perror("rdfstore_iterator_fetch_statement");
                fprintf(stderr,"Could not even create statement for store '%s'\n",(me->store->name != NULL) ? me->store->name : "(in-memory)" ); 

		return NULL;
		};
	statement->node = NULL;
	statement->hashcode = 0;
	statement->isreified = 0; /* expensive to check this in the database ?!??? */
        statement->subject = (RDF_Node *) RDFSTORE_MALLOC(sizeof(RDF_Node));
	if ( statement->subject == NULL ) {
		perror("rdfstore_iterator_fetch_statement");
                fprintf(stderr,"Could not even create statement subject for store '%s'\n",(me->store->name != NULL) ? me->store->name : "(in-memory)" ); 

		RDFSTORE_FREE(statement);

		return NULL;
		};
        statement->subject->hashcode=0;
        statement->predicate = (RDF_Node *) RDFSTORE_MALLOC(sizeof(RDF_Node));
	if ( statement->predicate == NULL ) {
		perror("rdfstore_iterator_fetch_statement");
                fprintf(stderr,"Could not even create statement predicate for store '%s'\n",(me->store->name != NULL) ? me->store->name : "(in-memory)" ); 

		RDFSTORE_FREE(statement->subject);
		RDFSTORE_FREE(statement);

		return NULL;
		};
        statement->predicate->hashcode=0;
        statement->object = (RDF_Node *) RDFSTORE_MALLOC(sizeof(RDF_Node));
	if ( statement->object == NULL ) {
		perror("rdfstore_iterator_fetch_statement");
                fprintf(stderr,"Could not even create statement object property for store '%s'\n",(me->store->name != NULL) ? me->store->name : "(in-memory)" ); 

		RDFSTORE_FREE(statement->subject);
		RDFSTORE_FREE(statement->predicate);
		RDFSTORE_FREE(statement);

		return NULL;
		};
        statement->object->hashcode=0;

	/* here are all the DB operations needed to fetch a statement */

	/* fetch statement */
	bzero(outbuf,sizeof(int));
	packInt( st_id, outbuf );
	key.data = outbuf;
	key.size = sizeof(int);
        err = rdfstore_flat_store_fetch ( me->store->nodes, key, &data );
        if ( err == 0 ) {
		length = ( sizeof(int) * 7 ) + 1; /* see doc/SWADe-rdfstore.html about how info is stored */

#ifdef RDFSTORE_DEBUG
                fprintf(stderr,"GOT statement '%s' %d\n",(char *)data.data+length);
#endif

		/* sort out various components */
		p = data.data + length;
		mask = *(p-1);

		/* subject */
		length=0;
		unpackInt( data.data, &length );
		statement->subject->value.resource.identifier = NULL;
        	statement->subject->value.resource.identifier = (char *) RDFSTORE_MALLOC( sizeof(char)*(length + 1) );
        	if ( statement->subject->value.resource.identifier == NULL ) {
			perror("rdfstore_iterator_fetch_statement");
                	fprintf(stderr,"Could not even fetch statement subject for store '%s'\n",(me->store->name != NULL) ? me->store->name : "(in-memory)" ); 
			RDFSTORE_FREE( data.data );
			RDFSTORE_FREE( statement->subject );
			RDFSTORE_FREE( statement->predicate );
			RDFSTORE_FREE( statement->object );
			RDFSTORE_FREE( statement );

                	return NULL;
                	};
		statement->subject->type= (mask & 2) ? 2 : 0;
		memcpy(statement->subject->value.resource.identifier,p,length);
		memcpy(statement->subject->value.resource.identifier+length,"\0",1);
		statement->subject->value.resource.identifier_len = length;
		p+=length;

		/* predicate */
		length=0;
		unpackInt( data.data+(sizeof(int)), &length );
		statement->predicate->value.resource.identifier=NULL;
        	statement->predicate->value.resource.identifier = (char *) RDFSTORE_MALLOC( sizeof(char)*(length + 1) );
        	if ( statement->predicate->value.resource.identifier == NULL ) {
			perror("rdfstore_iterator_fetch_statement");
                	fprintf(stderr,"Could not even fetch statement predicate for store '%s'\n",(me->store->name != NULL) ? me->store->name : "(in-memory)" ); 
			RDFSTORE_FREE( data.data );
                	RDFSTORE_FREE( statement->subject->value.resource.identifier );
			RDFSTORE_FREE( statement->subject );
			RDFSTORE_FREE( statement->predicate );
			RDFSTORE_FREE( statement->object );
			RDFSTORE_FREE( statement );

                	return NULL;
                	};
		statement->predicate->type= (mask & 4) ? 2 : 0;
		memcpy(statement->predicate->value.resource.identifier,p,length);
		memcpy(statement->predicate->value.resource.identifier+length,"\0",1);
		statement->predicate->value.resource.identifier_len = length;
		p+=length;

		/* object */
		length=0;
		unpackInt( data.data+(sizeof(int)*2), &length );
		if ( mask & 1 ) {
			/* object literal value */
			statement->object->value.literal.string = NULL;
        		statement->object->value.literal.string = (char *) RDFSTORE_MALLOC( sizeof(char)*(length + 1) );
        		if ( statement->object->value.literal.string == NULL ) {
				perror("rdfstore_iterator_fetch_statement");
                		fprintf(stderr,"Could not even fetch statement object literal for store '%s'\n",(me->store->name != NULL) ? me->store->name : "(in-memory)" ); 
				RDFSTORE_FREE( data.data );
		               	RDFSTORE_FREE( statement->subject->value.resource.identifier );
				RDFSTORE_FREE( statement->subject );
		               	RDFSTORE_FREE( statement->predicate->value.resource.identifier );
				RDFSTORE_FREE( statement->predicate );
				RDFSTORE_FREE( statement->object );
				RDFSTORE_FREE( statement );

				return NULL;
				};
			statement->object->type = 1; /* literal */
			memcpy(statement->object->value.literal.string,p,length);
			memcpy(statement->object->value.literal.string+length,"\0",1);
			statement->object->value.literal.string_len = length;
			p+=length;

			/* object xml:lang */
			length=0;
			unpackInt( data.data+(sizeof(int)*3), &length );
			if ( length ) {
				memcpy(statement->object->value.literal.lang,p,length);
				memcpy(statement->object->value.literal.lang+length,"\0",1);
				p+=length;
			} else {
				memcpy(statement->object->value.literal.lang,"\0",1); /* or =NULL ??? */
				};

			/* object rdf:dataType */
			length=0;
			unpackInt( data.data+(sizeof(int)*4), &length );
			statement->object->value.literal.dataType = NULL;
			if ( length ) {
        			statement->object->value.literal.dataType = (char *) RDFSTORE_MALLOC( sizeof(char)*(length + 1) );
        			if ( statement->object->value.literal.dataType == NULL ) {
					perror("rdfstore_iterator_fetch_statement");
                			fprintf(stderr,"Could not even fetch statement object literal rdf:dataType for store '%s'\n",(me->store->name != NULL) ? me->store->name : "(in-memory)" ); 
					RDFSTORE_FREE( data.data );
		               		RDFSTORE_FREE( statement->subject->value.resource.identifier );
					RDFSTORE_FREE( statement->subject );
		               		RDFSTORE_FREE( statement->predicate->value.resource.identifier );
					RDFSTORE_FREE( statement->predicate );
		               		RDFSTORE_FREE( statement->object->value.literal.string );
					RDFSTORE_FREE( statement->object );
					RDFSTORE_FREE( statement );

					return NULL;
					};
				statement->object->value.literal.parseType= ( strncmp(p,RDFSTORE_RDF_PARSETYPE_LITERAL,length) == 0 ) ? 1 : 0;
				memcpy(statement->object->value.literal.dataType,p,length);
				memcpy(statement->object->value.literal.dataType+length,"\0",1);
				p+=length;
			} else {
				statement->object->value.literal.parseType = 0;
				};
		} else {
			statement->object->value.resource.identifier=NULL;
        		statement->object->value.resource.identifier = (char *) RDFSTORE_MALLOC( sizeof(char)*(length + 1) );
        		if ( statement->object->value.resource.identifier == NULL ) {
				perror("rdfstore_iterator_fetch_statement");
                		fprintf(stderr,"Could not even fetch statement object for store '%s'\n",(me->store->name != NULL) ? me->store->name : "(in-memory)" ); 
				RDFSTORE_FREE( data.data );
                		RDFSTORE_FREE( statement->subject->value.resource.identifier );
				RDFSTORE_FREE( statement->subject );
                		RDFSTORE_FREE( statement->predicate->value.resource.identifier );
				RDFSTORE_FREE( statement->predicate );
				RDFSTORE_FREE( statement->object );
				RDFSTORE_FREE( statement );

                		return NULL;
                		};
			statement->object->type= (mask & 8) ? 2 : 0;
			memcpy(statement->object->value.resource.identifier,p,length);
			memcpy(statement->object->value.resource.identifier+length,"\0",1);
			statement->object->value.resource.identifier_len = length;
			p+=length;
			};

		/* context */
		length=0;
		unpackInt( data.data+(sizeof(int)*5), &length );
		statement->context = NULL;
		if ( length ) {
        		statement->context = (RDF_Node *) RDFSTORE_MALLOC(sizeof(RDF_Node));
			if ( statement->context == NULL ) {
				perror("rdfstore_iterator_fetch_statement");
                		fprintf(stderr,"Could not even create statement context for store '%s'\n",(me->store->name != NULL) ? me->store->name : "(in-memory)" ); 
				RDFSTORE_FREE( data.data );
		               	RDFSTORE_FREE( statement->subject->value.resource.identifier );
				RDFSTORE_FREE( statement->subject );
		               	RDFSTORE_FREE( statement->predicate->value.resource.identifier );
				RDFSTORE_FREE( statement->predicate );
				if ( statement->object->type != 1 ) {
		               		RDFSTORE_FREE( statement->object->value.resource.identifier );
				} else {
		               		RDFSTORE_FREE( statement->object->value.literal.string );
					if ( statement->object->value.literal.dataType != NULL )
						RDFSTORE_FREE( statement->object->value.literal.dataType );
					};
				RDFSTORE_FREE( statement->object );
				RDFSTORE_FREE( statement );

				return NULL;
				};
        		statement->context->hashcode=0;

			statement->context->value.resource.identifier=NULL;
	        	statement->context->value.resource.identifier = (char *) RDFSTORE_MALLOC( sizeof(char)*(length + 1) );
	        	if ( statement->context->value.resource.identifier == NULL ) {
				perror("rdfstore_iterator_fetch_statement");
	                	fprintf(stderr,"Could not even fetch statement context for store '%s'\n",(me->store->name != NULL) ? me->store->name : "(in-memory)" ); 

				RDFSTORE_FREE( data.data );
		               	RDFSTORE_FREE( statement->subject->value.resource.identifier );
				RDFSTORE_FREE( statement->subject );
		               	RDFSTORE_FREE( statement->predicate->value.resource.identifier );
				RDFSTORE_FREE( statement->predicate );
				if ( statement->object->type != 1 ) {
		               		RDFSTORE_FREE( statement->object->value.resource.identifier );
				} else {
		               		RDFSTORE_FREE( statement->object->value.literal.string );
					if ( statement->object->value.literal.dataType != NULL )
						RDFSTORE_FREE( statement->object->value.literal.dataType );
					};
				RDFSTORE_FREE( statement->object );
				RDFSTORE_FREE( statement->context );
				RDFSTORE_FREE( statement );
	
	                	return NULL;
	                	};
			statement->context->type= (mask & 16) ? 2 : 0;
			memcpy(statement->context->value.resource.identifier,p,length);
			memcpy(statement->context->value.resource.identifier+length,"\0",1);
			statement->context->value.resource.identifier_len = length;
			p+=length;
			};

		/* statement as resource stuff */
		length=0;
		unpackInt( data.data+(sizeof(int)*6), &length );
		statement->node = NULL;
		if ( length ) {
        		statement->node = (RDF_Node *) RDFSTORE_MALLOC(sizeof(RDF_Node));
			if ( statement->node == NULL ) {
				perror("rdfstore_iterator_fetch_statement");
                		fprintf(stderr,"Could not even create statement as resource for store '%s'\n",(me->store->name != NULL) ? me->store->name : "(in-memory)" ); 
				RDFSTORE_FREE( data.data );
		               	RDFSTORE_FREE( statement->subject->value.resource.identifier );
				RDFSTORE_FREE( statement->subject );
		               	RDFSTORE_FREE( statement->predicate->value.resource.identifier );
				RDFSTORE_FREE( statement->predicate );
				if ( statement->object->type != 1 ) {
		               		RDFSTORE_FREE( statement->object->value.resource.identifier );
				} else {
		               		RDFSTORE_FREE( statement->object->value.literal.string );
					if ( statement->object->value.literal.dataType != NULL )
						RDFSTORE_FREE( statement->object->value.literal.dataType );
					};
				RDFSTORE_FREE( statement->object );
				if ( statement->context != NULL ) {
		               		RDFSTORE_FREE( statement->context->value.resource.identifier );
					RDFSTORE_FREE( statement->context );
					};
				RDFSTORE_FREE( statement );

				return NULL;
				};
        		statement->node->hashcode=0;

			statement->node->value.resource.identifier=NULL;
	        	statement->node->value.resource.identifier = (char *) RDFSTORE_MALLOC( sizeof(char)*(length + 1) );
	        	if ( statement->node->value.resource.identifier == NULL ) {
				perror("rdfstore_iterator_fetch_statement");
	                	fprintf(stderr,"Could not even fetch statement as resource for store '%s'\n",(me->store->name != NULL) ? me->store->name : "(in-memory)" ); 

				RDFSTORE_FREE( data.data );
		               	RDFSTORE_FREE( statement->subject->value.resource.identifier );
				RDFSTORE_FREE( statement->subject );
		               	RDFSTORE_FREE( statement->predicate->value.resource.identifier );
				RDFSTORE_FREE( statement->predicate );
				if ( statement->object->type != 1 ) {
		               		RDFSTORE_FREE( statement->object->value.resource.identifier );
				} else {
		               		RDFSTORE_FREE( statement->object->value.literal.string );
					if ( statement->object->value.literal.dataType != NULL )
						RDFSTORE_FREE( statement->object->value.literal.dataType );
					};
				RDFSTORE_FREE( statement->object );
				if ( statement->context != NULL ) {
		               		RDFSTORE_FREE( statement->context->value.resource.identifier );
					RDFSTORE_FREE( statement->context );
					};
				RDFSTORE_FREE( statement->node );
				RDFSTORE_FREE( statement );
	
	                	return NULL;
	                	};
			statement->node->type = 0; /* see http://www.w3.org/TR/rdf-syntax-grammar/#section-Syntax-reifying why */
			memcpy(statement->node->value.resource.identifier,p,length);
			memcpy(statement->node->value.resource.identifier+length,"\0",1);
			statement->node->value.resource.identifier_len = length;
			p+=length;
			};

		RDFSTORE_FREE( data.data );
         } else {
		perror("rdfstore_iterator_fetch_statement");
                fprintf(stderr,"Could not even fetch statement '%d' (key is %d bytes) for store '%s': %s\n",st_id, (int)key.size, (me->store->name != NULL) ? me->store->name : "(in-memory)", rdfstore_flat_store_get_error( me->store->nodes ) ); 

		RDFSTORE_FREE(statement->subject);
		RDFSTORE_FREE(statement->predicate);
		RDFSTORE_FREE(statement->object);
		RDFSTORE_FREE(statement);

                return NULL;
		};

#ifdef RDFSTORE_DEBUG
	if (statement != NULL ) {
		fprintf(stderr,"\tS='%s'\n",statement->subject->value.resource.identifier);
		fprintf(stderr,"\tP='%s'\n",statement->predicate->value.resource.identifier);
                if ( statement->object->type != 1 ) {
			fprintf(stderr,"\tO='%s'\n",statement->object->value.resource.identifier);
                } else { 
                	fprintf(stderr,"\tOLIT='%s'\n",statement->object->value.literal.string);
                        };
                if ( statement->context != NULL )
			fprintf(stderr,"\tC='%s'\n",statement->context->value.resource.identifier);
                if ( statement->node != NULL )
			fprintf(stderr,"\tSRES='%s'\n",statement->node->value.resource.identifier);
		};
#endif

	return statement;
	};
