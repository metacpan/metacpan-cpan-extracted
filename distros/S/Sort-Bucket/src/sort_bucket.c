/*
=head1 NAME

sort_bucket.c - the main bucket sort code

=head1 SYNOPSIS

  #include "sort_bucket.c"

  ...

  do_bucket_sort(...);

=head1 DESCRIPTION

Provides a function to perform an in-place bucket sort on a vector of SVs:

  static void
  do_bucket_sort(SV** svs, int svcount, int bucket_bits);

The parameters are:

=over

=item SV** B<svs>

A pointer to the start of the SV vector.

=item int B<svcount>

The number of SVs in the vector.

=item int B<bucket_bits>

The number of bits to use in the major bucket values.  Must not be less than
1 or more than 31.  The input SVs will be distributed into 2^B<bucket_bits>
buckets.

=back

=cut
*/

typedef struct {
    U32  mse_key;
    SV*  mse_sv;
} ms_elt_t;
#define ms_cp(dest, src) ( (dest) = (src) )
#define ms_gt(a,b)       ( (a).mse_key > (b).mse_key )
#include "src/mergesort_algo.c"

#include "src/calculate_bucket_values.c"

static void sb__init_by_bucket_cursor(
      ms_elt_t *by_bucket, ms_elt_t** by_bucket_cursor,
                               int major_bucket_count, int *count_by_bucket);

static void sb__sort_within_major_buckets(
                 ms_elt_t **by_bucket_cursor, int major_bucket_count,
                                            int* count_by_bucket, SV** dest);

static void sb__populate_count_by_bucket(int *count_by_bucket,
                                             U32 *major_b, U32 *major_b_end);

static void sb__populate_buckets(
       ms_elt_t** by_bucket_cursor, U32* major_b, U32 *minor_b,
                                                      SV** svs, int svcount);

static int sb__max_count_by_bucket(
                               int major_bucket_count, int *count_by_bucket);

static void sb__init_by_bucket_cursor(
                 ms_elt_t *by_bucket, ms_elt_t** by_bucket_cursor,
                               int major_bucket_count, int *count_by_bucket);

static void sb__sort_within_major_buckets(
                 ms_elt_t **by_bucket_cursor, int major_bucket_count,
                                            int* count_by_bucket, SV** dest);

static void
do_bucket_sort(SV** svs, int svcount, int bucket_bits)
{
    U32 *minor_b;
    U32 *major_b;
    int major_bucket_count = 1 << bucket_bits;
    int *count_by_bucket, max_count_by_bucket;
    ms_elt_t *by_bucket_storage, *by_bucket;
    ms_elt_t **by_bucket_cursor_storage, **by_bucket_cursor;

    /* Compute the major and minor bucket values for each SV */
    Newx(major_b, svcount, U32);
    Newx(minor_b, svcount, U32);
    calculate_bucket_values(svcount, svs, major_b, minor_b, bucket_bits);

    /* Count the number of SVs that will fall into each major bucket */
    Newxz(count_by_bucket, major_bucket_count, int);
    sb__populate_count_by_bucket(count_by_bucket, major_b, major_b+svcount);

    max_count_by_bucket = sb__max_count_by_bucket(
                                         major_bucket_count, count_by_bucket);
                                              
    /* Allocate storage for a vector of count (SV*, minor bucket) pairs,
     * into which we will load the input SVs and their minor bucket values
     * in major bucket order.  Allow max_count_by_bucket extra slots at
     * the start, to be sure there's enough room for the partially in-place
     * sort within each bucket. */
    Newx(by_bucket_storage, svcount+max_count_by_bucket, ms_elt_t);
    by_bucket = by_bucket_storage + max_count_by_bucket;

    /* We'll need a vector of pointers into by_bucket, to keep track of
     * where we should place the next entry for each possible major bucket
     * value. */
    Newx(by_bucket_cursor_storage, major_bucket_count+1, ms_elt_t*);
    by_bucket_cursor = by_bucket_cursor_storage+1;
    sb__init_by_bucket_cursor(by_bucket, by_bucket_cursor,
                                          major_bucket_count, count_by_bucket);

    /* Now we're ready to load the SVs and their minor bucket values into
     * by_bucket in major bucket order. */
    sb__populate_buckets(by_bucket_cursor, major_b, minor_b, svs, svcount);
    Safefree(major_b);
    Safefree(minor_b);

    /* Now by_bucket_cursor[b] points to the first slot beyond bucket b,
     * i.e. the start of bucket b+1.  Adjust so that by_bucket_cursor[b]
     * points to the start of bucket b again. */
    --by_bucket_cursor;
    by_bucket_cursor[0] = by_bucket;
    
    /* Sort the SVs within each major bucket, and copy the sorted SV*s
     * into the SV vector that we're sorting. */
    sb__sort_within_major_buckets(
         by_bucket_cursor, major_bucket_count, count_by_bucket, svs);

    Safefree(by_bucket_cursor_storage);
    Safefree(by_bucket_storage);
    Safefree(count_by_bucket);
}

/*
=head1 PRIVATE FUNCTIONS

Functions with names starting in C<sb__> are not intended for use outside
this file.

=over

=item sb__populate_count_by_bucket(B<count_by_bucket>, B<major_b>, B<major_b_end>) 

Totals up the number of SVs that take each possible major bucket value, and
populates the B<count_by_bucket> vector of ints.

The elements of B<count_by_bucket> must initially be 0.

=cut
*/

static void
sb__populate_count_by_bucket(int *count_by_bucket,
                                               U32 *major_b, U32 *major_b_end)
{
    while ( major_b < major_b_end ) {
        ++count_by_bucket[ *major_b++ ];
    }
}

/*
=item sb__populate_buckets(B<by_bucket_cursor>, B<major_b>, B<minor_b>, B<svs>, B<svcount>)

Copies the input SVs into the vector of SV/minor_bucket pairs.

=cut
*/

static void
sb__populate_buckets(ms_elt_t** by_bucket_cursor, U32* major_b, U32 *minor_b,
                                                       SV** svs, int svcount)
{
    ms_elt_t *elt;
    U32 *major_b_end = major_b + svcount;

    while ( major_b < major_b_end ) {
        elt = by_bucket_cursor[*major_b++]++;
        elt->mse_key = *minor_b++;
        elt->mse_sv  = *svs++;
    }
}

/*
=item sb__max_count_by_bucket(B<major_bucket_count>, B<count_by_bucket>)

Finds the maximum value in the B<count_by_bucket> vector.

=cut
*/

static int
sb__max_count_by_bucket(int major_bucket_count, int *count_by_bucket)
{
    int i, max_count_by_bucket = 0;

    for ( i=0 ; i<major_bucket_count ; i++ ) {
        if (count_by_bucket[i] > max_count_by_bucket) {
            max_count_by_bucket = count_by_bucket[i];
        }
    }

    return max_count_by_bucket;
}

/*
=item sb__init_by_bucket_cursor(B<by_bucket>, B<by_bucket_cursor>, B<major_bucket_count>, B<count_by_bucket>)

Initialises the B<by_bucket_cursor> vector of pointers into B<by_bucket>, so
that each entry in B<by_bucket_cursor> points to the start of the section of
B<by_bucket> that corresponds to that major bucket value.

=cut
*/

static void
sb__init_by_bucket_cursor(ms_elt_t *by_bucket, ms_elt_t** by_bucket_cursor,
                                int major_bucket_count, int *count_by_bucket) 
{
    while (major_bucket_count--) {
        *by_bucket_cursor++ = by_bucket;
        by_bucket += *count_by_bucket++;
    }
}

/*
=item sb__sort_within_major_buckets(B<by_bucket_cursor>, B<major_bucket_count>, B<count_by_bucket>, B<dest>)

Sorts the elements within each major bucket, initially in minor bucket order
and then falling back to sortsv() for runs that compare equal in minor bucket.

Copies the sorted SV* values out into a destination vector at the same time.

=cut
*/

static void
sb__sort_within_major_buckets(
                 ms_elt_t **by_bucket_cursor, int major_bucket_count,
                                             int* count_by_bucket, SV** dest)
{
    int b, i;

    for ( b=0 ; b<major_bucket_count ; b++ ) {
        if (count_by_bucket[b]) {
            if (count_by_bucket[b] > 1) {
                ms_elt_t *bvals = by_bucket_cursor[b];
                int blen = count_by_bucket[b];
                int in_run =0, runstart =0;
                U32 prev;

                ms_do_mergesort(bvals, blen);
                bvals -= blen-1;

                /* Fall back to Perl's sort for runs that compared equal by 
                 * both major and minor bucket. */
                prev = bvals[0].mse_key;
                *dest++ = bvals[0].mse_sv;
                for ( i=1 ; i<blen ; i++ ) {
                    *dest++ = bvals[i].mse_sv;
                    if (in_run) {
                        if (bvals[i].mse_key != prev) {
                            /* End of the run, sort it in dest */
                            sortsv((dest-1)-(i-runstart), i-runstart, Perl_sv_cmp);
                            in_run = 0;
                            prev = bvals[i].mse_key;
                        }
                    } else {
                        if (bvals[i].mse_key == prev) {
                            /* The start of a new run */
                            in_run = 1;
                            runstart = i-1;
                        } else {
                            prev = bvals[i].mse_key;
                        }
                    }
                }
                if (in_run) {
                    /* This bucket ends on a run. */
                    sortsv(dest-(i-runstart), i-runstart, Perl_sv_cmp);
                }
            } else {
                *dest++ = by_bucket_cursor[b][0].mse_sv;
            }
        }
    }
}

/*
=back

=head1 AUTHOR

Nick Cleaton, E<lt>nick@cleaton.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Nick Cleaton

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
*/
