#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "src/sort_bucket.c"

MODULE = Sort::Bucket		PACKAGE = Sort::Bucket		

void
inplace_bucket_sort(av, bucket_bits=0)
        AV * av
        int bucket_bits
PROTOTYPE: \@;$
INIT:
        int len;
CODE:
    len = 1 + av_len(av);

    if (SvREADONLY(av))
        croak("%s", PL_no_modify);

    if (bucket_bits) {
        if (bucket_bits < 1 || bucket_bits > 31) {
            croak("%s", "bucket bits out of range");
        }
    } else if (len < 1024) {
        bucket_bits = 8;
    } else {
        int i = len>>12;
        bucket_bits = 8;
        while (i) {
            ++bucket_bits;
            i >>= 1;
        }
    }

    SvREADONLY_on(av);
    do_bucket_sort(AvARRAY(av), len, bucket_bits);
    SvREADONLY_off(av);

=head1 FUNCTIONS FOR TESTING

These functions are intended for use in the test suite.

=over

=item _set_readonly_for_testing(B<av>)

Sets the readonly flag on an AV.

=cut

void
_set_readonly_for_testing(av)
    AV * av
PROTOTYPE: \@
CODE:
    SvREADONLY_on(av);    

=item _ms_do_mergesort_testharness(B<values>, B<offset>, B<sortlen>)

This function gives the test suite low-level access to ms_do_mergesort().

The B<values> AV must hold U32 values.  Calls ms_do_mergesort() on
B<values>[B<offset> .. B<offset>+B<sortlen>-1], which will sort those
elements partially in place, moving them down B<sortlen>-1 slots in the
process.  See F<src/mergesort_algo.c>.

After this function returns, the elements of B<values> will be error
message strings if a problem was detected, otherwise they will be integers
giving the index within B<values> of the element that was moved to this
slot by the sort.

=cut

void
_ms_do_mergesort_testharness(values, offset, sortlen)
    AV* values
    int offset
    int sortlen
PROTOTYPE: \@$$
INIT:
    int vec_len, i, j;
    ms_elt_t *storage, *orig_storage;
    unsigned char *pv;
    STRLEN cur;
    SV *dummy_sv_vector;
CODE:
    if (sortlen < 1) {
        croak("sortlen < 1");
    }
    vec_len = 1 + av_len(values);
    if (offset + sortlen > vec_len) {
        croak("sort would read off the top of values");
    }
    if (offset < sortlen-1) {
        croak("sort would write off the bottom of values");
    }

    Newx(storage, vec_len, ms_elt_t);
    Newxz(dummy_sv_vector, vec_len, SV);
    for ( i=0 ; i<vec_len ; i++ ) {
        SV** elt = av_fetch(values, i, 0);
        if (!elt) {
            Safefree(dummy_sv_vector); Safefree(storage);
            croak("missing elt at %d", i);
        }
        storage[i].mse_key = SvUV(*elt);
        storage[i].mse_sv  = dummy_sv_vector + i;
    }
    
    Newx(orig_storage, vec_len, ms_elt_t);
    Copy(storage, orig_storage, vec_len, ms_elt_t);
    ms_do_mergesort(storage+offset, sortlen);

    for ( i=0 ; i<vec_len ; i++ ) {
        SV** elt = av_fetch(values, i, 0);
        int orig_pos = storage[i].mse_sv - dummy_sv_vector;
        if (orig_pos < 0 || orig_pos >= vec_len) {
            sv_setpv(*elt, "mse_sv out of bounds");
        } else if ( storage[i].mse_key != orig_storage[orig_pos].mse_key ) {
            sv_setpv(*elt, "mse_key does not match mse_sv");
        } else {
            sv_setiv(*elt, orig_pos);
        }
    }

    Safefree(orig_storage);
    Safefree(storage);
    Safefree(dummy_sv_vector);

=item _cbv_testharness(B<sv>, B<bits>, B<major_out>, B<minor_out>)

Compute the major and minor bucket values of a single SV.

=cut

void
_cbv_testharness(sv, bits, major_out, minor_out)
    SV* sv
    int bits
    SV* major_out
    SV* minor_out
PROTOTYPE: $$$$
INIT:
    U32 b_major[1], b_minor[1];
CODE:
    if (!sv || !major_out || !minor_out)
        croak("null SV*");
    if (bits < 1)
        croak("bits < 1");
    if (bits > 31) 
        croak("bits > 31");

    calculate_bucket_values(1, &sv, b_major, b_minor, bits);

    sv_setnv(major_out, (double)b_major[0]);
    sv_setnv(minor_out, (double)b_minor[0]);

=item _cbv_testharness_check_for_descending(B<array>, B<bits>)

Compute the major and minor bucket values for an array, using B<bits>
major bits.  Scan through the bucket values and identify the index of the
first element with bucket values lower than the previous element.
Return the index, or 0 if the bucket value sequence is non-descending.

Handy for testing - you feed it a sorted array and if it finds a
point where the bucket values descend that's a bug in the bucket value
calculation.

=cut

int
_cbv_testharness_check_for_descending(array, bits)
    AV* array
    int bits
PROTOTYPE: \@$
INIT:
    U32 *b_major, *b_minor;
    int len, i;
CODE:
    if (bits < 1)
        croak("bits < 1");
    if (bits > 31) 
        croak("bits > 31");

    len = 1 + av_len(array);
    Newx(b_major, len, U32);
    Newx(b_minor, len, U32);
    calculate_bucket_values(len, AvARRAY(array), b_major, b_minor, bits);

    RETVAL = 0;
    for ( i=1 ; i<len ; i++ ) {
        if (b_major[i] < b_major[i-1] 
          || (b_major[i] == b_major[i-1] && b_minor[i] < b_minor[i-1])
           ) {
            /* disorder at i */
            RETVAL = i;
            break;
        }
    }

    Safefree(b_major);
    Safefree(b_minor);
OUTPUT:
    RETVAL

=back

=cut

