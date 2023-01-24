/*
functions.h - Core functions for Net::IP::XS.

Copyright (C) 2010-2023 Tom Harrison <tomhrr@cpan.org>
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

#ifndef NETIP_FUNCTIONS
#define NETIP_FUNCTIONS

#include "limits.h"
#include "n128.h"

#ifdef __cplusplus
extern "C" {
#endif

#define STRTOL_FAILED(ret, str, end) \
    (((((ret) == LONG_MAX || ((ret) == LONG_MIN)) && (errno == ERANGE)) \
        || (((ret) == 0) && ((str) == (end)))))

#define STRTOUL_FAILED(ret, str, end) \
    (((((ret) == ULONG_MAX || ((ret) == 0)) && (errno == ERANGE)) \
        || (((ret) == 0) && ((str) == (end)))))

/* Comparator constants (less than, less than or equal to, etc.). */
#define LT 1
#define LE 2
#define GT 3
#define GE 4

/* Overlap constants. */
#define IP_NO_OVERLAP       0
#define IP_PARTIAL_OVERLAP  1
#define IP_A_IN_B_OVERLAP  -1
#define IP_B_IN_A_OVERLAP  -2
#define IP_IDENTICAL       -3

/* String length constants. */
#define MAX_IPV4_STR_LEN       16
#define MAX_IPV4_RANGE_STR_LEN 19
#define IPV4_BITSTR_LEN        33
#define MAX_IPV4_REVERSE_LEN   30 
#define MAX_IPV6_STR_LEN       64
#define MAX_IPV6_RANGE_STR_LEN 68
#define IPV6_BITSTR_LEN        129
#define MAX_IPV6_REVERSE_LEN   74
#define MAX_IPV6_NORMAL_RANGE  82
#define MAX_IPV6_HEXIP_STR_LEN 35

#define MAX_TYPE_STR_LEN       256
#define MAX_PREFIXES           128
#define MAX_IPV6_NUM_STR_LEN   40

const char    *NI_hv_get_pv(SV *object, const char *key, int keylen);
int            NI_hv_get_iv(SV *object, const char *key, int keylen);
unsigned int   NI_hv_get_uv(SV *object, const char *key, int keylen);

void           NI_set_Errno(int Errno);
int            NI_get_Errno(void);
void           NI_set_Error(const char *Error);
const char    *NI_get_Error(void);
void           NI_set_Error_Errno(int Errno, const char *Error, ...);

int            NI_hdtoi(char c);
int            NI_trailing_zeroes(unsigned long n);
unsigned long  NI_bintoint(const char *bitstr, int len);
unsigned long  NI_ip_uchars_to_ulong(unsigned char uchars[4]);
void           NI_ip_uchars_to_n128(unsigned char uchars[16], n128_t *num);

int            NI_iplengths(int version);

void           NI_ip_n128tobin(n128_t *num, int len, char *buf);
void           NI_ip_binton128(const char *bitstr, int len, n128_t *num);

int            NI_ip_inttobin_str(const char *ip_int_str, 
                                  int version, char *buf);
int            NI_ip_bintoint_str(const char *bitstr, char *buf);

int            NI_ip_is_ipv4(const char *str);
int            NI_ip_is_ipv6(const char *str);
int            NI_ip_get_version(const char *str);
int            NI_ip_get_mask(int len, int version, char *buf);

int            NI_ip_last_address_ipv6(n128_t *ip, int len, n128_t *buf);
unsigned long  NI_ip_last_address_ipv4(unsigned long ip, int len);
int            NI_ip_last_address_bin(const char *bitstr, int len, 
                                      int version, char *buf);

int            NI_ip_bincomp(const char *bitstr_1, const char *op_str, 
                             const char *bitstr_2, int *result);

void           NI_ip_is_overlap_ipv6(n128_t *begin_1, n128_t *end_1,
                                     n128_t *begin_2, n128_t *end_2, int *result);
void           NI_ip_is_overlap_ipv4(unsigned long begin_1, 
                                     unsigned long end_1,
                                     unsigned long begin_2, 
                                     unsigned long end_2,
                                     int *result);
int            NI_ip_is_overlap(const char *begin_1, const char *end_1,
                                const char *begin_2, const char *end_2, 
                                int *result);

int            NI_ip_check_prefix_ipv6(n128_t *ip, int len);
int            NI_ip_check_prefix_ipv4(unsigned long ip, int len);
int            NI_ip_check_prefix(const char *bitstr, int len, int version);

void           NI_ip_get_prefix_length_ipv6(n128_t *n128_1, n128_t *n128_2, 
                                            int bits, int *len);
void           NI_ip_get_prefix_length_ipv4(unsigned long begin, 
                                            unsigned long end,
                                            int bits, int *len);
int            NI_ip_get_prefix_length(const char *bitstr_1, 
                                       const char *bitstr_2, 
                                       int *len);

void           NI_ip_inttoip_ipv6(unsigned long n1, unsigned long n2, 
                                  unsigned long n3, unsigned long n4, 
                                  char *buf);
void           NI_ip_inttoip_ipv4(unsigned long n, char *buf);
void           NI_ip_inttoip_n128(n128_t *ip, char *buf);
int            NI_ip_bintoip(const char *bitstr, int version, char *buf);

int            NI_ip_binadd(const char *first, const char *second, 
                            char *buf, int maxlen);

int            NI_ip_range_to_prefix_ipv6(n128_t *begin, n128_t *end,
                                          int version, char **prefixes, 
                                          int *pcount);
int            NI_ip_range_to_prefix_ipv4(unsigned long begin, 
                                          unsigned long end,
                                          int version, char **prefixes, 
                                          int *pcount);
int            NI_ip_range_to_prefix(const char *bitstr_1, 
                                     const char *bitstr_2,
                                     int version, char **prefixes, 
                                     int *pcount);

int            NI_ip_aggregate_tail(int res, char **prefixes, int pcount,
                                    int version, char *buf);
int            NI_ip_aggregate_ipv6(n128_t *b1, n128_t *e1, n128_t *b2, n128_t *e2,
                                    int ipversion, char *buf);
int            NI_ip_aggregate_ipv4(unsigned long b1, unsigned long e1,
                                    unsigned long b2, unsigned long e2,
                                    int ipversion, char *buf);
int            NI_ip_aggregate(const char *b1, const char *e1, 
                               const char *b2, const char *e2,
                               int ipversion, char *buf);

int            NI_ip_iptobin(const char *ip, int ipversion, char *buf);

int            NI_ip_expand_address_ipv6(const char *ip, char *retbuf);
int            NI_ip_expand_address_ipv4(const char *ip, char *buf);
int            NI_ip_expand_address(const char *ip, int version, char *buf);

int            NI_ip_reverse_ipv6(const char *ip, int len, char *buf);
int            NI_ip_reverse_ipv4(const char *ip, int len, char *buf);
int            NI_ip_reverse(const char *ip, int len, int ipversion, char *buf);

int            NI_ip_normalize_prefix_ipv6(n128_t *ip, char *slash,
                                           char *ip1buf, char *ip2buf);
int            NI_ip_normalize_prefix_ipv4(unsigned long ip, char *slash,
                                           char *ip1buf, char *ip2buf);
int            NI_ip_normalize_prefix(char *ip, char *ip1buf, char *ip2buf);

int            NI_ip_tokenize_on_char(char *str, char separator,
                                      char **end_first, char **second);
int            NI_ip_normalize_plus_ipv6(char *ip, char *num,
                                         char *ipbuf1, char *ipbuf2);
int            NI_ip_normalize_plus_ipv4(char *ip, char *num,
                                         char *ipbuf1, char *ipbuf2);
int            NI_ip_normalize_range(char *ip, char *ipbuf1, char *ipbuf2);

int            NI_ip_normalize_plus(char *ip1, char *ipbuf1, char *ipbuf2);

int            NI_ip_normalize_bare(char *ip, char *ipbuf1);

int            NI_ip_normalize(char *ip, char *ipbuf1, char *ipbuf2);

int            NI_ip_normal_range(char *ip, char *buf);

int            NI_ip_compress_v4_prefix(const char *ip, int len, 
                                        char *buf, int maxlen);
int            NI_ip_compress_address(const char *ip, int version, char *buf);

int            NI_ip_splitprefix(const char *prefix, char *ipbuf, int *lenbuf);
int            NI_ip_iptype(const char *ip, int version, char *buf);
int            NI_ip_is_valid_mask(const char *mask, int version);
int            NI_ip_prefix_to_range(const char *ip, int len, int version, 
                                     char *buf);
int            NI_ip_get_embedded_ipv4(const char *ipv6, char *buf);

#ifdef __cplusplus
}
#endif

#endif
