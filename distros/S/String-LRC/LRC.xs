/*
 * Perl Extension for LRC computations
 * Author...: Ralph Padron (whoelse@elitedigital.net)
 * Revised..: 01-May-2002
 *
 * The Longitudinal Redundancy Check (LRC) is a one byte character,
 * commonly used as a field in data transmission over analog systems.
 * 
 * Most commonly, in STX-ETX bounded strings sent in financial protocols.
 *
 * Following some previous experience with such protocols, I wrote
 * an LRC function in perl and later decided to re-write in C 
 * for efficiency.  The result is this module String::LRC
 * 
 * NOTE:
 *	Included sv_type comparison and lrcinit in v1.01 
 *	following the idea by Soenke J. Peters and others 
 *	that someone perhaps can use the LRC of a file.
 *
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/*
# * In String-LRC v1.00, I ran this in perl simply by doing
# * the XOR like this.
# * 
# * my $buffer = shift(@_);
# * my @str = split(//,$buffer);
# * my $len = 0;
# * $len = length($buffer) if ($buffer);
# * my ($i, $check);
# * for ($i = 0;$i < $len ; $i++) {
# *	$check = $check ^ $str[$i];
# * }# for
# * return $check;
# *
# *
 */

/* getlrc(...)
 * generate the lrc using the XOR of each byte
 *
 * ALTERNATIVE:
 * generate the lrc using a unsigned char sum of each ptr 
 * position in the string, and then take the two's complment.
 * My OS professor from college would kill me, but I have to admit, I'm 
 * not sure if the XOR and this alternative are actually equivalent.
 *
 */ 
unsigned char 
getlrc(unsigned char *string, unsigned long stringSize, unsigned char lrcinit)
{
  unsigned long i;
  unsigned char lrc  = lrcinit;
  unsigned char *buf = (unsigned char *) string;
  for (i=0; i < stringSize;  i++)
	lrc = lrc ^ buf[i];
  return (unsigned char) lrc; 
} // getlrc

unsigned char getlrc_fp(PerlIO *fp,unsigned char lrcinit)
{
    unsigned char lrc = lrcinit;
    int c;
    while( (c=PerlIO_getc(fp)) != EOF ) {
        lrc = lrc ^ c;
    }
    return (unsigned char) lrc;		// normal return of lrc byte
}

svtype getsvtype(SV *sv)
{
  if (sv == NULL )
    return SVt_NULL;
  if (SvROK(sv))
    return SvTYPE(SvRV(sv));
  else 
    return SvTYPE(sv);
}


MODULE = String::LRC		PACKAGE = String::LRC

VERSIONCHECK: DISABLE
PROTOTYPES: DISABLE 


unsigned char
lrc(data, ...)
    char *data = NO_INIT
    PREINIT:
    unsigned char lrcinit = 0x00;
    STRLEN data_len;
    PPCODE:
	int sv_type;
	IO *io;
	SV *sv;
	unsigned char rv;
      {
	if ( items > 1 )
		lrcinit = (unsigned char) SvNV(ST(items - 1));

	sv_type = getsvtype(ST(0));

	if (sv_type == SVt_PVGV)
	  {
		io = sv_2io(ST(0));
		rv = (unsigned char) getlrc_fp(IoIFP(io), lrcinit);
	  }
	else
	  {
		data = (char *)SvPV(ST(0),data_len);
		rv = (unsigned char) getlrc(data, data_len, lrcinit);
	  }
	EXTEND(sp, 1);
	sv = newSV(0);
	//sv_setuv(sv, (UV)rv);
	sv_setpvn(sv, (char *)&rv, 1);
	PUSHs(sv_2mortal(sv));
      }
