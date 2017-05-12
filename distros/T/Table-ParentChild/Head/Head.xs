#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdio.h>
#include <string.h>
#include "src/head.h"
#include "src/element.h"

static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(char *name, int len, int arg)
{
    errno = EINVAL;
    return 0;
}

MODULE = Table::ParentChild::Head		PACKAGE = Table::ParentChild::Head		

double
constant(sv,arg)
    PREINIT:
	STRLEN		len;
    INPUT:
	SV *		sv
	char *		s = SvPV(sv, len);
	int		arg
    CODE:
	RETVAL = constant(s,len,arg);
    OUTPUT:
	RETVAL

head *
new( CLASS, id )
	char *			CLASS
	PREINIT:
	head *			p_head;
	INPUT:
	unsigned long	id;
	CODE:
	p_head = (head *) safemalloc( sizeof( head ));
	if( p_head == NULL ) {
		warn( "unable to allocate Table::ParentChild::Head" );
		XSRETURN_UNDEF;
	}
	p_head->id = id;
	p_head->first = NULL;
	RETVAL = p_head;
	OUTPUT:
	RETVAL

void
DESTROY( self )
	head *			self
	CODE:
	safefree( (char *) self );
	
void
add_node( p_head_parent, p_head_child, quantity )
	PREINIT:
	element *		node;
	element *		linked_list_node;
	INPUT:
	head *			p_head_parent;
	head *			p_head_child;
	double			quantity;
	CODE:
	node = (element *) safemalloc( sizeof( element ));
	node->next_parent	= NULL;
	node->next_child	= NULL;
	node->head_parent	= p_head_parent;
	node->head_child	= p_head_child;
	node->value			= quantity;

	linked_list_node = p_head_parent->first;
	p_head_parent->first = node;
	node->next_parent = linked_list_node;

	/*
	if( linked_list_node ) {
		printf( "First node: P(%ld) => C(%ld) = %lf\n", 
			linked_list_node->head_parent->id, 
			linked_list_node->head_child->id, 
			linked_list_node->value 
		);
		printf( "Inserting:  P(%ld) => C(%ld) = %lf\n", 
			node->head_parent->id, 
			node->head_child->id, 
			quantity 
		);
		printf( "Next node:  P(%ld) => C(%ld) = %lf\n", 
			node->next_parent->head_parent->id, 
			node->next_parent->head_child->id, 
			node->next_parent->value 
		);
	} else {
		printf( "Adding:     P(%ld) => C(%ld) = %lf\n", 
			node->head_parent->id, 
			node->head_child->id, 
			quantity 
		);
	}
	*/

	linked_list_node = p_head_child->first;
	p_head_child->first = node;
	node->next_child = linked_list_node;

	/*
	if( linked_list_node ) {
		printf( "First node: P(%ld) => C(%ld) = %lf\n", 
			linked_list_node->head_parent->id, 
			linked_list_node->head_child->id, 
			linked_list_node->value 
		);
		printf( "Inserting:  P(%ld) => C(%ld) = %lf\n", 
			node->head_parent->id, 
			node->head_child->id, 
			quantity 
		);
		printf( "Next node:  P(%ld) => C(%ld) = %lf\n", 
			node->next_child->head_parent->id, 
			node->next_child->head_child->id, 
			node->next_child->value 
		);
	} else {
		printf( "Adding:     P(%ld) => C(%ld) = %lf\n", 
			node->head_parent->id, 
			node->head_child->id, 
			quantity 
		);
	}
	*/

unsigned long
first_child( p_head_parent )
	INPUT:
	head *			p_head_parent;
	CODE:
	RETVAL = p_head_parent->first->head_parent->id;
	OUTPUT:
	RETVAL

unsigned long
first_parent( p_head_child )
	INPUT:
	head *			p_head_child;
	CODE:
	RETVAL = p_head_child->first->head_child->id;
	OUTPUT:
	RETVAL

unsigned long
id( p_head )
	INPUT:
	head *			p_head;
	CODE:
	RETVAL = p_head->id;
	OUTPUT:
	RETVAL

SV *
search_for_parents( p_head_child )
	INPUT:
	head *			p_head_child;
	PREINIT:
	HV *			hv_search_results;
	element *		node;
	CODE:
	hv_search_results = newHV();
	RETVAL = newRV_noinc((SV *) hv_search_results);

	node = p_head_child->first;
	while( node ) {
		/*
		printf( "Parent %ld found for Child %ld\n", node->head_parent->id, p_head_child->id );
		*/
		hv_store_ent( 
			hv_search_results, 
			newSVpvf( "%ld", node->head_parent->id ),
			newSVnv( node->value ),
			0
		);

		node = node->next_child;
	}
	OUTPUT:
	RETVAL

SV *
search_for_children( p_head_parent )
	INPUT:
	head *			p_head_parent;
	PREINIT:
	HV *			hv_search_results;
	element *		node;
	CODE:
	hv_search_results = newHV();
	RETVAL = newRV_noinc((SV *) hv_search_results);

	node = p_head_parent->first;
	while( node ) {
		/*
		printf( "Parent %ld found for Child %ld\n", node->head_parent->id, p_head_child->id );
		*/
		hv_store_ent( 
			hv_search_results, 
			newSVpvf( "%ld", node->head_child->id ),
			newSVnv( node->value ),
			0
		);

		node = node->next_parent;
	}
	OUTPUT:
	RETVAL

