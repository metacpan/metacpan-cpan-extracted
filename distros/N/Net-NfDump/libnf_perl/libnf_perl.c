 
#define NEED_PACKRECORD 1 

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

//#include "libnf.h"
#include "libnf_perl.h"

#define MATH_INT64_NATIVE_IF_AVAILABLE 1
#include "../perl_math_int64.h"

//#include "config.h"

#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdarg.h>
#include <errno.h>
#include <time.h>
#include <string.h>
#include <ctype.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/resource.h>
#include <netinet/in.h>

#ifdef HAVE_STDINT_H
#include <stdint.h>
#endif

#include <stdio.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <time.h>
#include <string.h>
#include <ctype.h>
#include <stdlib.h>
#include <errno.h>


#ifdef HAVE_STDINT_H
#include <stdint.h>
#endif


/* Ignore Math-Int64 on 64 bit platform */
/* #define MATH_INT64_NATIVE 1 */

#if MATH_INT64_NATIVE
#undef newSVu64
#define newSVu64 newSVuv
#undef SvU64 
#define SvU64 SvUV
#endif

/* defining macros for storing numbers, 64 bit numbers and strings into hash */
#define HV_STORE_NV(r,k,v) (void)hv_store(r, k, strlen(k), newSVnv(v), 0)
#define HV_STORE_U64V(r,k,v) (void)hv_store(r, k, strlen(k), newSVu64(v), 0)
#define HV_STORE_PV(r,k,v) (void)hv_store(r, k, strlen(k), newSVpvn(v, strlen(v)), 0)

/* list of maps used in file taht we create */
typedef struct libnf_file_list_s {
	char			 			*filename;
	struct libnf_file_list_s 	*next;
} libnf_file_list_t;

/* structure that bears all data related to one instance */
typedef struct libnf_instance_s {
	libnf_file_list_t		*files;					/* list of files to read */
	lnf_file_t				*lnf_nffile_r;			/* filehandle for reading */
	lnf_file_t				*lnf_nffile_w;			/* filehandle for wirting */
	int 					blk_record_remains; 	/* counter of processed rows in a signle block */
	lnf_filter_t			*filter;
	int						*field_list;
	int						field_last;
	uint64_t				processed_bytes;		/* read statistics */
	uint64_t				total_files;
	uint64_t				processed_files;
	uint64_t				processed_blocks;
	uint64_t				skipped_blocks;
	uint64_t				processed_records;
	char 					*current_filename;		/* currently processed file name */
	uint64_t				current_processed_blocks;
	time_t 					t_first_flow, t_last_flow;
	time_t					twin_start, twin_end;
	lnf_mem_t				*lnf_mem;				/* lnf_mem - aggregated/sorted results */
	lnf_rec_t				*lnf_rec;
} libnf_instance_t;


/* array of initalized instances */
libnf_instance_t *libnf_instances[NFL_MAX_INSTANCES] = { NULL };

// compare at most 16 chars
#define MAXMODELEN	16	

#define STRINGSIZE 10240
#define IP_STRING_LEN (INET6_ADDRSTRLEN)

/***********************************************************************
*                                                                      *
* functions and macros for converting data types to perl's SV and back *
*                                                                      *
************************************************************************/

/* cinverts unsigned integer 32b. to SV */
static inline SV * uint_to_SV(uint32_t n, int is_defined) {

	if (!is_defined) 
		return newSV(0);

	return newSVuv(n);
}

/* converts unsigned integer 64b. to SV */
static inline SV * uint64_to_SV(uint64_t n, int is_defined) {

	if (!is_defined) 
		return newSV(0);

	return newSVu64(n);
}

/* converts unsigned integer 64b. to SV */
static inline SV * double_to_SV(double n, int is_defined) {

	if (!is_defined) 
		return newSV(0);

	return newSVnv(n);
}

/*
************************************************************************
*                                                                      *
* end of convertion functions                                          *
*                                                                      *
************************************************************************
*/


/* returns the information about file get from file header */
SV * libnf_file_info(char *file) {
HV *res;
lnf_file_t *f;
char buf[LNF_INFO_BUFSIZE];

	res = (HV *)sv_2mortal((SV *)newHV());

	if (lnf_open(&f, file, LNF_READ, NULL) != LNF_OK) {
		return NULL;
	}

	if (lnf_info(f, LNF_INFO_VERSION, buf, LNF_INFO_BUFSIZE) == LNF_OK) 
		HV_STORE_PV(res, "version", buf);

	if (lnf_info(f, LNF_INFO_NFDUMP_VERSION, buf, LNF_INFO_BUFSIZE) == LNF_OK) 
		HV_STORE_PV(res, "nfdump_version", buf);

	if (lnf_info(f, LNF_INFO_BLOCKS, buf, LNF_INFO_BUFSIZE) == LNF_OK) 
		HV_STORE_NV(res, "blocks", *(uint64_t *)buf);

	if (lnf_info(f, LNF_INFO_COMPRESSED, buf, LNF_INFO_BUFSIZE) == LNF_OK) 
		HV_STORE_NV(res, "compressed", *(int *)buf);

	if (lnf_info(f, LNF_INFO_ANONYMIZED, buf, LNF_INFO_BUFSIZE) == LNF_OK) 
		HV_STORE_NV(res, "anonymized", *(int *)buf);

	if (lnf_info(f, LNF_INFO_CATALOG, buf, LNF_INFO_BUFSIZE) == LNF_OK) 
		HV_STORE_NV(res, "catalog", *(int *)buf);

	if (lnf_info(f, LNF_INFO_IDENT, buf, LNF_INFO_BUFSIZE) == LNF_OK) 
		HV_STORE_PV(res, "ident", buf);

	if (lnf_info(f, LNF_INFO_FLOWS, buf, LNF_INFO_BUFSIZE) == LNF_OK) 
		HV_STORE_NV(res, "flows", *(uint64_t *)buf);

	if (lnf_info(f, LNF_INFO_BYTES, buf, LNF_INFO_BUFSIZE) == LNF_OK) 
		HV_STORE_NV(res, "bytes", *(uint64_t *)buf);
		
	if (lnf_info(f, LNF_INFO_PACKETS, buf, LNF_INFO_BUFSIZE) == LNF_OK) 
		HV_STORE_NV(res, "packets", *(uint64_t *)buf);

	if (lnf_info(f, LNF_INFO_FIRST, buf, LNF_INFO_BUFSIZE) == LNF_OK) 
		HV_STORE_NV(res, "first", *(uint64_t *)buf);

	if (lnf_info(f, LNF_INFO_LAST, buf, LNF_INFO_BUFSIZE) == LNF_OK) 
		HV_STORE_NV(res, "last", *(uint64_t *)buf);

	if (lnf_info(f, LNF_INFO_FAILURES, buf, LNF_INFO_BUFSIZE) == LNF_OK) 
		HV_STORE_NV(res, "sequence_failures", *(uint64_t *)buf);

	lnf_close(f);	
	
	return newRV((SV *)res);
}

/* returns the information about instance */
SV * libnf_instance_info(int handle) {
libnf_instance_t *instance = libnf_instances[handle];
HV *res;
lnf_file_t *f;
char buf[LNF_INFO_BUFSIZE];
//lnf_info_t i;

	if (libnf_instances[handle] == NULL) {
		croak("%s handler %d not initialized", NFL_LOG, handle);
		return NULL;
	}

	res = (HV *)sv_2mortal((SV *)newHV());

	if (instance->lnf_nffile_r == NULL) {
		return NULL;
	}

	f = instance->lnf_nffile_r;

	if ( f != NULL ) {
		if (lnf_info(f, LNF_INFO_PROC_BLOCKS, buf, LNF_INFO_BUFSIZE) == LNF_OK)
			HV_STORE_NV(res, "current_processed_blocks", *(uint64_t *)buf);

		if (lnf_info(f, LNF_INFO_PROC_BLOCKS, buf, LNF_INFO_BUFSIZE) == LNF_OK) {
			uint64_t b = instance->processed_blocks + *(uint64_t *)buf;
			HV_STORE_NV(res, "processed_blocks", b);
		}

		if (lnf_info(f, LNF_INFO_BLOCKS, buf, LNF_INFO_BUFSIZE) == LNF_OK)
			HV_STORE_NV(res, "current_total_blocks", *(uint64_t *)buf);

		HV_STORE_NV(res, "total_files", instance->total_files);
		HV_STORE_NV(res, "processed_files", instance->processed_files);

	}
/*
	HV_STORE_NV(res, "processed_blocks", instance->processed_blocks);
	HV_STORE_NV(res, "processed_bytes", instance->processed_bytes);
	HV_STORE_NV(res, "processed_records", instance->processed_records);
*/

	return newRV((SV *)res);
}

/* converts master_record to perl structures (hashref) */
SV * libnf_master_record_to_AV(int handle, lnf_rec_t *lnf_rec) {
libnf_instance_t *instance = libnf_instances[handle];
AV *res_array;
int i=0;
int ret;

	if (instance == NULL ) {
		croak("%s handler %d not initialized", NFL_LOG, handle);
		return 0;
	}
	
	res_array = (AV *)sv_2mortal((SV *)newAV());

	i = 0;
	while ( instance->field_list[i] ) {
		SV * sv;
		int field = instance->field_list[i];

		switch (lnf_fld_type(field)) {
			case LNF_UINT8: {
                uint8_t t8 = 0;
                ret = lnf_rec_fget(lnf_rec, field, (void *)&t8);
				sv = uint_to_SV(t8, ret == LNF_OK);
                break;
            }
			case LNF_UINT16: {
                uint16_t t16 = 0;
                ret = lnf_rec_fget(lnf_rec, field, (void *)&t16);
				sv = uint_to_SV(t16, ret == LNF_OK);
                break;
            }
			case LNF_UINT32: {
                uint32_t t32 = 0;
                ret = lnf_rec_fget(lnf_rec, field, (void *)&t32);
				sv = uint_to_SV(t32, ret == LNF_OK);
                break;
            }
            case LNF_UINT64: {
                uint64_t t64 = 0;
                ret = lnf_rec_fget(lnf_rec, field, (void *)&t64);
				sv = uint64_to_SV(t64, ret == LNF_OK);
                break;
			}
            case LNF_DOUBLE: {
                double d = 0;
                ret = lnf_rec_fget(lnf_rec, field, (void *)&d);
				sv = double_to_SV(d, ret == LNF_OK);
                break;
			}
			case LNF_ADDR: {
				lnf_ip_t tip;

                ret = lnf_rec_fget(lnf_rec, field, (void *)&tip);

				if (ret != LNF_OK) {
					sv = newSV(0);
				} else {
					if (IN6_IS_ADDR_V4COMPAT((struct in6_addr *)&tip)) {
						sv = newSVpvn((char *)&tip.data[3], sizeof(tip.data[3]));
					} else {
						sv = newSVpvn((char *)&tip, sizeof(tip));
					}
				}
				break;
			}
			case LNF_MAC: {
				lnf_mac_t tmac;

                ret = lnf_rec_fget(lnf_rec, field, (void *)&tmac);
				if (ret != LNF_OK) {
					sv = newSV(0);
				} else {
					sv = newSVpvn((char *)&tmac, sizeof(tmac));
				}
				break;
			}
			case LNF_MPLS: {
				lnf_mpls_t tmpls;

                ret = lnf_rec_fget(lnf_rec, field, (void *)&tmpls);
				if (ret != LNF_OK) {
					sv = newSV(0);
				} else {
					sv = newSVpvn((char *)&tmpls, sizeof(lnf_mpls_t));
				}
				break;
			}
			case LNF_ACL: {
				lnf_acl_t tacl;

                ret = lnf_rec_fget(lnf_rec, field, (void *)&tacl);
				if (ret != LNF_OK) {
					sv = newSV(0);
				} else {
					sv = newSVpvn((char *)&tacl, sizeof(lnf_acl_t));
				}
				break;
			}
			case LNF_STRING: {
				char buf[LNF_MAX_STRING];

                ret = lnf_rec_fget(lnf_rec, field, (void *)&buf);
				if (ret != LNF_OK) {
					sv = newSV(0);
				} else {
					sv = newSVpvn(buf, strlen(buf));
				}
				break;
			}
			case LNF_BASIC_RECORD1: 
				sv = newSV(0);	
				break;
			default: 
				croak("%s Unknown field (id %02x) in %s !!", NFL_LOG, field, __FUNCTION__);
		} /* case */

		i++;
		av_push(res_array, sv);	
	}

 
	return newRV((SV *)res_array);
}


int libnf_init(void) {
int handle = 1;
libnf_instance_t *instance;

	/* find the first free handler and assign to array of open handlers/instances */
	while (libnf_instances[handle] != NULL) {
		handle++;
		if (handle >= NFL_MAX_INSTANCES - 1) {
			croak("%s no free handles available, max instances %d reached", NFL_LOG, NFL_MAX_INSTANCES);
			return 0;	
		}
	}

	instance = malloc(sizeof(libnf_instance_t));
	memset(instance, 0, sizeof(libnf_instance_t));

	if (instance == NULL) {
		croak("%s can not allocate memory for instance:", NFL_LOG );
		return 0;
	}

	libnf_instances[handle] = instance;

	/* initialise empty record */	
	lnf_rec_init(&instance->lnf_rec);
	instance->lnf_mem = NULL;

	instance->files = NULL;

	instance->field_list = NULL;


	return handle;
}


int libnf_set_fields(int handle, SV *fields) {
libnf_instance_t *instance = libnf_instances[handle];
I32 last_field = 0;
int i;

	if (instance == NULL ) {
		croak("%s handler %d not initialized", NFL_LOG, handle);
		return 0;
	}

	if ((!SvROK(fields))
		|| (SvTYPE(SvRV(fields)) != SVt_PVAV) 
		|| ((last_field = av_len((AV *)SvRV(fields))) < 0)) {
			croak("%s can not determine the list of fields", NFL_LOG);
			return 0;
	}

	// release memory allocated before	
	if (instance->field_list != NULL) {
		free(instance->field_list);
	}

	// last_field contains the highet index of array ! - not number of items 
	instance->field_list = malloc(sizeof(int) * (last_field + 2));

	if (instance->field_list == NULL) {
		croak("%s can not allocate memory in %s", NFL_LOG, __FUNCTION__);
		return 0;
	}

	for (i = 0; i <= last_field; i++) {
		int field = SvIV(*av_fetch((AV *)SvRV(fields), i, 0));

		if (field != 0 || field > NFL_MAX_FIELDS) {	
			instance->field_list[i] = field;
		} else {
			warn("%s ivalid itemd ID", NFL_LOG);
		}
	}

	instance->field_list[i++] = LNF_FLD_ZERO_;
	instance->field_last = last_field;
	return 1;
}

int libnf_aggr_add(int handle, int field, int flags, int numbits, int numbits6 ) {
libnf_instance_t *instance = libnf_instances[handle];
int ret = 0;

	if (instance == NULL ) {
		croak("%s handler %d not initialized", NFL_LOG, handle);
		return 0;
	}

	if (instance->lnf_mem == NULL) {
		if ((ret = lnf_mem_init(&instance->lnf_mem)) != LNF_OK ) {
			return 0;
		}
		/* first and last is always present */
		/* no need for that - solved in dependency */
		//if (lnf_mem_fadd(instance->lnf_mem, LNF_FLD_FIRST, LNF_AGGR_MIN, 0, 0) != LNF_OK ) {
//		if (lnf_mem_fadd(instance->lnf_mem, LNF_FLD_FIRST, 0, numbits, 0) != LNF_OK ) {
//			return 0;
//		}	
		//if (lnf_mem_fadd(instance->lnf_mem, LNF_FLD_LAST, LNF_AGGR_MAX, 0, 0) != LNF_OK ) {
//		if (lnf_mem_fadd(instance->lnf_mem, LNF_FLD_LAST, 0, numbits, 0) != LNF_OK ) {
//			return 0;
//		}	
	}

	if (lnf_mem_fadd(instance->lnf_mem, field, flags, numbits, numbits6) != LNF_OK ) {
		return 0;
	}	

	return 1;
} 

int libnf_listmode(int handle) {
libnf_instance_t *instance = libnf_instances[handle];

	if (instance == NULL ) {
		croak("%s handler %d not initialized", NFL_LOG, handle);
		return 0;
	}

	if (instance->lnf_mem == NULL) {
			return 0;
		}

	if (lnf_mem_setopt(instance->lnf_mem, LNF_OPT_LISTMODE, NULL, 0) != LNF_OK ) {
		return 0;
	}	

	return 1;
} 

int libnf_compatmode(int handle) {
libnf_instance_t *instance = libnf_instances[handle];

	if (instance == NULL ) {
		croak("%s handler %d not initialized", NFL_LOG, handle);
		return 0;
	}

	if (instance->lnf_mem == NULL) {
			return 0;
		}

	if (lnf_mem_setopt(instance->lnf_mem, LNF_OPT_COMP_STATSCMP, NULL, 0) != LNF_OK ) {
		return 0;
	}	

	return 1;
} 


int libnf_read_files(int handle, char *filter, int window_start, int window_end, SV *files) {
libnf_instance_t *instance = libnf_instances[handle];

libnf_file_list_t	*pfile;
lnf_rec_t	*lnf_rec;
I32 numfiles = 0;
int i;

	if (instance == NULL ) {
		croak("%s handler %d not initialized", NFL_LOG, handle);
		return 0;
	}

	/* copy files to the instance structure */
	if ((!SvROK(files))
		|| (SvTYPE(SvRV(files)) != SVt_PVAV) 
		|| ((numfiles = av_len((AV *)SvRV(files))) < 0)) {
			croak("%s can not determine the list of files", NFL_LOG);
			return 0;
	}

	pfile = malloc(sizeof(libnf_file_list_t));
	pfile->next = NULL;
	pfile->filename = NULL;
	instance->files = pfile;
	instance->total_files = numfiles + 1;
	instance->twin_start = window_start;
	instance->twin_end = window_end;
	instance->processed_blocks = 0;

	for (i = 0; i <= numfiles; i++) {
		STRLEN l;
		char * file = SvPV(*av_fetch((AV *)SvRV(files), i, 0), l);
		

		pfile->filename = malloc(l + 1);
		strcpy((char *)(pfile->filename), file);
		
		pfile->next = malloc(sizeof(libnf_file_list_t));
		pfile = pfile->next;
		pfile->filename = NULL;
		pfile->next = NULL;

	}
//	instance->nffile_r = NULL;
	instance->lnf_nffile_r = NULL;

	instance->filter = NULL;

	/* set filter */
	if (filter != NULL && strcmp(filter, "") != 0 && strcmp(filter, "any") != 0) {
		if ( lnf_filter_init(&instance->filter, filter) != LNF_OK ) {
			croak("%s can not setup filter (%s)", NFL_LOG, filter);
			return 0;
		}
	} 


	/* if aggregation is requested process all records and store in lnf_mem */
	if (instance->lnf_mem != NULL) {
		while ((lnf_rec = libnf_read_row_files(handle)) != NULL) {
			lnf_mem_write(instance->lnf_mem, lnf_rec);	
		}
	}

	return 1;
}


int libnf_create_file(int handle, char *filename, int compressed, int anonymized, char *ident) {
libnf_instance_t *instance = libnf_instances[handle];
int flags = 0;

	if (instance == NULL ) {
		croak("%s handler %d not initialized", NFL_LOG, handle);
		return 0;
	}


	/* the file was already opened */
	if (instance->lnf_nffile_w != NULL) {
		croak("%s file handler was opened before", NFL_LOG);
		return 0;
	}

	/* writing file */
	flags |= LNF_WRITE;
	flags |= compressed ? LNF_COMP  : 0x0;
	flags |= anonymized ? LNF_ANON  : 0x0;

    if ( lnf_open(&instance->lnf_nffile_w, filename, flags , ident) != LNF_OK ) {
		warn("%s cannot open file %s", NFL_LOG, filename);
		return 0;
    }

	return 1;
}

/* returns hashref or NULL if we are et the end of the file */
/* function is divided into two parts */
/* 1 - if the result is aggregated/sorted we read result from  mem object */
/* 2 - not agregated - call libnf_read_row_file */
SV * libnf_read_row(int handle) {
libnf_instance_t *instance = libnf_instances[handle];
//int ret;
//int match;
lnf_rec_t *lnf_rec;

	if (instance == NULL ) {
		croak("%s handler %d not initialized", NFL_LOG, handle);
		return 0;
	}

	if (instance->lnf_mem == NULL) {
		/* non aggregated result - read directly from file */
		lnf_rec = libnf_read_row_files(handle);

		if (lnf_rec != NULL) {
			return libnf_master_record_to_AV(handle, lnf_rec); 
		} else {
			return NULL;
		}

	} else {
		/* aggregated result - read from lnf_mem */

		if (lnf_mem_read(instance->lnf_mem, instance->lnf_rec) != LNF_EOF) {
			return libnf_master_record_to_AV(handle, instance->lnf_rec);
		} else {
			/* last record - clean lnf_mem object */
			lnf_mem_free(instance->lnf_mem);
			instance->lnf_mem = NULL;
			return NULL;
		}
	}

}


/* returns hashref or NULL if we are et the end of the file */
lnf_rec_t * libnf_read_row_files(int handle) {
libnf_instance_t *instance = libnf_instances[handle];
int ret;
int match;
uint64_t blocks;
lnf_rec_t *lnf_rec;

	if (instance == NULL ) {
		croak("%s handler %d not initialized", NFL_LOG, handle);
		return 0;
	}

#ifdef COMPAT15
int	v1_map_done = 0;
#endif

	lnf_rec = instance->lnf_rec;


begin:
		// get next data block from file
		if (instance->lnf_nffile_r) {
			ret = lnf_read(instance->lnf_nffile_r, lnf_rec);
		} else {
			ret = LNF_EOF;		/* the firt file in the list */
		}

		switch (ret) {
			case LNF_ERR_CORRUPT:
				croak("Skip corrupt data file '%s'\n", (char *)instance->files->filename);
				return NULL;
			case LNF_ERR_READ:
				croak("Read error in file '%s': %s\n", (char *)instance->files->filename, strerror(errno) );
				return NULL;
				// fall through - get next file in chain
			case LNF_EOF: {
				libnf_file_list_t *next;

				//CloseFile(instance->nffile_r);
				if (lnf_info(instance->lnf_nffile_r, LNF_INFO_BLOCKS, &blocks, sizeof(uint64_t)) == LNF_OK) {
					instance->processed_blocks += blocks;
				}
				lnf_close(instance->lnf_nffile_r);
				instance->lnf_nffile_r = NULL;
				if (instance->files->filename == NULL) {	// the end of the list 
					free(instance->files);
					instance->files = NULL;		
					return NULL;
				}
				//instance->nffile_r = OpenFile((char *)instance->files->filename, instance->nffile_r);
				if (lnf_open(&instance->lnf_nffile_r, (char *)instance->files->filename, LNF_READ, NULL) != LNF_OK) {
					croak("%s can not open/read file %s", NFL_LOG, instance->files->filename);
					return NULL;
				}
				instance->processed_files++;

				next = instance->files->next;

				/* prepare instance->files to nex unread file */
				if (instance->current_filename != NULL) {
					free(instance->current_filename);
				}

				instance->current_filename = instance->files->filename;
				free(instance->files);
				instance->files = next;

				goto begin;
			}

			default:
				// successfully read block
				instance->processed_bytes += ret;
	}

	// Time based filter
	// if no time filter is given, the result is always true

/*
	match  = instance->twin_start && (lnf_rec->master_record->first < instance->twin_start || 
						lnf_rec->master_record->last > instance->twin_end) ? 0 : 1;
*/
	/* to be FIXED XXX */
	match = 1;
	// filter netflow record with user supplied filter
//	instance->engine->nfrecord = (uint64_t *)lnf_rec.master_record;
	if ( instance->filter != NULL && match ) {
		match = lnf_filter_match(instance->filter, lnf_rec); 
	}

	if ( match == 0 ) { // record failed to pass all filters
		goto begin;
	}

	/* the record seems OK */
	return lnf_rec; 
//	return libnf_master_record_to_AV(handle, lnf_rec); 

} /* end of _next fnction */
                                  

/* copy row from the instance defined as the source handle to destination */
int libnf_copy_row(int handle, int src_handle) {
libnf_instance_t *instance = libnf_instances[handle];
libnf_instance_t *src_instance = libnf_instances[src_handle];

	if (instance == NULL ) {
		croak("%s handler %d not initialized", NFL_LOG, handle);
		return 0;
	}

	if (src_instance == NULL ) {
		croak("%s seource handler %d not initialized", NFL_LOG, handle);
		return 0;
	}

	if (!lnf_rec_copy(instance->lnf_rec, src_instance->lnf_rec) ) {
		return 0;
	} 

	return 1;

}

/* TAG for check_items_map.pl: libnf_write_row */
int libnf_write_row(int handle, SV * arrayref) {
libnf_instance_t *instance = libnf_instances[handle];
//extension_map_t *map;
//bit_array_t ext;
int last_field;
int i;
//res;
lnf_ip_t tip;

int field, ret;
lnf_rec_t *lnf_rec;

	if (instance == NULL ) {
		croak("%s handler %d not initialized", NFL_LOG, handle);
		return 0;
	}

	if ((!SvROK(arrayref))
		|| (SvTYPE(SvRV(arrayref)) != SVt_PVAV) 
		|| ((last_field = av_len((AV *)SvRV(arrayref))) < 0)) {
			croak("%s can not determine fields to store", NFL_LOG);
			return 0;
	}

	if (last_field != instance->field_last) {
		croak("%s number of fields do not match", NFL_LOG);
		return 0;
	}

	lnf_rec = instance->lnf_rec;

	i = 0;
	while ( instance->field_list[i] ) {

		SV * sv = (SV *)(*av_fetch((AV *)SvRV(arrayref), i, 0));

		if (!SvOK(sv)) {	// undef value 
			i++;
			continue;
		}

		field = instance->field_list[i];


		switch (lnf_fld_type(field)) {
			case LNF_UINT8:
			case LNF_UINT16:
			case LNF_UINT32: {
				uint32_t t32 = SvUV(sv);
				ret = lnf_rec_fset(lnf_rec, field, (void *)&t32);
				break;
			}
			case LNF_UINT64: {
				uint64_t t64 = SvU64(sv);
				ret = lnf_rec_fset(lnf_rec, field, (void *)&t64);
				break;
			}
			case LNF_DOUBLE: {
				double d = SvNV(sv);
				ret = lnf_rec_fset(lnf_rec, field, (void *)&d);
				break;
			}
			case LNF_ADDR: {
				char *s;
				STRLEN len;

			    s = SvPV(sv, len);

			    if ( len == sizeof(tip.data[3]) )  {
			        memset(&tip, 0x0, sizeof(tip));
			        memcpy(&tip.data[3], s, sizeof(tip.data[3]));
				} else if (len == sizeof(tip) ) {
			        memcpy(&tip, s, sizeof(tip));
				} else {
					warn("%s invalid IP address value for %d", NFL_LOG, field);
					return 0;
				}

				ret = lnf_rec_fset(lnf_rec, field, (void *)&tip);
				break;
			}
			case LNF_MAC: {
				char *s;
				STRLEN len;

				s = SvPV(sv, len);

				if ( len != sizeof(lnf_mac_t) ) {
					warn("%s invalid MAC address value for %d", NFL_LOG, field);
					return 0;
				}

				ret = lnf_rec_fset(lnf_rec, field, (void *)s);
				break;
			}

			case LNF_MPLS: {
				char *s;
				STRLEN len;

				s = SvPV(sv, len);

				if ( len != sizeof(lnf_mpls_t) ) {
					warn("%s invalid MPLS stack value for %d", NFL_LOG, field);
					return 0;
				}

				ret = lnf_rec_fset(lnf_rec, field, (void *)s);
				break;
			}

			case LNF_ACL: {
				char *s;
				STRLEN len;

				s = SvPV(sv, len);

				if ( len != sizeof(lnf_acl_t) ) {
					warn("%s invalid ACL value for %d", NFL_LOG, field);
					return 0;
				}

				ret = lnf_rec_fset(lnf_rec, field, (void *)s);
				break;
			}

			case LNF_STRING: {
				char buf[LNF_MAX_STRING];
				STRLEN len;
				char *s;

				s = SvPV(sv, len);	
				if (len > sizeof(buf) - 1) {
					len = sizeof(buf) - 1;
				}
				memcpy(buf, s, len);
				buf[len] = '\0';

				ret = lnf_rec_fset(lnf_rec, field, (void *)buf);
				break;
			}

			default:
				croak("%s Unknown ID (%d) in %s !!", NFL_LOG, field, __FUNCTION__);
		}
		if (ret != LNF_OK) {
			croak("%s Error when processing field %d, error code: %d !!", NFL_LOG, field, ret);
		}
		i++;
	}


	lnf_write(instance->lnf_nffile_w, lnf_rec);

	lnf_rec_clear(lnf_rec);

	return 1;
}

void libnf_finish(int handle) {
libnf_instance_t *instance = libnf_instances[handle];
libnf_file_list_t  *tmp_pfile, *pfile;

	if (instance == NULL ) {
		croak("%s handler %d not initialized", NFL_LOG, handle);
		return;
	}

	if (instance->lnf_nffile_w) {
		lnf_close(instance->lnf_nffile_w);
		instance->lnf_nffile_w = NULL;
	}

	if (instance->lnf_nffile_r) {	
		lnf_close(instance->lnf_nffile_r);
		instance->lnf_nffile_r = NULL;
	}

	lnf_rec_free(instance->lnf_rec);
	if (instance->filter != NULL) {
		lnf_filter_free(instance->filter);
		instance->filter = NULL;
	}

	/* release file list */
	pfile = instance->files;
	while (pfile != NULL) {
		if (pfile->filename != NULL) {
			free(pfile->filename);
		}
		tmp_pfile = pfile;
		pfile = pfile->next;
		free(tmp_pfile);
	}

	instance->files = NULL;

	/* field list */

	if (instance->field_list != NULL) {
		free(instance->field_list);
	}


	free(instance); 
	libnf_instances[handle] = NULL;

	return ;

} // End of process_data_finish


