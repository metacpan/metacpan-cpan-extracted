/*
n128.c - 128-bit integer.

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

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <limits.h>
#include <ctype.h>

#include "n128.h"

#ifdef __cplusplus
extern "C" {
#endif

static char *power_strings[] = {
    "1",
    "2",
    "4",
    "8",
    "16",
    "32",
    "64",
    "128",
    "256",
    "512",
    "1024",
    "2048",
    "4096",
    "8192",
    "16384",
    "32768",
    "65536",
    "131072",
    "262144",
    "524288",
    "1048576",
    "2097152",
    "4194304",
    "8388608",
    "16777216",
    "33554432",
    "67108864",
    "134217728",
    "268435456",
    "536870912",
    "1073741824",
    "2147483648",
    "4294967296",
    "8589934592",
    "17179869184",
    "34359738368",
    "68719476736",
    "137438953472",
    "274877906944",
    "549755813888",
    "1099511627776",
    "2199023255552",
    "4398046511104",
    "8796093022208",
    "17592186044416",
    "35184372088832",
    "70368744177664",
    "140737488355328",
    "281474976710656",
    "562949953421312",
    "1125899906842624",
    "2251799813685248",
    "4503599627370496",
    "9007199254740992",
    "18014398509481984",
    "36028797018963968",
    "72057594037927936",
    "144115188075855872",
    "288230376151711744",
    "576460752303423488",
    "1152921504606846976",
    "2305843009213693952",
    "4611686018427387904",
    "9223372036854775808",
    "18446744073709551616",
    "36893488147419103232",
    "73786976294838206464",
    "147573952589676412928",
    "295147905179352825856",
    "590295810358705651712",
    "1180591620717411303424",
    "2361183241434822606848",
    "4722366482869645213696",
    "9444732965739290427392",
    "18889465931478580854784",
    "37778931862957161709568",
    "75557863725914323419136",
    "151115727451828646838272",
    "302231454903657293676544",
    "604462909807314587353088",
    "1208925819614629174706176",
    "2417851639229258349412352",
    "4835703278458516698824704",
    "9671406556917033397649408",
    "19342813113834066795298816",
    "38685626227668133590597632",
    "77371252455336267181195264",
    "154742504910672534362390528",
    "309485009821345068724781056",
    "618970019642690137449562112",
    "1237940039285380274899124224",
    "2475880078570760549798248448",
    "4951760157141521099596496896",
    "9903520314283042199192993792",
    "19807040628566084398385987584",
    "39614081257132168796771975168",
    "79228162514264337593543950336",
    "158456325028528675187087900672",
    "316912650057057350374175801344",
    "633825300114114700748351602688",
    "1267650600228229401496703205376",
    "2535301200456458802993406410752",
    "5070602400912917605986812821504",
    "10141204801825835211973625643008",
    "20282409603651670423947251286016",
    "40564819207303340847894502572032",
    "81129638414606681695789005144064",
    "162259276829213363391578010288128",
    "324518553658426726783156020576256",
    "649037107316853453566312041152512",
    "1298074214633706907132624082305024",
    "2596148429267413814265248164610048",
    "5192296858534827628530496329220096",
    "10384593717069655257060992658440192",
    "20769187434139310514121985316880384",
    "41538374868278621028243970633760768",
    "83076749736557242056487941267521536",
    "166153499473114484112975882535043072",
    "332306998946228968225951765070086144",
    "664613997892457936451903530140172288",
    "1329227995784915872903807060280344576",
    "2658455991569831745807614120560689152",
    "5316911983139663491615228241121378304",
    "10633823966279326983230456482242756608",
    "21267647932558653966460912964485513216",
    "42535295865117307932921825928971026432",
    "85070591730234615865843651857942052864",
    "170141183460469231731687303715884105728",
    "340282366920938463463374607431768211456",
};

/*
 * n128_set(): copy N128 value from other N128 value.
 * @dst: destination N128 object.
 * @src: source N128 object.
 */
void 
n128_set(n128_t *dst, n128_t *src)
{
    memcpy(dst, src, sizeof(*dst));

    return;
}

/**
 * n128_set_ui(): set N128 value based on unsigned integer.
 * @n: the N128 object to be set.
 * @ui: the value to set.
 */
void 
n128_set_ui(n128_t *n, unsigned int ui)
{
    n->nums[0] = 0;
    n->nums[1] = 0;
    n->nums[2] = 0;
    n->nums[3] = ui;

    return;
}

/**
 * n128_cmp_ui(): compare N128 value against unsigned integer.
 * @n: the N128 object.
 * @ui: unsigned integer.
 *
 * Returns 1 if @n is more than @ui, 0 if @n is equal to @ui and -1 if
 * @n is less than @ui.
 */
int 
n128_cmp_ui(n128_t *n, unsigned int ui)
{
    return
        (n->nums[0] || n->nums[1] || n->nums[2] || (n->nums[3] > ui)) 
            ? 1
      : (n->nums[3] == ui)
            ? 0
            : -1;
}

/**
 * n128_blsft(): left-shift (circular) N128 value.
 * @n: the N128 object to shift.
 * @sft: the number of places by which the object should be shifted.
 */
void 
n128_blsft(n128_t *n, int sft)
{
    n128_t copy;
    int i;
    uint32_t mask;
    int diff;
    
    diff = sft - 31;
    if (diff >= 0) {
        sft = 31;
    }

    for (i = 0; i < 4; ++i) {
        copy.nums[i] = n->nums[i];
    }
    for (i = 0; i < 4; ++i) {
        n->nums[i] <<= sft;
    }
    for (i = 0; i < 4; ++i) {
        mask = ((1 << sft) - 1) << (32 - sft);
        mask &= copy.nums[(i + 1) % 4];
        mask >>= (32 - sft);
        n->nums[i] |= mask;
    }

    if (diff >= 0) {
        n128_blsft(n, diff);
    }

    return;
}

/**
 * n128_brsft(): right-shift (circular) N128 value.
 * @n: the N128 object to shift.
 * @sft: the number of places by which the object should be shifted.
 */
void 
n128_brsft(n128_t *n, int sft)
{
    n128_t copy;
    int i;
    uint32_t mask;
    int diff;
    
    diff = sft - 31;
    if (diff >= 0) {
        sft = 31;
    }

    for (i = 0; i < 4; ++i) {
        copy.nums[i] = n->nums[i];
    }
    for (i = 0; i < 4; ++i) {
        n->nums[i] >>= sft;
    }
    for (i = 0; i < 4; ++i) {
        mask = ((1 << sft) - 1);
        mask &= copy.nums[(i + 3) % 4];
        mask <<= (32 - sft);
        n->nums[i] |= mask;
    }

    if (diff >= 0) {
        n128_brsft(n, diff);
    }

    return;
}

/**
 * n128_and(): bitwise AND two N128 values.
 * @n1: first N128 object.
 * @n2: second N128 object.
 *
 * The result is stored in the first argument.
 */
void 
n128_and(n128_t *n1, n128_t *n2)
{
    int i;

    for (i = 0; i < 4; i++) {
        n1->nums[i] &= n2->nums[i];
    }

    return;
}

/**
 * n128_ior(): bitwise OR two N128 values.
 * @n1: first N128 object.
 * @n2: second N128 object.
 *
 * The result is stored in the first argument.
 */
void 
n128_ior(n128_t *n1, n128_t *n2)
{
    int i;

    for (i = 0; i < 4; i++) {
        n1->nums[i] |= n2->nums[i];
    }

    return;
}

/**
 * n128_xor(): bitwise XOR two N128 values.
 * @n1: first N128 object.
 * @n2: second N128 object.
 *
 * The result is stored in the first argument.
 */
void 
n128_xor(n128_t *n1, n128_t *n2)
{
    int i;

    for (i = 0; i < 4; i++) {
        n1->nums[i] ^= n2->nums[i];
    }

    return;
}

/**
 * n128_add(): add two N128 values.
 * @n1: first N128 object.
 * @n2: second N128 object.
 *
 * The result is stored in the first argument. Overflow is as per
 * an unsigned integer.
 */
int
n128_add(n128_t *n1, n128_t *n2)
{
    int i;
    int j;

    for (i = 0; i < 4; i++) {
        n1->nums[i] += n2->nums[i];
    }
    for (i = 1; i < 4; i++) {
        j = i - 1;
        if (n1->nums[i] < n2->nums[i]) {
            n1->nums[j]++;
            while (n1->nums[j] == 0 && j--) {
                n1->nums[j]++;
            }
        }
    }

    return 1;
}

/**
 * n128_com(): take the complement of an N128 value.
 * @n: N128 object.
 *
 * The result is stored in the argument.
 */
void 
n128_com(n128_t *n)
{
    int i;

    for (i = 0; i < 4; i++) {
        n->nums[i] = ~(n->nums[i]);
    }

    return;
}

/**
 * n128_add_ui(): add an unsigned integer value to an N128 value.
 * @n: N128 object.
 *
 * The result is stored in the first argument. Overflow is as per an
 * unsigned integer.
 */
int 
n128_add_ui(n128_t *n, unsigned int ui)
{
    n128_t n2;
    n128_set_ui(&n2, ui);
    n128_add(n, &n2);

    return 1;
}

/**
 * n128_sub(): subtract an N128 value from another.
 * @n1: N128 object (minuend).
 * @n2: N128 object (subtrahend).
 *
 * The result is stored in the first argument. Overflow is not
 * handled: if @n2 is greater than @n1, the result will be zero.
 */
int 
n128_sub(n128_t *n1, n128_t *n2)
{
    int res;
    n128_t n2c;
    n128_t *n2cp = &n2c;
    
    res = n128_cmp(n1, n2);
    if (res < 0) {
        return 0;
    }
    if (res == 0) {
        n128_set_ui(n1, 0);
        return 1;
    }
    n128_set(n2cp, n2);
    n128_com(n2cp);
    n128_add_ui(n2cp, 1);
    n128_add(n1, n2cp);

    return 1;
}

/**
 * n128_tstbit(): test whether a bit is set in an N128 value.
 * @n: N128 object.
 * @bit: the bit to test.
 *
 * Returns 1 if the bit is set, and zero if it is not. Bits begin at
 * zero and are ordered from least to most significant.
 */
int
n128_tstbit(n128_t *n, int bit)
{
    return (n->nums[3 - (bit / 32)] >> (bit % 32)) & 1;
}

/**
 * n128_setbit(): set a particular bit in an N128 value.
 * @n: N128 object.
 * @bit: the bit to set.
 *
 * See n128_tstbit().
 */
void
n128_setbit(n128_t *n, int bit)
{
    n->nums[3 - (bit / 32)] |= (1 << (bit % 32));
}

/**
 * n128_clrbit(): clear a particular bit in an N128 value.
 * @n: N128 object.
 * @bit: the bit to clear.
 *
 * See n128_tstbit().
 */
void
n128_clrbit(n128_t *n, int bit)
{
    n->nums[3 - (bit / 32)] &= ~(1 << (bit % 32));
}

/**
 * n128_cmp(): compare N128 value against another.
 * @n1: first N128 object.
 * @n2: second N128 object.
 *
 * Returns 1 if @n1 is more than @n2, 0 if @n1 is equal to @n2 and -1 if
 * @n1 is less than @n2.
 */
int
n128_cmp(n128_t *n1, n128_t *n2)
{
    return (n1->nums[0] > n2->nums[0]) ?  1
         : (n1->nums[0] < n2->nums[0]) ? -1
         : (n1->nums[1] > n2->nums[1]) ?  1
         : (n1->nums[1] < n2->nums[1]) ? -1
         : (n1->nums[2] > n2->nums[2]) ?  1
         : (n1->nums[2] < n2->nums[2]) ? -1
         : (n1->nums[3] > n2->nums[3]) ?  1
         : (n1->nums[3] < n2->nums[3]) ? -1
                                       : 0;
}

/**
 * n128_set_str_binary(): set N128 value based on bitstring.
 * @n: destination N128 object.
 * @bitstr: the bitstring.
 * @len: the length of the bitstring.
 *
 * The bitstring's bits must be ordered from most to
 * least significant. Any character in the bitstring that is not the
 * character '0' will be treated as the character '1'.
 */
void
n128_set_str_binary(n128_t *n, const char *bitstr, int len)
{
    int i;
    int j;
    int mylen;

    memset(n, 0, 4 * sizeof(uint32_t));
    mylen = (len > 128) ? 128 : len;

    if (mylen < 128) {
        for (i = 0; i < (128 - mylen); i++) {
            n128_clrbit(n, (127 - i));
        }
    } else {
        i = 0;
    }
    for (j = 0; i < 128; i++, j++) {
        if (bitstr[j] != '0') {
            n128_setbit(n, (127 - i));
        }
    }

    return;    
}

static void 
str_subtract(char *buf, int buflen, char *operand, int oplen)
{
    int i;
    int j;
    int carry = 0;
    int diff;

    for (i = buflen - 1, j = oplen - 1; i >= 0 && j >= 0; --i, --j) {
        diff = (buf[i] - (operand[j] + carry));
        if (diff >= 0) {
            buf[i] = diff + '0';
            carry = 0;
        } else {
            buf[i] = diff + '0' + 10;
            carry = 1;
        }
    }
    if (carry == 1) {
        buf[i]--;
    }

    return;
}

/**
 * n128_set_str_decimal(): set N128 value based on decimal string.
 * @n: destination N128 object.
 * @bitstr: the decimal string.
 * @len: the length of the decimal string.
 */
int 
n128_set_str_decimal(n128_t *n, const char *str, int len)
{
    int i;
    char *ps;
    int ps_len;
    char buf[40];
    char *bufp;

    if (len > 39) {
        return 0;
    }
    
    bufp = buf;
    strncpy(bufp, str, len);
    buf[len] = '\0';
    n128_set_ui(n, 0);

    for (i = 0; i < len; i++) {
        if (!isdigit(str[i])) {
            return 0;
        }
    }
    
    if (power_strings[127][0] > str[0]) {
        return 0;
    }

    for (i = 127; i >= 0; i--) {
        if (!len) {
            break;
        }
        ps = power_strings[i];
        ps_len = strlen(ps);
        if (ps_len > len) {
            continue;
        } else {
            if (ps_len == len) {
                if (strcmp(bufp, ps) < 0) {
                    continue;
                }
            }
            str_subtract(bufp, len, ps, ps_len);
            while (*bufp == '0') {
                ++bufp;
                --len;
            }
            n128_setbit(n, i);
        }
    }
    if (len) {
        return 0;
    }
 
    return 1;
}

/**
 * n128_scan0(): return the index of the least significant cleared bit.
 * @n: N128 object.
 */
int 
n128_scan0(n128_t *n)
{
    int i;

    for (i = 0; i < 128; i++) {
        if (!n128_tstbit(n, i)) {
            return i;
        }
    }

    return INT_MAX;
}

/**
 * n128_scan1(): return the index of the least significant set bit.
 * @n: N128 object.
 */
int 
n128_scan1(n128_t *n)
{
    int i;

    for (i = 0; i < 128; i++) {
        if (n128_tstbit(n, i)) {
            return i;
        }
    }

    return INT_MAX;
}

/**
 * n128_rscan1(): return the index of the most significant set bit.
 * @n: N128 object.
 */
static int 
n128_rscan1(n128_t *n)
{
    int i;

    for (i = 127; i >= 0; i--) {
        if (n128_tstbit(n, i)) {
            return i;
        }
    }

    return INT_MAX;
}

/**
 * n128_print_bin(): write an N128 value as a bitstring.
 * @n: N128 object.
 * @buf: bitstring buffer.
 * @ui_only: a boolean indicating whether only the first 32 bits
 * should be written.
 *
 * The buffer is null-terminated on completion, so it must have either
 * 129 or 33 characters' capacity, depending on the value of @ui_only.
 */
void 
n128_print_bin(n128_t *n, char *buf, int ui_only)
{
    int i;
    int j;

    j = (ui_only) ? 0 : 3; 

    for (; j >= 0; j--) {
        for (i = 31; i >= 0; i--) {
            *buf = (n128_tstbit(n, (j * 32) + i) ? '1' : '0');
            ++buf;
        }
    }
    *buf = '\0';

    return;
}

/**
 * n128_print_hex(): write an N128 value as a hexadecimal string.
 * @n: N128 object.
 * @buf: hexadecimal string buffer.
 *
 * The buffer is null-terminated on completion. It must have at least
 * 33 characters' capacity to handle all possible cases.
 */
void 
n128_print_hex(n128_t *n, char *buf)
{
    int byte;
    int i;
    static const char *lookup = "0123456789abcdef";

    for (i = 0; i < 16; i++) {
        byte = (n->nums[i / 4] >> ((3 - (i % 4)) * 8)) & 0xFF;
        if (byte) {
            break;
        }
    }

    *buf++ = '0';
    *buf++ = 'x';

    if (i == 16) {
        *buf++ = '0';
    } else {
        for (; i < 16; i++) {
            byte = (n->nums[i / 4] >> ((3 - (i % 4)) * 8)) & 0xFF;
            *buf++ = lookup[(byte >> 4) & 0xF];
            *buf++ = lookup[byte & 0xF];
        }
    }
    
    *buf = '\0';

    return;
}

static int 
n128_divmod_10(n128_t *n, n128_t *qp, n128_t *rp)
{
    n128_t ten;
    n128_t *tenp;
    n128_t t;
    n128_t *tp;
    n128_t na;
    n128_t *np;
    int shift;
    int shift1;
    int shift2;

    tenp = &ten;
    tp = &t;
    np = &na;
    n128_set(np, n);
    n128_set_ui(qp, 0);

    n128_set_ui(tenp, 10);
    shift1 = n128_rscan1(np);
    shift2 = n128_rscan1(tenp);
    shift = shift1 - shift2;
    if (shift < 0) {
        /* Divisor is larger than dividend. */
        n128_set_ui(qp, 0);
        n128_set(rp, np);
        return 1;
    }
    n128_blsft(tenp, shift);

    while (1) {
        n128_set(tp, np);
        if (n128_cmp(tp, tenp) >= 0) {
            n128_sub(tp, tenp);
            n128_setbit(qp, 0);
            n128_set(np, tp);
        }
        if (n128_cmp_ui(tenp, 10) == 0) {
            n128_set(rp, np);
            return 1;
        }
        n128_brsft(tenp, 1);
        n128_blsft(qp, 1);
    }
}

/**
 * n128_print_dec(): write an N128 value as a decimal string.
 * @n: N128 object.
 * @buf: decimal string buffer.
 *
 * The buffer is null-terminated on completion. It must have at least
 * 40 characters' capacity to handle all possible cases.
 */
void 
n128_print_dec(n128_t *n, char *buf)
{
    int i = 0;
    int nums[50];
    int nc = 0;
    n128_t na;
    n128_t *np = &na;
    n128_t q;
    n128_t *qp = &q;
    n128_t r;
    n128_t *rp = &r;
    
    n128_set(np, n);
    n128_set(qp, np);

    if (n128_cmp_ui(qp, 0) == 0) {
        *buf++ = '0';
        *buf = '\0';
        return;
    }

    while (n128_cmp_ui(qp, 0) != 0) {
        n128_set(np, qp);
        n128_divmod_10(np, qp, rp);
        nums[nc++] = rp->nums[3];
    }

    --nc;
    for (i = nc; i >= 0; i--) {
        *buf++ = '0' + nums[i];
    }
    *buf = '\0';

    return;
}

#ifdef __cplusplus
}
#endif
