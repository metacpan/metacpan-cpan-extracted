/*
Perl Extension for CRC computations
*/

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* 
 * From Matt Dillon's Diablo package.  Used with permission.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

typedef struct crc_hash_t {
    U32		h1;
    U32		h2;
} crc_hash_t;

typedef struct crc_Hash {
    struct crc_Hash *ha_Next;
    crc_hash_t	ha_Hv;
} crc_Hash;

int	crc_HashLimit = 0;

/*
 * Poly: 0x00600340.00F0D50A
 */

#define HINIT1	0xFAC432B1UL
#define HINIT2	0x0CD5E44AUL

#define POLY1	0x00600340UL
#define POLY2	0x00F0D50BUL

crc_hash_t CrcXor[256];
crc_hash_t Poly[64+1];

void
crc_init(void)
{
    int i;

    /*
     * Polynomials to use for various crc sizes.  Start with the 64 bit
     * polynomial and shift it right to generate the polynomials for fewer
     * bits.  Note that the polynomial for N bits has no bit set above N-8.
     * This allows us to do a simple table-driven CRC.
     */

    Poly[64].h1 = POLY1;
    Poly[64].h2 = POLY2;
    for (i = 63; i >= 16; --i) {
	Poly[i].h1 = Poly[i+1].h1 >> 1;
	Poly[i].h2 = (Poly[i+1].h2 >> 1) | ((Poly[i+1].h1 & 1) << 31) | 1;
    }

    for (i = 0; i < 256; ++i) {
	int j;
	int v = i;
	crc_hash_t hv = { 0, 0 };

	for (j = 0; j < 8; ++j, (v <<= 1)) {
	    hv.h1 <<= 1;
	    if (hv.h2 & 0x80000000UL)
		hv.h1 |= 1;
	    hv.h2 = (hv.h2 << 1);
	    if (v & 0x80) {
		hv.h1 ^= Poly[crc_HashLimit].h1;
		hv.h2 ^= Poly[crc_HashLimit].h2;
	    }
	}
	CrcXor[i] = hv;
    }
}

/*
 * testhash() - do the CRC.  The complexity is simply due to the programmable
 *		nature of the number of bits.   We extract the top 8 bits to
 *		use as a table lookup to obtain the polynomial XOR 8 bits at
 *		a time rather then 1 bit at a time.
 */

crc_hash_t
crc_calculate(char *p, int len)
{
    crc_hash_t hv = { HINIT1, HINIT2 };
    char *e = p + len;

    if (crc_HashLimit <= 32) {
	int s = crc_HashLimit - 8;
	U32 m = (U32)-1 >> (32 - crc_HashLimit);

	hv.h1 = 0;
	hv.h2 &= m;

	while (p < e) {
	    int i = (hv.h2 >> s) & 255;
	    /* printf("i = %d %08lx\n", i, CrcXor[i].h2); */
	    hv.h2 = ((hv.h2 << 8) & m) ^ *p ^ CrcXor[i].h2;
	    ++p;
	}
    } else if (crc_HashLimit < 32+8) {
	int s2 = 32 + 8 - crc_HashLimit;	/* bits in byte from h2 */
	U32 m = (U32)-1 >> (64 - crc_HashLimit);

	hv.h1 &= m;
	while (p < e) {
	    int i = ((hv.h1 << s2) | (hv.h2 >> (32 - s2))) & 255;
	    hv.h1 = (((hv.h1 << 8) ^ (int)(hv.h2 >> 24)) & m) ^ CrcXor[i].h1;
	    hv.h2 = (hv.h2 << 8) ^ *p ^ CrcXor[i].h2;
	    ++p;
	}
    } else {
	int s = crc_HashLimit - 40;
	U32 m = (U32)-1 >> (64 - crc_HashLimit);

	hv.h1 &= m;
	while (p < e) {
	    int i = (hv.h1 >> s) & 255;
	    hv.h1 = ((hv.h1 << 8) & m) ^ (int)(hv.h2 >> 24) ^ CrcXor[i].h1;
	    hv.h2 = (hv.h2 << 8) ^ *p ^ CrcXor[i].h2;
	    ++p;
	}
    }
    /* printf("%08lx.%08lx\n", (long)hv.h1, (long)hv.h2); */
    return(hv);
}


MODULE = String::CRC		PACKAGE = String::CRC

VERSIONCHECK: DISABLE

void
crc(data,bits=32)
    PREINIT:
	int data_len;
    INPUT:
	char *data = (char *)SvPV(ST(0),data_len);
	int bits;
    PPCODE:
	{
		crc_hash_t	h;
		U32		*rv;
		SV		*sv;

		if (bits < 16  || bits > 64) {
		    croak("String::CRC bits must be >= 16 and <= 64");
		}
		if (bits != crc_HashLimit) {
		    crc_HashLimit = bits;
		    crc_init();
		}
		h = crc_calculate(data, data_len);
		if (bits > 32 && GIMME == G_ARRAY) {
		    EXTEND(sp, 2);
		    sv = newSV(0);
		    sv_setuv(sv, (UV)h.h1);
		    PUSHs(sv_2mortal(sv));
		    sv = newSV(0);
		    sv_setuv(sv, (UV)h.h2);
		    PUSHs(sv_2mortal(sv));
		} else if (bits > 32) {
		    /* 
		     * problem.  how to return 64 bits in 32? 
		     * answer: as a string.
		     * U32 better be == 4 bytes!
		     */
		    EXTEND(sp, 1);
		    PUSHs(sv_2mortal(newSVpv((char *)&h, 8)));
		    if (sizeof(U32) != 4) croak("U32 not four bytes!");
		} else {
		    EXTEND(sp, 1);
		    sv = newSV(0);
		    sv_setuv(sv, (UV)h.h2);
		    PUSHs(sv_2mortal(sv));
		    /* PUSHs(sv_2mortal(newSViv(h.h2)));*/
		}
	}


