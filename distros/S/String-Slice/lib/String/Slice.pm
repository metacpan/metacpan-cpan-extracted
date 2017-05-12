# TODO:
# - Maybe support negative length (like substr).
# - Get code review to see if char offset in IV is OK.
# - Maybe croak unless string/slice match on utf8-ness.
use strict;
package String::Slice;

our $VERSION = '0.08';

use Exporter 'import';
our @EXPORT = qw(slice);

use Config;
use Inline C => Config => ccflags => $Config::Config{ccflags} . " -Wall";

use String::Slice::Inline C => <<'...';
int slice (SV* dummy, ...) {
  dVAR; dXSARGS;

  // Validate input:
  if (items < 2 || items > 4)
    croak("Usage: String::Slice::slice($slice, $string, $offset=0, $length=-1)");
  if (! SvPOKp(ST(0)))
    croak("String::Slice::slice '$slice' argument is not a string");
  if (! SvPOKp(ST(1)))
    croak("String::Slice::slice '$string' argument is not a string");
  {
    SV* slice = ST(0);
    SV* string = ST(1);
    I32 offset = items < 3 ? 0 : (I32)SvIV(ST(2));
    STRLEN length = items < 4 ? -1 : (STRLEN)SvUV(ST(3));

    // Set up local variables:
    U8* slice_ptr = SvPVX(slice);
    I32 slice_off;

    U8* string_ptr = SvPVX(string);
    U8* string_end = SvEND(string);

    U8* base_ptr;

    // Force string and slice to be string-type-scalars (SVt_PV):
#if PERL_VERSION > 18
    if(SvIsCOW(slice)) sv_force_normal(slice);
#endif

    // Is this a new slice? Start at beginning of string:
    if (slice_ptr < string_ptr || slice_ptr > string_end) {
      // Link the refcnt of string to slice:  (rafl++)
      sv_magicext(slice, string, PERL_MAGIC_ext, NULL, NULL, 0);

      // Special way to tell perl it doesn't own the slice memory:  (jdb++)
      SvLEN_set(slice, 0);

      // Make slice be utf8 if string is utf8:
      if (SvUTF8(string))
        SvUTF8_on(slice);

      // Make the SVs readonly:
      SvREADONLY_on(slice);
      SvREADONLY_on(string);

      base_ptr = string_ptr;
      slice_off = 0;
    }
    // Existing slice. Use it as starting point:
    else {
      base_ptr = slice_ptr;
      slice_off = SvIVX(slice);
    }

    if (SvUTF8(string)) {
      // Hop to the new offset:
      slice_ptr = utf8_hop(base_ptr, (offset - slice_off));
    } else {
      slice_ptr = base_ptr + (offset - slice_off);
    }

    // New offset is out of bounds. Handle failure:
    if (slice_ptr < string_ptr || slice_ptr > string_end) {
      // Reset the slice:
      SvPV_set(slice, 0);
      SvCUR_set(slice, 0);
      SvIVX(slice) = 0;

      // Failure:
      return 0;
    }
    // New offset is OK. Handle success:
    else {
      // Set the slice pointer:
      SvPV_set(slice, slice_ptr);

      // Set the slice character offset (sneaky hack into IV slot):
      SvIVX(slice) = offset;

      // Calculate and set the proper byte length for the utf8 slice:

      if (length < 0) {
          SvCUR_set(slice, string_end - slice_ptr);
      }
      else if (SvUTF8(string)) {
        if (length >= utf8_distance(string_end, slice_ptr)) {
          SvCUR_set(slice, string_end - slice_ptr);
        }
        else
          SvCUR_set(slice, utf8_hop(slice_ptr, length) - slice_ptr);
      } else {
        if (length >= string_end - slice_ptr)
          SvCUR_set(slice, string_end - slice_ptr);
        else
          SvCUR_set(slice, length);
      }

      // Success:
      return 1;
    }
  }
}
...

1;
