#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <ruli.h>

#include "const-c.inc"

static void push_ruli_addr(AV *srv_addrs, const ruli_addr_t *addr)
{
	SV *address;
	char buf[40];

	if (ruli_addr_snprint(buf, 40, addr) < 0)
		return;

	address = newSVpv(buf, strlen(buf));

	av_push(srv_addrs, address);
}

static SV *scan_srv_list(ruli_sync_t *sync_query)
{
	int srv_code;
	ruli_list_t *srv_list;
	int srv_list_size;
	int i;
        AV* srv_array;
        SV* srv_array_ref;

	const char *label_target    = "target";
	const char *label_priority  = "priority";
	const char *label_weight    = "weight";
	const char *label_port      = "port";
	const char *label_addr_list = "addr_list";

	SV* key_target    = newSVpv(label_target,    strlen(label_target));
	SV* key_priority  = newSVpv(label_priority,  strlen(label_priority));
	SV* key_weight    = newSVpv(label_weight,    strlen(label_weight));
	SV* key_port      = newSVpv(label_port,      strlen(label_port));
	SV* key_addr_list = newSVpv(label_addr_list, strlen(label_addr_list));

	/* Underlying SRV query failure? */
	srv_code = ruli_sync_srv_code(sync_query);
	if (srv_code == RULI_SRV_CODE_ALARM)
		return 0;

	/* Service provided? */
	if (srv_code == RULI_SRV_CODE_UNAVAILABLE)
		return 0;

	/* Server RCODE? */
	if (srv_code) {
		int rcode = ruli_sync_rcode(sync_query);
		if (rcode)
			return 0;

		return 0;
	}

	srv_list = ruli_sync_srv_list(sync_query);
	srv_list_size = ruli_list_size(srv_list);

	srv_array = newAV();
	srv_array_ref = newRV_inc((SV*) srv_array);

	/* Scan list of SRV records */
	for (i = 0; i < srv_list_size; ++i) {
		ruli_srv_entry_t *entry         = ruli_list_get(srv_list, i);
		ruli_list_t      *addr_list     = &entry->addr_list;
		int              addr_list_size = ruli_list_size(addr_list);
		char             txt_dname_buf[RULI_LIMIT_DNAME_TEXT_BUFSZ];
		int              txt_dname_len;
		int              j;

		HV*	srv;
		SV*	srv_ref;
		SV*	target;
		SV*	priority;
		SV*	weight;
		SV*	port;
		AV*	srv_addrs;
		SV*	srv_addrs_ref;

		if (ruli_dname_decode(txt_dname_buf, 
			RULI_LIMIT_DNAME_TEXT_BUFSZ,
	       		&txt_dname_len,
			entry->target, entry->target_len))
			continue;

		target   = newSVpv(txt_dname_buf, txt_dname_len);
		priority = newSViv(entry->priority);
		weight   = newSViv(entry->weight);
		port     = newSViv(entry->port);

		srv = newHV();
		srv_ref = newRV_inc((SV*) srv);
		av_push(srv_array, srv_ref);

		hv_store_ent(srv, key_target, target, 0);
		hv_store_ent(srv, key_priority, priority, 0);
		hv_store_ent(srv, key_weight, weight, 0);
		hv_store_ent(srv, key_port, port, 0);

		srv_addrs = newAV();
		srv_addrs_ref = newRV_inc((SV*) srv_addrs);
		hv_store_ent(srv, key_addr_list, srv_addrs_ref, 0);

		for (j = 0; j < addr_list_size; ++j) {
			ruli_addr_t *addr = ruli_list_get(addr_list, j);
			push_ruli_addr(srv_addrs, addr);
		}
	}

	return srv_array_ref;
}

MODULE = Net::RULI		PACKAGE = Net::RULI		

INCLUDE: const-xs.inc

PROTOTYPES: ENABLE

SV *
ruli_sync_query(service, domain, fallback_port, options)
	const char * service
	const char * domain
	int          fallback_port
	long         options
CODE:
	ruli_sync_t *sync_query;
        SV* srv_array_ref;

	/* Submit query */
	sync_query = ruli_sync_query(service, domain, fallback_port, options);
	if (!sync_query)
		XSRETURN_UNDEF;

	srv_array_ref = scan_srv_list(sync_query);

	ruli_sync_delete(sync_query);

	if (!srv_array_ref)
		XSRETURN_UNDEF;

	RETVAL = srv_array_ref;
OUTPUT:
	RETVAL

SV *
ruli_sync_smtp_query(domain, options)
	const char * domain
	long         options
CODE:
	ruli_sync_t *sync_query;
        SV* srv_array_ref;

	/* Submit query */
	sync_query = ruli_sync_smtp_query(domain, options);
	if (!sync_query)
		XSRETURN_UNDEF;

	srv_array_ref = scan_srv_list(sync_query);

	ruli_sync_delete(sync_query);

	if (!srv_array_ref)
		XSRETURN_UNDEF;

	RETVAL = srv_array_ref;
OUTPUT:
	RETVAL

SV *
ruli_sync_http_query(domain, force_port, options)
	const char * domain
	int          force_port
	long         options
CODE:
	ruli_sync_t *sync_query;
        SV* srv_array_ref;

	/* Submit query */
	sync_query = ruli_sync_http_query(domain, force_port, options);
	if (!sync_query)
		XSRETURN_UNDEF;

	srv_array_ref = scan_srv_list(sync_query);

	ruli_sync_delete(sync_query);

	if (!srv_array_ref)
		XSRETURN_UNDEF;

	RETVAL = srv_array_ref;
OUTPUT:
	RETVAL
