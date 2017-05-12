/* Fast xor routine */
/*
  Copyright (c) by Declan Malone 2013.
  Licensed under the terms of the GNU General Public License and
  the GNU Lesser (Library) General Public License.
*/

// implementation of fast_xor_strings follows that of the Perl
// safe_xor_strings subroutine.

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "xor.h"

MODULE = Net::OnlineCode  PACKAGE = Net::OnlineCode

PROTOTYPES: ENABLE

SV *
fast_xor_strings (dest_Str, ...)
	SV *dest_Str;
CODE:

  STRLEN  dest_size;
  char   *dest_ptr;
  SV     *dest_deref;

  SV     *source_Str;
  STRLEN  source_size;
  char   *source_ptr;

  int i;

  // dest_Str must be a referenece to a scalar
  if (!(SvROK(dest_Str) && SvTYPE((dest_deref = SvRV(dest_Str)))== SVt_PV)) {
    fprintf(stderr, "fast_xor_strings: arg 1 should be a reference to a SCALAR!\n");
    exit(1);			// Is this OK? It will do for now.
  }

  // get pointer to and length of (dereferenced) destination string
  dest_ptr = SvPV(dest_deref, dest_size);
  if (dest_size == 0) {
    fprintf(stderr, "fast_xor_strings: source string can't have zero length!\n");
    exit(1);
  }

  // handle variadic args
  if (items > 1) {
    for (i = 1; i < items; i++) {
      source_Str = ST(i);
      source_ptr = SvPV (source_Str, source_size);

      if (dest_size != source_size) {
	fprintf(stderr, "fast_xor_strings: targets not all same size as source\n");
	exit(1);
      }

      // call C library routine
      aligned_word_xor(dest_ptr, source_ptr, dest_size);
    }
  }

  // return the dereferenced SV
  SvREFCNT_inc(dest_deref); // fix up refcount for $$dest_Str
  RETVAL = dest_deref;
OUTPUT:
  RETVAL

#void
#bytewise_xor (dest, src, bytes)
#	char *dest
#	char *src
#	unsigned int bytes
#
#
#void
#aligned_word_xor (dest, src, bytes)
#	char *dest
#	char *src
#	unsigned int bytes
