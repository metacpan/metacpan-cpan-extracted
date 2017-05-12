typedef struct node NODE;
typedef struct list LIST;
typedef struct iplist IPLIST;
typedef struct init INIT;

void dump_intersection (INIT *, LIST *, unsigned long int, int);
char * dump_next_intersection_output (INIT *);
IPLIST * dump_intersection_output(INIT *);
LIST * setup_new_list (INIT *);
INIT * start_new (void);
