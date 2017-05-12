/*
	Search::ContextGraph - XS implementation

	(C) 2003 Schuyler Erle, Maciej Ceglowski
	
	This is free software, released
	under the GPL.  See LICENSE for more
	information.
	
*/
  
typedef struct edge_t {
    int	sink;
    float	weight;
    } Edge;

typedef enum node_type_t { UNUSED = 0, TERM, DOCUMENT } NodeType;

typedef struct node_t {
    //NodeType	type;
    int degree;
    int	capacity;
    float	energy;
    Edge *	edges;
    } Node;

typedef struct graph_t {
    int	size;
    int	capacity;
    Node *	nodes;
    float * energy;
    float	activationThreshold;
    float	collectionThreshold;
    float	startingEnergy;
    long 	maxDepth;
    long	numCalls;
    int		debug;
    int		indent;
    } Graph;

Edge *new_edge ( Edge *edge, long sink, float weight );
Node *new_node ( Node *node, NodeType type, long capacity );
int preallocate( Graph *graph, int capacity );
void presize( Graph *graph, long node, int size );
Graph *new_graph ( Graph *graph, long capacity,
	float activationThreshold, float collectionThreshold, long maxDepth );
void free_node (Node *node);
void free_graph (Graph *graph);
void reset_graph( Graph *graph );
Edge *add_edge ( Node *node, long sink, float weight );
Node *add_node ( Graph *graph, long id, NodeType type, long capacity );
int energize_node( Graph *graph, long id, float energy, int isStartingNode );
int compare_results( const void *a, const void *b );
Edge *collect_results( Graph *graph );
Edge *search_graph( Graph *graph, float startEnergy,
    long num_ids, long ids[]);
