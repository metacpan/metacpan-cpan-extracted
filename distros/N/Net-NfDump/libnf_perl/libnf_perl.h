
#include <stdio.h>
#include <stdlib.h>
#include <libnf.h>


/* multiple use of version for both perl and nfdump so we redefine it */
#define NFL_VERSION VRESION
#undef VERSION


/* string prefix for error and warning outputs */
#define NFL_LOG			"Net::NfDump: "


/* the maximim number of fields requested from the client */
#define NFL_MAX_FIELDS 256

/* the maxumim naumber of instances (objects) that can be used in code */
#define NFL_MAX_INSTANCES 512


/* return eroror codes */
#define NFL_NO_FREE_INSTANCES -1;

/* extend NF_XX codes with code idicates thet we already to read the next record */
#define NF_OK      1


/* perl - function prototypes */
SV * libnf_file_info(char *file);
SV * libnf_instance_info(int handle);
int libnf_init(void);
int libnf_set_fields(int handle, SV *fields);
int libnf_read_files(int handle, char *filter, int window_start, int window_end, SV *files);
int libnf_create_file(int handle, char *filename, int compressed, int anonymized, char *ident);
SV * libnf_read_row(int handle);
lnf_rec_t * libnf_read_row_files(int handle);
int libnf_copy_row(int handle, int src_handle);
int libnf_write_row(int handle, SV * arrayref);
void libnf_finish(int handle);

int libnf_aggr_add(int handle, int field, int flags, int numbits, int numbits6);
int libnf_listmode(int handle);
int libnf_compatmode(int handle);

