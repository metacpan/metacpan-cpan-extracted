/*
n128.h - 128-bit integer.

Copyright (C) 2012-2014 Tom Harrison <tomhrr@cpan.org>
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

#ifndef N128
#define N128

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct n128 { uint32_t nums[4]; } n128_t;
void n128_print_bin(n128_t *n, char *buf, int ui_only);
void n128_set(n128_t *dst, n128_t *src);
int n128_scan1(n128_t *n);
int n128_scan0(n128_t *n);
int n128_add(n128_t *a, n128_t *b);
int n128_add_ui(n128_t *a, unsigned int ui);
int n128_set_str_decimal(n128_t *n, const char *str, int len);
void n128_set_str_binary(n128_t *n, const char *bitstr, int len);
void n128_ior(n128_t *n1, n128_t *n2);
void n128_xor(n128_t *n1, n128_t *n2);
void n128_and(n128_t *n1, n128_t *n2);
void n128_com(n128_t *n1);
int n128_cmp(n128_t *n1, n128_t *n2);
void n128_clrbit(n128_t *n, int bit);
void n128_setbit(n128_t *n, int bit);
int n128_tstbit(n128_t *n, int bit);
int n128_sub(n128_t *n, n128_t *sub);
void n128_brsft(n128_t *n, int sft);
void n128_blsft(n128_t *n, int sft);
int n128_cmp_ui(n128_t *n, unsigned int ui);
void n128_set_ui(n128_t *n, unsigned int ui);
void n128_print_hex(n128_t *n, char *buf);
void n128_print_dec(n128_t *narg, char *buf);

#ifdef __cplusplus
}
#endif

#endif
