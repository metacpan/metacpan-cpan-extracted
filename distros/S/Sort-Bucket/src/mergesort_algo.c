/*
=head1 NAME

mergesort_algo.c - an implementation of the mergesort algorithm

=head1 SYNOPSIS

  typedef struct my_structure ms_elt_t;
  #define ms_gt(a, b)      ((a).comparison_key > (b).comparison_key)
  #define ms_cp(dest, src) ((dest) = (src))
  #include "mergesort_algo.c"

  ...

  ms_do_mergesort(...);

=head1 DESCRIPTION

An implementation of the mergesort algorithm, generic with respect to the
type of items being sorted.

=head1 DEFINITIONS REQUIRED

Before including this file, you must define the following:

=over

=item ms_elt_t

The type for the elements to be sorted.  ms_do_mergesort() will operate
on vectors of these.

=item ms_gt(ms_elt_t B<a>, ms_elt_t B<b>)

A function or macro to compare two ms_elt_t values, and return true if
B<a> is greater than B<b>.

If implemented as a macro, it may not evaluate either argument more than
once.

=item ms_cp(ms_elt_t B<dest>, ms_elt_t B<src>)

A function or macro to copy one ms_elt_t value to another.

If implemented as a macro, it may not evaluate either argument more than
once.

=back

=head1 FUNCTIONS PROVIDED

=over

=item static void ms_do_mergesort(ms_elt_t *B<vec>, size_t B<len>)>

Sorts the elements B<vec>[0] to B<vec>[B<len>-1].  

The sorted elements will be placed in B<vec>[-(B<len>-1) .. 0].  The contents
of B<vec>[1] to B<vec>[B<len>-1] are undefined after the sort.

Will not attempt to read or write below B<vec>[-(B<len>-1)] or above
B<vec>[B<len>-1].

=cut
*/

static void ms_do_mergesort_2(ms_elt_t *vec);
static void ms_do_mergesort_3(ms_elt_t *vec);

static void ms__merge_sorted_vectors(ms_elt_t* lower, size_t lower_len,
                                            ms_elt_t* upper, ms_elt_t* dest);

static void
ms_do_mergesort(ms_elt_t *vec, size_t len)
{
    switch (len) {
        case 0:
        case 1:
            break;
        case 2:
            ms_do_mergesort_2(vec);
            break;
        case 3:
            ms_do_mergesort_3(vec);
            break;
        default: {
            int lower_len, upper_len;

            /* Split in half, with the extra elt in the lower part if
             * len is odd */
            upper_len = len/2;
            lower_len = len - upper_len;

            /* Sort each half */
            ms_do_mergesort(vec, lower_len);
            ms_do_mergesort(vec+lower_len, upper_len);

            /* Merge the sorted halves to vec[len-1 .. 0] */
            ms__merge_sorted_vectors(
                vec-(lower_len-1), lower_len,
                vec+lower_len - (upper_len-1),
                vec - (len-1)
            );
        }
    }
}

/*
=item C<static void ms_do_mergesort_2(ms_elt_t *vec)>

As ms_do_mergesort(), but for a fixed len of 2.

=cut
*/

static void
ms_do_mergesort_2(ms_elt_t *vec)
{
    /* sort vec[0,1] to vec[-1,0] */

    if ( ms_gt(vec[0], vec[1]) ) {
        ms_cp(vec[-1], vec[1]);
        /* vec[0] already in place */
    } else {
        ms_cp(vec[-1], vec[0]);
        ms_cp(vec[0],  vec[1]);
    }
}

/*
=item C<static void ms_do_mergesort_3(ms_elt_t *vec)>

As ms_do_mergesort(), but for a fixed len of 3.

=cut
*/

static void
ms_do_mergesort_3(ms_elt_t *vec)
{
    /* sort vec[0,1] to vec[-1,0] */
    ms_do_mergesort_2(vec);

    /* merge vec[-1,0] and vec[2] to vec [-2,-1,0] */
    if ( ms_gt(vec[-1], vec[2]) ) {
        ms_cp(vec[-2], vec[2]);
        /* vec[-1,0] already in place */
    } else {
        ms_cp(vec[-2], vec[-1]);
        if ( ms_gt(vec[0], vec[2]) ) {
            ms_cp(vec[-1], vec[2]);
            /* vec[0] already in place */
        } else {
            ms_cp(vec[-1], vec[0]);
            ms_cp(vec[0],  vec[2]);
        }
    }
}

/*
=back

=head1 ALGORITHM

The mergesort algorithm works by splitting the input into two halves,
recursing into each half and then merging the sorted halves together.

This implementation sorts and merges within a single vector.  To sort
N elements, the elements must be placed in the upper part of a vector
of length 2N-1.  They will be sorted into the lower part.

Consider a sort of 7 elements, initially in reverse order and loaded
into the upper part of a vector of length 13:

  Index 0 1 2 3 4 5 6 7 8 9 A B C
  Value             l k j i h g f

First we split the 7 elements into 4 and 3.  We take 4 in the lower
part, and sort the lower part first.  To sort those 4 elements, we
split them into 2 sets of 2.  The lower 2 (l,k) are now sorted
from slots 6,7 to slots 5,6:

  Index 0 1 2 3 4 5 6 7 8 9 A B C
  Value           k l   j i h g f

Next we sort (j,i) from slots 8,9 to slots 7,8:

  Index 0 1 2 3 4 5 6 7 8 9 A B C
  Value           k l i j   h g f

To finish the sort of the lower 4, we merge pairs (k,l) and (i,j) into
slots 3,4,5,6:

  Index 0 1 2 3 4 5 6 7 8 9 A B C
  Value       i j k l       h g f

Now we move on to sorting (h,g,f).  Split it into (h,g) and (f), and sort
(h,g) into slots 9,A:

  Index 0 1 2 3 4 5 6 7 8 9 A B C
  Value       i j k l     g h   f

Now merge (g,h) and (f) into slots 8,9,A:

  Index 0 1 2 3 4 5 6 7 8 9 A B C
  Value       i j k l   f g h    

Finally merge (i,j,k,l) and (f,g,h) into slots 0,1,2,3,4,5,6:

  Index 0 1 2 3 4 5 6 7 8 9 A B C
  Value f g h i j k l            

A couple of points to note:

Each sort of N elements moves the sorted elements down exactly N-1
places.  Thus sorting the lower part first and ensuring that the lower part
length is >= the upper part length is enough to prevent the sorted parts
from overlapping.

When merging, the destination for the merge overlaps the lower source.
This is ok because the write pointer does not catch the lower read pointer
until the upper source is exhausted, at which point the merge is done and
the remainder of the upper source does not need to be moved.

This enables a small optimisation in the merge: there is no need to keep
track of the end of the upper source, since exhaustion of the upper source
can be tested for by comparing the write pointer with the lower read pointer.

=head1 PRIVATE FUNCTIONS

Functions with names starting in C<ms__> are not intended for use outside
this file.

=over

=item ms__merge_sorted_vectors(B<lower>, B<lower_len>, B<upper>, B<dest>)

The merge part of the mergesort algorithm.

B<lower> is a pointer to the lower input vector, B<lower_len> is its length.

B<upper> is a pointer to the upper input vector.

B<dest> is the destination for the merged vector.  The destination must be
such that the dest pointer catches the lower input pointer when the upper
input vector is exhausted, see ALGORITHM above.

Both input vectors must contain at least 1 element.

=cut
*/

static void
ms__merge_sorted_vectors(ms_elt_t* lower, size_t lower_len,
                                            ms_elt_t* upper, ms_elt_t* dest)
{
    ms_elt_t *lower_end = lower + lower_len;

    for (;;) {
        if ( ms_gt(*lower, *upper) ) {
            ms_cp(*dest++, *upper++);
            if ( dest >= lower ) {
                /* Upper half exhausted - done */
                break;
            }
        } else {
            ms_cp(*dest++, *lower++);
            if ( lower >= lower_end ) {
                /* Lower half exhausted */
                while (dest < lower) {
                    ms_cp(*dest++, *upper++);
                }
                break;
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
