/*
	Search::ContextGraph - XS implementation

	(C) 2003 Schuyler Erle, Maciej Ceglowski
	
	This is free software, released
	under the GPL.  See LICENSE for more
	information.
	
*/
  
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "cns.h"
#include "const-c.inc"


#define  DEFAULT_CAPACITY 2

  
MODULE = Search::ContextGraph		PACKAGE = Search::ContextGraph		

INCLUDE: const-xs.inc

void
free_node(node)
	Node *	node

Edge *
new_edge(edge, sink, weight)
	Edge *	edge
	long	sink
	float	weight

Graph *
new_graph(graph, capacity = DEFAULT_CAPACITY, activationThreshold = 1, collectionThreshold = 1, maxDepth = 100000000)
	Graph *	graph
	long	capacity
	float	activationThreshold
	float	collectionThreshold
	long 	maxDepth

Node *
new_node(node, type, capacity=DEFAULT_CAPACITY)
	Node *	node
	int 	type
	long	capacity

MODULE = Search::ContextGraph	PACKAGE = Search::ContextGraph::Graph 

Node *
add_node(graph, id, type, capacity=DEFAULT_CAPACITY)
	Graph *	graph
	long	id
	int	type
	long	capacity


void
collect_results(graph)
		Graph * graph
		
	PREINIT:	
		AV * list;
		AV *entry;
		SV *undef;
		Edge *result;
		int startSize;
		int i;
		int result_count;
		
    INIT:
    	result_count = 0;
    	undef = (SV*) &PL_sv_undef;
		list =  (AV *) sv_2mortal((SV *)newAV());
		startSize = 64;
		
    PPCODE:
		result = collect_results(graph);
		for (i = 0; result[i].weight > 0; i++) {
			entry = newAV();
			/* fprintf( stderr, "weight %ld, %ld, %f \n", i, result[i].sink, result[i].weight);
			*/
			av_push(entry, newSViv(result[i].sink));
			av_push(entry, newSVnv(result[i].weight));
			av_push(list, newRV_noinc((SV *)entry));
			result_count++;
		}
		
		//fprintf( stderr, "result count %ld ", result_count);

		if ( result_count > 0 ) {
			XPUSHs(newRV_noinc((SV *)list));
		} else {
			XPUSHs( undef  );
		}
		free( result );
	
	

int
energize_node(graph, id, energy, isStart)
	Graph *	graph
	int	id
	float	energy
	int isStart

void
preallocate( graph, number )
	Graph * graph
	int number
	
void
reset_graph(graph)
	Graph *	graph

void
free_graph(graph)
	Graph *	graph

Graph *
new(CLASS, startingEnergy = 100, activationEnergy = 1, collectionEnergy = 1, maxDepth = 100000000)
	char *CLASS = NO_INIT
	float startingEnergy;
	float activationEnergy;
	float collectionEnergy;
	long maxDepth;
	
    PROTOTYPE: $;$$$$
    CODE:
		/* Zero((void*)&RETVAL, sizeof(RETVAL), char); */
	RETVAL = malloc(sizeof(Graph));
		/* fprintf( stderr, "NEW called: %p\n", RETVAL ); */
		new_graph(
			(Graph *)RETVAL, DEFAULT_CAPACITY,
			 activationEnergy, collectionEnergy, maxDepth);
    OUTPUT:
	RETVAL

void
DESTROY(THIS)
	Graph * THIS;
    PROTOTYPE: $
    CODE:
	
	free_graph(THIS);

long
size(THIS, __value = NO_INIT)
	Graph * THIS
	long __value
    PROTOTYPE: $;$
    CODE:
	if (items > 1)
	    THIS->size = __value;
	RETVAL = THIS->size;
    OUTPUT:
	RETVAL

long
capacity(THIS, __value = NO_INIT)
	Graph * THIS
	long __value
    PROTOTYPE: $;$
    
    CODE:
	if (items > 1)
	    THIS->capacity = __value;
	RETVAL = THIS->capacity;
    OUTPUT:
	RETVAL

float
activationThreshold(THIS, __value = NO_INIT)
	Graph * THIS
	float __value
    PROTOTYPE: $;$
    
    CODE:
	if (items > 1)
	    THIS->activationThreshold = __value;
	RETVAL = THIS->activationThreshold;
    OUTPUT:
	RETVAL

float
collectionThreshold(THIS, __value = NO_INIT)
	Graph * THIS
	float __value
    PROTOTYPE: $;$
    CODE:
	if (items > 1)
	    THIS->collectionThreshold = __value;
	RETVAL = THIS->collectionThreshold;
    OUTPUT:
	RETVAL

float
startingEnergy(THIS, __value = NO_INIT)
	Graph * THIS
	float __value
    PROTOTYPE: $;$
    CODE:
	if (items > 1)
	    THIS->startingEnergy = __value;
	RETVAL = THIS->startingEnergy;
    OUTPUT:
	RETVAL

int
maxDepth( THIS )
	Graph * THIS
	PROTOTYPE: $
	CODE:
	RETVAL = THIS->maxDepth;
	OUTPUT:
	RETVAL
	
int
numCalls( THIS )
	Graph * THIS
	PROTOTYPE: $
	CODE:
	RETVAL = THIS->numCalls;
	OUTPUT:
	RETVAL
	
long
debug(THIS, __value = NO_INIT)
	Graph * THIS
	long __value
    PROTOTYPE: $;$
    CODE:
	if (items > 1)
	    THIS->debug = __value;
	RETVAL = THIS->debug;
    OUTPUT:
	RETVAL

long
indent(THIS, __value = NO_INIT)
	Graph * THIS
	long __value
    PROTOTYPE: $;$
    
    CODE:
	if (items > 1)
	    THIS->indent = __value;
	RETVAL = THIS->indent;
    OUTPUT:
	RETVAL

void
set_edge(THIS, source, sink, weight)
	Graph *THIS
	long source 
	long sink
	float weight
    PROTOTYPE: $$$$
    PREINIT:
    	Node *n;
    	Node *m;
    	
    CODE:
		n = THIS->nodes + source;
		m = THIS->nodes + sink;
		add_edge( n, sink, weight );
		add_edge( m, source, weight );

void
presize_node( THIS, node, size )
	Graph *THIS
	long node
	int size


void
set_directed_edge(THIS, source, sink, weight)
	Graph *THIS
	long source
	long sink
	float weight
    PROTOTYPE: $$$$
    PREINIT:
    	Node *n;
    CODE:
		n = THIS->nodes + source;
		add_edge( n, sink, weight );
	
MODULE = Search::ContextGraph	PACKAGE = Search::ContextGraph::Node 

Edge *
add_edge(node, sink, weight)
	Node *	node
	long	sink
	float	weight

Node *
new(CLASS, type, capacity = DEFAULT_CAPACITY)
	char *CLASS = NO_INIT
	int type
	long capacity
    PROTOTYPE: $$;$
    CODE:
	/* Zero((void*)&RETVAL, sizeof(RETVAL), char); */
	RETVAL = malloc(sizeof(Node));
	new_node((Node *)RETVAL, type, capacity);
    OUTPUT:
	RETVAL



long
degree(THIS, __value = NO_INIT)
	Node * THIS
	long __value
    PROTOTYPE: $;$
    CODE:
	if (items > 1)
	    THIS->degree = __value;
	RETVAL = THIS->degree;
    OUTPUT:
	RETVAL

long
capacity(THIS, __value = NO_INIT)
	Node * THIS
	long __value
    PROTOTYPE: $;$
    CODE:
	if (items > 1)
	    THIS->capacity = __value;
	RETVAL = THIS->capacity;
    OUTPUT:
	RETVAL

float
energy(THIS, __value = NO_INIT)
	Node * THIS
	float __value
    PROTOTYPE: $;$
    CODE:
	if (items > 1)
	    THIS->energy = __value;
	RETVAL = THIS->energy;
    OUTPUT:
	RETVAL


MODULE = Search::ContextGraph PACKAGE = Search::ContextGraph::Edge  

Edge *
new(CLASS, sink, weight)
	long sink
	float weight
    PROTOTYPE: $$$
    INIT:
    sink = 0;
    weight = 0;
    CODE:
	RETVAL = malloc(sizeof(Edge));
	new_edge((Edge *)RETVAL, sink, weight);
    OUTPUT:
	RETVAL

long
sink(THIS, __value = NO_INIT)
	Edge * THIS
	long __value
    PROTOTYPE: $;$
    CODE:
	if (items > 1)
	    THIS->sink = __value;
	RETVAL = THIS->sink;
    OUTPUT:
	RETVAL

float
weight(THIS, __value = NO_INIT)
	Edge * THIS
	float __value
    PROTOTYPE: $;$
    CODE:
	if (items > 1)
	    THIS->weight = __value;
	RETVAL = THIS->weight;
    OUTPUT:
	RETVAL

