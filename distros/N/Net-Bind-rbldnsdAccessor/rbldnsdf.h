/*	rbldnsdf.h	*/

#include "rblf_base.h"
#include "rbldnsd/rbldnsd.h"

unsigned int rblf_query(const char *zonename, const char *domain, struct dnspacket * pkt);
int rblf_answer(struct rblf_info * ri, unsigned char **ptrptr, unsigned char * bom, unsigned char * eom);
unsigned int rblf_create_zone(const char *zone, int argc, char **argv, void *driverdata, void **dbdata);
