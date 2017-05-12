#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include <math.h>
#include <stdlib.h>

#define CHARFROMHEX(ch) ( \
	( ( (ch) >= 0x30 ) && ( (ch) <= 0x39 ) ) \
		? (ch) - 0x30 \
		: ( ( (ch) >='a' ) && ( (ch) <= 'f' ) ) \
			? (ch) - 0x57 \
			: ( ( (ch) >='A' ) && ( (ch) <= 'F' ) ) \
				? (ch) - 0x37 \
				: 0 )

#define NIBBLETOHEX(val) \
	( (val) >= 10 && (val) <= 15 ? 87 + (val) : 48 + (val) )

static const char *NIBBLE_HEX_TABLE = "0123456789abcdef";

MODULE = PAB3::Crypt::XOR		PACKAGE = PAB3::Crypt::XOR

BOOT:
{
}

#/******************************************************************************
# * original by BrowseX XOR Encryption
# *
# * The BrowseX  XOR encryption varies by generating a start seed based
# * upon the XORing of all characters in the password. Modulo arithmetic is
# * used with the seed to determine the offset within the password to start.
# * Modulo is again used to determine when to recalculate the seed based upon
# * the currently selected password character. And finally, the password
# * character itself is XORed with the current seed before it is itself used
# * to XOR the data. 
# ******************************************************************************/

#/******************************************************************************
# * xs_aperiodic( _pass, _ibuf )
# ******************************************************************************/

void
xs_aperiodic( _pass, _ibuf )
SV *_pass;
SV *_ibuf;
PREINIT:
	STRLEN plen, ilen, i, p;
	char seed, rval, *obuf, *ibuf, *pass, *p1;
CODE:
	pass = SvPVx( _pass, plen );
	ibuf = SvPVx( _ibuf, ilen );
	New( 1, obuf, ilen, char );
	p1 = obuf;
	seed = pass[0];
	for( i = 1; i < plen; i ++ )
		seed = seed ^ pass[i];
	p = (seed % plen);
	for( i = 0; i < ilen; i ++ ) {
		p ++;
		if( p >= plen ) p = 0;
		rval = pass[p];
		if( p == (seed % plen) )
			seed = (pass[p] ^ seed);
		rval = (pass[p] ^ seed);
		*p1 ++ = (ibuf[i] ^ rval);
	}
	ST(0) = sv_2mortal( newSVpvn( obuf, ilen ) );
	Safefree( obuf );


#/******************************************************************************
# * encrypt_hex( _pass, _ibuf )
# ******************************************************************************/

void encrypt_hex( _pass, _ibuf )
SV *_pass;
SV *_ibuf;
PREINIT:
	STRLEN plen, ilen, i, p;
	char seed, rval, *obuf, *ibuf, *pass, *p1, rem;
CODE:
	pass = SvPVx( _pass, plen );
	ibuf = SvPVx( _ibuf, ilen );
	New( 1, obuf, ilen * 2, char );
	p1 = obuf;
	seed = pass[0];
	for( i = 1; i < plen; i ++ )
		seed = seed ^ pass[i];
	p = (seed % plen);
	for( i = 0; i < ilen; i ++ ) {
		p ++;
		if( p >= plen )
			p = 0;
		rval = pass[p];
		if( p == (seed % plen) ) {
			seed = (pass[p] ^ seed);
		}
		rval = (pass[p] ^ seed);
		rval ^= ibuf[i];
		rem = rval % 16;
		rval /= 16;
		*p1 ++ = NIBBLE_HEX_TABLE[rval];
		*p1 ++ = NIBBLE_HEX_TABLE[rem];
	}
	ST(0) = sv_2mortal( newSVpvn( obuf, p1 - obuf ) );
	Safefree( obuf );


#/******************************************************************************
# * decrypt_hex( _pass, _ibuf )
# ******************************************************************************/

void decrypt_hex( _pass, _ibuf )
SV *_pass;
SV *_ibuf;
PREINIT:
	STRLEN plen, ilen, i, p;
	char seed, rval, *obuf, *ibuf, *pass, *p1, ch, val;
CODE:
	pass = SvPVx( _pass, plen );
	ibuf = SvPVx( _ibuf, ilen );
	New( 1, obuf, ilen / 2 + (ilen % 2) + 1, char );
	p1 = obuf;
	seed = pass[0];
	for( i = 1; i < plen; i ++ )
		seed = seed ^ pass[i];
	p = (seed % plen);
	for( i = 1; i < ilen; i += 2 ) {
		p ++;
		if( p >= plen ) p = 0;
		rval = pass[p];
		if( p == (seed % plen) ) {
			seed = (pass[p] ^ seed);
		}
		rval = (pass[p] ^ seed);
		ch = ibuf[i - 1];
		val = CHARFROMHEX( ch ) << 4;
		ch = ibuf[i];
		*p1 ++ = ((val + CHARFROMHEX( ch )) ^ rval);
	}
	ST(0) = sv_2mortal( newSVpvn( obuf, p1 - obuf ) );
	Safefree( obuf );
