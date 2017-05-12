/*
 * $Id: system.h,v 1.1 2005/07/20 13:44:13 mchapman Exp $
 */

#ifndef _SYSTEM_H
#define _SYSTEM_H

#if HAVE_CONFIG_H
# include <config.h>
#endif /* HAVE_CONFIG_H */

#include <cdp.h>

/*
 * These headers should exist. Even gnulib assumes they do...
 */
#include <assert.h>
#include <errno.h>
#ifndef errno
extern int errno;
#endif
#include <stddef.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <strdup.h>
#include <string.h>
#include <xalloc.h>

#if HAVE_PCAP_H
# include <pcap.h>
#endif /* HAVE_PCAP_H */

#if HAVE_LIBNET_H
# include <libnet.h>
#endif /* HAVE_LIBNET_H */

#define MALLOC(C, T) ((T *)xnmalloc((C), sizeof(T)))
#define MALLOC_VOIDP(C) ((void *)xmalloc(C))
#define CALLOC(C, T) ((T *)xcalloc((C), sizeof(T)))

static inline char *
SALLOC(size_t c) {
	char *p;
        
	assert(c);
        
	p = MALLOC(c, char);
	*p = *(p + c - 1) = '\0';
	return p;
}

#define NEW(DST, SRC, T) \
	do { \
		(DST) = MALLOC(1, T); \
		*(DST) = (SRC); \
	} while (0)
#define DUP(DST, SRC, T) NEW(DST, *(SRC), T)

#ifdef NDEBUG
#define xfree(P) free(P)
#else /* ! NDEBUG */
#define xfree(P) do { assert(P); free(P); (P) = NULL; } while (0)
#endif /* ! NDEBUG */

#define FREE(P) xfree(P)

#define VOIDP_DIFF(P, Q) ((ptrdiff_t)((char *)(P) - (char *)(Q)))
#define VOIDP_OFFSET(P, O) ((void *)((char *)(P) + (ptrdiff_t)(O)))

struct _cdp {
	pcap_t *pcap;
	libnet_t *libnet;
	
	int flags;
	
	char *port;
	uint8_t mac[6];
	cdp_llist_t *addresses;
	uint8_t *duplex;
	
	const struct pcap_pkthdr *header;
	const void *data;
};

#endif /* _SYSTEM_H */
