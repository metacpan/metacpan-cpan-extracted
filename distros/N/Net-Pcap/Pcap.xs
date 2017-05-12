/*
 * Pcap.xs
 *
 * XS wrapper for LBL pcap(3) library.
 *
 * Copyright (C) 2005, 2006, 2007, 2008, 2009 Sebastien Aperghis-Tramoni 
 *   with some code contributed by Jean-Louis Morel. All rights reserved.
 * Copyright (C) 2003 Marco Carnut. All rights reserved. 
 * Copyright (C) 1999 Tim Potter. All rights reserved. 
 *
 * This program is free software; you can redistribute it and/or modify it 
 * under the same terms as Perl itself.
 *
 */

#ifdef __cplusplus
extern "C" {
#endif

#ifdef _CYGWIN
#include <windows.h>
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_PL_signals 1
#define NEED_sv_2pv_nolen 1
#include "ppport.h"

#include <pcap.h>

#ifdef _CYGWIN
#include <Win32-Extensions.h>
#endif

/* Perl specific constants */
#define PERL_SIGNALS_SAFE       0x00010000
#define PERL_SIGNALS_UNSAFE     0x00010001

#include "const-c.inc"
#include "stubs.inc"

#ifdef __cplusplus
}
#endif


typedef struct bpf_program  pcap_bpf_program_t;

/* A struct for holding the user context and callback information*/
typedef struct User_Callback {
    SV *callback_fn;
    SV *user;
} User_Callback;


/* Wrapper for callback function */

void callback_wrapper(u_char *user, const struct pcap_pkthdr *h, const u_char *pkt) {
    SV *packet  = newSVpvn((char *)pkt, h->caplen);
    HV *hdr     = newHV();
    SV *ref_hdr = newRV_inc((SV*)hdr);
    User_Callback* user_callback = (User_Callback*) user;

    /* Fill the hash fields */
    hv_store(hdr, "tv_sec",  strlen("tv_sec"),  newSViv(h->ts.tv_sec),  0);
    hv_store(hdr, "tv_usec", strlen("tv_usec"), newSViv(h->ts.tv_usec), 0);
    hv_store(hdr, "caplen",  strlen("caplen"),  newSVuv(h->caplen),     0);
    hv_store(hdr, "len",     strlen("len"),     newSVuv(h->len),        0);	

    /* Push arguments onto stack */
    dSP;
    PUSHMARK(sp);
    XPUSHs((SV*)user_callback->user);
    XPUSHs(ref_hdr);
    XPUSHs(packet);
    PUTBACK;

    /* Call perl function */
    call_sv (user_callback->callback_fn, G_DISCARD);

    /* Decrement refcount to temp SVs */
    SvREFCNT_dec(packet);
    SvREFCNT_dec(hdr);
    SvREFCNT_dec(ref_hdr);
}


MODULE = Net::Pcap      PACKAGE = Net::Pcap     PREFIX = pcap_

INCLUDE: const-xs.inc

PROTOTYPES: DISABLE


char *
pcap_lookupdev(err)
	SV *err

	CODE:
		if (SvROK(err)) {
            char    *errbuf = NULL;
            SV      *err_sv = SvRV(err);

            Newx(errbuf, PCAP_ERRBUF_SIZE+1, char);
			RETVAL = pcap_lookupdev(errbuf);
#ifdef WPCAP
            {   /* Conversion from Windows Unicode (UCS-2) to ANSI */
                int     size    = lstrlenW((PWSTR)RETVAL) + 2;
                char    *str    = NULL;

                Newx(str, size, char); 
                WideCharToMultiByte(CP_ACP, 0, (PWSTR)RETVAL, -1, str, size, NULL, NULL);	
                lstrcpyA(RETVAL, str);
                Safefree(str);
            }
#endif /* WPCAP */
			if (RETVAL == NULL) {
				sv_setpv(err_sv, errbuf);
			} else {
				err_sv = &PL_sv_undef;
			}

			safefree(errbuf);

		} else
			croak("arg1 not a hash ref");

	OUTPUT:
		RETVAL
		err


int
pcap_lookupnet(device, net, mask, err)
	const char *device
	SV *net
	SV *mask
	SV *err

	CODE:
		if (SvROK(net) && SvROK(mask) && SvROK(err)) {
			bpf_u_int32  netp, maskp;
            char    *errbuf     = NULL;
            SV      *net_sv     = SvRV(net);
            SV      *mask_sv    = SvRV(mask);
            SV      *err_sv     = SvRV(err);

            Newx(errbuf, PCAP_ERRBUF_SIZE+1, char);
			RETVAL = pcap_lookupnet(device, &netp, &maskp, errbuf);

			netp = ntohl(netp);
			maskp = ntohl(maskp);

			if (RETVAL != -1) {
				sv_setuv(net_sv, netp);
				sv_setuv(mask_sv, maskp);
				err_sv = &PL_sv_undef;
			} else {
				sv_setpv(err_sv, errbuf);
			}

			safefree(errbuf);

		} else {
			RETVAL = -1;
			if (!SvROK(net )) croak("arg2 not a reference");
			if (!SvROK(mask)) croak("arg3 not a reference");
			if (!SvROK(err )) croak("arg4 not a reference");
		}

	OUTPUT:
		net
		mask
		err
		RETVAL


void
pcap_findalldevs_xs(devinfo, err)
    SV * devinfo
    SV * err
 
    PREINIT:
        char    *errbuf = NULL;
        Newx(errbuf, PCAP_ERRBUF_SIZE+1, char);
    
    PPCODE:
        if ( SvROK(err) && SvROK(devinfo) && (SvTYPE(SvRV(devinfo)) == SVt_PVHV) ) {
            int r;
            pcap_if_t *alldevs, *d;
            HV *hv;
            SV *err_sv = SvRV(err);
            
            hv = (HV *)SvRV(devinfo);
            
            r = pcap_findalldevs(&alldevs, errbuf);

            switch(r) {
                case 0: /* normal case */
                    for (d=alldevs; d; d=d->next) {
                        XPUSHs(sv_2mortal(newSVpv(d->name, 0)));

                        if (d->description)
                            hv_store(hv, d->name, strlen(d->name), newSVpv(d->description, 0), 0);
                        else
                            if ( (strcmp(d->name,"lo") == 0) || (strcmp(d->name,"lo0") == 0)) 
                                hv_store(hv, d->name, strlen(d->name), 
                                        newSVpv("Loopback device", 0), 0);
                            else
                                hv_store(hv, d->name, strlen(d->name), 
                                        newSVpv("No description available", 0), 0);
                    }
            
                    pcap_freealldevs(alldevs);
                    err_sv = &PL_sv_undef;
                    break;

                case 3: { /* function is not available */
                    char *dev = pcap_lookupdev(errbuf);

                    if (dev == NULL) {
                        sv_setpv(err_sv, errbuf);
                        break;
                    }

                    XPUSHs(sv_2mortal(newSVpv(dev, 0)));
                    if ( (strcmp(dev,"lo") == 0) || (strcmp(dev,"lo0") == 0)) 
                        hv_store(hv, dev, strlen(dev), newSVpv("", 0), 0);
                    else
                        hv_store(hv, dev, strlen(dev), newSVpv("No description available", 0), 0);
                    break;
                }

                case -1: /* error */
                    sv_setpv(err_sv, errbuf); 
                    break;
            }
        } else {
            if ( !SvROK(devinfo) || (SvTYPE(SvRV(devinfo)) != SVt_PVHV) ) 
                croak("arg1 not a hash ref");
            if ( !SvROK(err) )
                croak("arg2 not a scalar ref");
        }
        safefree(errbuf);


pcap_t *
pcap_open_live(device, snaplen, promisc, to_ms, err)
	const char *device
	int snaplen
	int promisc
	int to_ms
	SV *err;

	CODE:
		if (SvROK(err)) {
            char    *errbuf = NULL;
            SV      *err_sv = SvRV(err);

            Newx(errbuf, PCAP_ERRBUF_SIZE+1, char);
#ifdef _MSC_VER
            /* Net::Pcap hangs when to_ms == 0 under ActivePerl/MSVC */
            if (to_ms == 0)
                to_ms = 1;
#endif
			RETVAL = pcap_open_live(device, snaplen, promisc, to_ms, errbuf);

			if (RETVAL == NULL) {
				sv_setpv(err_sv, errbuf);
			} else {
				err_sv = &PL_sv_undef;
			}

			safefree(errbuf);

		} else
			croak("arg5 not a reference");

	OUTPUT:
		err
		RETVAL


pcap_t *
pcap_open_dead(linktype, snaplen)
    int linktype
    int snaplen

    OUTPUT:
        RETVAL


pcap_t *
pcap_open_offline(fname, err)
	const char *fname
	SV *err

	CODE:
		if (SvROK(err)) {
            char    *errbuf = NULL;
            SV      *err_sv = SvRV(err);

            Newx(errbuf, PCAP_ERRBUF_SIZE+1, char);
			RETVAL = pcap_open_offline(fname, errbuf);

			if (RETVAL == NULL) {
				sv_setpv(err_sv, errbuf);
			} else {
				err_sv = &PL_sv_undef;
			}

			safefree(errbuf);

		} else
			croak("arg2 not a reference");	

	OUTPUT:
		err
		RETVAL


pcap_dumper_t *
pcap_dump_open(p, fname)
	pcap_t *p
	const char *fname


int
pcap_setnonblock(p, nb, err)
	pcap_t *p
	int nb
	SV *err

	CODE:
		if (SvROK(err)) {
            char    *errbuf = NULL;
            SV      *err_sv = SvRV(err);

            Newx(errbuf, PCAP_ERRBUF_SIZE+1, char);
			RETVAL = pcap_setnonblock(p, nb, errbuf);

			if (RETVAL == -1) {
				sv_setpv(err_sv, errbuf);
			} else {
				err_sv = &PL_sv_undef;
			}

			safefree(errbuf);

		} else
			croak("arg3 not a reference");	

	OUTPUT:
		err
		RETVAL


int
pcap_getnonblock(p, err)
    pcap_t *p
    SV *err

    CODE:
        if (SvROK(err)) {
            char    *errbuf = NULL;
            SV      *err_sv = SvRV(err);

            Newx(errbuf, PCAP_ERRBUF_SIZE+1, char);
            RETVAL = pcap_getnonblock(p, errbuf);

            if (RETVAL == -1) {
                sv_setpv(err_sv, errbuf);
            } else {
                err_sv = &PL_sv_undef;
            }

            safefree(errbuf);

		} else
			croak("arg2 not a reference");	

  OUTPUT:
    err
    RETVAL


int
pcap_dispatch(p, cnt, callback, user)
	pcap_t *p
	int cnt
	SV *callback
	SV *user

	CODE:
    User_Callback user_callback;
    {
		user_callback.callback_fn = newSVsv(callback);
		user_callback.user = newSVsv(user);

		*(pcap_geterr(p)) = '\0';   /* reset error string */

		RETVAL = pcap_dispatch(p, cnt, callback_wrapper, (u_char *)&user_callback);

		SvREFCNT_dec(user_callback.user);
		SvREFCNT_dec(user_callback.callback_fn);
    }	
	OUTPUT:
		RETVAL


int
pcap_loop(p, cnt, callback, user)
	pcap_t *p
	int cnt
	SV *callback
	SV *user

	CODE:
    User_Callback user_callback;
    {
		user_callback.callback_fn = newSVsv(callback);
		user_callback.user = newSVsv(user);

		RETVAL = pcap_loop(p, cnt, callback_wrapper, (u_char *)&user_callback);

		SvREFCNT_dec(user_callback.user);
		SvREFCNT_dec(user_callback.callback_fn);
    }
	OUTPUT:
		RETVAL


SV *
pcap_next(p, pkt_header)
	pcap_t *p
	SV *pkt_header

	CODE:
		if (SvROK(pkt_header) && (SvTYPE(SvRV(pkt_header)) == SVt_PVHV)) {
			struct pcap_pkthdr real_h;
			const u_char *result;
			HV *hv;

			memset(&real_h, '\0', sizeof(real_h));

			result = pcap_next(p, &real_h);

			hv = (HV *)SvRV(pkt_header);	
	
			if (result != NULL) {
				hv_store(hv, "tv_sec",  strlen("tv_sec"),  newSViv(real_h.ts.tv_sec),  0);
				hv_store(hv, "tv_usec", strlen("tv_usec"), newSViv(real_h.ts.tv_usec), 0);
				hv_store(hv, "caplen",  strlen("caplen"),  newSVuv(real_h.caplen),     0);
				hv_store(hv, "len",     strlen("len"),     newSVuv(real_h.len),        0);	

				RETVAL = newSVpv((char *)result, real_h.caplen);

			} else 
				RETVAL = &PL_sv_undef;

		} else
            croak("arg2 not a hash ref");	

    OUTPUT:
        pkt_header
        RETVAL     


int
pcap_next_ex(p, pkt_header, pkt_data)
    pcap_t *p
    SV *pkt_header
    SV *pkt_data

    CODE:
        /* Check if pkt_header is a hashref and pkt_data a scalarref */
        if (SvROK(pkt_header) && (SvTYPE(SvRV(pkt_header)) == SVt_PVHV) && SvROK(pkt_data)) {
			struct pcap_pkthdr *header;
			const u_char *data;
			HV *hv;

			memset(&header, '\0', sizeof(header));

			RETVAL = pcap_next_ex(p, &header, &data);

			hv = (HV *)SvRV(pkt_header);	

			if (RETVAL == 1) {
                hv_store(hv, "tv_sec",  strlen("tv_sec"),  newSViv(header->ts.tv_sec),  0);
                hv_store(hv, "tv_usec", strlen("tv_usec"), newSViv(header->ts.tv_usec), 0);
                hv_store(hv, "caplen",  strlen("caplen"),  newSVuv(header->caplen),     0);
                hv_store(hv, "len",     strlen("len"),     newSVuv(header->len),        0);	

                sv_setpvn((SV *)SvRV(pkt_data), (char *) data, header->caplen);
            }

        } else {
            RETVAL = -1;
            if (!SvROK(pkt_header) || (SvTYPE(SvRV(pkt_header)) != SVt_PVHV))
                croak("arg2 not a hash ref");
            if (!SvROK(pkt_data))
                croak("arg3 not a scalar ref");
        }

    OUTPUT:
        pkt_header
        pkt_data
        RETVAL


void 
pcap_dump(p, pkt_header, sp)
	pcap_dumper_t *p
	SV *pkt_header
	SV *sp

	CODE:
		/* Check if pkt_header is a hashref */
		if (SvROK(pkt_header) && (SvTYPE(SvRV(pkt_header)) == SVt_PVHV)) {
		        struct pcap_pkthdr real_h;
			char *real_sp;
			HV *hv;
			SV **sv;

			memset(&real_h, '\0', sizeof(real_h));

			/* Copy from hash to pcap_pkthdr */
			hv = (HV *)SvRV(pkt_header);

			sv = hv_fetch(hv, "tv_sec", strlen("tv_sec"), 0);
			if (sv != NULL) {
				real_h.ts.tv_sec = SvIV(*sv);
			}

			sv = hv_fetch(hv, "tv_usec", strlen("tv_usec"), 0);
			if (sv != NULL) {
				real_h.ts.tv_usec = SvIV(*sv);
			}

			sv = hv_fetch(hv, "caplen", strlen("caplen"), 0);
			if (sv != NULL) {
			        real_h.caplen = SvIV(*sv);
		        }

			sv = hv_fetch(hv, "len", strlen("len"), 0);
			if (sv != NULL) {
			        real_h.len = SvIV(*sv);
			}

			real_sp = SvPV(sp, PL_na);

			/* Call pcap_dump() */
			pcap_dump((u_char *)p, &real_h, (u_char *)real_sp);

		} else
            croak("arg2 not a hash ref");


int 
pcap_compile(p, fp, str, optimize, mask)
	pcap_t *p
	SV *fp
	char *str
	int optimize
	bpf_u_int32 mask

	CODE:
		if (SvROK(fp)) {
            pcap_bpf_program_t  *real_fp = NULL;

            Newx(real_fp, 1, pcap_bpf_program_t);
			*(pcap_geterr(p)) = '\0';   /* reset error string */
			RETVAL = pcap_compile(p, real_fp, str, optimize, mask);
			sv_setref_pv(SvRV(fp), "pcap_bpf_program_tPtr", (void *)real_fp);

		} else
			croak("arg2 not a reference");

	OUTPUT:
		fp
		RETVAL


int
pcap_compile_nopcap(snaplen, linktype, fp, str, optimize, mask)
    int snaplen
    int linktype
	SV *fp
	char *str
	int optimize
	bpf_u_int32 mask

    CODE:
		if (SvROK(fp)) {
            pcap_bpf_program_t  *real_fp = NULL;

            Newx(real_fp, 1, pcap_bpf_program_t);
			RETVAL = pcap_compile_nopcap(snaplen, linktype, real_fp, str, optimize, mask);
			sv_setref_pv(SvRV(fp), "pcap_bpf_program_tPtr", (void *)real_fp);

		} else
			croak("arg3 not a reference");

    OUTPUT:
        fp
        RETVAL


int
pcap_offline_filter(fp, header, p)
    pcap_bpf_program_t *fp
    SV *header
    SV *p

    CODE:
        /* Check that header is a hashref */
        if (SvROK(header) && (SvTYPE(SvRV(header)) == SVt_PVHV)) {
            struct pcap_pkthdr real_h;
            char *real_p;
            HV *hv;
            SV **sv;

            memset(&real_h, '\0', sizeof(real_h));

            /* Copy from hash to pcap_pkthdr */
            hv = (HV *)SvRV(header);

            sv = hv_fetch(hv, "tv_sec", strlen("tv_sec"), 0);
            if (sv != NULL) {
                real_h.ts.tv_sec = SvIV(*sv);
            }

            sv = hv_fetch(hv, "tv_usec", strlen("tv_usec"), 0);
            if (sv != NULL) {
                real_h.ts.tv_usec = SvIV(*sv);
            }

            sv = hv_fetch(hv, "caplen", strlen("caplen"), 0);
            if (sv != NULL) {
                real_h.caplen = SvIV(*sv);
            }

            sv = hv_fetch(hv, "len", strlen("len"), 0);
            if (sv != NULL) {
                real_h.len = SvIV(*sv);
            }

            real_p = SvPV(p, PL_na);

            RETVAL = pcap_offline_filter(fp, &real_h, (unsigned char *) real_p);

        } else
            croak("arg2 not a hash ref");

    OUTPUT:
        RETVAL


int 
pcap_setfilter(p, fp)
	pcap_t *p
	pcap_bpf_program_t *fp


void
pcap_freecode(fp)
	pcap_bpf_program_t *fp


void
pcap_breakloop(p)
    pcap_t *p


void
pcap_close(p)
	pcap_t *p


void
pcap_dump_close(p)
	pcap_dumper_t *p


FILE *
pcap_dump_file(p)
	pcap_dumper_t *p


int
pcap_dump_flush(p)
	pcap_dumper_t *p


int 
pcap_datalink(p)
	pcap_t *p


int
pcap_set_datalink(p, linktype)
    pcap_t *p
    int linktype


int
pcap_datalink_name_to_val(name)
    const char *name


const char *
pcap_datalink_val_to_name(linktype)
    int linktype


const char *
pcap_datalink_val_to_description(linktype)
    int linktype


int 
pcap_snapshot(p)
	pcap_t *p


int 
pcap_is_swapped(p)
	pcap_t *p


int 
pcap_major_version(p)
	pcap_t *p


int 
pcap_minor_version(p)
	pcap_t *p


void
pcap_perror(p, prefix)
	pcap_t *p
	char *prefix
 

char *
pcap_geterr(p)
	pcap_t *p


char *
pcap_strerror(error)
	int error


const char *
pcap_lib_version()


SV *
pcap_perl_settings(setting)
    int setting

    CODE:
        RETVAL = 0;

        switch (setting) {
            case PERL_SIGNALS_SAFE:
                RETVAL = newSVuv(PL_signals);
                PL_signals = 0;
                break;
            case PERL_SIGNALS_UNSAFE:
                RETVAL = newSVuv(PL_signals);
                PL_signals = PERL_SIGNALS_UNSAFE_FLAG;
                break;
        }

    OUTPUT:
        RETVAL


FILE *
pcap_file(p)
	pcap_t *p


int
pcap_fileno(p)
	pcap_t *p


int
pcap_get_selectable_fd(p)
	pcap_t *p


int
pcap_stats(p, ps)
	pcap_t *p;
	SV *ps;

	CODE:
		/* Call pcap_stats() function */

		if (SvROK(ps) && (SvTYPE(SvRV(ps)) == SVt_PVHV)) {
			struct pcap_stat real_ps;
			HV *hv;

			*(pcap_geterr(p)) = '\0';   /* reset error string */

			RETVAL = pcap_stats(p, &real_ps);

			/* Copy pcap_stats fields into hash */

			hv = (HV *)SvRV(ps);

			hv_store(hv, "ps_recv", strlen("ps_recv"), 
						newSVuv(real_ps.ps_recv), 0);
			hv_store(hv, "ps_drop", strlen("ps_drop"), 
						newSVuv(real_ps.ps_drop), 0);
			hv_store(hv, "ps_ifdrop", strlen("ps_ifdrop"), 
						newSVuv(real_ps.ps_ifdrop), 0);

		} else
            croak("arg2 not a hash ref");

	OUTPUT:
		RETVAL


int
pcap_createsrcstr(source, type, host, port, name, err)
    SV *    source 
    int     type  
    char *  host 
    char *  port  
    char *  name
    SV *    err

    CODE:
        if (SvROK(source) && SvROK(err)) {
            char    *errbuf     = NULL;
            char    *sourcebuf  = NULL;
            SV      *err_sv     = SvRV(err);
            SV      *source_sv  = SvRV(source);

            Newx(errbuf, PCAP_ERRBUF_SIZE+1, char);
            Newx(sourcebuf, PCAP_BUF_SIZE+1, char);

            RETVAL = pcap_createsrcstr(sourcebuf, type, host, port, name, errbuf);

            if (RETVAL != -1) {
                sv_setpv(source_sv, sourcebuf);
                err_sv = &PL_sv_undef;
            } else {
                sv_setpv(err_sv, errbuf);
            }

            safefree(errbuf);
            safefree(sourcebuf);

        } else {
            RETVAL = -1;
            if (!SvROK(source)) croak("arg1 not a reference");
            if (!SvROK(err)) croak("arg6 not a reference");
        }

    OUTPUT:
        source
        err
        RETVAL


int
pcap_parsesrcstr(source, type, host, port, name, err)
    char * source  
    SV *   type 
    SV *   host 
    SV *   port  
    SV *   name 
    SV *   err 

    CODE:
        if ( !SvROK(type) ) croak("arg2 not a reference");   
        if ( !SvROK(host) ) croak("arg3 not a reference");  
        if ( !SvROK(port) ) croak("arg4 not a reference");
        if ( !SvROK(name) ) croak("arg5 not a reference");
        if ( !SvROK(err ) ) croak("arg6 not a reference");

        else {  
            int     rtype;
            char    *hostbuf    = NULL;
            char    *portbuf    = NULL;
            char    *namebuf    = NULL;
            char    *errbuf     = NULL;
            SV      *type_sv    = SvRV(type);
            SV      *host_sv    = SvRV(host);
            SV      *port_sv    = SvRV(port);
            SV      *name_sv    = SvRV(name);    
            SV      *err_sv     = SvRV(err);    

            Newx(hostbuf, PCAP_BUF_SIZE+1, char);
            Newx(portbuf, PCAP_BUF_SIZE+1, char);
            Newx(namebuf, PCAP_BUF_SIZE+1, char);
            Newx(errbuf, PCAP_ERRBUF_SIZE+1, char);

            RETVAL = pcap_parsesrcstr(source, &rtype, hostbuf, portbuf, namebuf, errbuf);

            if (RETVAL != -1) {
                sv_setiv(type_sv, rtype);
                sv_setpv(host_sv, hostbuf);
                sv_setpv(port_sv, portbuf);
                sv_setpv(name_sv, namebuf);				
                err_sv = &PL_sv_undef;
            } else {
                sv_setpv(err_sv, errbuf);
            }

            safefree(hostbuf);
            safefree(portbuf);
            safefree(namebuf);
            safefree(errbuf);
        }

    OUTPUT:
        type
        host
        port
        name
        err
        RETVAL


pcap_t *
pcap_open(source, snaplen, flags, read_timeout, auth, err)
    char *source
    int snaplen
    int flags
    int read_timeout
    SV *auth
    SV *err

    CODE:
        if (!SvROK(err))
            croak("arg6 not a reference");

        if ( !SvOK(auth) || (SvOK(auth) && SvROK(auth) && (SvTYPE(SvRV(auth)) == SVt_PVHV)) ) {
            struct pcap_rmtauth real_auth;
            struct pcap_rmtauth *preal_auth;
            char    *errbuf = NULL;
            SV      *err_sv = SvRV(err);

            Newx(errbuf, PCAP_ERRBUF_SIZE+1, char);

            if (!SvOK(auth)) {      /* if auth (struct pcap_rmtauth) is undef */
                preal_auth = NULL;

            } else {                    /* auth (struct pcap_rmtauth) is a hashref */  
                HV *hv;
                SV **sv;

                memset(&real_auth, '\0', sizeof(real_auth));

                /* Copy from hash to pcap_rmtauth */
                hv = (HV *)SvRV(auth);
                sv = hv_fetch(hv, "type", strlen("type"), 0);

                if (sv != NULL)
                    real_auth.type = SvIV(*sv);

                sv = hv_fetch(hv, "username", strlen("username"), 0);

                if (sv != NULL)
                    real_auth.username = SvPV(*sv, PL_na);

                sv = hv_fetch(hv, "password", strlen("password"), 0);

                if (sv != NULL)
                    real_auth.password = SvPV(*sv, PL_na);

                preal_auth = &real_auth;
            }

            RETVAL = pcap_open(source, snaplen, flags, read_timeout, preal_auth, errbuf); 

            if (RETVAL == NULL) {
                sv_setpv(err_sv, errbuf);				
            } else {
                err_sv = &PL_sv_undef;
            }  	  

            safefree(errbuf);

        } else
            croak("arg5 not a hash ref");

    OUTPUT:
        RETVAL
        err


int
pcap_setuserbuffer(p, size)
    pcap_t *p
    int size


int
pcap_setbuff(p, dim)
    pcap_t *p
    int dim


int
pcap_setmode (p, mode)
    pcap_t *p
    int mode


int
pcap_setmintocopy(p, size) 
    pcap_t *p
    int size


void
pcap_getevent(p)
    pcap_t *p

    PREINIT:
        unsigned int h;

    PPCODE:
        h = (unsigned int) pcap_getevent(p);  
        ST(0) = sv_newmortal();
        sv_setref_iv(ST(0), "Win32::Event", h);
        XSRETURN(1);

 
int 
pcap_sendpacket(p, buf)
    pcap_t *p
    SV *buf

    CODE:
        RETVAL = pcap_sendpacket(p, (u_char *)SvPVX(buf), sv_len(buf));  

    OUTPUT:
        RETVAL


pcap_send_queue * 
pcap_sendqueue_alloc(memsize)
    u_int memsize


MODULE = Net::Pcap      PACKAGE = pcap_send_queuePtr

void
DESTROY(queue)
    pcap_send_queue * queue

    CODE:
        pcap_sendqueue_destroy(queue);


MODULE = Net::Pcap      PACKAGE = Net::Pcap     PREFIX = pcap_

int
pcap_sendqueue_queue(queue, header, p)
    pcap_send_queue * queue
    SV *header
    SV *p

    CODE:
        /* Check that header is a hashref */
        if (SvROK(header) && (SvTYPE(SvRV(header)) == SVt_PVHV)) {
            struct pcap_pkthdr real_h;
            char *real_p;
            HV *hv;
            SV **sv;

            memset(&real_h, '\0', sizeof(real_h));

            /* Copy from hash to pcap_pkthdr */
            hv = (HV *)SvRV(header);

            sv = hv_fetch(hv, "tv_sec", strlen("tv_sec"), 0);
            if (sv != NULL) {
                real_h.ts.tv_sec = SvIV(*sv);
            }

            sv = hv_fetch(hv, "tv_usec", strlen("tv_usec"), 0);
            if (sv != NULL) {
                real_h.ts.tv_usec = SvIV(*sv);
            }

            sv = hv_fetch(hv, "caplen", strlen("caplen"), 0);
            if (sv != NULL) {
                real_h.caplen = SvIV(*sv);
            }

            sv = hv_fetch(hv, "len", strlen("len"), 0);
            if (sv != NULL) {
                real_h.len = SvIV(*sv);
            }

            real_p = SvPV(p, PL_na);

            /* Call pcap_sendqueue_queue() */
            RETVAL = pcap_sendqueue_queue(queue, &real_h, (unsigned char *) real_p);

        } else
            croak("arg2 not a hash ref");

    OUTPUT:
        RETVAL	


u_int
pcap_sendqueue_transmit(p, queue, sync)
    pcap_t *p
    pcap_send_queue * queue
    int sync

