/*
	Search::ContextGraph - XS implementation

	(C) 2003 Schuyler Erle, Maciej Ceglowski
	
	This is free software, released
	under the GPL.  See LICENSE for more
	information.
	
*/
  
# include "cns.h"
# include <unistd.h>
# include <stdlib.h>
# include <stdio.h>
# include <string.h>
# include <math.h>

# define debug 0



Edge *new_edge ( Edge *edge, long sink, float weight ) {
    /* Initialize a given edge struct. */
    edge->sink   = sink;
    edge->weight = weight;
    return edge;
}

Node *new_node ( Node *node, NodeType type, long capacity ) {
    /* Initialize a given node struct. */
    //node->type	    = type;
    node->degree    = 0;
    node->capacity  = capacity;
    node->edges	    = calloc( capacity, sizeof(Node) );
    memset( node->edges, 0, capacity * sizeof(Node) );
    if (debug)
    	fprintf(stderr, "%p new_node(%d) capacity = %ld\n", node, type, capacity );
    return node;
}

Graph *new_graph ( Graph *graph, long capacity,
	float activationThreshold, float collectionThreshold, long maxDepth) {
    /* Initialize a given graph struct. */
    graph->size	    = 0;
    graph->capacity = capacity;
    graph->activationThreshold = activationThreshold;
    graph->collectionThreshold = collectionThreshold;
    graph->maxDepth = maxDepth;
    graph->nodes    = calloc( capacity, sizeof(Node)  );
    graph->energy   = calloc( capacity, sizeof(float) );
    memset( graph->nodes, 0, capacity * sizeof(Node) );
    return graph;
}

void free_node (Node *node) {
    free( node->edges );
}

void free_graph (Graph *graph) {
    long n;
    /*fprintf( stderr, "%p graph size: %ld\n", graph, graph->size );*/
    for (n = 0; n < graph->size; n++)
		free_node( graph->nodes + n );
	free( graph->energy);
    free( graph->nodes );
    free( graph );
}


void reset_graph( Graph *graph ) {
    graph->energy = realloc( graph->energy, graph->size * sizeof(float) );
    memset( graph->energy, 0, graph->size * sizeof(float) );
    graph->numCalls = 0;
    graph->maxDepth = -1;
}

Edge *add_edge ( Node *node, long sink, float weight ) {
    long deg = ++(node->degree);
    long cap = node->capacity;
    Edge *edge;

	if (debug)
    printf( "* adding edge -> %ld(%f) to %p (%ld / %ld)\n", 
	sink, weight, node, deg, cap );

    /* If we have more edges than we've allocated memory for, reallocate. */
    if (deg > cap) {
    	
		//if( cap < 255 ) {
			
		//	node->capacity = cap + 256;
			//fprintf( stderr, "\tincreasing node capacity %d , %d\n", node->capacity , cap);
		//} else {
			//printf( "\tdoubling node capacity %d\n", node->capacity);
			node->capacity *= 2;
		//}
		
		node->edges = realloc( node->edges, node->capacity * sizeof(Edge) );
		memset( node->edges + cap, 0, 
			( node->capacity - cap ) * sizeof(Edge) );
    }

    /* Initialize the new edge. */
    edge = node->edges + deg - 1;
    new_edge( edge, sink, weight );
    return edge;
}

int preallocate ( Graph *graph, int nodecount ) {

	int original;
	
	original = graph->capacity;
	
	if ( original < nodecount ) {
		printf( "Pre-allocationg graph capacity (was %d) to %d\n", 	original, nodecount );
		graph->capacity = nodecount;
		graph->nodes = realloc( graph->nodes, graph->capacity * sizeof(Node));
		memset( graph->nodes + original, 0, (graph->capacity - original) * sizeof(Node) );
	}
	return 1;
}

void presize_node( Graph *graph, long id, int size ) {

	Node *n = ( graph->nodes + id );
	long deg = n->degree;
	long cap = n->capacity;
	
	if ( cap <  size ) {
		n->capacity = size;
		n->edges = realloc( n->edges, size * sizeof( Edge ));
		memset( n->edges + cap, 0, (n->capacity -cap ) * sizeof(Edge));
		//printf( "Presizing node capacity (was %d) to %d\n", cap, n->capacity );
	}
	
}


Node *add_node ( Graph *graph, long id, NodeType type, long capacity ) {
    Node *node;

    /* If the index of the to-be-created node is bigger than we've allocated,
     * we need to reallocated. */
    if (debug)
    	fprintf( stderr, "%p add_node %ld/%d (%d)\n",
			graph, id, graph->size, graph->capacity);
	
	
    if (id >= graph->size) {
	long cap = graph->capacity;
	graph->size = id + 1;

	/* Increase the capacity until it's bigger than the number of nodes
	 * we need, if such need be, and then resize the lists if the capacity
	 * changed. */
	while (graph->size > graph->capacity )
	    graph->capacity *= 2;

		if (graph->capacity > cap) {
			graph->nodes = realloc(
				graph->nodes, graph->capacity * sizeof(Node));
			memset( graph->nodes + cap, 0, (graph->capacity - cap) * sizeof(Node) );
		}
    }
    if (debug)
    	fprintf( stderr, "%p --> size: %d capacity: %d\n",
	    graph, graph->size, graph->capacity);

    /* Initialize the new node, unless there already is such a node. */
    node = graph->nodes + id;
    if ( node->capacity == 0 ){
		new_node( node, type, capacity );
	 	if (debug)
    	fprintf( stderr, "%p --> new node\n",
	   	 node);
	} else {
		fprintf( stderr, "node %p ", node );
	}
    return node;
}

int energize_node( Graph *graph, long id, float energy, int isStartingPoint) {
    Node *node = graph->nodes + id;
    float *slot = graph->energy + id;
    
    float subenergy = 0;
    static int depth = 0;
    long n;
    
    // Keep track of some search statistics
    graph->numCalls++;
	if ( ++depth > graph->maxDepth ) 
		graph->maxDepth = depth;
	
	
	if (debug){
    	int i;
    	for (i = 0; i< depth;i++)
    		fprintf( stderr, "   ");
    	fprintf(stderr, "%ld: energizing %f + %f\n", id, node->energy, energy);
    }
    
    /* Activate the node and calculate the propagating energy. */
    *slot += energy;
    if (node->degree) {
    	
    	//printf( "* denominator is %f\n", denom );
		subenergy = energy / (log( node->degree ) + 1);    
	}

	/* Special case handling for nodes with just one neighbor 
	   Normally, we don't propagate energy at a singleton node 
	   But if it's the query node, we want to continue the search */
	
	if ( node->degree == 1 ) {
	
		if ( isStartingPoint == 0 ){
			depth--;
			return 0;	
		} else {
			subenergy = energy;
		}
	}
	/*			     **********************/

	 /* Bail if the subenergy isn't big enough to propagate. */
    if (subenergy < graph->activationThreshold){
    	depth--;
		return 0;
	}
	
    /* Otherwise, recurse through our neighbors. */
    if (debug){
    	int i;
    	for (i = 0; i< depth;i++)
    		fprintf( stderr, "   ");
    	fprintf(stderr, "%ld: propagating subenergy %f to %d neighbors\n", 
    		id, subenergy, node->degree);
    }
    
    for (n = 0; n < node->degree; n++) {
		energize_node( graph,
			node->edges[n].sink, node->edges[n].weight * subenergy , 0 );
    }
	
	if (debug){
    	int i;
    	for (i = 0; i< depth;i++)
    		fprintf( stderr, "   ");
    	fprintf(stderr, "%ld: finished\n", id);
    }
    depth--;
    return 1;
}

int compare_results( const void *a, const void *b ) {
    const Edge *x = a, *y = b;
    /* Sort nodes in descending order by energy. */
    return (x->weight > y->weight ? -1 :
	   (x->weight < y->weight ?  1 : 0));
}

 Edge *collect_results( Graph *graph ) {
 
    /* The result list will be a NULL-terminated list of edge structs. The
     * weight entry in each struct will contain the accumulated activation energy
     * of each sink. */
    long n, m;

    int result_size = 64;
      
    Edge *result = calloc( result_size, sizeof(Edge) );
    
    /* Find the nodes that scored higher than the threshold. */
    for (n = 0, m = 0; n < graph->size; n++ ) {
		if ( *( graph->energy + n) > graph->collectionThreshold ) {

			Edge *e = result + m++;
			e->sink = n;
			e->weight = *( graph->energy + n);
			
		} 
		
		/* Expand as necessary to fit the result list */
		while ( (m+1) > result_size ) {
			result_size *= 2;
			result = realloc( result, result_size * sizeof( Edge ));
		}
    }	
   
    memset( result + m, 0,   sizeof(Edge) );
    return result;

}

