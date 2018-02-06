/*
functions.c - Core functions for Net::IP::XS.

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

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "functions.h"
#include "inet_pton.h"

#ifdef __cplusplus
extern "C" {
#endif

/* Global error string and error number (tied to $Net::IP::XS::ERROR
 * and $Net::IP::XS::ERRNO). */
static char netip_Error[512];
static int  netip_Errno;

/**
 * NI_hv_get_pv(): get string value from hashref.
 * @object: reference to a hashref.
 * @key: hashref key as a string.
 * @keylen: the length of the hashref key.
 *
 * Returns a pointer to the beginning of the string to which @key is
 * mapped in the hashref. If @key does not exist in the hashref,
 * returns 0.
 */
const char*
NI_hv_get_pv(SV *object, const char *key, int keylen)
{
    SV **ref;

    ref = hv_fetch((HV*) SvRV(object), key, keylen, 0);
    if (!ref) {
        return NULL;
    }
    return SvPV(*ref, PL_na);
}

/**
 * NI_hv_get_iv(): get integer value from hashref.
 * @object: reference to a hashref.
 * @key: hashref key as a string.
 * @keylen: the length of the hashref key.
 *
 * Returns the integer to which @key is mapped in the hashref.  If
 * @key does not exist in the hashref, returns 0.
 */
int
NI_hv_get_iv(SV *object, const char *key, int keylen)
{
    SV **ref;

    ref = hv_fetch((HV*) SvRV(object), key, keylen, 0);
    if (!ref) {
        return -1;
    }
    return SvIV(*ref);
}

/**
 * NI_hv_get_uv(): get unsigned integer value from hashref.
 * @object: reference to a hashref.
 * @key: hashref key as a string.
 * @keylen: the length of the hashref key.
 *
 * Returns the unsigned integer to which @key is mapped in the
 * hashref. If @key does not exist in the hashref, returns 0.
 */
unsigned int
NI_hv_get_uv(SV *object, const char *key, int keylen)
{
    SV **ref;

    ref = hv_fetch((HV*) SvRV(object), key, keylen, 0);
    if (!ref) {
        return -1;
    }
    return SvUV(*ref);
}

/**
 * NI_set_Errno() - set the global error number.
 * @Errno: the new error number.
 */
void
NI_set_Errno(int Errno)
{
    netip_Errno = Errno;
}

/**
 * NI_get_Errno() - get the global error number.
 */
int
NI_get_Errno(void)
{
    return netip_Errno;
}

/**
 * NI_set_Error() - set the global error string.
 * @Error: the new error string.
 *
 * If the error string is more than 512 characters in length
 * (including the ending null), only the first 511 characters will be
 * used (with a null as the 512th character).
 */
void
NI_set_Error(const char *Error)
{
    int len;

    len = strlen(Error);
    if (len > 511) {
        len = 511;
    }
    memcpy(netip_Error, Error, len);
    netip_Error[len] = '\0';
}

/**
 * NI_get_Error() - get the global error string.
 */
const char*
NI_get_Error(void)
{
    return (const char *) netip_Error;
}

/**
 * NI_set_Error_Errno() - set the global error number and string.
 * @Errno: the new error number.
 * @Error: the new error string (can include printf modifiers).
 * @...: format arguments to substitute into @Error.
 */
void
NI_set_Error_Errno(int Errno, const char *Error, ...)
{
    va_list args;

    va_start(args, Error);
    vsnprintf(netip_Error, 512, Error, args);
    netip_Error[511] = '\0';
    netip_Errno = Errno;
    va_end(args);
}

/**
 * NI_ip_uchars_to_n128(): make N128 integer from array of chars.
 * @uchars: array of at least 16 unsigned chars.
 * @buf: N128 integer buffer.
 */
void
NI_ip_uchars_to_n128(unsigned char uchars[16], n128_t *num)
{
    int i;
    int j;
    unsigned long k;

    for (i = 0; i < 4; i++) {
        j = i * 4;
        k = (  (uchars[j + 3])
             | (uchars[j + 2] << 8)
             | (uchars[j + 1] << 16)
             | (uchars[j]     << 24));
        num->nums[i] = k;
    }
}

/**
 * NI_ip_uchars_to_ulong(): get whole integer from array of chars.
 * @uchars: array of at least 4 unsigned chars.
 */
unsigned long
NI_ip_uchars_to_ulong(unsigned char uchars[4])
{
    return
        (uchars[3]
      | (uchars[2] << 8)
      | (uchars[1] << 16)
      | (uchars[0] << 24));
}

/**
 * NI_hdtoi(): convert hexadecimal character to integer.
 * @c: hexadecimal character.
 *
 * Returns -1 when the character is not a valid hexadecimal character.
 */
int
NI_hdtoi(char c)
{
    c = tolower(c);

    return
        (isdigit(c))               ? c - '0'
      : ((c >= 'a') && (c <= 'f')) ? 10 + (c - 'a')
                                   : -1;
}

/**
 * NI_trailing_zeroes(): get trailing zeroes from number treated as binary.
 * @n: the number.
 */
int
NI_trailing_zeroes(unsigned long n)
{
    int c;

    if (!n) {
        return CHAR_BIT * sizeof(n);
    }

    n = (n ^ (n - 1)) >> 1;
    for (c = 0; n; c++) {
        n >>= 1;
    }

    return c;
}

/**
 * NI_bintoint(): convert bitstring to integer.
 * @bitstr: the bitstring.
 * @len: the number of characters to use from the bitstring.
 */
unsigned long
NI_bintoint(const char *bitstr, int len)
{
    unsigned long res;
    int i;
    int help;

    res  = 0;
    help = len - 1;

    for (i = 0; i < len; i++) {
        res += (((unsigned long) (bitstr[i] == '1')) << (help - i));
    }

    return res;
}

/**
 * NI_bintoint_nonzero(): convert bitstring to integer.
 * @bitstr: the bitstring.
 * @len: the number of characters to use from the bitstring.
 *
 * This function treats all non-zero characters in the bitstring as 
 * if they were '1', whereas NI_bintoint() treats all non-one
 * characters as if they were '0'.
 */
unsigned long
NI_bintoint_nonzero(const char *bitstr, int len)
{
    unsigned long res;
    int i;
    int help;

    res  = 0;
    help = len - 1;

    for (i = 0; i < len; i++) {
        res += (((unsigned long) (bitstr[i] != '0')) << (help - i));
    }

    return res;
}

/**
 * NI_iplengths() - return length in bits of the version of IP address.
 * @version: IP version as integer (either 4 or 6).
 *
 * Returns 0 if @version is an invalid value.
 */
int
NI_iplengths(int version)
{
    switch (version) {
        case 4:  return 32;
        case 6:  return 128;
        default: return 0;
    };
}

/**
 * NI_ip_n128tobin(): make bitstring from N128 integer.
 * @num: N128 integer.
 * @len: the number of bits to write to the buffer.
 * @buf: the bitstring buffer.
 *
 * This does not null-terminate the buffer.
 */
void
NI_ip_n128tobin(n128_t *num, int len, char *buf)
{
    int i;

    if (len == 0) {
        return;
    }

    for (i = 0; i < len; i++) {
        buf[len - 1 - i] = (n128_tstbit(num, i) ? '1' : '0');
    }
}

/**
 * NI_ip_inttobin_str() - make bitstring from IP address integer.
 * @ip_int_str: the IP address integer as a string.
 * @version: the IP address version.
 * @buf: the bitstring buffer.
 *
 * Returns 1 if the buffer is able to be populated properly. Returns 0
 * if the IP version is invalid. This function null-terminates the
 * buffer. The buffer must have at least 129 characters' capacity.
 */
int
NI_ip_inttobin_str(const char *ip_int_str, int version, char *buf)
{
    n128_t num;
    int i;
    int len;
    int res;

    if (!version) {
        NI_set_Error_Errno(101, "Cannot determine IP "
                                "version for %s", ip_int_str);
        return 0;
    }

    len = strlen(ip_int_str);
    for (i = 0; i < len; i++) {
        if (!isdigit(ip_int_str[i])) {
            memset(buf, '0', (version == 4) ? 32 : 128);
            buf[(version == 4) ? 32 : 128] = '\0';
            return 1;
        }
    }

    n128_set_ui(&num, 0);
    res = n128_set_str_decimal(&num, ip_int_str, strlen(ip_int_str));
    if (!res) {
        return 0;
    }

    n128_print_bin(&num, buf, (version == 4));

    return 1;
}

/**
 * NI_ip_bintoint_str(): convert bitstring to integer string.
 * @bitstr: the bitstring.
 * @buf: the integer string buffer.
 */
int
NI_ip_bintoint_str(const char *bitstr, char *buf)
{
    unsigned long num_ulong;
    n128_t num_n128;
    int len;

    len = strlen(bitstr);

    if (len <= 32) {
        num_ulong = NI_bintoint_nonzero(bitstr, len);
        sprintf(buf, "%lu", num_ulong);
        return 1;
    }

    n128_set_ui(&num_n128, 0);

    n128_set_str_binary(&num_n128, bitstr, len);
    n128_print_dec(&num_n128, buf);

    return 1;
}

/**
 * NI_ip_is_ipv4(): check whether string is an IPv4 address.
 * @str: IP address string (null-terminated).
 */
int
NI_ip_is_ipv4(const char *str)
{
    int i;
    int len;
    int quads = 0;
    int quadspots[3];
    long current_quad;
    int cq_index;
    char *endptr;

    len = strlen(str);
    if (!len) {
        NI_set_Error_Errno(107, "Invalid chars in IP ");
        return 0;
    }

    /* Contains invalid characters. */

    for (i = 0; i < len; i++) {
        if (!isdigit(str[i]) && str[i] != '.') {
            NI_set_Error_Errno(107, "Invalid chars in IP %s", str);
            return 0;
        }
    }

    /* Starts or ends with '.'. */

    if (str[0] == '.') {
        NI_set_Error_Errno(103, "Invalid IP %s - starts with a dot", str);
        return 0;
    }

    if (str[len - 1] == '.') {
        NI_set_Error_Errno(104, "Invalid IP %s - ends with a dot", str);
        return 0;
    }

    /* Contains more than four quads (octets). */
    
    for (i = 0; i < len; i++) {
        if (str[i] == '.') {
            if (quads == 3) {
                NI_set_Error_Errno(105, "Invalid IP address %s", str);
                return 0;
            }
            quadspots[quads] = i + 1;
            quads++;
        }
    }

    /* Contains an empty quad. */

    for (i = 0; i < (len - 1); i++) {
        if ((str[i] == '.') && (str[i + 1] == '.')) {
            NI_set_Error_Errno(106, "Empty quad in IP address %s", str);
            return 0;
        }
    }

    /* Contains an invalid quad value. */

    for (cq_index = 0; cq_index <= quads; cq_index++) {
        i = (cq_index > 0) ? (quadspots[cq_index - 1]) : 0;

        endptr = NULL;

        current_quad = strtol(str + i, &endptr, 10);
        if (STRTOL_FAILED(current_quad, str + i, endptr)
                || (!(current_quad >= 0 && current_quad < 256))) {
            NI_set_Error_Errno(107, "Invalid quad in IP address "
                                    "%s - %d", str, current_quad);
            return 0;
        }
    }

    return 1;
}

/**
 * NI_ip_is_ipv6(): check whether string is an IPv6 address.
 * @str: the IP address string.
 */
int
NI_ip_is_ipv6(const char *str)
{
    int i;
    int len;
    int octs = 0;
    int octspots[8];
    int oct_index;
    const char *double_colon;
    const char *next_oct;
    const char *cc;
    int count;
    int is_hd;
    int max_colons;

    len = strlen(str);

    double_colon = strstr(str, "::");
    max_colons = (double_colon == NULL) ? 7 : 8;

    /* Store a pointer to the next character after each ':' in
     * octspots. */

    for (i = 0; i < len; i++) {
        if (str[i] == ':') {
            if (octs == max_colons) {
                return 0;
            }
            octspots[octs++] = i + 1;
        }
    }

    if (!octs) {
        return 0;
    }

    for (oct_index = 0; oct_index <= octs; oct_index++) {
        i = (oct_index > 0) ? (octspots[oct_index - 1]) : 0;

        /* Empty octet. */

        if (str[i] == ':') {
            continue;
        }
        if (strlen(str + i) == 0) {
            continue;
        }

        /* Last octet can be an IPv4 address. */

        cc = str + i;
        if ((oct_index == octs) && NI_ip_is_ipv4(cc)) {
            continue;
        }

        /* 1-4 hex digits. */

        next_oct = strchr(str + i, ':');
        if (next_oct == NULL) {
            next_oct = (str + len);
        }

        count = next_oct - cc;
        is_hd = 1;

        while (cc != next_oct) {
            if (!isxdigit(*cc)) {
                is_hd = 0;
                break;
            }
            cc++;
        }

        if (is_hd && (count <= 4)) {
            continue;
        }

        NI_set_Error_Errno(108, "Invalid IP address %s", str);
        return 0;
    }

    /* Starts or ends with ':'. */

    if ((str[0] == ':') && (str[1] != ':')) {
        NI_set_Error_Errno(109, "Invalid address %s "
                                "(starts with :)", str);
        return 0;
    }

    if ((str[len - 1] == ':') && (str[len - 2] != ':')) {
        NI_set_Error_Errno(110, "Invalid address %s "
                                "(ends with :)", str);
        return 0;
    }

    /* Contains more than one '::'. */

    if ((double_colon != NULL) && (strstr(double_colon + 1, "::"))) {
        NI_set_Error_Errno(111, "Invalid address %s "
                                "(More than one :: pattern)", str);
        return 0;
    }

    /* Doesn't contain '::', though it has fewer than eight segments. */

    if ((octs != 7) && (double_colon == NULL)) {
        NI_set_Error_Errno(112, "Invalid number of octets %s",  str);
        return 0;
    }

    return 1;
}

/**
 * NI_ip_get_version(): return the version of the IP address string.
 * @str: the IP address string.
 *
 * Returns 0 if the string is neither an IPv4 nor an IPv6 address
 * string.
 */
int
NI_ip_get_version(const char *str)
{
    if ((!strchr(str, ':')) && NI_ip_is_ipv4(str)) {
        return 4;
    } else if (NI_ip_is_ipv6(str)) {
        return 6;
    } else {
        return 0;
    }
}

/**
 * NI_ip_get_mask(): make bitstring network mask.
 * @len: the mask's prefix length.
 * @version: the mask's IP address version.
 * @buf: the bitstring mask buffer.
 *
 * If @len is larger than the number of bits for an IP address of the
 * specified version, then @len is set to equal that number of bits.
 * So if 48 were specified for @len for an IPv4 address, it would be
 * set to 32. This function does not null-terminate the buffer. The
 * buffer must have 32 or 128 characters' capacity for IPv4 and IPv6
 * respectively.
 */
int
NI_ip_get_mask(int len, int version, char *buf)
{
    int size;

    if (!version) {
        NI_set_Error_Errno(101, "Cannot determine IP version");
        return 0;
    }

    size = NI_iplengths(version);

    if (len < 0) {
        len = 0;
    } else if (len > size) {
        len = size;
    }

    memset(buf, '1', len);
    memset(buf + len, '0', (size - len));

    return 1;
}

/**
 * NI_ip_last_address_ipv6(): get last address of prefix.
 * @ip: the beginning IP address.
 * @len: the prefix length.
 * @buf: N128 integer buffer for the last address.
 */
int
NI_ip_last_address_ipv6(n128_t *ip, int len, n128_t *buf)
{
    int i;

    memcpy(buf, ip, sizeof(*ip));

    len = (len == 0) ? 128 : (128 - len);

    for (i = 0; i < len; i++) {
        n128_setbit(buf, i);
    }

    return 1;
}

/**
 * NI_ip_last_address_ipv4(): get last address of prefix.
 * @ip: the beginning IP address.
 * @len: the prefix length.
 */
unsigned long
NI_ip_last_address_ipv4(unsigned long ip, int len)
{
    unsigned long mask;

    mask = (len == 0) ? 0xFFFFFFFF : ((1 << (32 - len)) - 1);
    return ip | mask;
}

/**
 * NI_ip_last_address_bin(): make last address of prefix as a bitstring.
 * @bitstr: the beginning IP address as a bitstring.
 * @len: the prefix length.
 * @version: the IP address version.
 * @buf: the last address bitstring buffer.
 *
 * This function does not null-terminate the buffer. The buffer must
 * have 32 or 128 characters' capacity for IPv4 and IPv6 respectively.
 */
int
NI_ip_last_address_bin(const char *bitstr, int len, int version, char *buf)
{
    int size;

    if (!version) {
        NI_set_Error_Errno(101, "Cannot determine IP version");
        return 0;
    }

    size = NI_iplengths(version);

    if ((len < 0) || (len > size)) {
        len = size;
    }

    strncpy(buf, bitstr, len);
    memset(buf + len, '1', (size - len));

    return 1;
}

/**
 * NI_ip_bincomp(): compare two bitstrings.
 * @bitstr_1: first bitstring.
 * @op_str: the comparator as a string.
 * @bitstr_2: second bitstring.
 * @result: a pointer to an integer.
 *
 * The bitstrings and the comparator must be null-terminated. The
 * comparator must be one of 'gt', 'ge', 'lt', and 'le'. 'gt' means
 * 'greater than', 'ge' means 'greater than or equal to', 'lt' means
 * 'less than', 'le' means 'less than or equal to'. Returns 1 or 0
 * depending on whether the strings were able to be compared
 * successfully. If the comparison was able to be made, the result of
 * the comparison is stored in @result. This function will not compare
 * two bitstrings of different lengths.
 */
int
NI_ip_bincomp(const char *bitstr_1, const char *op_str, 
              const char *bitstr_2, int *result)
{
    const char *b;
    const char *e;
    int op;
    int res;

    op = (!strcmp(op_str, "gt")) ? GT
       : (!strcmp(op_str, "lt")) ? LT
       : (!strcmp(op_str, "le")) ? LE
       : (!strcmp(op_str, "ge")) ? GE
                                 : 0;

    if (!op) {
        NI_set_Error_Errno(131, "Invalid Operator %s", op_str);
        return 0;
    }

    if ((op == GT) || (op == GE)) {
        b = bitstr_1;
        e = bitstr_2;
    } else {
        b = bitstr_2;
        e = bitstr_1;
    }

    if (strlen(b) != (strlen(e))) {
        NI_set_Error_Errno(130, "IP addresses of different length");
        return 0;
    }

    res = strcmp(b, e);

    *result =
        (!res && ((op == GE) || (op == LE)))
            ? 1
            : (res > 0);

    return 1;
}

/**
 * NI_ip_is_overlap_ipv6(): get overlap status of two ranges.
 * @begin_1: beginning address of first range.
 * @end_1: ending address of first range.
 * @begin_2: beginning address of second range.
 * @end_2: ending address of second range.
 * @result: a pointer to an integer.
 */
void
NI_ip_is_overlap_ipv6(n128_t *begin_1, n128_t *end_1,
                      n128_t *begin_2, n128_t *end_2, int *result)
{
    int res;

    if (!n128_cmp(begin_1, begin_2)) {
        if (!n128_cmp(end_1, end_2)) {
            *result = IP_IDENTICAL;
            return;
        }
        res = n128_cmp(end_1, end_2);
        *result = (res < 0) ? IP_A_IN_B_OVERLAP
                            : IP_B_IN_A_OVERLAP;
        return;
    }

    if (!n128_cmp(end_1, end_2)) {
        res = n128_cmp(begin_1, begin_2);
        *result = (res < 0) ? IP_B_IN_A_OVERLAP
                            : IP_A_IN_B_OVERLAP;
        return;
    }

    res = n128_cmp(begin_1, begin_2);
    if (res < 0) {
        res = n128_cmp(end_1, begin_2);
        if (res < 0) {
            *result = IP_NO_OVERLAP;
            return;
        }
        res = n128_cmp(end_1, end_2);
        *result = (res < 0) ? IP_PARTIAL_OVERLAP
                            : IP_B_IN_A_OVERLAP;
        return;
    }

    res = n128_cmp(end_2, begin_1);
    if (res < 0) {
        *result = IP_NO_OVERLAP;
        return;
    }

    res = n128_cmp(end_2, end_1);
    *result = (res < 0) ? IP_PARTIAL_OVERLAP
                        : IP_A_IN_B_OVERLAP;

    return;
}

/**
 * NI_ip_is_overlap_ipv4(): get overlap status of two ranges.
 * @begin_1: beginning address of first range.
 * @end_1: ending address of first range.
 * @begin_2: beginning address of second range.
 * @end_2: ending address of second range.
 * @result: a pointer to an integer.
 */
void
NI_ip_is_overlap_ipv4(unsigned long begin_1, unsigned long end_1,
                       unsigned long begin_2, unsigned long end_2,
                       int *result)
{
    if (begin_1 == begin_2) {
        if (end_1 == end_2) {
            *result = IP_IDENTICAL;
            return;
        }
        *result =
            (end_1 < end_2)
                ? IP_A_IN_B_OVERLAP
                : IP_B_IN_A_OVERLAP;
        return;
    }

    if (end_1 == end_2) {
        *result =
            (begin_1 < begin_2)
                ? IP_B_IN_A_OVERLAP
                : IP_A_IN_B_OVERLAP;
        return;
    }

    if (begin_1 < begin_2) {
        if (end_1 < begin_2) {
            *result = IP_NO_OVERLAP;
            return;
        }
        *result =
            (end_1 < end_2)
                ? IP_PARTIAL_OVERLAP
                : IP_B_IN_A_OVERLAP;
        return;
    }

    if (end_2 < begin_1) {
        *result = IP_NO_OVERLAP;
        return;
    }

    *result =
        (end_2 < end_1)
            ? IP_PARTIAL_OVERLAP
            : IP_A_IN_B_OVERLAP;

    return;
}

/**
 * NI_ip_is_overlap(): get overlap status of two ranges.
 * @begin_1: beginning bitstring IP address for first range.
 * @end_1: ending bitstring IP address for first range.
 * @begin_2: beginning bitstring IP address for second range.
 * @end_2: ending bitstring IP address for second range.
 * @result: a pointer to an integer.
 *
 * Each bitstring must be null-terminated.  Returns 1 or 0 depending
 * on whether the ranges are able to be compared successfully. If the
 * overlap status is able to be determined, stores that status in
 * @result. Returns 0 if the bitstrings are not all of equal length.
 * The possible overlap statuses are NO_OVERLAP, IP_PARTIAL_OVERLAP,
 * IP_A_IN_B_OVERLAP (first range completely contained within second
 * range), IP_B_IN_A_OVERLAP (second range completely contained within
 * first range) and IP_IDENTICAL.
 */
int
NI_ip_is_overlap(const char *begin_1, const char *end_1,
                 const char *begin_2, const char *end_2, int *result)
{
    int b1_len;
    int b2_len;
    int res = 0;
    n128_t begin_1_n128;
    n128_t end_1_n128;
    n128_t begin_2_n128;
    n128_t end_2_n128;
    unsigned long begin_1_ulong;
    unsigned long begin_2_ulong;
    unsigned long end_1_ulong;
    unsigned long end_2_ulong;

    b1_len = strlen(begin_1);
    b2_len = strlen(begin_2);

    if (!(     (b1_len == (int) strlen(end_1))
            && (b2_len == (int) strlen(end_2))
            && (b1_len == b2_len))) {
        NI_set_Error_Errno(130, "IP addresses of different length");
        return 0;
    }

    NI_ip_bincomp(begin_1, "le", end_1, &res);
    if (!res) {
        NI_set_Error_Errno(140, "Invalid range %s - %s", begin_1, end_1);
        return 0;
    }

    NI_ip_bincomp(begin_2, "le", end_2, &res);
    if (!res) {
        NI_set_Error_Errno(140, "Invalid range %s - %s", begin_2, end_2);
        return 0;
    }

    /* IPv4-specific version (avoids using N128). */

    if (b1_len <= 32) {
        begin_1_ulong = NI_bintoint(begin_1, b1_len);
        begin_2_ulong = NI_bintoint(begin_2, b1_len);
        end_1_ulong   = NI_bintoint(end_1,   b1_len);
        end_2_ulong   = NI_bintoint(end_2,   b1_len);
        NI_ip_is_overlap_ipv4(begin_1_ulong, end_1_ulong,
                              begin_2_ulong, end_2_ulong, result);
        return 1;
    }

    /* IPv6 version (using N128). */

    n128_set_str_binary(&begin_1_n128, begin_1, b1_len);
    n128_set_str_binary(&begin_2_n128, begin_2, b1_len);
    n128_set_str_binary(&end_1_n128,   end_1,   b1_len);
    n128_set_str_binary(&end_2_n128,   end_2,   b1_len);

    NI_ip_is_overlap_ipv6(&begin_1_n128, &end_1_n128, 
                          &begin_2_n128, &end_2_n128, result);

    return 1;
}

/**
 * NI_ip_check_prefix_ipv6(): check whether prefix length is valid.
 * @ip: IP address.
 * @len: the prefix length.
 */
int
NI_ip_check_prefix_ipv6(n128_t *ip, int len)
{
    n128_t mask;
    char buf[IPV6_BITSTR_LEN];
    int i;

    if ((len < 0) || (len > 128)) {
        NI_set_Error_Errno(172, "Invalid prefix length /%d", len);
        return 0;
    }

    n128_set_ui(&mask, 0);
    for (i = 0; i < (128 - len); i++) {
        n128_setbit(&mask, i);
    }
    n128_and(&mask, ip);

    if (n128_cmp_ui(&mask, 0)) {
        NI_ip_n128tobin(ip, len, buf);
        buf[len] = '\0';
        NI_set_Error_Errno(171, "Invalid prefix %s/%d", buf, len);
        return 0;
    }

    return 1;
}

/**
 * NI_ip_check_prefix_ipv4(): check whether prefix length is valid.
 * @ip: IP address.
 * @len: the prefix length.
 */
int
NI_ip_check_prefix_ipv4(unsigned long ip, int len)
{
    unsigned long mask;

    if ((len < 0) || (len > 32)) {
        NI_set_Error_Errno(172, "Invalid prefix length /%d", len);
        return 0;
    }

    mask = (len == 0) ? 0xFFFFFFFF : ((1 << (32 - len)) - 1);

    if ((ip & mask) != 0) {
        NI_set_Error_Errno(171, "Invalid prefix %u/%d", ip, len);
        return 0;
    }

    return 1;
}

/**
 * NI_ip_check_prefix(): check whether prefix length is valid for address.
 * @bitstr: the bitstring IP address.
 * @len: the prefix length.
 * @version: the IP address version.
 *
 * The bitstring must be null-terminated.
 */
int
NI_ip_check_prefix(const char *bitstr, int len, int version)
{
    int iplen;
    const char *c;

    if (len < 0) {
        NI_set_Error_Errno(172, "Invalid prefix length /%d", len);
        return 0;
    }

    iplen = strlen(bitstr);

    if (len > iplen) {
        NI_set_Error_Errno(170, "Prefix length %d is longer than "
                                "IP address (%d)", len, iplen);
        return 0;
    }

    c = bitstr + len;

    while (*c != '\0') {
        if (*c != '0') {
            NI_set_Error_Errno(171, "Invalid prefix %s/%d", bitstr, len);
            return 0;
        }
        c++;
    }

    if (iplen != NI_iplengths(version)) {
        NI_set_Error_Errno(172, "Invalid prefix length /%d", len);
        return 0;
    }

    return 1;
}

/**
 * NI_ip_get_prefix_length_ipv4(): get prefix length for a given range.
 * @begin: first IP address.
 * @end: second IP address.
 * @bits: number of bits to check.
 * @len: a pointer to an integer.
 */
void
NI_ip_get_prefix_length_ipv4(unsigned long begin, unsigned long end,
                              int bits, int *len)
{
    int i;
    int res = 0;

    for (i = 0; i < bits; i++) {
        if ((begin & 1) == (end & 1)) {
            res = bits - i;
            break;
        }
        begin >>= 1;
        end   >>= 1;
    }

    *len = res;
}

/**
 * NI_ip_get_prefix_length_ipv6(): get prefix length for a given range.
 * @num1: first IP address as an N128 integer.
 * @num2: second IP address as an N128 integer.
 * @bits: number of bits to check
 * @len: a pointer to an integer.
 *
 * Returns 1 or 0 depending on whether the prefix length could be
 * calculated. Stores the prefix length in @len if it is able to be
 * calculated.
 */
void
NI_ip_get_prefix_length_ipv6(n128_t *num1, n128_t *num2, int bits, int *len)
{
    int i;
    int res = 0;

    for (i = 0; i < bits; i++) {
        if (n128_tstbit(num1, i) == n128_tstbit(num2, i)) {
            res = bits - i;
            break;
        }
    }

    *len = res;
}

/**
 * NI_ip_get_prefix_length(): get prefix length for a given range.
 * @bitstr_1: first IP address as a bitstring.
 * @bitstr_2: second IP address as a bitstring.
 * @len: a pointer to an integer.
 *
 * Returns 1 or 0 depending on whether the prefix length could be
 * calculated. Stores the prefix length in @len if it is able to be
 * calculated.
 */
int
NI_ip_get_prefix_length(const char *bitstr_1, const char *bitstr_2, int *len)
{
    int bin1_len;
    int bin2_len;
    int i;
    int res;

    bin1_len = strlen(bitstr_1);
    bin2_len = strlen(bitstr_2);

    if (bin1_len != bin2_len) {
        NI_set_Error_Errno(130, "IP addresses of different length");
        return 0;
    }

    res = bin1_len;

    for (i = (bin1_len - 1); i >= 0; i--) {
        if (bitstr_1[i] == bitstr_2[i]) {
            res = (bin1_len - 1 - i);
            break;
        }
    }

    *len = res;
    return 1;
}

/**
 * NI_ip_inttoip_ipv4(): make IPv4 address from integer.
 * @n: the IP address as a number.
 * @buf: the IP address buffer.
 */
void
NI_ip_inttoip_ipv4(unsigned long n, char *buf)
{
    sprintf(buf, "%lu.%lu.%lu.%lu", (n >> 24) & 0xFF,
                                    (n >> 16) & 0xFF,
                                    (n >> 8)  & 0xFF,
                                    (n >> 0)  & 0xFF);
}

/**
 * NI_ip_inttoip_ipv6(): make IPv6 address from integers.
 * @n1: the most significant 32 bits of the address.
 * @n2: the next-most significant 32 bits of the address.
 * @n3: the next-most significant 32 bits of the address.
 * @n4: the least significant 32 bits of the address.
 * @buf: the IP address buffer.
 */
void
NI_ip_inttoip_ipv6(unsigned long n1, unsigned long n2,
                   unsigned long n3, unsigned long n4, char *buf)
{
    sprintf(buf, "%04x:%04x:%04x:%04x:%04x:%04x:%04x:%04x",
                 (unsigned int) (n1 >> 16) & 0xFFFF,
                 (unsigned int) (n1      ) & 0xFFFF,
                 (unsigned int) (n2 >> 16) & 0xFFFF,
                 (unsigned int) (n2      ) & 0xFFFF,
                 (unsigned int) (n3 >> 16) & 0xFFFF,
                 (unsigned int) (n3      ) & 0xFFFF,
                 (unsigned int) (n4 >> 16) & 0xFFFF,
                 (unsigned int) (n4      ) & 0xFFFF);
}

/**
 * NI_ip_inttoip_n128(): make IPv6 address from N128 integer.
 * @ip: IP address.
 * @buf: the IP address buffer.
 */
void
NI_ip_inttoip_n128(n128_t *ip, char *buf)
{
    NI_ip_inttoip_ipv6(ip->nums[0], ip->nums[1],
                       ip->nums[2], ip->nums[3], buf);
}

/**
 * NI_ip_bintoip(): make IP address from bitstring.
 * @bitstr: the IP address as a bitstring.
 * @version: IP address version as integer.
 * @buf: the IP address buffer.
 *
 * The bitstring must be null-terminated. This function null-terminates the
 * buffer, so it has to have between eight and sixteen characters' capacity
 * (inclusive) for IPv4 addresses, depending on the value of the address, and
 * 40 characters' capacity for IPv6 addresses. Bitstrings that have fewer
 * characters than there are bits in the relevant version of IP address will be
 * treated as if they were left-padded with '0' characters until that number of
 * bits is met: e.g., passing "1" and 4 as the first two arguments to this
 * function will yield "0.0.0.1" in @buf.
 */
int
NI_ip_bintoip(const char *bitstr, int version, char *buf)
{
    int size;
    int iplen;
    int longs;
    int i;
    int j;
    int excess;
    int bits;
    unsigned long nums[4];

    iplen = NI_iplengths(version);
    size  = strlen(bitstr);
    if (size > iplen) {
        NI_set_Error_Errno(189, "Invalid IP length for "
                                "binary IP %s", bitstr);
        return 0;
    }

    if (version == 4) {
        nums[0] = NI_bintoint(bitstr, size);
        NI_ip_inttoip_ipv4(nums[0], buf);
        return 1;
    }

    for (i = 0; i < 4; i++) {
        nums[i] = 0;
    }

    excess = size % 32;
    longs  = (size / 32) + (!excess ? 0 : 1);

    for (i = (4 - longs), j = 0; i < 4; i++, j++) {
        bits =
            (i == (4 - longs) && excess)
                ? excess
                : 32;
        nums[i] = NI_bintoint(bitstr + (j * 32), bits);
    }

    NI_ip_inttoip_ipv6(nums[0], nums[1], nums[2], nums[3], buf);
    return 1;
}

/**
 * NI_ip_binadd(): add two bitstring IP addresses.
 * @ip1: first bitstring IP address.
 * @ip2: second bitstring IP address.
 * @buf: result buffer.
 * @maxlen: maximum capacity of buffer.
 *
 * Both bitstrings must be null-terminated and of the same length as
 * each other. The result is stored as a bitstring and
 * null-terminated. The result will be of the length of the
 * bitstrings, regardless of the result of the addition.
 */
int
NI_ip_binadd(const char *ip1, const char *ip2, char *buf, int maxlen)
{
    n128_t num1;
    n128_t num2;
    int len1;
    int len2;

    len1 = strlen(ip1);
    len2 = strlen(ip2);

    if (len1 != len2) {
        NI_set_Error_Errno(130, "IP addresses of different length");
        return 0;
    }
    if (len1 > (maxlen - 1)) {
        return 0;
    }

    n128_set_str_binary(&num1, ip1, len1);
    n128_set_str_binary(&num2, ip2, len2);
    n128_add(&num1, &num2);
    NI_ip_n128tobin(&num1, len1, buf);

    buf[len2] = '\0';
    return 1;
}

/**
 * NI_ip_range_to_prefix_ipv4(): get prefixes contained within range.
 * @begin: beginning address.
 * @end: ending address.
 * @version: IP address version.
 * @prefixes: prefix strings buffer.
 * @pcount: prefix count buffer.
 *
 * Will write at most 32 prefix strings to @prefixes.
 */
int
NI_ip_range_to_prefix_ipv4(unsigned long begin, unsigned long end,
                           int version, char **prefixes, int *pcount)
{
    unsigned long current;
    unsigned long mask;

    unsigned long zeroes;
    int iplen;
    int res;
    int i;
    int prefix_length;
    char *new_prefix;
    char range[4];

    current = 0;
    mask = 0;

    iplen = NI_iplengths(version);

    *pcount = 0;

    while (begin <= end) {
        /* Calculate the number of zeroes that exist on the right of
         * 'begin', and create a mask for that number of bits. */
        zeroes = NI_trailing_zeroes(begin);
        mask = 0;

        for (i = 0; i < (int) zeroes; i++) {
            mask |= (1 << i);
        }

        /* Find the largest range (from 'begin' to 'current') that
         * does not exceed 'end'. */

        do {
            current = begin;
            current |= mask;
            mask >>= 1;
        } while (current > end);

        /* Get the prefix length for the range and add the stringified
         * range to @prefixes. */

        NI_ip_get_prefix_length_ipv4(begin, current,
                                     iplen, &prefix_length);

        new_prefix = (char *) malloc(MAX_IPV4_RANGE_STR_LEN);
        if (!new_prefix) {
            printf("NI_ip_range_to_prefix: malloc failed!\n");
            return 0;
        }

        prefixes[(*pcount)++] = new_prefix;
        NI_ip_inttoip_ipv4(begin, new_prefix);
        strcat(new_prefix, "/");
        res = snprintf(range, 4, "%d", prefix_length);
        strncat(new_prefix, range, res);

        begin = current + 1;

        /* Do not continue getting prefixes if 'current' completely
         * comprises set bits. */

        if (current == 0xFFFFFFFF) {
            break;
        }
    }

    return 1;
}

/**
 * NI_ip_range_to_prefix_ipv6(): get prefixes contained within range.
 * @begin: beginning address.
 * @end: ending address.
 * @version: IP address version.
 * @prefixes: prefix strings buffer.
 * @pcount: prefix count buffer.
 *
 * Will write at most 128 prefix strings to @prefixes.
 */
int
NI_ip_range_to_prefix_ipv6(n128_t *begin, n128_t *end,
                           int version, char **prefixes, int *pcount)
{
    n128_t current;
    n128_t mask;
    unsigned long zeroes;
    int iplen;
    unsigned long res;
    int i;
    int prefix_length;
    char *new_prefix;
    char tempip[IPV6_BITSTR_LEN];
    char range[4];

    iplen = NI_iplengths(version);

    tempip[iplen] = '\0';
    *pcount = 0;

    while (n128_cmp(begin, end) <= 0) {
        if (*pcount == 128) {
            return 0;
        }

        /* Calculate the number of zeroes that exist on the right of
         * 'begin', and create a mask for that number of bits. */

        zeroes = n128_scan1(begin);
        zeroes = ((zeroes == INT_MAX) ? (unsigned) iplen : zeroes) - 1;

        n128_set_ui(&mask, 0);
        for (i = 0; i < ((int) zeroes + 1); i++) {
            n128_setbit(&mask, i);
        }

        /* Find the largest range (from 'begin' to 'current') that
         * does not exceed 'end'. */

        do {
            n128_set(&current, begin);
            n128_ior(&current, &mask);
            n128_clrbit(&mask, zeroes);
            zeroes--;
        } while (n128_cmp(&current, end) > 0);

        /* Get the prefix length for the range and add the stringified
         * range to @prefixes. */

        NI_ip_get_prefix_length_ipv6(begin, &current,
                                     iplen, &prefix_length);

        new_prefix = (char *) malloc(MAX_IPV6_RANGE_STR_LEN);
        if (!new_prefix) {
            printf("NI_ip_range_to_prefix: malloc failed!\n");
            return 0;
        }

        prefixes[(*pcount)++] = new_prefix;
        NI_ip_n128tobin(begin, iplen, tempip);
        NI_ip_bintoip(tempip, version, new_prefix);
        strcat(new_prefix, "/");
        res = snprintf(range, 4, "%d", prefix_length);
        strncat(new_prefix, range, res);

        n128_set(begin, &current);
        n128_add_ui(begin, 1);

        /* Do not continue getting prefixes if 'current' completely
         * comprises set bits. */

        res = n128_scan0(&current);
        if (res == INT_MAX) {
            break;
        }
    }

    return 1;
}

/**
 * NI_ip_range_to_prefix(): get prefixes contained within range.
 * @begin: first IP address as a bitstring.
 * @end: second IP address as a bitstring.
 * @version: IP address version.
 * @prefixes: prefix strings buffer.
 * @pcount: prefix count buffer.
 *
 * Both bitstrings must be null-terminated. If unsure of the number of
 * prefixes that will be created, @prefixes must contain space for 128
 * character pointers. Returns 1/0 depending on whether it completed
 * successfully.
 */
int
NI_ip_range_to_prefix(const char *begin, const char *end,
                      int version, char **prefixes, int *pcount)
{
    n128_t begin_n128;
    n128_t end_n128;
    unsigned long begin_ulong;
    unsigned long end_ulong;
    int iplen;
    int res;

    if (!version) {
        NI_set_Error_Errno(101, "Cannot determine IP version");
        return 0;
    }

    if (strlen(begin) != strlen(end)) {
        NI_set_Error_Errno(130, "IP addresses of different length");
        return 0;
    }

    iplen = NI_iplengths(version);
    if (!iplen) {
        return 0;
    }

    if (version == 4) {
        begin_ulong = NI_bintoint(begin, 32);
        end_ulong   = NI_bintoint(end,   32);
        return NI_ip_range_to_prefix_ipv4(begin_ulong, end_ulong,
                                          version, prefixes, pcount);
    }

    n128_set_str_binary(&begin_n128, begin, strlen(begin));
    n128_set_str_binary(&end_n128,   end,   strlen(end));

    res = NI_ip_range_to_prefix_ipv6(&begin_n128, &end_n128,
                                     version, prefixes, pcount);

    return res;
}

/**
 * NI_ip_aggregate_tail(): post-processing after version-specific aggregation.
 * @res: the result of the relevant ip_range_to_prefix function.
 * @prefixes: prefix strings buffer.
 * @pcount: prefix count.
 * @version: IP address version.
 * @buf: the buffer for the new range.
 *
 * If @res is false, then frees the prefixes and returns zero. If no
 * prefixes were returned, returns zero. If more than one prefix was

 * returned, frees the prefixes and returns 161. Otherwise, populates
 * the buffer (null-terminated) with the first range from @prefixes
 * and returns 1.
 */
int
NI_ip_aggregate_tail(int res, char **prefixes, int pcount,
                     int version, char *buf)
{
    int i;
    int len;
    int max;

    if (!res) {
        for (i = 0; i < pcount; i++) {
            free(prefixes[i]);
        }
        return 0;
    }

    if (pcount == 0) {
        return 0;
    }

    if (pcount > 1) {
        for (i = 0; i < pcount; i++) {
            free(prefixes[i]);
        }
        return 161;
    }

    len = strlen(*prefixes);
    max = (version == 4) ? MAX_IPV4_RANGE_STR_LEN - 1 
                         : MAX_IPV6_RANGE_STR_LEN - 1;
    if (len > max) {
        len = max;
    }

    strncpy(buf, *prefixes, len);
    buf[len] = 0;

    return 1;
}

/**
 * NI_ip_aggregate_ipv6(): get the aggregate range of two ranges as a string.
 * @begin_1: beginning N128 integer IP address for first range.
 * @end_1: ending N128 integer IP address for first range.
 * @begin_2: beginning N128 integer IP address for second range.
 * @end_2: ending N128 integer IP address for second range.
 * @version: IP address version.
 * @buf: the buffer for the new range.
 *
 * See NI_ip_aggregate().
 */
int
NI_ip_aggregate_ipv6(n128_t *b1, n128_t *e1, n128_t *b2, n128_t *e2,
                     int version, char *buf)
{
    char *prefixes[128];
    int pcount;
    int res;

    n128_add_ui(e1, 1);
    if (n128_cmp(e1, b2)) {
        return 160;
    }

    pcount = 0;
    res = NI_ip_range_to_prefix_ipv6(b1, e2, version, prefixes, &pcount);
    return NI_ip_aggregate_tail(res, prefixes, pcount, version, buf);
}

/**
 * NI_ip_aggregate_ipv4(): get the aggregate range of two ranges as a string.
 * @begin_1: beginning integer IP address for first range.
 * @end_1: ending integer IP address for first range.
 * @begin_2: beginning integer IP address for second range.
 * @end_2: ending integer IP address for second range.
 * @version: IP address version.
 * @buf: the buffer for the new range.
 *
 * See NI_ip_aggregate().
 */
int
NI_ip_aggregate_ipv4(unsigned long b1, unsigned long e1,
                     unsigned long b2, unsigned long e2,
                     int version, char *buf)
{
    char *prefixes[128];
    int pcount;
    int res;

    if (e1 + 1 != b2) {
        return 160;
    }

    pcount = 0;
    res = NI_ip_range_to_prefix_ipv4(b1, e2, version, prefixes, &pcount);
    return NI_ip_aggregate_tail(res, prefixes, pcount, version, buf);
}

/**
 * NI_ip_aggregate(): get the aggregate range of two ranges as a string.
 * @begin_1: beginning bitstring IP address for first range.
 * @end_1: ending bitstring IP address for first range.
 * @begin_2: beginning bitstring IP address for second range.
 * @end_2: ending bitstring IP address for second range.
 * @version: IP address version.
 * @buf: the buffer for the new range.
 *
 * Returns zero and sets error messages if the ranges are not
 * contiguous or the aggregate of the ranges cannot be represented as
 * a single prefix. Otherwise, populates the buffer with the aggregate
 * of the two ranges as a prefix range string (e.g. '1.0.0.0/8').
 */
int
NI_ip_aggregate(const char *b1, const char *e1, 
                const char *b2, const char *e2,
                int version, char *buf)
{
    int res;
    int i;
    n128_t b1_n128;
    n128_t e1_n128;
    n128_t b2_n128;
    n128_t e2_n128;
    unsigned long b1_ulong;
    unsigned long e1_ulong;
    unsigned long b2_ulong;
    unsigned long e2_ulong;
    const char *addr_args[4];
    addr_args[0] = b1;
    addr_args[1] = b2;
    addr_args[2] = e1;
    addr_args[3] = e2;

    if (!version) {
        NI_set_Error_Errno(101, "Cannot determine IP version for %s",
                                b1);
        return 0;
    } else if (version == 4) {
        for (i = 0; i < 4; i++) {
            if (strlen(addr_args[i]) != 32) {
                NI_set_Error_Errno(107, "Invalid IP address %s",
                                   addr_args[i]);
                return 0;
            }
        }
        b1_ulong = NI_bintoint(b1, 32);
        e1_ulong = NI_bintoint(e1, 32);
        b2_ulong = NI_bintoint(b2, 32);
        e2_ulong = NI_bintoint(e2, 32);
        res = NI_ip_aggregate_ipv4(b1_ulong, e1_ulong, 
                                   b2_ulong, e2_ulong, version, buf);
    } else {
        for (i = 0; i < 4; i++) {
            if (strlen(addr_args[i]) != 128) {
                NI_set_Error_Errno(108, "Invalid IP address %s",
                                   addr_args[i]);
                return 0;
            }
        }
        n128_set_str_binary(&b1_n128, b1, strlen(b1));
        n128_set_str_binary(&e1_n128, e1, strlen(e1));
        n128_set_str_binary(&b2_n128, b2, strlen(b2));
        n128_set_str_binary(&e2_n128, e2, strlen(e2));
        res = NI_ip_aggregate_ipv6(&b1_n128, &e1_n128, 
                                   &b2_n128, &e2_n128, version, buf);
    }

    if (res == 0) {
        return 0;
    }
    if (res == 160) {
        NI_set_Error_Errno(160, "Ranges not contiguous - %s - %s", e1, b2);
        return 0;
    }
    if (res == 161) {
        NI_set_Error_Errno(161, "%s - %s is not a single prefix", b1, e2);
        return 0;
    }
    return 1;
}

/**
 * NI_ip_iptobin(): get bitstring from IP address.
 * @ip: single IP address as a string.
 * @version: IP address version.
 * @buf: bitstring buffer.
 *
 * Returns zero (and may also set Error/Errno) if the IP address is
 * invalid. If an IPv6 address is provided, it must be fully expanded
 * - IPv6 addresses like '0::0' or '0:0:0:0:0:0:0:0' will not be
 *   handled correctly.
 */

int
NI_ip_iptobin(const char *ip, int ipversion, char *buf)
{
    int res;
    int j;
    int k;
    int y;
    int i;
    char c;
    int ncount;
    unsigned char ipv4[4];

    if (ipversion == 4) {
        res = inet_pton4(ip, ipv4);
        if (res == 0) {
            return 0;
        }

        for (j = 0; j < 4; j++) {
            for (i = 0; i < 8; i++) {
                buf[(j * 8) + i] =
                    ((ipv4[j] & (1 << (8 - i - 1)))) ? '1' : '0';
            }
        }
        return 1;
    } else {
        j = 0;
        ncount = 0;
        while ((c = ip[j])) {
            if (c != ':') {
                ncount++;
            }
            j++;
        }
        if (ncount != 32) {
            NI_set_Error_Errno(102, "Bad IP address %s", ip);
            return 0;
        }

        i = -1;
        for (j = 0; ip[j] != '\0'; j++) {
            if (ip[j] == ':') {
                continue;
            } else {
                i++;
            }

            y = NI_hdtoi(ip[j]);
            if (y == -1) {
                return 0;
            }

            for (k = 0; k < 4; k++) {
                buf[ (i * 4) + k ] =
                    ((y >> (3 - k)) & 1) ? '1' : '0';
            }
        }
        return 1;
    }
}

/**
 * NI_ip_expand_address_ipv4(): expand an IPv4 address.
 * @ip: the IPv4 address as a string.
 * @buf: the IP address buffer.
 *
 * The IPv4 address string must be null-terminated. The buffer will be
 * null-terminated on success.
 */
int
NI_ip_expand_address_ipv4(const char *ip, char *buf)
{
    int res;
    unsigned char ipv4[4];

    res = inet_pton4(ip, ipv4);
    if (!res) {
        return 0;
    }

    NI_ip_inttoip_ipv4(NI_ip_uchars_to_ulong(ipv4), buf);

    return 1;
}

/**
 * NI_ip_expand_address_ipv6(): expand an IPv6 address.
 * @ip: the IPv6 address as a string.
 * @buf: the IP address buffer.
 *
 * The IPv6 address string must be null-terminated. The buffer will be
 * null-terminated on success.
 */
int
NI_ip_expand_address_ipv6(const char *ip, char *retbuf)
{
    int res;
    int i;
    unsigned char ipv6[16];
    unsigned long n[4];

    res = inet_pton6(ip, ipv6);
    if (!res) {
        return 0;
    }

    for (i = 0; i < 4; i++) {
        n[i] = (ipv6[(i * 4) + 0] << 24)
             | (ipv6[(i * 4) + 1] << 16)
             | (ipv6[(i * 4) + 2] << 8)
             | (ipv6[(i * 4) + 3]);
    }

    NI_ip_inttoip_ipv6(n[0], n[1], n[2], n[3], retbuf);

    return 1;
}

/**
 * NI_ip_expand_address(): expand an IP address.
 * @ip: the IP address as a string.
 * @version: the IP address version.
 * @buf: the IP address buffer.
 *
 * See NI_ip_expand_address_ipv4() and NI_ip_expand_address_ipv6(). This
 * function dispatches to one of those functions depending on the
 * value of the @version argument.
 */
int
NI_ip_expand_address(const char *ip, int version, char *buf)
{
    return
        (version == 4)
            ? NI_ip_expand_address_ipv4(ip, buf)
            : NI_ip_expand_address_ipv6(ip, buf);
}

/**
 * NI_ip_reverse_ipv4(): get reverse domain for an IPv4 address.
 * @ip: the IP address as a string.
 * @len: the prefix length of the reverse domain.
 * @buf: the reverse domain buffer.
 *
 * If the length is not evenly divisible by eight, then it will be
 * treated as though it were the next number lower than it that is
 * evenly divisible by eight when determining how many octets to
 * print. So e.g. if the length is 31, three octets from the address
 * will be included in the domain. The buffer is null-terminated. The
 * longest possible IPv4 reverse domain name contains 25 characters
 * (including the null terminator).
 */
int
NI_ip_reverse_ipv4(const char *ip, int len, char *buf)
{
    int res;
    int quads;
    int i;
    char numbuf[5];
    unsigned char ipv4[4];

    if ((len < 0) || (len > 32)) {
        return 0;
    }
    quads = len / 8;

    res = inet_pton4(ip, ipv4);
    if (!res) {
        return 0;
    }

    for (i = (quads - 1); i >= 0; i--) {
        sprintf(numbuf, "%u.", ipv4[i]);
        strcat(buf, numbuf);
    }

    strcat(buf, "in-addr.arpa.");
    return 1;
}

/**
 * NI_ip_reverse_ipv6(): get reverse domain for an IPv4 address.
 * @ip: the IP address as a string.
 * @len: the prefix length of the reverse domain.
 * @buf: the reverse domain buffer.
 *
 * If the length is not evenly divisible by four, then it will be
 * treated as though it were the next number lower than it that is
 * evenly divisible by four when determining how many nibbles to
 * print. So e.g. if the length is 10, two nibbles from the address
 * will be included in the domain. The buffer is null-terminated. The
 * longest possible IPv6 reverse domain name contains 74 characters
 * (including the null terminator).
 */
int
NI_ip_reverse_ipv6(const char *ip, int len, char *buf)
{
    int res;
    int i;
    int index;
    int shift;
    unsigned char ipv6[16];

    if ((len < 0) || (len > 128)) {
        return 0;
    }
    len = (len / 4);

    res = inet_pton6(ip, ipv6);
    if (!res) {
        return 0;
    }

    for (i = (len - 1); i >= 0; i--) {
        index = i / 2;
        shift = !(i % 2) * 4;
        sprintf(buf, "%x.", ((ipv6[index] >> shift) & 0xF));
        buf += 2;
    }
    strcat(buf, "ip6.arpa.");
    return 1;
}

/**
 * NI_ip_reverse(): get reverse domain for an IP address.
 * @ip: the IP address as a string.
 * @len: the prefix length of the reverse domain.
 * @buf: the reverse domain buffer.
 *
 * See NI_ip_reverse_ipv4() and NI_ip_reverse_ipv6().
 */
int
NI_ip_reverse(const char *ip, int len, int ipversion, char *buf)
{
    if (!ipversion) {
        ipversion = NI_ip_get_version(ip);
    }
    if (!ipversion) {
        NI_set_Error_Errno(101, "Cannot determine IP "
                                "version for %s", ip);
        return 0;
    }

    if (ipversion == 4) {
        return NI_ip_reverse_ipv4(ip, len, buf);
    } else if (ipversion == 6) {
        return NI_ip_reverse_ipv6(ip, len, buf);
    }

    return 0;
}

/**
 * NI_ip_normalize_prefix_ipv4(): get first and last address from prefix range.
 * @ip: IP address.
 * @slash: pointer to first '/' in original string.
 * @ip1buf: first IP address buffer.
 * @ip2buf: second IP address buffer.
 *
 * Both buffers are null-terminated on success.
 */
int
NI_ip_normalize_prefix_ipv4(unsigned long ip, char *slash,
                            char *ip1buf, char *ip2buf)
{
    unsigned long current;
    char *endptr = NULL;
    int res;
    long clen  = 0;
    int addcst = 0;
    char c;

    current = ip;

    for (;;) {
        c = *slash++;
        if (c != '/') {
            break;
        }

        endptr = NULL;

        clen = strtol(slash, &endptr, 10);
        if (STRTOL_FAILED(clen, slash, endptr)) {
            return 0;
        }
        if (*endptr == ',') {
            addcst = 1;
        } else if (endptr != (slash + strlen(slash))) {
	    NI_set_Error_Errno(172, "Invalid prefix length /%s", slash);
            return 0;
        } else {
            addcst = 0;
        }

        res = NI_ip_check_prefix_ipv4(current, clen);
        if (!res) {
            return 0;
        }

        current = NI_ip_last_address_ipv4(current, clen);

        if (addcst) {
            current += 1;
            slash = endptr + 1;
        }
    }

    NI_ip_inttoip_ipv4(ip,      ip1buf);
    NI_ip_inttoip_ipv4(current, ip2buf);

    return 2;
}

/**
 * NI_ip_normalize_prefix_ipv6(): get first and last address from prefix range.
 * @ip: IP address (N128 integer).
 * @slash: pointer to first '/' in original string.
 * @ip1buf: first IP address buffer.
 * @ip2buf: second IP address buffer.
 *
 * Both buffers are null-terminated on success.
 */
int
NI_ip_normalize_prefix_ipv6(n128_t *ip, char *slash,
                            char *ip1buf, char *ip2buf)
{
    n128_t current;
    char *endptr = NULL;
    int res;
    long clen  = 0;
    int addcst = 0;
    char c;

    n128_set(&current, ip);

    for (;;) {
        c = *slash++;
        if (c != '/') {
            break;
        }

        endptr = NULL;

        clen = strtol(slash, &endptr, 10);
        if (STRTOL_FAILED(clen, slash, endptr)) {
            return 0;
        }
        if (*endptr == ',') {
            addcst = 1;
        } else if (endptr != (slash + strlen(slash))) {
	    NI_set_Error_Errno(172, "Invalid prefix length /%s", slash);
            return 0;
        } else {
            addcst = 0;
        }

        res = NI_ip_check_prefix_ipv6(&current, clen);
        if (!res) {
            return 0;
        }

        NI_ip_last_address_ipv6(&current, clen, &current);

        if (addcst) {
            n128_add_ui(&current, 1);
            slash = endptr + 1;
        }
    }

    NI_ip_inttoip_n128(ip,       ip1buf);
    NI_ip_inttoip_n128(&current, ip2buf);

    return 2;
}

/**
 * NI_ip_normalize_prefix(): get first and last address from prefix range.
 * @ip: IP address prefix range as a string.
 * @ip1buf: first IP address buffer.
 * @ip2buf: second IP address buffer.
 *
 * The range can include commas and additional prefixes, e.g.
 * '0.0.0.0/32,/32,/32' will yield '0.0.0.0' and '0.0.0.2'.
 */
int
NI_ip_normalize_prefix(char *ip, char *ip1buf, char *ip2buf)
{
    char c;
    int res;
    int i;
    char *slash;
    int islash;
    char *start;
    unsigned char ipnum[16];
    unsigned long ipv4;
    n128_t ipv6;
    int ipversion;

    i      = 0;
    slash  = NULL;
    islash = -1;
    start  = ip;

    while ((c = *ip)) {
        if (isspace(c)) {
            return -1;
        }
        if (i && (c == '/') && (!slash)) {
            slash  = ip;
            islash = i;
        }
        i++;
        ip++;
    }

    if (islash < 1) {
        return -1;
    }

    *slash = '\0';
    ipversion = NI_ip_get_version(start);

    if (ipversion == 4) {
        res = inet_pton4(start, ipnum);
        if (!res) {
            return 0;
        }
        *slash = '/';
        ipv4 = NI_ip_uchars_to_ulong(ipnum);
        return NI_ip_normalize_prefix_ipv4(ipv4,
                                           slash,
                                           ip1buf,
                                           ip2buf);
    } else if (ipversion == 6) {
        res = inet_pton6(start, ipnum);
        if (!res) {
            return 0;
        }
        *slash = '/';
        NI_ip_uchars_to_n128(ipnum, &ipv6);
        res = NI_ip_normalize_prefix_ipv6(&ipv6,
                                          slash,
                                          ip1buf,
                                          ip2buf);
        return res;
    } else {
        return 0;
    }
}

/**
 * NI_ip_tokenize_on_char(): get parts of string before and after char.
 * @str: the string to tokenize.
 * @separator: the char that separates the two parts of the string.
 * @end_first: buffer for the end of the first string.
 * @second: buffer for the start of the second string.
 *
 * Tokenizes the string based on the @separator character. Ignores
 * whitespace occurring before and after @separator. For example, if
 * the string provided is '127.0.0.1 - 127.0.0.255', @end_first will
 * point to the space immediately after the first IP address, and
 * @second will point to the second IP address.
 */
int
NI_ip_tokenize_on_char(char *str, char separator,
                       char **end_first, char **second)
{
    char c;
    char *break_char;
    int i;
    int hit_separator;

    break_char = NULL;
    i = 0;
    hit_separator = 0;

    while ((c = *str)) {
        if (c == separator) {
            hit_separator = 1;
            if (!break_char) {
                if (!i) {
                    return 0;
                } else {
                    break_char = str;
                }
            }
            break;
        } else if (isspace(c)) {
            if (!break_char) {
                break_char = str;
            }
        } else {
            break_char = NULL;
        }
        str++;
        i++;
    }

    if (!hit_separator) {
        return 0;
    }

    str++;
    c = *str;
    if (c == '\0') {
        return 0;
    }

    while ((c = *str) && (isspace(c))) {
        str++;
    }

    if (c == '\0') {
        return 0;
    }

    *end_first = break_char;
    *second    = str;

    return 1;
}

/**
 * NI_ip_normalize_range(): get first and last address from a range.
 * @ip: the IP address range to normalize.
 * @ipbuf1: first IP address buffer.
 * @ipbuf2: second IP address buffer.
 *
 * @ip must be a range containing a hyphen, e.g. '127.0.0.0 -
 * 127.0.0.255'. Whitespace before and after the hyphen is ignored.
 * The IP address buffers will be null-terminated on success.
 */
int
NI_ip_normalize_range(char *ip, char *ipbuf1, char *ipbuf2)
{
    char *break_char;
    char *start;
    int ipversion;
    int res;
    char old_char;

    res = NI_ip_tokenize_on_char(ip, '-', &break_char, &start);
    if (!res) {
        return -1;
    }

    old_char = *break_char;
    *break_char = '\0';

    ipversion = NI_ip_get_version(start);
    if (!ipversion) {
        *break_char = old_char;
        return 0;
    }

    res = NI_ip_expand_address(ip, ipversion, ipbuf1);
    *break_char = old_char;

    if (!res) {
        return 0;
    }

    res = NI_ip_expand_address(start, ipversion, ipbuf2);
    if (!res) {
        return 0;
    }

    return 2;
}

/**
 * NI_ip_normalize_plus_ipv4(): get first and last address from addition.
 * @ip: the IP address string.
 * @num: the number of addresses to add as a string.
 * @ipbuf1: first IP address buffer.
 * @ipbuf2: second IP address buffer.
 *
 * The IP address buffers will be null-terminated on success.
 */
int
NI_ip_normalize_plus_ipv4(char *ip, char *num,
                          char *ipbuf1, char *ipbuf2)
{
    int res;
    char *endptr;
    unsigned char ipnum[4];
    unsigned long ipv4;
    unsigned long addnum;

    res = inet_pton4(ip, ipnum);
    if (!res) {
        return 0;
    }

    ipv4 = NI_ip_uchars_to_ulong(ipnum);

    endptr = NULL;

    addnum = strtoul(num, &endptr, 10);
    if (STRTOUL_FAILED(addnum, num, endptr)) {
        return 0;
    }
    if (addnum > 0xFFFFFFFF) {
        return 0;
    }

    NI_ip_inttoip_ipv4(ipv4, ipbuf1);
    ipv4 += addnum;
    NI_ip_inttoip_ipv4(ipv4, ipbuf2);

    return 2;
}

/**
 * NI_ip_normalize_plus_ipv6(): get first and last address from addition.
 * @ip: the IP address string.
 * @num: the number of addresses to add as a string.
 * @ipbuf1: first IP address buffer.
 * @ipbuf2: second IP address buffer.
 *
 * The IP address buffers will be null-terminated on success.
 */
int
NI_ip_normalize_plus_ipv6(char *ip, char *num,
                          char *ipbuf1, char *ipbuf2)
{
    unsigned char ipnum[16];
    n128_t ipv6;
    n128_t addnum;
    int res;

    res = inet_pton6(ip, ipnum);
    if (!res) {
        return 0;
    }

    NI_ip_uchars_to_n128(ipnum, &ipv6);

    res = n128_set_str_decimal(&addnum, num, strlen(num));
    if (!res) {
        return 0;
    }

    NI_ip_inttoip_n128(&ipv6, ipbuf1);
    n128_add(&ipv6, &addnum);
    NI_ip_inttoip_n128(&ipv6, ipbuf2);

    return 2;
}

/**
 * NI_ip_normalize_plus(): get first and last address from addition.
 * @ip: the IP address string.
 * @ipbuf1: first IP address buffer.
 * @ipbuf2: second IP address buffer.
 *
 * @ip must begin with an IP address, then contain a '+' and an
 * integer, e.g. '127.0.0.0 + 16777216', '2000::+1234849245892845'.
 * The IP address buffers will be null-terminated on success.
 */
int
NI_ip_normalize_plus(char *ip1, char *ipbuf1, char *ipbuf2)
{
    char *break_char;
    char *start;
    int ipversion;
    int res;
    char old_char;

    res = NI_ip_tokenize_on_char(ip1, '+', &break_char, &start);
    if (!res) {
        return -1;
    }

    old_char = *break_char;
    *break_char = '\0';

    ipversion = NI_ip_get_version(ip1);

    switch (ipversion) {
        case 4:  res = NI_ip_normalize_plus_ipv4(ip1, start, ipbuf1, ipbuf2);
                 break;
        case 6:  res = NI_ip_normalize_plus_ipv6(ip1, start, ipbuf1, ipbuf2);
                 break;
        default: res = 0;
    }

    *break_char = old_char;
    return res;
}

/**
 * NI_ip_normalize_bare(): normalize a single IP address.
 * @ip: the IP address string.
 * @ipbuf1: the IP address buffer.
 *
 * Checks the version of the IP address and then expands it. For a
 * valid IP address, this function has the same effect as calling
 * NI_ip_expand_address(). The IP address buffer will be
 * null-terminated on success.
 */
int
NI_ip_normalize_bare(char *ip, char *ipbuf1)
{
    int ipversion;
    int res;

    ipversion = NI_ip_get_version(ip);
    if (!ipversion) {
        return 0;
    }

    res = NI_ip_expand_address(ip, ipversion, ipbuf1);
    if (!res) {
        return 0;
    }

    return 1;
}

/**
 * NI_ip_normalize(): normalize an IP address string.
 * @ip: the IP address string.
 * @ipbuf1: the first IP address buffer.
 * @ipbuf2: the second IP address buffer.
 *
 * The various formats that @ip can take are described in
 * NI_ip_normalize_prefix(), NI_ip_normalize_range(),
 * NI_ip_normalize_plus() and NI_ip_normalize_bare(). Returns zero on
 * failure, otherwise returns the number of IP address buffers that
 * were populated. Those buffers will be null-terminated on success.
 */
int
NI_ip_normalize(char *ip, char *ipbuf1, char *ipbuf2)
{
    int res;

    res = NI_ip_normalize_prefix(ip, ipbuf1, ipbuf2);
    if (res >= 0) {
        return res;
    }

    res = NI_ip_normalize_range(ip, ipbuf1, ipbuf2);
    if (res >= 0) {
        return res;
    }

    res = NI_ip_normalize_plus(ip, ipbuf1, ipbuf2);
    if (res >= 0) {
        return res;
    }

    res = NI_ip_normalize_bare(ip, ipbuf1);
    if (res >= 0) {
        return res;
    }

    return 0;
}

/**
 * NI_ip_normal_range(): normalize an IP address string into a range.
 * @ip: the IP address string.
 * @buf: the IP address range buffer.
 *
 * Uses NI_ip_normalize() to get the first and last (if applicable)
 * addresses from the string. Sets the buffer so that it is always in
 * range format (i.e. first address, hyphen, second address), even
 * where the IP address string contains only one address, in which
 * case both of the addresses will be the same. @buf is
 * null-terminated on success.
 */
int
NI_ip_normal_range(char *ip, char *buf)
{
    char ip1buf[MAX_IPV6_STR_LEN];
    char ip2buf[MAX_IPV6_STR_LEN];
    int res;

    res = NI_ip_normalize(ip, ip1buf, ip2buf);
    if (!res) {
        return 0;
    }

    sprintf(buf, "%s - %s", ip1buf,
                            (res == 1) ? ip1buf : ip2buf);

    return 1;
}

/**
 * NI_ip_compress_v4_prefix(): get smallest representation of IPv4 prefix range.
 * @ip: the IP address.
 * @len: the prefix length of the range.
 * @buf: buffer for the compressed representation.
 * @maxlen: maximum capacity of buffer.
 */
int
NI_ip_compress_v4_prefix(const char *ip, int len, char *buf, int maxlen)
{
    int dotcount;
    const char *c;
    int buflen;

    if ((len < 0) || (len > 32)) {
        return 0;
    }
    if (strlen(ip) > (MAX_IPV4_RANGE_STR_LEN - 1)) {
        return 0;
    }

    c = ip;
    dotcount = (len == 0) ? 1 : ((len / 8) + (!(len % 8) ? 0 : 1));
    while (dotcount--) {
        c = strchr(c, '.');
        if (c == NULL) {
            c = ip + (strlen(ip) + 1);
            break;
        }
        if (*(c + 1) != '\0') {
            c++;
        }
    }

    buflen = c - ip - 1;
    if (buflen > maxlen) {
        buflen = maxlen;
    }

    strncpy(buf, ip, buflen);
    buf[buflen] = '\0';

    return 1;
}

/**
 * NI_ip_compress_address(): get smallest representation of IPv6 prefix range.
 * @ip: the IP address.
 * @version: the IP address version.
 * @buf: buffer for the compressed representation.
 *
 * If @ip is an IPv4 address, it will simply be copied to @buf.
 */
int
NI_ip_compress_address(const char *ip, int version, char *buf)
{
    unsigned char ipv6[16];
    int i;
    char mybuf[5];
    int res;
    int in_ws = 0;
    int ws_index = -1;
    int ws_start[4];
    int ws_count[4];
    int largest_index;
    int largest;

    memset(ws_start, 0, 4 * sizeof(int));
    memset(ws_count, 0, 4 * sizeof(int));

    if (!version) {
        NI_set_Error_Errno(101, "Cannot determine IP version for %s",
                                ip);
        return 0;
    }

    if (version == 4) {
        strcpy(buf, ip);
        return 1;
    }

    res = inet_pton6(ip, ipv6);
    if (!res) {
        return 0;
    }

    for (i = 0; i < 16; i += 2) {
        if ((ipv6[i] == 0) && (ipv6[i + 1] == 0)) {
            if (!in_ws) {
                in_ws = 1;
                ws_start[++ws_index] = i;
            }
            ws_count[ws_index] += 1;
        } else {
            in_ws = 0;
        }
    }

    largest       = 0;
    largest_index = -1;

    for (i = 0; i < 4; i++) {
        /* "The symbol '::' MUST NOT be used to shorten just one 16-bit 0
            field. For example, the representation 2001:db8:0:1:1:1:1:1 is
            correct, but 2001:db8::1:1:1:1:1 is not correct"
            (RFC 5952, [4.2.2]). So make sure that ws_count is greater
            than 1. */
        if (ws_count[i] > largest && ws_count[i] > 1) {
            largest       = ws_count[i];
            largest_index = i;
        }
    }

    for (i = 0; i < 16; i += 2) {
        if ((largest_index != -1) && (i == ws_start[largest_index])) {
            if (i == 0) {
                strcat(buf, ":");
            }
            i += ((largest * 2) - 2);
            strcat(buf, ":");
        } else {
            sprintf(mybuf, "%x",
                    (ipv6[i] << 8) + ipv6[i + 1]);
            strcat(buf, mybuf);
            if (i < 14) {
                strcat(buf, ":");
            }
        }
    }

    return 1;
}

/**
 * NI_ip_splitprefix(): split range into IP address and prefix length.
 * @prefix: the IP address prefix range.
 * @ipbuf: the IP address buffer.
 * @lenbuf: the prefix length buffer.
 */
int
NI_ip_splitprefix(const char *prefix, char *ipbuf, int *lenbuf)
{
    const char *c;
    const char *slash;
    char *endptr;
    long num;
    int len;

    c = slash = strchr(prefix, '/');
    if (!slash) {
        return 0;
    }

    len = slash - prefix;
    if ((len == 0) || (len > (MAX_IPV6_STR_LEN - 1))) {
        return 0;
    }

    c++;
    if (*c == '\0') {
        return 0;
    }

    endptr = NULL;

    num = strtol(c, &endptr, 10);
    if (STRTOL_FAILED(num, c, endptr)) {
        return 0;
    }
    if (num < 0) {
        return 0;
    }

    memcpy(ipbuf, prefix, len);
    ipbuf[len] = '\0';
    *lenbuf = num;

    return 1;
}

/**
 * NI_ip_iptype(): get type of IP address as a string.
 * @ip: the IP address.
 * @version: the IP address version.
 * @buf: the type buffer.
 *
 * The type buffer will be null-terminated on success. Relies on
 * IPv4ranges and IPv6ranges for determining types.
 */
int
NI_ip_iptype(const char *ip, int version, char *buf)
{
    HV *hash;
    HE *entry;
    char *key;
    I32 keylen;
    SV *value;
    STRLEN len;
    int current_keylen;
    char *typestr;

    hash = get_hv(
        (version == 4 ? "Net::IP::XS::IPv4ranges"
                      : "Net::IP::XS::IPv6ranges"), 0);

    if (!hash) {
        return 0;
    }

    hv_iterinit(hash);
    current_keylen = 0;

    while ((entry = hv_iternext(hash))) {
        key = hv_iterkey(entry, &keylen);
        if (keylen > current_keylen) {
            if (!strncmp(key, ip, keylen)) {
                current_keylen = keylen;
                value = hv_iterval(hash, entry);
                typestr = SvPV(value, len);
                if (len > (MAX_TYPE_STR_LEN - 1)) {
                    len = (MAX_TYPE_STR_LEN - 1);
                }
                memcpy(buf, typestr, len);
                buf[len] = '\0';
            }
        }
    }

    if (current_keylen) {
        return 1;
    }

    if (version == 4) {
        memcpy(buf, "PUBLIC", 6);
        buf[6] = '\0';
        return 1;
    }

    NI_set_Error_Errno(180, "Cannot determine type for %s", ip);

    return 0;
}

/**
 * NI_ip_is_valid_mask(): determine the validity of a bitstring mask.
 * @mask: bitstring mask.
 * @version: mask's IP address version.
 */
int
NI_ip_is_valid_mask(const char *mask, int version)
{
    const char *c;
    int iplen;
    int mask_len;
    int state;

    if (!version) {
        NI_set_Error_Errno(101, "Cannot determine IP version for %s",
                                mask);
        return 0;
    }

    iplen    = NI_iplengths(version);
    mask_len = strlen(mask);

    if (mask_len != iplen) {
        NI_set_Error_Errno(150, "Invalid mask length for %s", mask);
        return 0;
    }

    state = 0;
    c     = mask;

    while (*c != '\0') {
        if ((*c == '1') && (state == 0)) {
            c++;
            continue;
        }
        if (*c == '0') {
            if (state == 0) {
                state = 1;
            }
            c++;
            continue;
        }
        NI_set_Error_Errno(151, "Invalid mask %s", mask);
        return 0;
    }

    return 1;
}

/**
 * NI_ip_prefix_to_range(): get begin/end addresses from address and length.
 * @ip: IP address.
 * @len: prefix length of range.
 * @version: IP address version.
 * @buf: last IP address buffer.
 */
int
NI_ip_prefix_to_range(const char *ip, int len, int version, char *buf)
{
    char bitstr1[IPV6_BITSTR_LEN];
    char bitstr2[IPV6_BITSTR_LEN];

    if (!version) {
        NI_set_Error_Errno(101, "Cannot determine IP version");
        return 0;
    }

    if (!NI_ip_expand_address(ip, version, buf)) {
        return 0;
    }

    if (!NI_ip_iptobin(ip, version, bitstr1)) {
        return 0;
    }

    bitstr1[(version == 4) ? 32 : 128] = '\0';

    if (!NI_ip_check_prefix(bitstr1, len, version)) {
        return 0;
    }

    NI_ip_last_address_bin(bitstr1, len, version, bitstr2);

    bitstr2[(version == 4) ? 32 : 128] = '\0';

    if (!NI_ip_bintoip(bitstr2, version, buf)) {
        return 0;
    }

    return 1;
}

/**
 * NI_ip_get_embedded_ipv4(): get IPv4 address contained within IPv6 address.
 * @ipv6: IPv6 address as a string.
 * @buf: IPv4 address buffer.
 */
int
NI_ip_get_embedded_ipv4(const char *ipv6, char *buf)
{
    const char *c;
    int len;

    c = strrchr(ipv6, ':');
    if (c == NULL) {
        c = ipv6;
    } else {
        c++;
    }

    len = strlen(c);
    if (len > (MAX_IPV4_STR_LEN - 1)) {
        len = (MAX_IPV4_STR_LEN - 1);
    }
    if ((len > 0) && NI_ip_is_ipv4(c)) {
        strncpy(buf, c, len);
        buf[len] = '\0';
        return 1;
    } else {
        return 0;
    }
}

#ifdef __cplusplus
}
#endif
