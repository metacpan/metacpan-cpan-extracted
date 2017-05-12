/* -*- Mode: C -*- */

#define PERL_NO_GET_CONTEXT 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

static UV netmask[] = { 0x00000000,
                        0x80000000,
                        0xc0000000,
                        0xe0000000,
                        0xf0000000,
                        0xf8000000,
                        0xfc000000,
                        0xfe000000,
                        0xff000000,
                        0xff800000,
                        0xffc00000,
                        0xffe00000,
                        0xfff00000,
                        0xfff80000,
                        0xfffc0000,
                        0xfffe0000,
                        0xffff0000,
                        0xffff8000,
                        0xffffc000,
                        0xffffe000,
                        0xfffff000,
                        0xfffff800,
                        0xfffffc00,
                        0xfffffe00,
                        0xffffff00,
                        0xffffff80,
                        0xffffffc0,
                        0xffffffe0,
                        0xfffffff0,
                        0xfffffff8,
                        0xfffffffc,
                        0xfffffffe,
                        0xffffffff,
};

int
parse_ip(pTHX_ const char *p, const char sep, UV *out, const char **remainder) {
    int i = 0;
    UV ip = 0;
    while (1) {
        const char *start = p;
        int v = 0;
        while (*p >= '0' && *p <= '9') {
            v = v * 10 + (*p - '0');
            if (v > 255) return 0;
            p++;
        }
        if (p == start) return 0;
        ip = (ip << 8) + v;

        if (++i < 4) {
            if (*(p++) != '.') return 0;
        }
        else {
            if (*(p++) != sep) return 0;
            *out = ip;
            if (remainder) *remainder = p;
            return 1;
        }
    }
}

int
parse_len(pTHX_ const char *p, int *out) {
    int len = 0;
    const char *start = p;
    while ((*p >= '0') && (*p <= '9')) {
        len = len * 10 + *p - '0';
        if (len > 32) return 0;
        p++;
    }
    if ((*p != '\0') || (p == start)) return 0;
    *out = len;
    return 1;
}

MODULE = Sort::Key::IPv4		PACKAGE = Sort::Key::IPv4		
PROTOTYPES: DISABLE

UV
pack_ipv4(ipv4=NULL)
    SV *ipv4
PREINIT:
    const char *p;
CODE:
    if (!ipv4)
        ipv4 = DEFSV;
    if (!parse_ip(aTHX_ SvPV_nolen(ipv4), '\0', &RETVAL, NULL))
        Perl_croak(aTHX_ "bad IPv4 specification %s", SvPV_nolen(ipv4));
OUTPUT:
    RETVAL

void
pack_netipv4(netipv4=NULL)
    SV *netipv4
PREINIT:
    UV ip;
    const char *p;
PPCODE:
    if (!netipv4)
        netipv4 = DEFSV;
    if (parse_ip(aTHX_ SvPV_nolen(netipv4), '/', &ip, &p)) {
        int len;
        if (parse_len(aTHX_ p, &len)) {
            UV m = netmask[len];
            if ((ip & ~m) == 0) {
                XPUSHs(sv_2mortal(newSVuv(ip)));
                XPUSHs(sv_2mortal(newSVuv(m)));
                XSRETURN(2);
            }
        }
    }
    Perl_croak(aTHX_ "bad IPv4 network specification %s", SvPV_nolen(netipv4));

