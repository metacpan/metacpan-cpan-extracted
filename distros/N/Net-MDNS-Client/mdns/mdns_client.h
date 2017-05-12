#include "mdnsd.h"
#define MAX_STRING 1024
/* Initialise the mdns engine.  Call before any other mdns calls */
int mdnsc_start();
/* Stop the mdns engine.  Call before any other mdns calls */
void mdnsc_stop();

/*
 *	Query types are  "host by service", "ip by hostname" and "data by hostname"
 *	To be used in the query function
 */
char * mdnsc_make_query(char * query_type, char * hostname, char * service, char * domain, char * protocol);

/*
 *	Send a query (using query string and query types from above)
 *	Call returns immediately, call get_a_result to get responses
 */
int mdnsc_query(char *query_type, char *query_string);
/*
 *	Call with the same options as query to cancel that query 
 */
void mdnsc_cancel_query(char *query_type, char *query_string);
/*
 *	Walk the response list.  Returns NULL at the end of the list, then returns to the start
 *	There is a different list for each query stirng <-> query type combo, so save your
 *	queries somewhere.
 */
mdnsda mdnsc_get_a_result(char * query_type, char *query_string);
/*
 *	Call this lots of times per second
 */
int mdnsc_process_network_events();

