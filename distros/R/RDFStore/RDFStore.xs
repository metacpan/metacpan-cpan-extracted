/*
  *
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
*/

#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"  
#include "perl.h"
#include "XSUB.h"

#ifdef PERL_IMPLICIT_CONTEXT
static PerlInterpreter *my_perl;
#endif

#ifdef _NOT_CORE
#  include "ppport.h"
#endif

#include "dbms.h"
#include "dbms_compat.h"

#ifndef PERL_VERSION
#    include "patchlevel.h"
#    define PERL_REVISION       5
#    define PERL_VERSION        PATCHLEVEL
#    define PERL_SUBVERSION     SUBVERSION
#endif

#if PERL_REVISION == 5 && (PERL_VERSION < 4 || (PERL_VERSION == 4 && PERL_SUBVERSION <= 75 ))
#    define PL_sv_undef         sv_undef
#    define PL_na               na
#endif

#ifndef DB_VERSION_MAJOR
#undef __attribute__
#endif

#ifdef op
#    undef op
#endif

#if PERL_REVISION > 5 || (PERL_REVISION == 5 && PERL_VERSION >= 7)


#ifndef DB_VERSION_MAJOR

#undef  dNOOP
#define dNOOP extern int Perl___notused

/* Ditto for dXSARGS. */
#undef  dXSARGS
#define dXSARGS                             \
        dSP; dMARK;                     \
        I32 ax = mark - PL_stack_base + 1;      \
        I32 items = sp - mark

#endif

#undef dXSI32
#define dXSI32 dNOOP

#endif

#include "dbms_comms.h"  

#include "rdfstore_log.h"  
#include "rdfstore.h"  
#include "rdfstore_iterator.h"  
#include "rdfstore_serializer.h"  
#include "rdfstore_utf8.h"  
#include "rdfstore_digest.h"  

typedef RDF_Node * RDFStore_RDFNode;
typedef RDF_Statement * RDFStore_Statement;
typedef RDF_Triple_Pattern * RDFStore_Triple_Pattern;
typedef rdfstore * RDFStore;
typedef dbms * DBMS;

/* this version interacts with $! in perl.. */
void
myerror(char * erm, int erx ) {    
#ifdef dTHX
	dTHX;
#endif
        SV* sv = perl_get_sv("RDFStore::ERROR",TRUE);
        SV* sv2 = perl_get_sv("!",TRUE);

        sv_setiv(sv, (IV) erx);
        sv_setpv(sv, erm );
        SvIOK_on(sv);

        sv_setiv(sv2, (IV) erx);
        sv_setpv(sv2, erm );
        SvIOK_on(sv2);
#if 0
        fprintf(stderr,"RDFStore: ERROR %s\n",erm);
#endif
	}

/* this version interacts with $! in perl.. */
void
set_dbms_error(char * erm, int erx ) {
#ifdef dTHX
	dTHX;
#endif
	SV* sv = perl_get_sv("DBMS::ERROR",TRUE); 
	SV* sv2 = perl_get_sv("!",TRUE); 

	sv_setiv(sv, (IV) erx);
	sv_setpv(sv, erm );
	SvIOK_on(sv);

	sv_setiv(sv2, (IV) erx);
	sv_setpv(sv2, erm );
	SvIOK_on(sv2);

#if 0
	fprintf(stderr,"DBMSD: ERROR %s\n",erm);
#endif
	}

RDFStore_Statement
new_Statement_Object ( SV * subject, SV * predicate, SV * object, SV * context, int isreified, SV * node ) {
        RDFStore_Statement ss=NULL;
	
	if ( ! ( ( SvROK( subject ) ) &&
		 ( sv_isa( subject, "RDFStore::Resource") ) &&
		 ( SvROK( predicate ) ) &&
		 ( sv_isa( predicate, "RDFStore::Resource") ) &&
		 ( SvROK( object ) ) &&
		 (	( sv_isa( object, "RDFStore::Literal") ) ||
			( sv_isa( object, "RDFStore::Resource") ) ) ) ) {
		croak("new: Cannot create statement: invalid subject, predicate or object\n");
		return NULL;
		};

	ss = rdfstore_statement_new(	rdfstore_resource_clone( (RDFStore_RDFNode)(SvIV(SvRV(subject))) ),
					rdfstore_resource_clone( (RDFStore_RDFNode)(SvIV(SvRV(predicate))) ),
					rdfstore_node_clone( (RDFStore_RDFNode)(SvIV(SvRV(object))) ),
					(	( context != NULL ) &&
						( context != &PL_sv_undef ) &&
						( SvTRUE(context) ) &&
						( SvROK(context) ) &&
						( sv_isa( context, "RDFStore::Resource") ) ) ?
							rdfstore_resource_clone( (RDFStore_RDFNode)(SvIV(SvRV(context))) ) : NULL,
					(	( node != NULL ) &&
						( node != &PL_sv_undef ) &&
						( SvTRUE(node) ) &&
						( SvROK(node) ) &&
						( sv_isa( node, "RDFStore::Resource") ) ) ?
							rdfstore_resource_clone( (RDFStore_RDFNode)(SvIV(SvRV(node))) ) : NULL,
					isreified );

	return ss;
	};

MODULE = RDFStore       PACKAGE = RDFStore::RDFNode     PREFIX = RDFStore_RDFNode_

PROTOTYPES: DISABLE

BOOT:
{
#ifdef dTHX
  dTHX;
#endif
  AV *isa = perl_get_av("RDFStore::RDFNode::ISA",1);
  av_push(isa,newSVpv("RDFStore::Digest::Digestable",0)); 
};

void
RDFStore_RDFNode_new ( package )
	SV*             package

        PREINIT:
        	RDFStore_RDFNode mm;
		SV * node;

        PPCODE:
                if (!SvROK(package)) {
                        STRLEN my_na;
                        char *sclass = SvPV(package, my_na);

			/* allocate mem for the node */
			mm = (RDFStore_RDFNode) rdfstore_node_new();

			if (mm==NULL) {
                        	XSRETURN_UNDEF;
                		};

                        /* bless() the node */
                        node = sv_newmortal();
                        sv_setref_pv( node, sclass, (void*)mm);
                        SvREADONLY_on(SvRV(node));

			XPUSHs( node );
                } else {
                        /* just get through */
                        mm = (RDFStore_RDFNode)SvIV(SvRV(package));
                        };

                XSRETURN(1);

unsigned char *
RDFStore_RDFNode_getLabel ( me )  
        SV*             me

        PREINIT:
                RDFStore_RDFNode mm = (RDFStore_RDFNode)SvIV(SvRV(me));
		int ll=0;

        CODE:
                RETVAL = rdfstore_node_get_label( mm, &ll );
        OUTPUT:
                RETVAL

void
RDFStore_RDFNode_getDigest ( me )
	SV*		me

	PREINIT:
                RDFStore_RDFNode mm = (RDFStore_RDFNode)SvIV(SvRV(me));
		int dl=0;
		unsigned char * dd=NULL;

	PPCODE:
        	dd = rdfstore_node_get_digest( mm, &dl );
		if (	( dd != NULL )  &&
			( dl > 0 ) ) {
        		ST(0) = sv_2mortal( newSVpv( dd, dl ) );
			XSRETURN(1);
		} else {
			XSRETURN_UNDEF;
			};

void
RDFStore_RDFNode_DESTROY( me )  
        SV*             me

        PREINIT:
                RDFStore_RDFNode mm = (RDFStore_RDFNode)SvIV(SvRV(me));

        CODE:
		rdfstore_node_free( mm );

MODULE = RDFStore       PACKAGE = RDFStore::Resource     PREFIX = RDFStore_Resource_

PROTOTYPES: DISABLE

BOOT:
{
#ifdef dTHX
  dTHX;
#endif
  AV *isa = perl_get_av("RDFStore::Resource::ISA",1);
  av_push(isa,newSVpv("RDFStore::RDFNode",0)); 
};

void
RDFStore_Resource_new ( package, namespace, localname=NULL, bNode=0 )
	SV*             package
	unsigned char *		namespace
	unsigned char *		localname
	int		bNode

        PREINIT:
        	RDFStore_RDFNode mm;
		SV * resource;

        PPCODE:
                if (!SvROK(package)) {
                        STRLEN my_na;
                        char *sclass = SvPV(package, my_na);

			if (	( namespace != NULL ) &&
				( localname != NULL ) &&
				( strlen( localname ) > 0 ) ) {
				mm = rdfstore_resource_new_from_qname( namespace, strlen(namespace), localname, strlen(localname), (bNode) ? RDFSTORE_NODE_TYPE_BNODE : RDFSTORE_NODE_TYPE_RESOURCE );
			} else {
				if (	( namespace == NULL ) ||
					(       ( namespace != NULL ) &&
						( strlen( namespace ) <= 0 ) ) ) {
                        		/* Resource identifier can not be null (empty) */
                        		XSRETURN_UNDEF;
				} else {
					mm = rdfstore_resource_new( namespace, strlen(namespace), (bNode) ? RDFSTORE_NODE_TYPE_BNODE : RDFSTORE_NODE_TYPE_RESOURCE );
					};
				};

			if ( mm == NULL ) {
                        	XSRETURN_UNDEF;
                		};
				
                        /* re-bless() the node to a resource */
                        resource = sv_newmortal();
                        sv_setref_pv(resource, sclass, (void*)mm);
                        SvREADONLY_on(SvRV(resource));

			XPUSHs( resource );
                } else {
                        /* just get through */
                        mm = (RDFStore_RDFNode)SvIV(SvRV(package));
                        };

                XSRETURN(1);

int
RDFStore_Resource_isAnonymous ( me )
	SV*		me

	PREINIT:
                RDFStore_RDFNode mm = (RDFStore_RDFNode)SvIV(SvRV(me));

	CODE:
		RETVAL = rdfstore_resource_is_anonymous( mm );
	OUTPUT:
		RETVAL

void
RDFStore_Resource_getNamespace ( me )
        SV*             me

        PREINIT:
                RDFStore_RDFNode mm = (RDFStore_RDFNode)SvIV(SvRV(me));
		int ll=0;
		unsigned char * ns=NULL;

        PPCODE:
		ns = rdfstore_resource_get_namespace( mm, &ll );

		if ( ll <= 0 ) {
			XSRETURN_UNDEF;
			};

		ST(0) = sv_2mortal( newSVpv( ns, ll ) );

                XSRETURN(1);

void
RDFStore_Resource_getLocalName ( me )
        SV*             me

        PREINIT:
                RDFStore_RDFNode mm = (RDFStore_RDFNode)SvIV(SvRV(me));
		unsigned char * nc=NULL;
		int ll=0;

        PPCODE:
		nc = rdfstore_resource_get_localname( mm, &ll );

		if (	( nc == NULL ) ||
			( ll <= 0 ) ) {
			XSRETURN_UNDEF;
			};

		ST(0) = sv_2mortal( newSVpv( nc, ll ) );

		XSRETURN(1);

void
RDFStore_Resource_getbNode ( me )
	SV*		me

	PREINIT:
                RDFStore_RDFNode mm = (RDFStore_RDFNode)SvIV(SvRV(me));
		unsigned char * bn=NULL;
		int ll=0;

	PPCODE:
		bn = rdfstore_resource_get_bnode( mm, &ll );

		if (	( bn == NULL ) ||
			( ll <= 0 ) ) {
			XSRETURN_UNDEF;
			};

		XPUSHs( sv_2mortal(newSVpv( bn, ll )) );

		XSRETURN(1);

void
RDFStore_Resource_DESTROY( me )  
        SV*             me

        PREINIT:
                RDFStore_RDFNode mm = (RDFStore_RDFNode)SvIV(SvRV(me));

        CODE:
		rdfstore_resource_free( mm );

MODULE = RDFStore       PACKAGE = RDFStore::Literal     PREFIX = RDFStore_Literal_

PROTOTYPES: DISABLE

BOOT:
{
#ifdef dTHX
  dTHX;
#endif
  AV *isa = perl_get_av("RDFStore::Literal::ISA",1);
  av_push(isa,newSVpv("RDFStore::RDFNode",0)); 
};

void
RDFStore_Literal_new ( package, content=NULL, parseType=0, lang=NULL, dataType=NULL )
	SV*             package
	unsigned char *          content
	int		parseType
	unsigned char *          lang
	unsigned char *		dataType

        PREINIT:
        	RDFStore_RDFNode mm;
		SV * literal;

        PPCODE:
                if (!SvROK(package)) {
                        STRLEN my_na;
                        char *sclass = SvPV(package, my_na);

			/* strlen() is not UTF8 safe - Perl does this with SvLEN() but must SV* ... */
			mm = rdfstore_literal_new( content, ( content != NULL ) ? strlen(content) : 0 , parseType, lang, dataType );

			if ( mm == NULL ) {
				XSRETURN_UNDEF;
                		};
				
                        /* re-bless() the node to a literal */
                        literal = sv_newmortal();
                        sv_setref_pv( literal, sclass, (void*)mm);
                        SvREADONLY_on(SvRV(literal));

			XPUSHs( literal );
                } else {
                        /* just get through */
                        mm = (RDFStore_RDFNode)SvIV(SvRV(package));
                        };

                XSRETURN(1);

int
RDFStore_Literal_getParseType ( me )
	SV*		me

	PREINIT:
                RDFStore_RDFNode mm = (RDFStore_RDFNode)SvIV(SvRV(me));

	CODE:
		RETVAL = rdfstore_literal_get_parsetype( mm );
        OUTPUT:
          	RETVAL

unsigned char *
RDFStore_Literal_getLang ( me )
	SV*		me

	PREINIT:
                RDFStore_RDFNode mm = (RDFStore_RDFNode)SvIV(SvRV(me));

	CODE:
		RETVAL = rdfstore_literal_get_lang( mm );
        OUTPUT:
          	RETVAL

unsigned char *
RDFStore_Literal_getDataType ( me )
	SV*		me

	PREINIT:
                RDFStore_RDFNode mm = (RDFStore_RDFNode)SvIV(SvRV(me));

	CODE:
		RETVAL = rdfstore_literal_get_datatype( mm );
        OUTPUT:
          	RETVAL

void
RDFStore_Literal_DESTROY( me )  
        SV*             me

        PREINIT:
                RDFStore_RDFNode mm = (RDFStore_RDFNode)SvIV(SvRV(me));

        CODE:
		rdfstore_literal_free( mm );

MODULE = RDFStore       PACKAGE = RDFStore::Statement     PREFIX = RDFStore_Statement_

PROTOTYPES: DISABLE

BOOT:
{
#ifdef dTHX
  dTHX;
#endif
  AV *isa = perl_get_av("RDFStore::Statement::ISA",1);
  av_push(isa,newSVpv("RDFStore::Resource",0)); 
};

void
RDFStore_Statement_new ( package, subject, predicate, object, context=NULL, isreified=0, identifier=NULL )
	SV*     package
	SV*	subject
	SV*	predicate
	SV*	object
	SV*	context
	int	isreified
	SV*	identifier

        PREINIT:
        	RDFStore_Statement mm;
		SV * statement;

        PPCODE:
                if (!SvROK(package)) {
                        STRLEN my_na;
                        char *sclass = SvPV(package, my_na);

			mm = new_Statement_Object( subject, predicate, object, context, isreified, identifier );

			if ( mm == NULL ) {
				XSRETURN_UNDEF;
                		};
				
                        /* re-bless() the node to a literal */
                        statement = sv_newmortal();
                        sv_setref_pv( statement, sclass, (void*)mm);
                        SvREADONLY_on(SvRV(statement));

			XPUSHs( statement );
                } else {
                        /* just get through */
                        mm = (RDFStore_Statement)SvIV(SvRV(package));
                        };

                XSRETURN(1);

int
RDFStore_Statement_isReified ( me )
	SV*		me

	PREINIT:
                RDFStore_Statement mm = (RDFStore_Statement)SvIV(SvRV(me));

	CODE:

		RETVAL = rdfstore_statement_isreified( mm );

	OUTPUT:
		RETVAL

void
RDFStore_Statement_subject ( me )
	SV*		me

	PREINIT:
                RDFStore_Statement mm = (RDFStore_Statement)SvIV(SvRV(me));
		RDFStore_RDFNode nn=NULL;
		SV * node;

	PPCODE:
		nn  = rdfstore_statement_get_subject( mm );

		if ( nn != NULL ) {
			/* bless() the node */
                        node = sv_newmortal();
                        sv_setref_pv( node, "RDFStore::Resource", (void*) rdfstore_resource_clone( nn ) );
                        SvREADONLY_on(SvRV(node));

			XPUSHs( node );

			XSRETURN(1);
		} else {
			XSRETURN_UNDEF;
			};

void
RDFStore_Statement_predicate ( me )
	SV*		me

	PREINIT:
                RDFStore_Statement mm = (RDFStore_Statement)SvIV(SvRV(me));
		RDFStore_RDFNode nn=NULL;
		SV * node;

	PPCODE:
		nn  = rdfstore_statement_get_predicate( mm );

                if ( nn != NULL ) {
                        /* bless() the node */
                        node = sv_newmortal();
                        sv_setref_pv( node, "RDFStore::Resource", (void*) rdfstore_resource_clone( nn ) );      
                        SvREADONLY_on(SvRV(node));

			XPUSHs( node );

                        XSRETURN(1);
                } else {
			XSRETURN_UNDEF;
                        };

void
RDFStore_Statement_object ( me )
	SV*		me

	PREINIT:
                RDFStore_Statement mm = (RDFStore_Statement)SvIV(SvRV(me));
		RDFStore_RDFNode nn=NULL;
		SV * node;

	PPCODE:
		nn  = rdfstore_statement_get_object( mm );

                if ( nn != NULL ) {
                        /* bless() the node */
                        node = sv_newmortal();
                        if (  rdfstore_node_get_type( nn ) != RDFSTORE_NODE_TYPE_LITERAL ) {
                        	sv_setref_pv( node, "RDFStore::Resource", (void*) rdfstore_resource_clone( nn ) );      
			} else {
                        	sv_setref_pv( node, "RDFStore::Literal", (void*) rdfstore_literal_clone( nn ) );      
				};
                        SvREADONLY_on(SvRV(node));

			XPUSHs( node );

                        XSRETURN(1);
                } else {
			XSRETURN_UNDEF;
                        };

void
RDFStore_Statement_context ( me )
	SV*		me

	PREINIT:
                RDFStore_Statement mm = (RDFStore_Statement)SvIV(SvRV(me));
		RDFStore_RDFNode nn=NULL;
		SV * node;

	PPCODE:
		nn  = rdfstore_statement_get_context( mm );

                if ( nn != NULL ) {
                       	/* bless() the node */
                       	node = sv_newmortal();
                       	sv_setref_pv( node, "RDFStore::Resource", (void*) rdfstore_resource_clone( nn ) );      
                       	SvREADONLY_on(SvRV(node));

			XPUSHs( node );

                       	XSRETURN(1);
               	} else {
			XSRETURN_UNDEF;
                       	};

void
RDFStore_Statement_getDigest ( me )
	SV*		me

	PREINIT:
                RDFStore_Statement mm = (RDFStore_Statement)SvIV(SvRV(me));
		unsigned char * dd = NULL;
		int dl=0;

	PPCODE:
        	dd = rdfstore_statement_get_digest( mm, &dl );
		if (	( dd != NULL )  &&
			( dl > 0 ) ) {
			ST(0) = sv_2mortal( newSVpv( dd, dl ) );
			XSRETURN(1);
		} else {
			XSRETURN_UNDEF;
			};

void
RDFStore_Statement_toString ( me )
        SV*             me

        PREINIT:
                RDFStore_Statement mm = (RDFStore_Statement)SvIV(SvRV(me));
		unsigned char *	ntriples_rep=NULL;
		int nl=0;

        PPCODE:
		ntriples_rep = rdfstore_statement_to_string( mm, &nl );
	
		if (	( ntriples_rep == NULL ) ||
			( nl <= 0 ) )
			XSRETURN_UNDEF;

                ST(0) = sv_2mortal(newSVpv( ntriples_rep, nl ));

                RDFSTORE_FREE( ntriples_rep );

                XSRETURN(1);

void
RDFStore_Statement_getLabel ( me )
        SV*             me

        PREINIT:
                RDFStore_Statement mm = (RDFStore_Statement)SvIV(SvRV(me));
		unsigned char * label=NULL;
		int ll=0;

        PPCODE:
                label = rdfstore_statement_get_label( mm, &ll );

		if (	( label == NULL ) ||
			( ll <= 0 ) )
			XSRETURN_UNDEF;
		ST(0) = sv_2mortal(newSVpv(label,ll));

		XSRETURN(1);

void
RDFStore_Statement_DESTROY( me )
        SV*             me

        PREINIT:
                RDFStore_Statement mm = (RDFStore_Statement)SvIV(SvRV(me));

        CODE:
		rdfstore_statement_free( mm );

MODULE = RDFStore	PACKAGE = RDFStore	PREFIX = RDFStore_

PROTOTYPES: DISABLE

int
RDFStore_if_modified_since ( name=NULL, since )
	char *	name
	char *	since
	
	PREINIT:
		int status=0;

	CODE:
		status=rdfstore_if_modified_since( name, since, NULL,NULL,NULL,&myerror );

                RETVAL = (status) ? 0 : 1;
        OUTPUT:
          	RETVAL

void
RDFStore_new ( package, directory="", flags=0, freetext=0, sync=0, remote=0, host=DBMS_HOST,port=DBMS_PORT )
        SV*             package
	char *          directory
	int             flags
	int             freetext
	int             sync
	int             remote
	char *          host
	int		port

        PREINIT:
                RDFStore mm;
		SV * store;

        PPCODE:
                if (!SvROK(package)) {
                        /* bless() the store cursor */
                        STRLEN my_na;
                        char *sclass = SvPV(package, my_na);

                        /* connect */
			if ( rdfstore_connect( &mm, directory, flags, ( freetext ? freetext : 0 ),( sync ? sync : 0 ),( remote ? remote : 0 ), host, port, NULL,NULL,NULL,&myerror ) != 0 ) {
				XSRETURN_UNDEF;
                                };

                        store = sv_newmortal();
                        sv_setref_pv( store, sclass, (void*)mm);
                        SvREADONLY_on(SvRV(store));

			XPUSHs( store );
                } else {
                        /* just get through */
                        mm = (RDFStore)SvIV(SvRV(package));
                        };

                XSRETURN(1);

void
RDFStore_debug_malloc_dump()
    CODE:
#ifdef RDFSTORE_DEBUG_MALLOC
	rdfstore_log_debug_malloc_dump();
#endif

void
RDFStore_DESTROY( me )
        SV*             me

        PREINIT:
                RDFStore mm = (RDFStore)SvIV(SvRV(me));

        CODE:
		/* disconnect and free if necessary */
		rdfstore_disconnect( mm );

unsigned int
RDFStore_size( me )
        SV*             me

	PREINIT:
                RDFStore mm = (RDFStore)SvIV(SvRV(me));

	CODE:

        	if ( rdfstore_size( mm, &RETVAL ) ) {
                	XSRETURN_UNDEF;
			};

        OUTPUT:
                RETVAL

int
RDFStore_insert ( me, subject, predicate=NULL, object=NULL, context=NULL )
        SV*             me
        SV*             subject
        SV*             predicate
        SV*             object
        SV*             context

	PREINIT:
                RDFStore mm = (RDFStore)SvIV(SvRV(me));
		int status=0;
		RDFStore_Statement statement;
		
	CODE:
		if ( !  ( ( subject != NULL ) &&
                          ( subject != &PL_sv_undef ) &&
                          ( SvTRUE(subject) ) &&
			  ( SvROK(subject) ) &&
                          (     ( sv_isa( subject, "RDFStore::Resource") ) ||
                                ( sv_isa( subject, "RDFStore::Statement") ) ) ) ) {
                        croak("insert: Invalid subject or statement\n");
                        XSRETURN_UNDEF;
                        };
                if (	( predicate != NULL ) &&
			( predicate != &PL_sv_undef ) &&
			( SvTRUE(predicate) ) ) {
			if ( ! ( ( SvROK(predicate) ) &&
                        	 ( sv_isa( predicate, "RDFStore::Resource") ) ) ) {
                        	croak("insert: Invalid predicate\n");
                        	XSRETURN_UNDEF;
                        	};
                        };
                if (	( object != NULL ) &&
			( object != &PL_sv_undef ) &&
			( SvTRUE(object) ) ) {
			if ( ! ( ( SvROK(object) ) &&
                        	 (	( sv_isa( object, "RDFStore::Literal") ) ||
					( sv_isa( object, "RDFStore::Resource") ) ) ) ) {
                        	croak("insert: Invalid object\n");
                        	XSRETURN_UNDEF;
                        	};
                        };
		if (	( context != NULL ) &&
			( context != &PL_sv_undef ) &&
			( SvTRUE(context) ) ) {
			if ( ! ( ( SvROK(context) ) &&
                        	 ( sv_isa( context, "RDFStore::Resource") ) ) ) {
                        	croak("insert: Invalid statement context\n");
                        	XSRETURN_UNDEF;
                        	};
                        };

		/* create a temporary statement */
                if ( ! sv_isa( ST(1), "RDFStore::Statement") ) {
			statement = new_Statement_Object( subject, predicate, object, NULL, 0, NULL );
			if ( statement == NULL ) {
                                XSRETURN_UNDEF;
                		};
		} else {
			statement = ((RDFStore_Statement)SvIV(SvRV(ST(1))));
			};

		status=rdfstore_insert( mm, statement, ( ( context != NULL ) && ( context != &PL_sv_undef ) && ( SvROK( context ) ) ) ? (RDFStore_RDFNode)SvIV(SvRV(context)) : NULL );

                if ( ! sv_isa( ST(1), "RDFStore::Statement") ) {
			rdfstore_statement_free( statement );
			};

                RETVAL = (status) ? 0 : 1;
        OUTPUT:
          	RETVAL

int
RDFStore_remove ( me, subject, predicate=NULL, object=NULL, context=NULL )
        SV*             me
        SV*             subject
        SV*             predicate
        SV*             object
        SV*             context

        PREINIT:
                RDFStore mm = (RDFStore)SvIV(SvRV(me));
                int status=0;
                RDF_Statement *	statement;

        CODE:
		if ( !  ( ( subject != NULL ) &&  
                          ( subject != &PL_sv_undef ) &&  
                          ( SvTRUE(subject) ) &&  
                          ( SvROK(subject) ) &&
                          (     ( sv_isa( subject, "RDFStore::Resource") ) ||
                                ( sv_isa( subject, "RDFStore::Statement") ) ) ) ) {
                        croak("remove: Invalid subject or statement\n");
                        XSRETURN_UNDEF;
                        };
		if (    ( predicate != NULL ) &&
                        ( predicate != &PL_sv_undef ) &&
			( SvTRUE(predicate) ) ) {
                        if ( ! ( ( SvROK(predicate) ) &&
                                 ( sv_isa( predicate, "RDFStore::Resource") ) ) ) {     
                                croak("remove: Invalid predicate\n");
                                XSRETURN_UNDEF;
                                };
                        };
                if (    ( object != NULL ) &&
                        ( object != &PL_sv_undef ) &&
			( SvTRUE(object) ) ) {
                        if ( ! ( ( SvROK(object) ) &&
                                 (      ( sv_isa( object, "RDFStore::Literal") ) ||
                                        ( sv_isa( object, "RDFStore::Resource") ) ) ) ) {
                                croak("remove: Invalid object\n");
                                XSRETURN_UNDEF;
                                };
                        };
                if (    ( context != NULL ) &&
                        ( context != &PL_sv_undef ) &&
			( SvTRUE(context) ) ) {
                        if ( ! ( ( SvROK(context) ) &&
                                 ( sv_isa( context, "RDFStore::Resource") ) ) ) {
                                croak("remove: Invalid statement context\n");
                                XSRETURN_UNDEF;
                                };
                        };

		/* create a temporary statement */
		if ( ! sv_isa( ST(1), "RDFStore::Statement") ) {
			statement = new_Statement_Object( subject, predicate, object, NULL, 0, NULL );
                        if ( statement == NULL ) {
                                XSRETURN_UNDEF;
                                };
                } else {
                        statement = ((RDFStore_Statement)SvIV(SvRV(ST(1))));
                        };

                status=rdfstore_remove( mm, statement, ( ( context != NULL ) && ( context != &PL_sv_undef ) && ( SvROK( context ) ) ) ? (RDFStore_RDFNode)SvIV(SvRV(context)) : NULL );

                if ( ! sv_isa( ST(1), "RDFStore::Statement") ) {
			rdfstore_statement_free( statement );
                        };

                RETVAL = (status) ? 0 : 1;
        OUTPUT:
                RETVAL

int
RDFStore_contains ( me, subject, predicate=NULL, object=NULL, context=NULL )
        SV*             me
        SV*             subject
        SV*             predicate
        SV*             object
        SV*             context

        PREINIT:
                RDFStore mm = (RDFStore)SvIV(SvRV(me));
                int status=0;
                RDF_Statement *	statement;

        CODE:
		if ( !  ( ( subject != NULL ) &&  
                          ( subject != &PL_sv_undef ) &&  
                          ( SvTRUE(subject) ) &&  
                          ( SvROK(subject) ) &&
                          (     ( sv_isa( subject, "RDFStore::Resource") ) ||
                                ( sv_isa( subject, "RDFStore::Statement") ) ) ) ) {
                        croak("contains: Invalid subject or statement\n");
                        XSRETURN_UNDEF;
                        };
		if (    ( predicate != NULL ) &&
                        ( predicate != &PL_sv_undef ) &&
			( SvTRUE(predicate) ) ) {
                        if ( ! ( ( SvROK(predicate) ) &&
                                 ( sv_isa( predicate, "RDFStore::Resource") ) ) ) {     
                                croak("contains: Invalid predicate\n");
                                XSRETURN_UNDEF;
                                };
                        };
                if (    ( object != NULL ) &&
                        ( object != &PL_sv_undef ) &&
			( SvTRUE(object) ) ) {
                        if ( ! ( ( SvROK(object) ) &&
                                 (      ( sv_isa( object, "RDFStore::Literal") ) ||
                                        ( sv_isa( object, "RDFStore::Resource") ) ) ) ) {
                                croak("contains: Invalid object\n");
                                XSRETURN_UNDEF;
                                };
                        };
                if (    ( context != NULL ) &&
                        ( context != &PL_sv_undef ) &&
			( SvTRUE(context) ) ) {
                        if ( ! ( ( SvROK(context) ) &&
                                 ( sv_isa( context, "RDFStore::Resource") ) ) ) {
                                croak("contains: Invalid statement context\n");
                                XSRETURN_UNDEF;
                                };
                        };

                /* create a temporary statement */
		if ( ! sv_isa( ST(1), "RDFStore::Statement") ) {
			statement = new_Statement_Object( subject, predicate, object, NULL, 0, NULL );
                        if ( statement == NULL ) {
                                XSRETURN_UNDEF;
                                };
                } else {
                        statement = ((RDFStore_Statement)SvIV(SvRV(ST(1))));
                        };

                status=rdfstore_contains( mm, statement, ( ( context != NULL ) && ( context != &PL_sv_undef ) && ( SvROK( context ) ) ) ? (RDFStore_RDFNode)SvIV(SvRV(context)) : NULL );

                if ( ! sv_isa( ST(1), "RDFStore::Statement") ) {
			rdfstore_statement_free( statement );
                        };

                RETVAL = (status) ? 0 : 1;
        OUTPUT:
                RETVAL

void
RDFStore_set_context ( me, given_context )
	SV*		me
	SV*		given_context

	PREINIT:
		RDFStore mm = (RDFStore)SvIV(SvRV(me));
		int status=0;
		RDFStore_RDFNode nn=NULL;

	PPCODE:
		if ( ! ( ( SvROK(given_context) ) &&
                         ( sv_isa( given_context, "RDFStore::Resource") ) ) ) {
                        croak("set_context: Invalid statement context\n");
			XSRETURN_UNDEF;
                        };

                nn = (RDFStore_RDFNode)SvIV(SvRV(given_context));

		status=rdfstore_set_context( mm, nn );

		ST(0) = sv_2mortal( newSViv( (status) ? 0 : 1 ) );

		XSRETURN(1);

int
RDFStore_reset_context ( me )
	SV*		me

	PREINIT:
		RDFStore mm = (RDFStore)SvIV(SvRV(me));
		int status=0;

	CODE:
		status=rdfstore_reset_context( mm );

                RETVAL = (status) ? 0 : 1;
        OUTPUT:
          	RETVAL

void
RDFStore_get_context ( me )
	SV*		me

	PREINIT:
		RDFStore mm = (RDFStore)SvIV(SvRV(me));
        	RDFStore_RDFNode	context=NULL;	
		SV * node;

	PPCODE:
		context=rdfstore_get_context( mm );

                if ( context != NULL )  {

			/* bless() the context into a resource */
                        node = sv_newmortal();
                        sv_setref_pv( node, "RDFStore::Resource", (void*) rdfstore_resource_clone(context) );
                        SvREADONLY_on(SvRV(node));

			XPUSHs( node );

                	XSRETURN(1);
		} else {
			XSRETURN_UNDEF;
			};

int
RDFStore_set_source_uri ( me, uri )
	SV*		me
	SV*		uri

	PREINIT:
		RDFStore mm = (RDFStore)SvIV(SvRV(me));
		int status=0;

	CODE:
		if ( ( SvPOK(ST(1)) && SvCUR(ST(1)) ) ) {
			status=rdfstore_set_source_uri( mm, SvPV(uri, SvLEN(uri) ) );
		} else {
			status = 0;
			};

                RETVAL = (status) ? 0 : 1;
        OUTPUT:
          	RETVAL

void
RDFStore_get_source_uri ( me )
	SV*		me

	PREINIT:
		RDFStore mm = (RDFStore)SvIV(SvRV(me));
		int status=0;
		char	uri[RDFSTORE_MAX_URI_LENGTH];
		int	ll=0;

	PPCODE:
		status=rdfstore_get_source_uri( mm, uri ); /* should return the len too due to UTF-8 story... */

		if ( status )
			XSRETURN_UNDEF;
		ll = strlen(uri);

		ST(0) = sv_2mortal(newSVpv(uri,ll));

		XSRETURN(1);

int
RDFStore_is_empty ( me )
	SV*		me
	
	PREINIT:
		RDFStore mm = (RDFStore)SvIV(SvRV(me));
		int status=0;

	CODE:
		status=rdfstore_is_empty( mm );

                RETVAL = (status) ? 0 : 1;
        OUTPUT:
          	RETVAL

int
RDFStore_is_connected ( me )
	SV*		me
	
	PREINIT:
		RDFStore mm = (RDFStore)SvIV(SvRV(me));
		int status=0;

	CODE:
		status=rdfstore_isconnected( mm );

                RETVAL = (status) ? 0 : 1;
        OUTPUT:
          	RETVAL

int
RDFStore_is_remote ( me )
	SV*		me
	
	PREINIT:
		RDFStore mm = (RDFStore)SvIV(SvRV(me));
		int status=0;

	CODE:
		status=rdfstore_isremote( mm );

                RETVAL = (status) ? 0 : 1;
        OUTPUT:
          	RETVAL

void
RDFStore_elements ( me )
	SV*		me

	PREINIT:
		RDFStore mm = (RDFStore)SvIV(SvRV(me));
		RDFStore_Iterator       cc;
		SV * iterator;

	PPCODE:
                cc = rdfstore_elements( mm );

		if ( cc != NULL ) {
                	iterator = sv_newmortal();
                	sv_setref_pv( iterator, "RDFStore::Iterator", (void*)cc);
                	SvREADONLY_on(SvRV(iterator));

			XPUSHs( iterator );

			XSRETURN(1);
		} else {
			XSRETURN_UNDEF;
			};
	
void
RDFStore_search( me, rpn=NULL )
	SV*		me
	SV*		rpn

	PREINIT:
		RDFStore mm = (RDFStore)SvIV(SvRV(me));
		int i=0;
		RDF_Triple_Pattern *	tp=NULL;
		STRLEN			len;
		RDFStore_Iterator	cc;
		SV * iterator;
		SV ** hval=NULL;
		AV * list=NULL;
		SV * node=NULL;
		int search_type=0;
		
	PPCODE:
		if( ! SvROK(rpn) )
			XSRETURN_UNDEF;

		tp = rdfstore_triple_pattern_new();

		if ( tp == NULL ) {
			XSRETURN_UNDEF;
			};

		hval = hv_fetch( (HV*) SvRV(rpn), "s", 1, 0);
		if(	hval &&
			SvROK(*hval) &&
			(SvTYPE(SvRV(*hval)) == SVt_PVAV) ) {
			list = (AV*) SvRV(*hval);
			for(i=0;i<=av_len(list);i++) {
				node = *av_fetch(list, i, 0);
				if (	( node != NULL ) &&
					( node != &PL_sv_undef ) &&
					( SvTRUE(node) ) ) {
                        			if ( ! ( ( SvROK(node) ) &&
                                 			 ( sv_isa( node, "RDFStore::Resource") ) ) ) {     
                                			croak("search: Invalid subject at pos %d\n",i);
							rdfstore_triple_pattern_free(tp);
							XSRETURN_UNDEF;
						} else {
							rdfstore_triple_pattern_add_subject( tp, rdfstore_node_clone( (RDFStore_RDFNode)SvIV(SvRV(node)) ) );
                                			};
                        			};
				};
			};
		hval = hv_fetch( (HV*) SvRV(rpn), "p", 1, 0);
		if(	hval &&
			SvROK(*hval) &&
			(SvTYPE(SvRV(*hval)) == SVt_PVAV) ) {
			list = (AV*) SvRV(*hval);
			for(i=0;i<=av_len(list);i++) {
				node = *av_fetch(list, i, 0);
				if (	( node != NULL ) &&
					( node != &PL_sv_undef ) &&
					( SvTRUE(node) ) ) {
                        			if ( ! ( ( SvROK(node) ) &&
                                 			 ( sv_isa( node, "RDFStore::Resource") ) ) ) {     
                                			croak("search: Invalid predicate at pos %d\n",i);
							rdfstore_triple_pattern_free(tp);
							XSRETURN_UNDEF;
						} else {
							rdfstore_triple_pattern_add_predicate( tp, rdfstore_node_clone( (RDFStore_RDFNode)SvIV(SvRV(node)) ) );
                                			};
                        			};
				};
			};
		hval = hv_fetch( (HV*) SvRV(rpn), "o", 1, 0);
		if(	hval &&
			SvROK(*hval) &&
			(SvTYPE(SvRV(*hval)) == SVt_PVAV) ) {
			list = (AV*) SvRV(*hval);
			for(i=0;i<=av_len(list);i++) {
				node = *av_fetch(list, i, 0);
				if (	( node != NULL ) &&
					( node != &PL_sv_undef ) &&
					( SvTRUE(node) ) ) {
                        			if ( ! ( ( SvROK(node) ) &&
                                 			 ( ( sv_isa( node, "RDFStore::Literal") ) ||
							   ( sv_isa( node, "RDFStore::Resource") ) ) ) ) {     
                                			croak("search: Invalid object at pos %d\n",i);
							rdfstore_triple_pattern_free(tp);
							XSRETURN_UNDEF;
						} else {
							rdfstore_triple_pattern_add_object( tp, rdfstore_node_clone( (RDFStore_RDFNode)SvIV(SvRV(node)) ) );
                                			};
                        			};
				};
			};
		hval = hv_fetch( (HV*) SvRV(rpn), "c", 1, 0);
		if(	hval &&
			SvROK(*hval) &&
			(SvTYPE(SvRV(*hval)) == SVt_PVAV) ) {
			list = (AV*) SvRV(*hval);
			for(i=0;i<=av_len(list);i++) {
				node = *av_fetch(list, i, 0);
				if (	( node != NULL ) &&
					( node != &PL_sv_undef ) &&
					( SvTRUE(node) ) ) {
                        			if ( ! ( ( SvROK(node) ) &&
                                 			 ( sv_isa( node, "RDFStore::Resource") ) ) ) {     
                                			croak("search: Invalid context at pos %d\n",i);
							rdfstore_triple_pattern_free(tp);
							XSRETURN_UNDEF;
						} else {
							rdfstore_triple_pattern_add_context( tp, rdfstore_node_clone( (RDFStore_RDFNode)SvIV(SvRV(node)) ) );
                                			};
                        			};
				};
			};

		hval = hv_fetch( (HV*) SvRV(rpn), "xml:lang", 8, 0);
		if(	hval &&
			SvROK(*hval) &&
			(SvTYPE(SvRV(*hval)) == SVt_PVAV) ) {
			list = (AV*) SvRV(*hval);
			for(i=0;i<=av_len(list);i++) {
				node = *av_fetch(list, i, 0);
				if (	( node != NULL ) &&
					( node != &PL_sv_undef ) &&
					SvTRUE(node) &&
					SvPOK(node) &&
					SvCUR(node) ) {
					rdfstore_triple_pattern_add_lang( tp, (unsigned char *)(SvPV(node,len)) );
                        		};
				};
			};
		hval = hv_fetch( (HV*) SvRV(rpn), "rdf:datatype", 12, 0);
		if(	hval &&
			SvROK(*hval) &&
			(SvTYPE(SvRV(*hval)) == SVt_PVAV) ) {
			list = (AV*) SvRV(*hval);
			for(i=0;i<=av_len(list);i++) {
				node = *av_fetch(list, i, 0);
				if (	( node != NULL ) &&
					( node != &PL_sv_undef ) &&
					SvTRUE(node) &&
					SvPOK(node) &&
					SvCUR(node) ) {
					unsigned char * ddtt = (unsigned char *)(SvPV(node,len));
					rdfstore_triple_pattern_add_datatype( tp, ddtt, len );
                        		};
				};
			};
		hval = hv_fetch( (HV*) SvRV(rpn), "words", 5, 0);
		if(	hval &&
			SvROK(*hval) &&
			(SvTYPE(SvRV(*hval)) == SVt_PVAV) ) {
			list = (AV*) SvRV(*hval);
			for(i=0;i<=av_len(list);i++) {
				node = *av_fetch(list, i, 0);
				if (	( node != NULL ) &&
					( node != &PL_sv_undef ) &&
					SvTRUE(node) &&
					SvPOK(node) &&
					SvCUR(node) ) {
					unsigned char * word = (unsigned char *)(SvPV(node,len));
					rdfstore_triple_pattern_add_word( tp, word, len );
                        		};
				};
			};
		hval = hv_fetch( (HV*) SvRV(rpn), "ranges", 6, 0);
		if(	hval &&
			SvROK(*hval) &&
			(SvTYPE(SvRV(*hval)) == SVt_PVAV) ) {
			list = (AV*) SvRV(*hval);
			for(i=0;i<=av_len(list);i++) {
				node = *av_fetch(list, i, 0);
				if (	( node != NULL ) &&
					( node != &PL_sv_undef ) &&
					SvTRUE(node) &&
					SvPOK(node) &&
					SvCUR(node) ) {
					unsigned char * term = (unsigned char *)(SvPV(node,len));
					rdfstore_triple_pattern_add_ranges( tp, term, len );
                        		};
				};
			};

		hval = hv_fetch( (HV*) SvRV(rpn), "s_op", 4, 0);
		if(	hval &&
			SvPOK(*hval) ) {
			unsigned char * op = (unsigned char *)(SvPV(*hval,len));
			rdfstore_triple_pattern_set_subjects_operator( tp, (	(strcmp(op,"and")==0) ||
										(strcmp(op,"AND")==0) ||
										(strcmp(op,"&")==0) ) ? 1 : 0 );
			};
		hval = hv_fetch( (HV*) SvRV(rpn), "p_op", 4, 0);
		if(	hval &&
			SvPOK(*hval) ) {
			unsigned char * op = (unsigned char *)(SvPV(*hval,len));
			rdfstore_triple_pattern_set_predicates_operator( tp, (	(strcmp(op,"and")==0) ||
										(strcmp(op,"AND")==0) ||
										(strcmp(op,"&")==0) ) ? 1 : 0 );
			};
		hval = hv_fetch( (HV*) SvRV(rpn), "o_op", 4, 0);
		if(	hval &&
			SvPOK(*hval) ) {
			unsigned char * op = (unsigned char *)(SvPV(*hval,len));
			rdfstore_triple_pattern_set_objects_operator( tp, (	(strcmp(op,"and")==0) ||
										(strcmp(op,"AND")==0) ||
										(strcmp(op,"&")==0) ) ? 1 : 0 );
			};
		hval = hv_fetch( (HV*) SvRV(rpn), "c_op", 4, 0);
		if(	hval &&
			SvPOK(*hval) ) {
			unsigned char * op = (unsigned char *)(SvPV(*hval,len));
			rdfstore_triple_pattern_set_contexts_operator( tp, (	(strcmp(op,"and")==0) ||
										(strcmp(op,"AND")==0) ||
										(strcmp(op,"&")==0) ) ? 1 : 0 );
			};
		hval = hv_fetch( (HV*) SvRV(rpn), "xml:lang_op", 11, 0);
		if(	hval &&
			SvPOK(*hval) ) {
			unsigned char * op = (unsigned char *)(SvPV(*hval,len));
			rdfstore_triple_pattern_set_langs_operator( tp, (	(strcmp(op,"and")==0) ||
										(strcmp(op,"AND")==0) ||
										(strcmp(op,"&")==0) ) ? 1 : 0 );
			};
		hval = hv_fetch( (HV*) SvRV(rpn), "rdf:datatype_op", 15, 0);
		if(	hval &&
			SvPOK(*hval) ) {
			unsigned char * op = (unsigned char *)(SvPV(*hval,len));
			rdfstore_triple_pattern_set_datatypes_operator( tp, (	(strcmp(op,"and")==0) ||
										(strcmp(op,"AND")==0) ||
										(strcmp(op,"&")==0) ) ? 1 : 0 );
			};
		hval = hv_fetch( (HV*) SvRV(rpn), "words_op", 8, 0);
		if(	hval &&
			SvPOK(*hval) ) {
			unsigned char * op = (unsigned char *)(SvPV(*hval,len));
			rdfstore_triple_pattern_set_words_operator( tp, (	(strcmp(op,"and")==0) ||
										(strcmp(op,"AND")==0) ||
										(strcmp(op,"&")==0) ) ? 1 : 0 );
			};
		hval = hv_fetch( (HV*) SvRV(rpn), "ranges_op", 9, 0);
		if(	hval &&
			SvPOK(*hval) ) {
			unsigned char * op = (unsigned char *)(SvPV(*hval,len));
			rdfstore_triple_pattern_set_ranges_operator( tp, (
						( (strcmp(op,"a < b")==0) || (strcmp(op,"a lt b")==0) ) ? 1 :
						( (strcmp(op,"a <= b")==0) || (strcmp(op,"a le b")==0) ) ? 2 :
						( (strcmp(op,"a == b")==0) || (strcmp(op,"a eq b")==0) ) ? 3 :
						( (strcmp(op,"a != b")==0) || (strcmp(op,"a ne b")==0) ) ? 4 :
						( (strcmp(op,"a >= b")==0) || (strcmp(op,"a ge b")==0) ) ? 5 : 
						( (strcmp(op,"a > b")==0) || (strcmp(op,"a gt b")==0) ) ? 6 :
						( (strcmp(op,"a < b < c")==0) || (strcmp(op,"a lt b lt c")==0) ) ? 7 :
						( (strcmp(op,"a <= b < c")==0) || (strcmp(op,"a le b lt c")==0) ) ? 8 :
						( (strcmp(op,"a <= b <= c")==0) || (strcmp(op,"a le b le c")==0) ) ? 9 :
						( (strcmp(op,"a < b <= c")==0) || (strcmp(op,"a lt b le c")==0) ) ? 10 : 0 ));
			};

		/* special not used yet... */
		hval = hv_fetch( (HV*) SvRV(rpn), "search_type", 11, 0);
		if(	hval &&
			SvIOK(*hval) ) {
			search_type = ( SvIV(*hval) ) ? 1 : 0;
			};

		cc = rdfstore_search( mm, tp, search_type );

		rdfstore_triple_pattern_free(tp);

		if ( cc == NULL ) {
			XSRETURN_UNDEF;
			};

		if ( cc != NULL ) {
                	iterator = sv_newmortal();
                	sv_setref_pv( iterator, "RDFStore::Iterator", (void*)cc);
                	SvREADONLY_on(SvRV(iterator));

			XPUSHs( iterator );

			XSRETURN(1);
		} else {
			XSRETURN_UNDEF;
			};

void
RDFStore_fetch_object ( me, resource, given_context=NULL )
	SV*		me
	SV*		resource	
	SV*		given_context	

	PREINIT :
		RDFStore mm = (RDFStore)SvIV(SvRV(me));
		RDFStore_RDFNode res=NULL;
		RDFStore_RDFNode ctx=NULL;
		RDFStore_Iterator cc;
		SV * iterator;

	PPCODE:
		if ( ! ( ( SvROK(resource) ) &&
                         ( sv_isa( resource, "RDFStore::Resource") ) ) ) {
                        croak("fetch_object: Invalid resource\n");
			XSRETURN_UNDEF;
                        };

		if (    ( given_context != NULL ) &&
                        ( given_context != &PL_sv_undef ) &&
                        ( SvTRUE(given_context) ) ) {
                        if ( ! ( ( SvROK(given_context) ) &&
                                 ( sv_isa( given_context, "RDFStore::Resource") ) ) ) {
				croak("fetch_object: Invalid context\n");
				XSRETURN_UNDEF;
                                };

                	ctx = (RDFStore_RDFNode)SvIV(SvRV(given_context));
                        };

                res = (RDFStore_RDFNode)SvIV(SvRV(resource));

		cc = rdfstore_fetch_object( mm, res, ctx );

		if ( cc == NULL ) {
			XSRETURN_UNDEF;
			};

		if ( cc != NULL ) {
                	iterator = sv_newmortal();
                	sv_setref_pv( iterator, "RDFStore::Iterator", (void*)cc);
                	SvREADONLY_on(SvRV(iterator));

			XPUSHs( iterator );

			XSRETURN(1);
		} else {
			XSRETURN_UNDEF;
			};

MODULE = RDFStore	PACKAGE = RDFStore::Iterator	PREFIX = RDFStore_Iterator_

PROTOTYPES: DISABLE

void
RDFStore_Iterator_new ( package, store )
	SV*		package
        RDFStore 	store

	PREINIT:
		RDFStore_Iterator context;
		SV * iterator;
		store = NULL;

	PPCODE:
		if (!SvROK(package)) {
			/* bless() the store cursor */
            		STRLEN my_na;
            		char *sclass = SvPV(package, my_na);
			context = rdfstore_elements( store );

            		iterator = sv_newmortal();
            		sv_setref_pv( iterator, sclass, (void*)context);
            		SvREADONLY_on(SvRV(iterator));

			XPUSHs( iterator );
        	} else {
			/* just get through */
            		context = (RDFStore_Iterator)SvIV(SvRV(package));
        		};
        
        	XSRETURN(1);

unsigned int
RDFStore_Iterator_size ( me )
	SV*             me

        PREINIT:
                RDFStore_Iterator context = (RDFStore_Iterator)SvIV(SvRV(me));
        CODE:

                RETVAL = rdfstore_iterator_size ( context );

        OUTPUT:
                RETVAL

int
RDFStore_Iterator_hasnext ( me )
	SV*		me

	PREINIT:
		RDFStore_Iterator context = (RDFStore_Iterator)SvIV(SvRV(me));

	CODE:

		RETVAL = rdfstore_iterator_hasnext ( context );

	OUTPUT:
		RETVAL

void
RDFStore_Iterator_next ( me )
	SV*		me

	PREINIT:
        	RDFStore_Statement ss;	
		RDFStore_Iterator context = (RDFStore_Iterator)SvIV(SvRV(me));
		SV * statement;

	PPCODE:
		ss = rdfstore_iterator_next ( context );

                if ( ss != NULL )  {
			/* bless() the statement */
                        statement = sv_newmortal();
                        sv_setref_pv( statement, "RDFStore::Statement", (void*)ss);
                        SvREADONLY_on(SvRV(statement));

			XPUSHs( statement );

			XSRETURN(1);
		} else {
			XSRETURN_UNDEF;
			};

void
RDFStore_Iterator_next_subject ( me )
	SV*		me

	PREINIT:
        	RDFStore_RDFNode resource;	
		RDFStore_Iterator context = (RDFStore_Iterator)SvIV(SvRV(me));
		SV * node;

	PPCODE:
		resource = rdfstore_iterator_next_subject ( context );

                if ( resource != NULL )  {
			/* bless() the node */
                        node = sv_newmortal();
                        sv_setref_pv( node, "RDFStore::Resource", (void*)resource);
                        SvREADONLY_on(SvRV(node));

			XPUSHs( node );

			XSRETURN(1);
		} else {
			XSRETURN_UNDEF;
			};

void
RDFStore_Iterator_next_predicate ( me )
	SV*		me

	PREINIT:
        	RDFStore_RDFNode resource;	
		RDFStore_Iterator context = (RDFStore_Iterator)SvIV(SvRV(me));
		SV * node;

	PPCODE:
		resource = rdfstore_iterator_next_predicate ( context );

		if ( resource != NULL )  {
                        node = sv_newmortal();
                        sv_setref_pv( node, "RDFStore::Resource", (void*)resource); 
                        SvREADONLY_on(SvRV(node));

			XPUSHs( node );

			XSRETURN(1);
                } else {
			XSRETURN_UNDEF;
                        };

void
RDFStore_Iterator_next_object ( me )
	SV*		me

	PREINIT:
        	RDFStore_RDFNode object;	
		RDFStore_Iterator context = (RDFStore_Iterator)SvIV(SvRV(me));
		SV * node;

	PPCODE:
		object = rdfstore_iterator_next_object ( context );

		if ( object != NULL )  {
                        node = sv_newmortal();
                        sv_setref_pv( node, ( rdfstore_node_get_type( object ) != RDFSTORE_NODE_TYPE_LITERAL ) ? "RDFStore::Resource" : "RDFStore::Literal", (void*)object); 
                        SvREADONLY_on(SvRV(node));

			XPUSHs( node );

                        XSRETURN(1);    
                } else {
			XSRETURN_UNDEF;
                        };

void
RDFStore_Iterator_next_context ( me )
	SV*		me

	PREINIT:
        	RDFStore_RDFNode resource;	
		RDFStore_Iterator context = (RDFStore_Iterator)SvIV(SvRV(me));
		SV * node;

	PPCODE:
		resource = rdfstore_iterator_next_context ( context );

		if ( resource != NULL )  {
                        node = sv_newmortal();
                        sv_setref_pv( node, "RDFStore::Resource", (void*)resource); 
                        SvREADONLY_on(SvRV(node));

			XPUSHs( node );

			XSRETURN(1);
                } else {
			XSRETURN_UNDEF;
                        };

void
RDFStore_Iterator_current ( me )
	SV*		me

	PREINIT:
        	RDFStore_Statement ss;	
		RDFStore_Iterator context = (RDFStore_Iterator)SvIV(SvRV(me));
		SV * statement;

	PPCODE:
		ss = rdfstore_iterator_current ( context );

		if ( ss != NULL )  {
			/* bless() the statement */
                        statement = sv_newmortal();
                        sv_setref_pv( statement, "RDFStore::Statement", (void*)ss);
                        SvREADONLY_on(SvRV(statement));

			XPUSHs( statement );

			XSRETURN(1);
                } else {
			XSRETURN_UNDEF;
                        };

void
RDFStore_Iterator_current_subject ( me )
	SV*		me

	PREINIT:
        	RDFStore_RDFNode resource;	
		RDFStore_Iterator context = (RDFStore_Iterator)SvIV(SvRV(me));
		SV * node;

	PPCODE:
		resource = rdfstore_iterator_current_subject ( context );

		if ( resource != NULL )  {
                        node = sv_newmortal();
                        sv_setref_pv( node, "RDFStore::Resource", (void*)resource); 
                        SvREADONLY_on(SvRV(node));

			XPUSHs( node );

			XSRETURN(1);
                } else {
			XSRETURN_UNDEF;
                        };

void
RDFStore_Iterator_current_predicate ( me )
	SV*		me

	PREINIT:
        	RDFStore_RDFNode resource;	
		RDFStore_Iterator context = (RDFStore_Iterator)SvIV(SvRV(me));
		SV * node;

	PPCODE:
		resource = rdfstore_iterator_current_predicate ( context );

		if ( resource != NULL )  {
                        node = sv_newmortal();
                        sv_setref_pv( node, "RDFStore::Resource", (void*)resource); 
                        SvREADONLY_on(SvRV(node));

			XPUSHs( node );

			XSRETURN(1);
                } else {
			XSRETURN_UNDEF;
                        };

void
RDFStore_Iterator_current_object ( me )
	SV*		me

	PREINIT:
        	RDFStore_RDFNode object;	
		RDFStore_Iterator context = (RDFStore_Iterator)SvIV(SvRV(me));
		SV * node;

	PPCODE:
		object = rdfstore_iterator_current_object ( context );

                if ( object != NULL )  {
                        node = sv_newmortal();
                        sv_setref_pv( node, ( rdfstore_node_get_type( object ) != RDFSTORE_NODE_TYPE_LITERAL ) ? "RDFStore::Resource" : "RDFStore::Literal", (void*)object); 
                        SvREADONLY_on(SvRV(node));

			XPUSHs( node );

			XSRETURN(1);
                } else {
			XSRETURN_UNDEF;
                        };

void
RDFStore_Iterator_current_context ( me )
	SV*		me

	PREINIT:
        	RDFStore_RDFNode resource;	
		RDFStore_Iterator context = (RDFStore_Iterator)SvIV(SvRV(me));
		SV * node;

	PPCODE:
		resource = rdfstore_iterator_current_context ( context );

		if ( resource != NULL )  {
                        node = sv_newmortal();
                        sv_setref_pv( node, "RDFStore::Resource", (void*)resource); 
                        SvREADONLY_on(SvRV(node));

			XPUSHs( node );

			XSRETURN(1);
                } else {
			XSRETURN_UNDEF;
                        };

void
RDFStore_Iterator_first ( me )
	SV*		me

	PREINIT:
        	RDFStore_Statement ss;	
		RDFStore_Iterator context = (RDFStore_Iterator)SvIV(SvRV(me));
		SV * statement;

	PPCODE:
		ss = rdfstore_iterator_first ( context );

		if ( ss != NULL )  {
			/* bless() the statement */
                        statement = sv_newmortal();
                        sv_setref_pv( statement, "RDFStore::Statement", (void*)ss);
                        SvREADONLY_on(SvRV(statement));

			XPUSHs( statement );

			XSRETURN(1);
                } else {
			XSRETURN_UNDEF;
                        };

void
RDFStore_Iterator_first_subject ( me )
	SV*		me

	PREINIT:
        	RDFStore_RDFNode resource;	
		RDFStore_Iterator context = (RDFStore_Iterator)SvIV(SvRV(me));
		SV * node;

	PPCODE:
		resource = rdfstore_iterator_first_subject ( context );

		if ( resource != NULL )  {
                        node = sv_newmortal();
                        sv_setref_pv( node, "RDFStore::Resource", (void*)resource); 
                        SvREADONLY_on(SvRV(node));

			XPUSHs( node );

			XSRETURN(1);
                } else {
			XSRETURN_UNDEF;
                        };

void
RDFStore_Iterator_first_predicate ( me )
	SV*		me

	PREINIT:
        	RDFStore_RDFNode resource;	
		RDFStore_Iterator context = (RDFStore_Iterator)SvIV(SvRV(me));
		SV * node;

	PPCODE:
		resource = rdfstore_iterator_first_predicate ( context );

		if ( resource != NULL )  {
                        node = sv_newmortal();
                        sv_setref_pv( node, "RDFStore::Resource", (void*)resource); 
                        SvREADONLY_on(SvRV(node));

			XPUSHs( node );

			XSRETURN(1);
                } else {
			XSRETURN_UNDEF;
                        };

void
RDFStore_Iterator_first_object ( me )
	SV*		me

	PREINIT:
        	RDFStore_RDFNode object;	
		RDFStore_Iterator context = (RDFStore_Iterator)SvIV(SvRV(me));
		SV * node;

	PPCODE:
		object = rdfstore_iterator_first_object ( context );

                if ( object != NULL )  {
                        node = sv_newmortal();
                        sv_setref_pv( node, ( rdfstore_node_get_type( object ) != RDFSTORE_NODE_TYPE_LITERAL ) ? "RDFStore::Resource" : "RDFStore::Literal", (void*)object); 
                        SvREADONLY_on(SvRV(node));

			XPUSHs( node );

			XSRETURN(1);
                } else {
			XSRETURN_UNDEF;
                        };

void
RDFStore_Iterator_first_context ( me )
	SV*		me

	PREINIT:
        	RDFStore_RDFNode resource;	
		RDFStore_Iterator context = (RDFStore_Iterator)SvIV(SvRV(me));
		SV * node;

	PPCODE:
		resource = rdfstore_iterator_first_context ( context );

		if ( resource != NULL )  {
                        node = sv_newmortal();
                        sv_setref_pv( node, "RDFStore::Resource", (void*)resource); 
                        SvREADONLY_on(SvRV(node));

			XPUSHs( node );

			XSRETURN(1);
                } else {
			XSRETURN_UNDEF;
                        };

void
RDFStore_Iterator_each ( me )
	SV*		me

	PREINIT:
        	RDFStore_Statement ss;	
		RDFStore_Iterator context = (RDFStore_Iterator)SvIV(SvRV(me));
		SV * statement;

	PPCODE:
		ss = rdfstore_iterator_each ( context );

		if ( ss != NULL )  {
			/* bless() the statement */
                        statement = sv_newmortal();
                        sv_setref_pv( statement, "RDFStore::Statement", (void*)ss);
                        SvREADONLY_on(SvRV(statement));

			XPUSHs( statement );

			XSRETURN(1);
                } else {
			XSRETURN_UNDEF;
                        };

void
RDFStore_Iterator_each_subject ( me )
	SV*		me

	PREINIT:
        	RDFStore_RDFNode resource;	
		RDFStore_Iterator context = (RDFStore_Iterator)SvIV(SvRV(me));
		SV * node;

	PPCODE:
		resource = rdfstore_iterator_each_subject ( context );

		if ( resource != NULL )  {
                        node = sv_newmortal();
                        sv_setref_pv( node, "RDFStore::Resource", (void*)resource); 
                        SvREADONLY_on(SvRV(node));

			XPUSHs( node );

			XSRETURN(1);
                } else {
			XSRETURN_UNDEF;
                        };

void
RDFStore_Iterator_each_predicate ( me )
	SV*		me

	PREINIT:
        	RDFStore_RDFNode resource;	
		RDFStore_Iterator context = (RDFStore_Iterator)SvIV(SvRV(me));
		SV * node;

	PPCODE:
		resource = rdfstore_iterator_each_predicate ( context );

		if ( resource != NULL )  {
                        node = sv_newmortal();
                        sv_setref_pv( node, "RDFStore::Resource", (void*)resource); 
                        SvREADONLY_on(SvRV(node));

			XPUSHs( node );

			XSRETURN(1);
                } else {
			XSRETURN_UNDEF;
                        };

void
RDFStore_Iterator_each_object ( me )
	SV*		me

	PREINIT:
        	RDFStore_RDFNode object;	
		RDFStore_Iterator context = (RDFStore_Iterator)SvIV(SvRV(me));
		SV * node;

	PPCODE:
		object = rdfstore_iterator_each_object ( context );

                if ( object != NULL )  {
                        node = sv_newmortal();
                        sv_setref_pv( node, ( rdfstore_node_get_type( object ) != RDFSTORE_NODE_TYPE_LITERAL ) ? "RDFStore::Resource" : "RDFStore::Literal", (void*)object); 
                        SvREADONLY_on(SvRV(node));

			XPUSHs( node );

			XSRETURN(1);
                } else {
			XSRETURN_UNDEF;
                        };

void
RDFStore_Iterator_each_context ( me )
	SV*		me

	PREINIT:
        	RDFStore_RDFNode resource;	
		RDFStore_Iterator context = (RDFStore_Iterator)SvIV(SvRV(me));
		SV * node;

	PPCODE:
		resource = rdfstore_iterator_each_context ( context );

		if ( resource != NULL )  {
                        node = sv_newmortal();
                        sv_setref_pv( node, "RDFStore::Resource", (void*)resource); 
                        SvREADONLY_on(SvRV(node));

			XPUSHs( node );

			XSRETURN(1);
                } else {
			XSRETURN_UNDEF;
                        };

int
RDFStore_Iterator_remove ( me )
        SV*             me

        PREINIT:
                RDFStore_Iterator context = (RDFStore_Iterator)SvIV(SvRV(me));

        CODE:

                RETVAL = rdfstore_iterator_remove ( context );

        OUTPUT:
                RETVAL

int
RDFStore_Iterator_contains ( me, subject, predicate=NULL, object=NULL, cc=NULL )
        SV*             me
        SV*             subject
        SV*             predicate
        SV*             object
        SV*             cc

        PREINIT:
                RDFStore_Iterator context = (RDFStore_Iterator)SvIV(SvRV(me));
                RDF_Statement *	statement;

        CODE:
		if ( !  ( ( subject != NULL ) &&  
                          ( subject != &PL_sv_undef ) &&  
                          ( SvTRUE(subject) ) &&  
                          ( SvROK(subject) ) &&
                          (     ( sv_isa( subject, "RDFStore::Resource") ) ||
                                ( sv_isa( subject, "RDFStore::Statement") ) ) ) ) {
                        croak("iterator_contains: Invalid subject or statement\n");
                        XSRETURN_UNDEF;
                        };
		if (    ( predicate != NULL ) &&
                        ( predicate != &PL_sv_undef ) &&
			( SvTRUE(predicate) ) ) {
                        if ( ! ( ( SvROK(predicate) ) &&
                                 ( sv_isa( predicate, "RDFStore::Resource") ) ) ) {
                                croak("search: Invalid predicate\n");
				XSRETURN_UNDEF;
                                };
                        };
                if (    ( object != NULL ) &&
                        ( object != &PL_sv_undef ) &&
			( SvTRUE(object) ) ) {
                        if ( ! ( ( SvROK(object) ) &&
                                 (      ( sv_isa( object, "RDFStore::Literal") ) ||
                                        ( sv_isa( object, "RDFStore::Resource") ) ) ) ) {
                                croak("search: Invalid object\n");
				XSRETURN_UNDEF;
                                };
                        };
                if (    ( cc != NULL ) &&
                        ( cc != &PL_sv_undef ) &&
			( SvTRUE(cc) ) ) {
                        if ( ! ( ( SvROK(cc) ) &&
                                 ( sv_isa( cc, "RDFStore::Resource") ) ) ) {
                                croak("search: Invalid statement context\n");
				XSRETURN_UNDEF;
                                };
                        };

                /* create a temporary statement */
		if ( ! sv_isa( ST(1), "RDFStore::Statement") ) {
			statement = new_Statement_Object( subject, predicate, object, NULL, 0, NULL );
                        if ( statement == NULL ) {
                                XSRETURN_UNDEF;
                                };
                } else {
                        statement = ((RDFStore_Statement)SvIV(SvRV(ST(1))));
                        };

		RETVAL=rdfstore_iterator_contains( context, statement, ( ( cc != NULL ) && ( cc != &PL_sv_undef ) && ( SvROK( cc ) ) ) ? (RDFStore_RDFNode)SvIV(SvRV(cc)) : NULL );

                if ( ! sv_isa( ST(1), "RDFStore::Statement") ) {
			rdfstore_statement_free( statement );
                        };
        OUTPUT:
                RETVAL

void
RDFStore_Iterator_duplicate ( me )
	SV*             me

        PREINIT:
                RDFStore_Iterator context = (RDFStore_Iterator)SvIV(SvRV(me));
                RDFStore_Iterator duplicate;
		SV * iterator;

	PPCODE:
                duplicate = rdfstore_iterator_duplicate ( context );

		if ( duplicate != NULL ) {
                	iterator = sv_newmortal();
                	sv_setref_pv( iterator, "RDFStore::Iterator", (void*)duplicate);
                	SvREADONLY_on(SvRV(iterator));

			XPUSHs( iterator );

			XSRETURN(1);
		} else {
			XSRETURN_UNDEF;
			};

void
RDFStore_Iterator_intersect ( me, you )
	SV*             me
	SV*             you

        PREINIT:
                RDFStore_Iterator context = (RDFStore_Iterator)SvIV(SvRV(me));
                RDFStore_Iterator context1 = (RDFStore_Iterator)SvIV(SvRV(you));
                RDFStore_Iterator cc;
		SV * iterator;

	PPCODE:
                cc = rdfstore_iterator_intersect ( context, context1 );
		if ( cc != NULL ) {
                	iterator = sv_newmortal();
                	sv_setref_pv( iterator, "RDFStore::Iterator", (void*)cc);
                	SvREADONLY_on(SvRV(iterator));

			XPUSHs( iterator );

			XSRETURN(1);
		} else {
			XSRETURN_UNDEF;
			};

void
RDFStore_Iterator_unite ( me, you )
	SV*             me
	SV*             you

        PREINIT:
                RDFStore_Iterator context = (RDFStore_Iterator)SvIV(SvRV(me));
                RDFStore_Iterator context1 = (RDFStore_Iterator)SvIV(SvRV(you));
                RDFStore_Iterator cc;
		SV * iterator;

	PPCODE:
                cc = rdfstore_iterator_unite ( context, context1 );
		if ( cc != NULL ) {
                	iterator = sv_newmortal();
                	sv_setref_pv( iterator, "RDFStore::Iterator", (void*)cc);
                	SvREADONLY_on(SvRV(iterator));

			XPUSHs( iterator );

			XSRETURN(1);
		} else {
			XSRETURN_UNDEF;
			};

void
RDFStore_Iterator_subtract ( me, you )
	SV*             me
	SV*             you

        PREINIT:
                RDFStore_Iterator context = (RDFStore_Iterator)SvIV(SvRV(me));
                RDFStore_Iterator context1 = (RDFStore_Iterator)SvIV(SvRV(you));
                RDFStore_Iterator cc;
		SV * iterator;

	PPCODE:
                cc = rdfstore_iterator_subtract ( context, context1 );
		if ( cc != NULL ) {
                	iterator = sv_newmortal();
                	sv_setref_pv( iterator, "RDFStore::Iterator", (void*)cc);
                	SvREADONLY_on(SvRV(iterator));

			XPUSHs( iterator );

			XSRETURN(1);
		} else {
			XSRETURN_UNDEF;
			};

void
RDFStore_Iterator_complement ( me )
	SV*             me

        PREINIT:
                RDFStore_Iterator context = (RDFStore_Iterator)SvIV(SvRV(me));
                RDFStore_Iterator cc;
		SV * iterator;

	PPCODE:
                cc = rdfstore_iterator_complement ( context );
		if ( cc != NULL ) {
                	iterator = sv_newmortal();
                	sv_setref_pv( iterator, "RDFStore::Iterator", (void*)cc);
                	SvREADONLY_on(SvRV(iterator));

			XPUSHs( iterator );

			XSRETURN(1);
		} else {
			XSRETURN_UNDEF;
			};

void
RDFStore_Iterator_exor ( me, you )
	SV*             me
	SV*             you

        PREINIT:
                RDFStore_Iterator context = (RDFStore_Iterator)SvIV(SvRV(me));
                RDFStore_Iterator context1 = (RDFStore_Iterator)SvIV(SvRV(you));
                RDFStore_Iterator cc;
		SV * iterator;

	CODE:
                cc = rdfstore_iterator_exor ( context, context1 );
		if ( cc != NULL ) {
                	iterator = sv_newmortal();
                	sv_setref_pv( iterator, "RDFStore::Iterator", (void*)cc);
                	SvREADONLY_on(SvRV(iterator));

			XPUSHs( iterator );

			XSRETURN(1);
		} else {
			XSRETURN_UNDEF;
			};

void
RDFStore_Iterator_DESTROY(me)
	SV*		me

	PREINIT:
		RDFStore_Iterator context = (RDFStore_Iterator)SvIV(SvRV(me));

        CODE:
		rdfstore_iterator_close( context );

MODULE = RDFStore       PACKAGE = RDFStore::Util::UTF8  PREFIX = RDFStore_Util_UTF8_

PROTOTYPES: DISABLE

void
RDFStore_Util_UTF8_cp_to_utf8 ( cp )
        unsigned long cp

        PREINIT:
		unsigned int utf8_size=0;
		unsigned char utf8_buff[RDFSTORE_UTF8_MAXLEN+1]; /* one utf8 char */
                bzero(utf8_buff,RDFSTORE_UTF8_MAXLEN);	

        PPCODE:
		if ( rdfstore_utf8_cp_to_utf8( cp, &utf8_size, utf8_buff ) ) {
			XSRETURN_UNDEF;
			};
		
		memcpy(utf8_buff+utf8_size,"\0",1);

        	ST(0) = sv_2mortal( newSVpv( utf8_buff, utf8_size ) );

		XSRETURN(1);

void
RDFStore_Util_UTF8_utf8_to_cp ( utf8_buff )
        unsigned char * utf8_buff

        PREINIT:
		unsigned long cp=0;
		unsigned int utf8_size=0;

        PPCODE:

        	if ( utf8_buff == NULL )
			XSRETURN_UNDEF;

		if ( ( rdfstore_utf8_is_utf8( utf8_buff, &utf8_size ) ) && ( utf8_size > 1 ) ) {
			if ( rdfstore_utf8_utf8_to_cp( utf8_size, utf8_buff, &cp ) ) {
				XSRETURN_UNDEF;
				};
                } else {
			XSRETURN_UNDEF;
                        };

        	ST(0) = sv_2mortal( newSViv( cp ) );

		XSRETURN(1);

int
RDFStore_Util_UTF8_is_utf8 ( utf8_buff )
        unsigned char * utf8_buff

        PREINIT:
		unsigned int utf8_size=0;

        CODE:
        	if ( utf8_buff == NULL )
			XSRETURN_UNDEF;
		if ( rdfstore_utf8_is_utf8( utf8_buff, &utf8_size ) ) {
			RETVAL = utf8_size;
		} else {
			RETVAL = 0;
			};

	OUTPUT:
		RETVAL

void
RDFStore_Util_UTF8_to_utf8 ( string )
        unsigned char * string

        PREINIT:
		unsigned int utf8_size=0;
		unsigned char utf8_buff[RDFSTORE_UTF8_MAXLEN+1]; /* one utf8 char */
                bzero(utf8_buff,RDFSTORE_UTF8_MAXLEN);	

        PPCODE:

        	if ( string == NULL )
			XSRETURN_UNDEF;

		if ( rdfstore_utf8_string_to_utf8( strlen(string), string, &utf8_size, utf8_buff ) ) {
			XSRETURN_UNDEF;
                        };

		memcpy(utf8_buff+utf8_size,"\0",1);

        	ST(0) = sv_2mortal( newSVpv( utf8_buff, utf8_size ) );

		XSRETURN(1);

void
RDFStore_Util_UTF8_to_utf8_foldedcase ( string )
        unsigned char * string

        PREINIT:
		unsigned int utf8_size=0;
		unsigned char utf8_casefolded_buff[RDFSTORE_UTF8_MAXLEN_FOLD+1]; /* one case-folded utf8 char */
                bzero(utf8_casefolded_buff,RDFSTORE_UTF8_MAXLEN_FOLD);	

        PPCODE:

        	if ( string == NULL )
			XSRETURN_UNDEF;

		if ( rdfstore_utf8_string_to_utf8_foldedcase( strlen(string), string, &utf8_size, utf8_casefolded_buff ) ) {
			XSRETURN_UNDEF;
                        };

		memcpy(utf8_casefolded_buff+utf8_size,"\0",1);

        	ST(0) = sv_2mortal( newSVpv( utf8_casefolded_buff, utf8_size ) );

		XSRETURN(1);

MODULE = RDFStore       PACKAGE = RDFStore::Util::Digest  PREFIX = RDFStore_Util_Digest_

PROTOTYPES: DISABLE

void
RDFStore_Util_Digest_computeDigest ( input )
        unsigned char *   input

        PREINIT: 
                unsigned char dd[RDFSTORE_SHA_DIGESTSIZE];

        PPCODE:

        	if (! SvPOK(ST(0)) )
			XSRETURN_UNDEF;
        	rdfstore_digest_digest(input, strlen(input), dd);

        	ST(0) = sv_2mortal( newSVpv( dd, RDFSTORE_SHA_DIGESTSIZE ) );

		XSRETURN(1);

char *
RDFStore_Util_Digest_getDigestAlgorithm ()

        CODE:

        RETVAL = (char *) rdfstore_digest_get_digest_algorithm();

        OUTPUT:

        RETVAL

MODULE = RDFStore       PACKAGE = DBMS

PROTOTYPES: DISABLE

DBMS
TIEHASH(class,name,mode=DBMS_MODE,bt_compare_fcn_type=0,host=DBMS_HOST,port=DBMS_PORT)
	char * 		class
	char *		name
	dbms_xsmode_t	mode
	char *		host
	int		port
	int		bt_compare_fcn_type

	PREINIT:
	dbms * me;

	CODE: 
	class = class;

	me = dbms_connect(name,host,port,mode,&safemalloc,&safefree,NULL,&set_dbms_error, bt_compare_fcn_type);
	if (me==NULL) 
		XSRETURN_UNDEF;
	
	RETVAL=me;

	OUTPUT:

	RETVAL

void
DESTROY(me)
	DBMS	me

	CODE:

	/* disconect, close any sockets and free me memory. */
	dbms_disconnect(me);

DBT
FETCH(me, key)
	DBMS 		me
	DBT		key

	PREINIT:
	int retval;
	CODE:


	RETVAL.data = NULL; RETVAL.size = 0;

	if(dbms_comms(me, TOKEN_FETCH, &retval, &key, NULL,NULL,&RETVAL))
                XSRETURN_UNDEF;

	if (retval == 1)
		XSRETURN_UNDEF;

	OUTPUT:

	RETVAL

DBT
INC(me, key) 
        DBMS           	me
        DBT            	key

        PREINIT:
        int retval;  

        CODE:
        if (dbms_comms(me, TOKEN_INC, &retval, &key, NULL, NULL, &RETVAL))
                XSRETURN_UNDEF;

	if (retval == 1) 
		XSRETURN_UNDEF;

	OUTPUT:

	RETVAL
        
DBT
DEC(me, key) 
        DBMS           	me
        DBT            	key

        PREINIT:
        int retval;  

        CODE:
        if (dbms_comms(me, TOKEN_DEC, &retval, &key, NULL, NULL, &RETVAL))
                XSRETURN_UNDEF;

	if (retval == 1) 
		XSRETURN_UNDEF;

	OUTPUT: 

        RETVAL
        
int
STORE(me, key, value)
	DBMS		me	
	DBT		key
	DBT		value

        PREINIT:
	int retval;

        CODE:
	if (dbms_comms(me, TOKEN_STORE, &retval, &key, &value, NULL, NULL))
                XSRETURN_UNDEF;

        RETVAL = (retval == 0) ? 1 : 0;

	OUTPUT:

        RETVAL

int
DELETE(me, key)
	DBMS	me
	DBT	key
        PREINIT:
	int retval;

        CODE:

        if(dbms_comms(me, TOKEN_DELETE, &retval, &key, NULL, NULL, NULL))
                XSRETURN_UNDEF;

        RETVAL = (retval == 0) ? 1 : 0;

	OUTPUT:

        RETVAL                               

DBT
FROM(me, key)
	DBMS	me	
	DBT		key

        PREINIT:
	int retval;

        CODE:
	RETVAL.data = NULL; RETVAL.size = 0;
        if(dbms_comms(me, TOKEN_FROM, &retval, &key, NULL, &RETVAL, NULL))
                XSRETURN_UNDEF;

	if (retval == 1)
		XSRETURN_UNDEF;

	OUTPUT:

        RETVAL                               

DBT
FIRSTKEY(me)
	DBMS	me

        PREINIT:
	int retval;

        CODE:
	RETVAL.data = NULL; RETVAL.size = 0;
        if(dbms_comms(me, TOKEN_FIRSTKEY, &retval, NULL, NULL, &RETVAL, NULL))
                XSRETURN_UNDEF;

	if (retval == 1)
		XSRETURN_UNDEF;

	OUTPUT:

        RETVAL                               

DBT
NEXTKEY(me, key)
	DBMS	me	
	DBT		key

       	PREINIT:
	int retval;

        CODE:             
	RETVAL.data = NULL; RETVAL.size = 0;

        if (dbms_comms(me, TOKEN_NEXTKEY, &retval, &key, NULL, &RETVAL, NULL))
		XSRETURN_UNDEF;

	if (retval == 1)
		XSRETURN_UNDEF;

	OUTPUT:

        RETVAL
                                           
DBT
PING(me)
	DBMS	me	

       	PREINIT:
	int retval;

        CODE:             
	RETVAL.data = NULL; RETVAL.size = 0;

        if (dbms_comms(me, TOKEN_PING, &retval, NULL, NULL, &RETVAL, NULL))
		XSRETURN_UNDEF;

	if (retval == 1)
		XSRETURN_UNDEF;

	OUTPUT:

        RETVAL
                                           
DBT
DROP(me)
	DBMS	me	

       	PREINIT:
	int retval;

        CODE:             
	RETVAL.data = NULL; RETVAL.size = 0;

        if (dbms_comms(me, TOKEN_DROP, &retval, NULL, NULL, &RETVAL, NULL))
		XSRETURN_UNDEF;

	if (retval == 1)
		XSRETURN_UNDEF;

	OUTPUT:

        RETVAL
                                           
int
sync(me)
	DBMS	me	

	PREINIT:
	int retval;

	CODE:

        if (dbms_comms(me, TOKEN_SYNC, &retval, NULL, NULL, NULL, NULL))
                XSRETURN_UNDEF;

	RETVAL = (retval == 0) ? 1 : 0;

	OUTPUT:

        RETVAL                         

int
EXISTS(me, key)
	DBMS	me
	DBT	key

        PREINIT:
	int retval;

        CODE:

        if (dbms_comms(me, TOKEN_EXISTS, &retval, &key, NULL,NULL, NULL))
                XSRETURN_UNDEF;

	RETVAL = (retval == 0) ? 1 : 0;

	OUTPUT:

        RETVAL                         

int
CLEAR(me)
	DBMS	me

        PREINIT:
	int retval;

        CODE:
        if (dbms_comms(me, TOKEN_CLEAR, &retval, NULL, NULL, NULL, NULL))
                XSRETURN_UNDEF;

	RETVAL = (retval == 0) ? 1 : 0;

	OUTPUT:

        RETVAL                         

