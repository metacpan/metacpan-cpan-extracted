/*
object.h - Functions for Net::IP::XS's object-oriented interface.

Copyright (C) 2010-2018 Tom Harrison <tomhrr@cpan.org>
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

#ifndef NETIP_OBJECT
#define NETIP_OBJECT

#ifdef __cplusplus
extern "C" {
#endif

#include "limits.h"

void NI_object_set_Error_Errno(SV *ipo, int Errno, char *Error, ...);
void NI_copy_Error_Errno(SV *ipo);

int  NI_find_prefixes(SV *ipo, char **prefixes, int *pcount);

int  NI_set_ipv6_n128s(SV *ipo);
int  NI_set(SV* ip, char *data, int ipversion);

int  NI_get_begin_n128(SV *ipo, n128_t **begin);
int  NI_get_end_n128(SV *ipo, n128_t **end);
int  NI_get_n128s(SV *ipo, n128_t **begin, n128_t **end);

int  NI_short(SV *ipo, char *buf);
int  NI_print(SV *ipo, char *buf, int maxlen);

int  NI_last_ip(SV *ipo, char *buf, int maxlen);

int  NI_size_str_ipv4(SV *ipo, char *buf);
int  NI_size_str_ipv6(SV *ipo, char *buf);
int  NI_size_str(SV *ipo, char *size);

int  NI_intip_str_ipv4(SV *ipo, char *buf);
int  NI_intip_str_ipv6(SV *ipo, char *buf);
int  NI_intip_str(SV *ipo, char *buf, int maxlen);

int  NI_hexip_ipv4(SV *ipo, char *buf);
int  NI_hexip_ipv6(SV *ipo, char *hexip);
int  NI_hexip(SV *ipo, char *buf, int maxlen);

int  NI_hexmask(SV *ipo, char *buf, int maxlen);

int  NI_prefix(SV *ipo, char *buf, int maxlen);

int  NI_mask(SV *ipo, char *buf, int maxlen);

int  NI_iptype(SV *ipo, char *buf, int maxlen);

int  NI_reverse_ip(SV *ipo, char *buf);

int  NI_last_bin(SV *ipo, char *buf, int maxlen);

int  NI_last_int_str_ipv4(SV *ipo, char *buf);
int  NI_last_int_str_ipv6(SV *ipo, char *buf);
int  NI_last_int_str(SV *ipo, char *buf, int maxlen);

int  NI_bincomp(SV *ipo1, char *op, SV *ipo2, int *resbuf);

int  NI_overlaps_ipv4(SV *ipo1, SV* ipo2, int *buf);
int  NI_overlaps_ipv6(SV *ipo1, SV* ipo2, int *buf);
int  NI_overlaps(SV *ipo1, SV* ipo2, int *buf);

SV *NI_binadd(SV *ipo1, SV *ipo2);

SV *NI_aggregate_ipv4(SV *ipo1, SV *ipo2);
SV *NI_aggregate_ipv6(SV *ipo1, SV *ipo2);
SV *NI_aggregate(SV *ipo1, SV *ipo2);

int NI_ip_add_num_ipv4(SV *ipo, unsigned long num, char *buf);
int NI_ip_add_num_ipv6(SV *ipo, n128_t *num, char *buf);
SV *NI_ip_add_num(SV *ipo, const char *num);

#ifdef __cplusplus
}
#endif

#endif
