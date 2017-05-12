/*
NetIpXs.xs - XS wrapper around the core Net::IP::XS functions.

Copyright (C) 2010-2016 Tom Harrison <tomhrr@cpan.org>
Original inet_pton4, inet_pton6 are Copyright (C) 2006 Free Software
Foundation.
Original interface, and the auth and ip_auth functions, are Copyright
(C) 1999-2002 RIPE NCC.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
*/

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdio.h>
#include <ctype.h>
#include <stdarg.h>
#include <stdlib.h>

#include "inet_pton.h"
#include "functions.h"
#include "object.h"

MODULE = Net::IP::XS::N128  PACKAGE = Net::IP::XS::N128 PREFIX = net_ip_xs_n128

SV *
new(package)
        char *package
    PREINIT:
        HV *stash;
        SV *ref;
        SV *num_ref;
        n128_t num;
    CODE:
        stash = gv_stashpv("Net::IP::XS::N128", 1);
        n128_set_ui(&num, 0);
        num_ref = newSVpv((const char*) &num, 16);
        ref = newRV_noinc(num_ref);
        sv_bless(ref, stash);
        RETVAL = ref;
    OUTPUT:
        RETVAL

int
set_ui(self, ui)
        SV *self
        unsigned int ui
    PREINIT:
        STRLEN len;
        n128_t num;
    CODE:
        if (!sv_isa(self, "Net::IP::XS::N128")) {
            RETVAL = 0;
        } else {
            Copy(SvPV(SvRV(self), len), &num, 1, n128_t);
            n128_set_ui(&num, ui);
            sv_setpvn(SvRV(self), (const char*) &num, 16);
            RETVAL = 1;
        }
    OUTPUT:
        RETVAL

int
set_binstr(self, binstr)
        SV *self
        const char *binstr
    PREINIT:
        STRLEN len;
        n128_t num;
    CODE:
        if (!sv_isa(self, "Net::IP::XS::N128")) {
            RETVAL = 0;
        } else {
            Copy(SvPV(SvRV(self), len), &num, 1, n128_t);
            n128_set_str_binary(&num, binstr, strlen(binstr));
            sv_setpvn(SvRV(self), (const char*) &num, 16);
            RETVAL = 1;
        }
    OUTPUT:
        RETVAL

int
set_decstr(self, decstr)
        SV *self
        const char *decstr
    PREINIT:
        STRLEN len;
        n128_t num;
    CODE:
        if (!sv_isa(self, "Net::IP::XS::N128")) {
            RETVAL = 0;
        } else {
            Copy(SvPV(SvRV(self), len), &num, 1, n128_t);
            n128_set_str_decimal(&num, decstr, strlen(decstr));
            sv_setpvn(SvRV(self), (const char*) &num, 16);
            RETVAL = 1;
        }
    OUTPUT:
        RETVAL

int
cmp_ui(self, ui)
        SV *self
        unsigned int ui
    PREINIT:
        STRLEN len;
        n128_t num;
    CODE:
        if (!sv_isa(self, "Net::IP::XS::N128")) {
            RETVAL = 0;
        } else {
            Copy(SvPV(SvRV(self), len), &num, 1, n128_t);
            RETVAL = n128_cmp_ui(&num, ui);
        }
    OUTPUT:
        RETVAL

int
cmp(self, other)
        SV *self
        SV *other
    PREINIT:
        STRLEN len;
        n128_t num1;
        n128_t num2;
    CODE:
        if (!sv_isa(self,  "Net::IP::XS::N128")
         || !sv_isa(other, "Net::IP::XS::N128")) {
            RETVAL = 0;
        } else {
            Copy(SvPV(SvRV(self),  len), &num1, 1, n128_t);
            Copy(SvPV(SvRV(other), len), &num2, 1, n128_t);
            RETVAL = n128_cmp(&num1, &num2);
        }
    OUTPUT:
        RETVAL

int
blsft(self, shift)
        SV *self
        int shift
    PREINIT:
        STRLEN len;
        n128_t num;
    CODE:
        if (!sv_isa(self, "Net::IP::XS::N128")) {
            RETVAL = 0;
        } else {
            Copy(SvPV(SvRV(self), len), &num, 1, n128_t);
            n128_blsft(&num, shift);
            sv_setpvn(SvRV(self), (const char*) &num, 16);
            RETVAL = 1;
        }
    OUTPUT:
        RETVAL

int
brsft(self, shift)
        SV *self
        int shift
    PREINIT:
        STRLEN len;
        n128_t num;
    CODE:
        if (!sv_isa(self, "Net::IP::XS::N128")) {
            RETVAL = 0;
        } else {
            Copy(SvPV(SvRV(self), len), &num, 1, n128_t);
            n128_brsft(&num, shift);
            sv_setpvn(SvRV(self), (const char*) &num, 16);
            RETVAL = 1;
        }
    OUTPUT:
        RETVAL

int
band(self, other)
        SV *self
        SV *other
    PREINIT:
        STRLEN len;
        n128_t num1;
        n128_t num2;
    CODE:
        if (!sv_isa(self,  "Net::IP::XS::N128")
         || !sv_isa(other, "Net::IP::XS::N128")) {
            RETVAL = 0;
        } else {
            Copy(SvPV(SvRV(self),  len), &num1, 1, n128_t);
            Copy(SvPV(SvRV(other), len), &num2, 1, n128_t);
            n128_and(&num1, &num2);
            sv_setpvn(SvRV(self), (const char*) &num1, 16);
            RETVAL = 1;
        }
    OUTPUT:
        RETVAL

int
bior(self, other)
        SV *self
        SV *other
    PREINIT:
        STRLEN len;
        n128_t num1;
        n128_t num2;
    CODE:
        if (!sv_isa(self,  "Net::IP::XS::N128")
         || !sv_isa(other, "Net::IP::XS::N128")) {
            RETVAL = 0;
        } else {
            Copy(SvPV(SvRV(self),  len), &num1, 1, n128_t);
            Copy(SvPV(SvRV(other), len), &num2, 1, n128_t);
            n128_ior(&num1, &num2);
            sv_setpvn(SvRV(self), (const char*) &num1, 16);
            RETVAL = 1;
        }
    OUTPUT:
        RETVAL

int
bxor(self, other)
        SV *self
        SV *other
    PREINIT:
        STRLEN len;
        n128_t num1;
        n128_t num2;
    CODE:
        if (!sv_isa(self,  "Net::IP::XS::N128")
         || !sv_isa(other, "Net::IP::XS::N128")) {
            RETVAL = 0;
        } else {
            Copy(SvPV(SvRV(self),  len), &num1, 1, n128_t);
            Copy(SvPV(SvRV(other), len), &num2, 1, n128_t);
            n128_xor(&num1, &num2);
            sv_setpvn(SvRV(self), (const char*) &num1, 16);
            RETVAL = 1;
        }
    OUTPUT:
        RETVAL

int
badd(self, other)
        SV *self
        SV *other
    PREINIT:
        STRLEN len;
        n128_t num1;
        n128_t num2;
    CODE:
        if (!sv_isa(self,  "Net::IP::XS::N128")
         || !sv_isa(other, "Net::IP::XS::N128")) {
            RETVAL = 0;
        } else {
            Copy(SvPV(SvRV(self),  len), &num1, 1, n128_t);
            Copy(SvPV(SvRV(other), len), &num2, 1, n128_t);
            n128_add(&num1, &num2);
            sv_setpvn(SvRV(self), (const char*) &num1, 16);
            RETVAL = 1;
        }
    OUTPUT:
        RETVAL

int
bsub(self, other)
        SV *self
        SV *other
    PREINIT:
        STRLEN len;
        n128_t num1;
        n128_t num2;
    CODE:
        if (!sv_isa(self,  "Net::IP::XS::N128")
         || !sv_isa(other, "Net::IP::XS::N128")) {
            RETVAL = 0;
        } else {
            Copy(SvPV(SvRV(self),  len), &num1, 1, n128_t);
            Copy(SvPV(SvRV(other), len), &num2, 1, n128_t);
            n128_sub(&num1, &num2);
            sv_setpvn(SvRV(self), (const char*) &num1, 16);
            RETVAL = 1;
        }
    OUTPUT:
        RETVAL

int
badd_ui(self, ui)
        SV *self
        unsigned int ui
    PREINIT:
        STRLEN len;
        n128_t num;
    CODE:
        if (!sv_isa(self,  "Net::IP::XS::N128")) {
            RETVAL = 0;
        } else {
            Copy(SvPV(SvRV(self), len), &num, 1, n128_t);
            n128_add_ui(&num, ui);
            sv_setpvn(SvRV(self), (const char*) &num, 16);
            RETVAL = 1;
        }
    OUTPUT:
        RETVAL

int
bnot(self)
        SV *self
    PREINIT:
        STRLEN len;
        n128_t num;
    CODE:
        if (!sv_isa(self,  "Net::IP::XS::N128")) {
            RETVAL = 0;
        } else {
            Copy(SvPV(SvRV(self), len), &num, 1, n128_t);
            n128_com(&num);
            sv_setpvn(SvRV(self), (const char*) &num, 16);
            RETVAL = 1;
        }
    OUTPUT:
        RETVAL

int
tstbit(self, bit)
        SV *self
        int bit
    PREINIT:
        STRLEN len;
        n128_t num;
    CODE:
        if (!sv_isa(self,  "Net::IP::XS::N128")) {
            RETVAL = 0;
        } else {
            Copy(SvPV(SvRV(self), len), &num, 1, n128_t);
            RETVAL = n128_tstbit(&num, bit);
        }
    OUTPUT:
        RETVAL

int
setbit(self, bit)
        SV *self
        int bit
    PREINIT:
        STRLEN len;
        n128_t num;
    CODE:
        if (!sv_isa(self,  "Net::IP::XS::N128")) {
            RETVAL = 0;
        } else {
            Copy(SvPV(SvRV(self), len), &num, 1, n128_t);
            n128_setbit(&num, bit);
            sv_setpvn(SvRV(self), (const char*) &num, 16);
            RETVAL = 1;
        }
    OUTPUT:
        RETVAL

int
clrbit(self, bit)
        SV *self
        int bit
    PREINIT:
        STRLEN len;
        n128_t num;
    CODE:
        if (!sv_isa(self,  "Net::IP::XS::N128")) {
            RETVAL = 0;
        } else {
            Copy(SvPV(SvRV(self), len), &num, 1, n128_t);
            n128_clrbit(&num, bit);
            sv_setpvn(SvRV(self), (const char*) &num, 16);
            RETVAL = 1;
        }
    OUTPUT:
        RETVAL

SV *
bstr(self)
        SV *self
    PREINIT:
        STRLEN len;
        n128_t num;
        char buf[40];
    CODE:
        if (!sv_isa(self, "Net::IP::XS::N128")) {
            RETVAL = &PL_sv_undef;
        } else {
            Copy(SvPV(SvRV(self), len), &num, 1, n128_t);
            n128_print_dec(&num, buf);
            RETVAL = newSVpv(buf, 0);
        }
    OUTPUT:
        RETVAL

SV *
as_hex(self)
        SV *self
    PREINIT:
        STRLEN len;
        n128_t num;
        char buf[40];
    CODE:
        if (!sv_isa(self, "Net::IP::XS::N128")) {
            RETVAL = &PL_sv_undef;
        } else {
            Copy(SvPV(SvRV(self), len), &num, 1, n128_t);
            n128_print_hex(&num, buf);
            RETVAL = newSVpv(buf, 0);
        }
    OUTPUT:
        RETVAL

MODULE = Net::IP::XS        PACKAGE = Net::IP::XS

PROTOTYPES: ENABLE

SV *
ip_get_Error(data)
        void *data
    CODE:
        RETVAL = newSVpv(NI_get_Error(), 0);
    OUTPUT:
        RETVAL

void
ip_set_Error(data, str)
        void *data
        char *str
    CODE:
        NI_set_Error(str);

SV *
ip_get_Errno(data)
        void *data
    CODE:
        RETVAL = newSViv(NI_get_Errno());
    OUTPUT:
        RETVAL

void
ip_set_Errno(data, num)
        void *data
        int num
    CODE:
        NI_set_Errno(num);

SV *
ip_is_ipv4(ip)
        char *ip
    CODE:
        RETVAL = newSViv(NI_ip_is_ipv4(ip));
    OUTPUT:
        RETVAL

SV *
ip_is_ipv6(ip)
        char *ip
    CODE:
        RETVAL = newSViv(NI_ip_is_ipv6(ip));
    OUTPUT:
        RETVAL

SV *
ip_binadd(begin, end)
        char *begin
        char *end
    PREINIT:
        char buf[IPV6_BITSTR_LEN];
        int res;
    CODE:
        buf[0] = '\0';
        res = NI_ip_binadd(begin, end, buf, IPV6_BITSTR_LEN);
        RETVAL = (res) ? newSVpv(buf, 0) : &PL_sv_undef;
    OUTPUT:
        RETVAL

SV *
ip_get_prefix_length(bin1, bin2)
        char *bin1
        char *bin2
    PREINIT:
        int res;
        int result;
    CODE:
        res = NI_ip_get_prefix_length(bin1, bin2, &result);
        RETVAL = (res) ? newSViv(result) : &PL_sv_undef;
    OUTPUT:
        RETVAL

void
ip_splitprefix(prefix)
        char *prefix
    PREINIT:
        char buf[MAX_IPV6_STR_LEN];
        int len;
        int res;
    PPCODE:
        res = NI_ip_splitprefix(prefix, buf, &len);
        if (res) {
            XPUSHs(sv_2mortal(newSVpv(buf, 0)));
            XPUSHs(sv_2mortal(newSViv(len)));
        }

SV *
ip_is_valid_mask(mask, ipversion)
        char *mask
        int ipversion
    PREINIT:
        int res;
    CODE:
        res = NI_ip_is_valid_mask(mask, ipversion);
        RETVAL = (res) ? newSViv(1) : &PL_sv_undef;
    OUTPUT:
        RETVAL

SV *
ip_expand_address(ip, ipversion)
        char *ip
        int ipversion
    PREINIT:
        int  res;
        char buf[MAX_IPV6_STR_LEN];
    CODE:
        buf[0] = '\0';
        res = NI_ip_expand_address(ip, ipversion, buf);
        RETVAL = (res) ? newSVpv(buf, 0) : &PL_sv_undef;
    OUTPUT:
        RETVAL

SV *
ip_bincomp(begin, op_arg, end)
        char *begin
        char *op_arg
        char *end
    PREINIT:
        int res;
        int result;
    CODE:
        res = NI_ip_bincomp(begin, op_arg, end, &result);
        RETVAL = (res) ? newSViv(result) : &PL_sv_undef;
    OUTPUT:
        RETVAL

SV *
ip_get_mask(len, ipversion)
        int len
        int ipversion
    PREINIT:
        int res;
        char buf[128];
    CODE:
        res = NI_ip_get_mask(len, ipversion, buf);
        RETVAL = (res) ? newSVpv(buf, NI_iplengths(ipversion)) : &PL_sv_undef;
    OUTPUT:
        RETVAL

SV *
ip_last_address_bin(binip, len, ipversion)
        char *binip
        int len
        int ipversion
    PREINIT:
        char buf[128];
        int res;
    CODE:
        res = NI_ip_last_address_bin(binip, len, ipversion, buf);
        RETVAL = (res) ? newSVpv(buf, NI_iplengths(ipversion)) : &PL_sv_undef;
    OUTPUT:
        RETVAL

SV *
ip_get_version(ip)
        char *ip
    PREINIT:
        int res;
    CODE:
        res = NI_ip_get_version(ip);
        RETVAL = (res) ? newSViv(res) : &PL_sv_undef;
    OUTPUT:
        RETVAL

SV *
ip_inttobin_str(str, ipversion)
        char *str
        int ipversion
    PREINIT:
        char buf[129];
        int res;
    CODE:
        res = NI_ip_inttobin_str(str, ipversion, buf);
        RETVAL = (res) ? newSVpv(buf, 0) : &PL_sv_undef;
    OUTPUT:
        RETVAL

SV *
ip_bintoint_str(binip)
        char *binip
    PREINIT:
        char buf[MAX_IPV6_NUM_STR_LEN];
    CODE:
        NI_ip_bintoint_str(binip, buf);
        RETVAL = newSVpv(buf, 0);
    OUTPUT:
        RETVAL

SV *
ip_iplengths(ipversion)
        int ipversion
    PREINIT:
        int res;
    CODE:
        res = NI_iplengths(ipversion);
        RETVAL = (res) ? newSViv(res) : &PL_sv_undef;
    OUTPUT:
        RETVAL


SV *
ip_bintoip(ip, ipversion)
        char *ip
        int ipversion
    PREINIT:
        char buf[MAX_IPV6_STR_LEN];
        int res;
    CODE:
        buf[0] = '\0';
        res = NI_ip_bintoip(ip, ipversion, buf);
        RETVAL = (res) ? newSVpv(buf, 0) : &PL_sv_undef;
    OUTPUT:
        RETVAL

SV *
ip_iptobin(ip, ipversion)
        char *ip
        int ipversion
    PREINIT:
        char buf[128];
        int res;
    CODE:
        res = NI_ip_iptobin(ip, ipversion, buf);
        RETVAL = (res) ? newSVpv(buf, NI_iplengths(ipversion))
                       : &PL_sv_undef;
    OUTPUT:
        RETVAL

SV *
ip_is_overlap(b1, e1, b2, e2)
        char *b1
        char *e1
        char *b2
        char *e2
    PREINIT:
        int res;
        int result;
    CODE:
        res = NI_ip_is_overlap(b1, e1, b2, e2, &result);
        RETVAL = (res) ? newSViv(result) : &PL_sv_undef;
    OUTPUT:
        RETVAL

SV *
ip_check_prefix(ip, len, ipversion)
        char *ip
        int len
        int ipversion
    PREINIT:
        int res;
    CODE:
        res = NI_ip_check_prefix(ip, len, ipversion);
        RETVAL = (res) ? newSViv(res) : &PL_sv_undef;
    OUTPUT:
        RETVAL

void
ip_range_to_prefix(begin, end, ipversion)
        char *begin
        char *end
        int ipversion
    PREINIT:
        char *prefixes[MAX_PREFIXES];
        int pcount;
        int res;
        int i;
    PPCODE:
        pcount = 0;
        res = NI_ip_range_to_prefix(begin, end, ipversion, prefixes, &pcount);
        if (!res) {
            for (i = 0; i < pcount; i++) {
                free(prefixes[i]);
            }
            ST(0) = &PL_sv_undef;
        } else {
            for (i = 0; i < pcount; i++) {
                XPUSHs(sv_2mortal(newSVpv(prefixes[i], 0)));
                free(prefixes[i]);
            }
        }

SV *
ip_get_embedded_ipv4(ipv6)
        char *ipv6
    PREINIT:
        char buf[16];
        int res;
    CODE:
        res = NI_ip_get_embedded_ipv4(ipv6, buf);
        RETVAL = (res) ? newSVpv(buf, 0) : &PL_sv_undef;
    OUTPUT:
        RETVAL

SV *
ip_aggregate(b1, e1, b2, e2, ipversion)
        char *b1
        char *e1
        char *b2
        char *e2
        int ipversion
    PREINIT:
        char buf[MAX_IPV6_RANGE_STR_LEN];
        int res;
    CODE:
        res = NI_ip_aggregate(b1, e1, b2, e2, ipversion, buf);
        RETVAL = (res) ? newSVpv(buf, 0) : &PL_sv_undef;
    OUTPUT:
        RETVAL

void
ip_prefix_to_range(ip, len, version)
        char *ip
        int len
        int version
    PREINIT:
        char buf[MAX_IPV6_RANGE_STR_LEN];
        int res;
    PPCODE:
        res = NI_ip_prefix_to_range(ip, len, version, buf);
        if (res) {
            XPUSHs(sv_2mortal(newSVpv(ip, 0)));
            XPUSHs(sv_2mortal(newSVpv(buf, 0)));
        } else {
            ST(0) = &PL_sv_undef;
        }

SV *
ip_reverse(ip, len, ipversion)
        char *ip
        int len
        int ipversion
    PREINIT:
        char buf[MAX_IPV6_REVERSE_LEN];
        int res;
    CODE:
        buf[0] = '\0';
        res = NI_ip_reverse(ip, len, ipversion, buf);
        RETVAL = (res) ? newSVpv(buf, 0) : &PL_sv_undef;
    OUTPUT:
        RETVAL

void
ip_normalize(ip)
        char *ip
    PREINIT:
        char buf1[MAX_IPV6_STR_LEN];
        char buf2[MAX_IPV6_STR_LEN];
        int res;
    PPCODE:
        buf1[0] = '\0';
        buf2[0] = '\0';
        res = NI_ip_normalize(ip, buf1, buf2);
        if (res >= 1) {
            XPUSHs(sv_2mortal(newSVpv(buf1, 0)));
        }
        if (res >= 2) {
            XPUSHs(sv_2mortal(newSVpv(buf2, 0)));
        }

SV *
ip_normal_range(ip)
        char *ip
    PREINIT:
        char buf[MAX_IPV6_NORMAL_RANGE];
        int res;
    CODE:
        res = NI_ip_normal_range(ip, buf);
        RETVAL = (res) ? newSVpv(buf, 0) : &PL_sv_undef;
    OUTPUT:
        RETVAL

SV *
ip_compress_address(ip, version)
        char *ip
        int version
    PREINIT:
        char buf[MAX_IPV6_STR_LEN];
        int res;
    CODE:
        buf[0] = '\0';
        res = NI_ip_compress_address(ip, version, buf);
        RETVAL = (res) ? newSVpv(buf, 0) : &PL_sv_undef;
    OUTPUT:
        RETVAL

SV *
ip_compress_v4_prefix(ip, len)
        char *ip
        int len
    PREINIT:
        char buf[MAX_IPV4_RANGE_STR_LEN];
        int res;
    CODE:
        buf[0] = '\0';
        res = NI_ip_compress_v4_prefix(ip, len, buf,
                                       MAX_IPV4_RANGE_STR_LEN);
        RETVAL = (res) ? newSVpv(buf, 0) : &PL_sv_undef;
    OUTPUT:
        RETVAL

SV *
ip_iptype(ip, ipversion)
        char *ip
        int ipversion
    PREINIT:
        char buf[MAX_TYPE_STR_LEN];
        int res;
    CODE:
        res = NI_ip_iptype(ip, ipversion, buf);
        RETVAL = (res) ? newSVpv(buf, 0) : &PL_sv_undef;
    OUTPUT:
        RETVAL

SV *
new(package, data, ...)
        char *package
        char *data
    PREINIT:
        HV *stash;
        HV *hash;
        SV *ref;
        int res;
        int ipversion;
    CODE:
        ipversion = (items > 2) ? SvIV(ST(2)) : 0;
        hash  = newHV();
        ref   = newRV_noinc((SV*) hash);
        stash = gv_stashpv(package, 1);
        sv_bless(ref, stash);
        res = NI_set(ref, data, ipversion);
        if (!res) {
            SvREFCNT_dec(ref);
            RETVAL = &PL_sv_undef;
        } else {
            RETVAL = ref;
        }
    OUTPUT:
        RETVAL

SV *
print(self)
        SV *self
    PREINIT:
        char buf[MAX_IPV6_NORMAL_RANGE];
        int res;
    CODE:
        if (!sv_isa(self, "Net::IP::XS")) {
            RETVAL = &PL_sv_undef;
        } else {
            res = NI_print(self, buf, MAX_IPV6_NORMAL_RANGE);
            RETVAL = (res) ? newSVpv(buf, 0) : &PL_sv_undef;
        }
    OUTPUT:
        RETVAL

SV *
size_str(self)
        SV *self
    PREINIT:
        char buf[MAX_IPV6_NUM_STR_LEN];
        int res;
    CODE:
        if (!sv_isa(self, "Net::IP::XS")) {
            RETVAL = &PL_sv_undef;
        } else {
            res = NI_size_str(self, buf);
            RETVAL = (res) ? newSVpv(buf, 0) : &PL_sv_undef;
        }
    OUTPUT:
        RETVAL

SV *
intip_str(self)
        SV *self
    PREINIT:
        char buf[MAX_IPV6_NUM_STR_LEN];
        int res;
    CODE:
        if (!sv_isa(self, "Net::IP::XS")) {
            RETVAL = &PL_sv_undef;
        } else {
            res = NI_intip_str(self, buf, MAX_IPV6_NUM_STR_LEN);
            RETVAL = (res) ? newSVpv(buf, 0) : &PL_sv_undef;
        }
    OUTPUT:
        RETVAL

SV *
hexip(self)
        SV *self
    PREINIT:
        char buf[MAX_IPV6_HEXIP_STR_LEN];
        int res;
    CODE:
        if (!sv_isa(self, "Net::IP::XS")) {
            RETVAL = &PL_sv_undef;
        } else {
            res = NI_hexip(self, buf, MAX_IPV6_HEXIP_STR_LEN);
            RETVAL = (res) ? newSVpv(buf, 0) : &PL_sv_undef;
        }
    OUTPUT:
        RETVAL

SV *
hexmask(self)
        SV *self
    PREINIT:
        char buf[MAX_IPV6_HEXIP_STR_LEN];
        int res;
    CODE:
        if (!sv_isa(self, "Net::IP::XS")) {
            RETVAL = &PL_sv_undef;
        } else {
            res = NI_hexmask(self, buf, MAX_IPV6_HEXIP_STR_LEN);
            RETVAL = (res) ? newSVpv(buf, 0) : &PL_sv_undef;
        }
    OUTPUT:
        RETVAL

SV *
prefix(self)
        SV *self
    PREINIT:
        char buf[MAX_IPV6_RANGE_STR_LEN];
        int res;
    CODE:
        if (!sv_isa(self, "Net::IP::XS")) {
            RETVAL = &PL_sv_undef;
        } else {
            res = NI_prefix(self, buf, MAX_IPV6_RANGE_STR_LEN);
            RETVAL = (res) ? newSVpv(buf, 0) : &PL_sv_undef;
        }
    OUTPUT:
        RETVAL

SV *
mask(self)
        SV *self
    PREINIT:
        char buf[128];
        int res;
    CODE:
        if (!sv_isa(self, "Net::IP::XS")) {
            RETVAL = &PL_sv_undef;
        } else {
            res = NI_mask(self, buf, 128);
            RETVAL = (res) ? newSVpv(buf, 0) : &PL_sv_undef;
        }
    OUTPUT:
        RETVAL

SV *
iptype(self)
        SV *self
    PREINIT:
        char buf[MAX_TYPE_STR_LEN];
        int res;
    CODE:
        if (!sv_isa(self, "Net::IP::XS")) {
            RETVAL = &PL_sv_undef;
        } else {
            res = NI_iptype(self, buf, MAX_TYPE_STR_LEN);
            RETVAL = (res) ? newSVpv(buf, 0) : &PL_sv_undef;
        }
    OUTPUT:
        RETVAL

SV *
reverse_ip(self)
        SV *self
    PREINIT:
        char buf[MAX_IPV6_REVERSE_LEN];
        int res;
    CODE:
        if (!sv_isa(self, "Net::IP::XS")) {
            RETVAL = &PL_sv_undef;
        } else {
            buf[0] = '\0';
            res = NI_reverse_ip(self, buf);
            RETVAL = (res) ? newSVpv(buf, 0) : &PL_sv_undef;
        }
    OUTPUT:
        RETVAL

SV *
last_bin(self)
        SV *self
    PREINIT:
        char buf[IPV6_BITSTR_LEN];
        int res;
    CODE:
        if (!sv_isa(self, "Net::IP::XS")) {
            RETVAL = &PL_sv_undef;
        } else {
            buf[0] = '\0';
            res = NI_last_bin(self, buf, IPV6_BITSTR_LEN);
            RETVAL = (res) ? newSVpv(buf, 0) : &PL_sv_undef;
        }
    OUTPUT:
        RETVAL

SV *
last_int_str(self)
        SV *self
    PREINIT:
        char buf[MAX_IPV6_NUM_STR_LEN];
        int res;
    CODE:
        if (!sv_isa(self, "Net::IP::XS")) {
            RETVAL = &PL_sv_undef;
        } else {
            buf[0] = '\0';
            res = NI_last_int_str(self, buf, MAX_IPV6_NUM_STR_LEN);
            RETVAL = (res) ? newSVpv(buf, 0) : &PL_sv_undef;
        }
    OUTPUT:
        RETVAL

SV *
last_ip(self)
        SV *self
    PREINIT:
        char buf[MAX_IPV6_STR_LEN];
        int res;
    CODE:
        if (!sv_isa(self, "Net::IP::XS")) {
            RETVAL = &PL_sv_undef;
        } else {
            buf[0] = '\0';
            res = NI_last_ip(self, buf, MAX_IPV6_STR_LEN);
            RETVAL = (res) ? newSVpv(buf, 0) : &PL_sv_undef;
        }
    OUTPUT:
        RETVAL

SV *
short(self)
        SV *self
    PREINIT:
        char buf[MAX_IPV6_STR_LEN];
        int res;
    CODE:
        if (!sv_isa(self, "Net::IP::XS")) {
            RETVAL = &PL_sv_undef;
        } else {
            buf[0] = '\0';
            res = NI_short(self, buf);
            RETVAL = (res) ? newSVpv(buf, 0) : &PL_sv_undef;
        }
    OUTPUT:
        RETVAL

SV *
bincomp(self, op, other)
        SV *self
        char *op
        SV *other
    PREINIT:
        int res;
        int result;
    CODE:
        if (!sv_isa(self, "Net::IP::XS") || !sv_isa(other, "Net::IP::XS")) {
            RETVAL = &PL_sv_undef;
        } else {
            res = NI_bincomp(self, op, other, &result);
            RETVAL = (res) ? newSViv(result) : &PL_sv_undef;
        }
    OUTPUT:
        RETVAL

SV *
binadd(self, other)
        SV *self
        SV *other
    PREINIT:
        SV *new_ip;
    CODE:
        if (!sv_isa(self, "Net::IP::XS") || !sv_isa(other, "Net::IP::XS")) {
            RETVAL = &PL_sv_undef;
        } else {
            new_ip = NI_binadd(self, other);
            RETVAL = (new_ip) ? new_ip : &PL_sv_undef;
        }
    OUTPUT:
        RETVAL

SV *
aggregate(self, other)
        SV *self
        SV *other
    PREINIT:
        SV *new_ip;
    CODE:
        if (!sv_isa(self, "Net::IP::XS") || !sv_isa(other, "Net::IP::XS")) {
            RETVAL = &PL_sv_undef;
        } else {
            new_ip = NI_aggregate(self, other);
            RETVAL = (new_ip) ? new_ip : &PL_sv_undef;
        }
    OUTPUT:
        RETVAL

SV *
overlaps(self, other)
        SV *self
        SV *other
    PREINIT:
        int res;
        int result;
    CODE:
        if (!sv_isa(self, "Net::IP::XS") || !sv_isa(other, "Net::IP::XS")) {
            RETVAL = &PL_sv_undef;
        } else {
            res = NI_overlaps(self, other, &result);
            RETVAL = (res) ? newSViv(result) : &PL_sv_undef;
        }
    OUTPUT:
        RETVAL

void
find_prefixes(self)
        SV *self
    PREINIT:
        char *prefixes[MAX_PREFIXES];
        int pcount;
        int res;
        int i;
    PPCODE:
        if (!sv_isa(self, "Net::IP::XS")) {
            ST(0) = &PL_sv_undef;
        } else {
            pcount = 0;
            res = NI_find_prefixes(self, prefixes, &pcount);
            if (!res) {
                for (i = 0; i < pcount; i++) {
                    free(prefixes[i]);
                }
                ST(0) = &PL_sv_undef;
            } else {
                for (i = 0; i < pcount; i++) {
                    XPUSHs(sv_2mortal(newSVpv(prefixes[i], 0)));
                    free(prefixes[i]);
                }
            }
        }

SV *
ip_add_num(self, num, unused)
        SV *self
        char *num
        SV *unused
    PREINIT:
        SV *new_ip;
    CODE:
        if (!sv_isa(self, "Net::IP::XS")) {
            RETVAL = &PL_sv_undef;
        } else {
            new_ip = NI_ip_add_num(self, num);
            RETVAL = (new_ip) ? new_ip : &PL_sv_undef;
        }
    OUTPUT:
        RETVAL

SV *
set_ipv6_n128s(self)
        SV *self
    PREINIT:
        int res;
    CODE:
        if (!sv_isa(self, "Net::IP::XS")) {
            RETVAL = &PL_sv_undef;
        } else {
            res = NI_set_ipv6_n128s(self);
            RETVAL = (res) ? newSViv(1) : &PL_sv_undef;
        }
    OUTPUT:
        RETVAL
