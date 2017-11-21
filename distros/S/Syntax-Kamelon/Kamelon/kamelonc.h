typedef struct stack_node {
    long long parser;
	 char context[64];
	 char captures[16][64];
	 struct stack_node * next;
} 
stack_node_t;

typedef struct yashe {
    int debug;
	 stack_node_t stack;
}
yashe_t;

int debug (yashe_t * sh);

stack_node_t stack (yashe_t * sh);

