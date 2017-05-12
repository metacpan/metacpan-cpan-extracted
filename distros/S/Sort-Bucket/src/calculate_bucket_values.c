/*
=head1 NAME

calculate_bucket_values.c - compute bucket values for SVs

=head1 SYNOPSIS

  #include "calculate_bucket_values.c"

  ...

  calculate_bucket_values(...);

=head1 DESCRIPTION

Provides a function to compute vectors of major and minor numerical bucket
values from a vector of SVs:

  static void calculate_bucket_values(
            int svcount, SV** src,
            U32* b_major, U32* b_minor, int major_bits);

The parameters are:

=over

=item int B<svcount>

The number of SVs in the vector.

=item SV** B<src>

A pointer to the start of the SV vector.

=item U32 *B<b_major>

A pointer to a vector of B<svcount> U32s.  The major bucket values are to be
stored here.

=item U32 *B<b_minor>

A pointer to a vector of B<svcount> U32s.  The minor bucket values are to be
stored here.

=item int B<major_bits>

The number of bits to use in the major bucket values.  Must not be less than
1 or more than 31.

The major bucket values will range from 0 to (2^B<major_bits>)-1.

=back

=cut
*/

static void cbv__1to7(  int svcount, SV** src,
                           U32* b_major, U32* b_minor, int major_bits);
static void cbv__8to15( int svcount, SV** src,
                           U32* b_major, U32* b_minor, int major_bits);
static void cbv__16to23(int svcount, SV** src,
                           U32* b_major, U32* b_minor, int major_bits);
static void cbv__24to31(int svcount, SV** src,
                           U32* b_major, U32* b_minor, int major_bits);

static void
calculate_bucket_values(int svcount, SV** src,
                              U32* b_major, U32* b_minor, int major_bits)
{
    if (major_bits < 8) {
        cbv__1to7(  svcount, src, b_major, b_minor, major_bits);
    } else if (major_bits < 16) {
        cbv__8to15( svcount, src, b_major, b_minor, major_bits);
    } else if (major_bits < 24) {
        cbv__16to23(svcount, src, b_major, b_minor, major_bits);
    } else {
        cbv__24to31(svcount, src, b_major, b_minor, major_bits);
    }
}

/*
=head1 PRIVATE FUNCTIONS

Functions with names starting in C<cbv__> are not intended for use outside
this file.

=over

=item cbv__sv_to_null_padded_str(B<sv>, B<want_len>, B<buf>)

Converts B<sv> to a string, padding with NULLs if necessary to ensure
that its length is at least B<want_len> bytes.

B<buf> is storage into which this function may choose to copy the string.
It must have capacity for B<want_len> bytes.

Returns a pointer to the string.

=cut
*/

static unsigned char *
cbv__sv_to_null_padded_str(SV *sv, int want_len, unsigned char *buf)
{
    unsigned char *pv;
    STRLEN cur;

    if (sv) {
        pv = SvPV(sv, cur);
    } else {
        cur = 0;
    }

    if (cur < want_len) {
        int i;
        for ( i=0 ; i<cur ; i++ ) {
            buf[i] = pv[i];
        }
        for ( ; i<want_len ; i++ ) {
            buf[i] = '\0';
        }
        return buf;
    } else {
        return pv;
    }
}

/*
=item cbv__1to7(B<svcount>, B<src>, B<b_major>, B<b_minor>, B<major_bits>)

An implementation of calculate_bucket_values() for B<major_bits> in the range
1 to 7.

The most significant B<major_bits> bits of byte 0 are taken as the
major bucket, and bytes 0,1,2,3 are packed into the minor bucket value.

=cut
*/

static void
cbv__1to7(int svcount, SV** src,
                               U32* b_major, U32* b_minor, int major_bits)
{
    unsigned char *pv, buf[4];
    int major_rightshift = 8 - major_bits;

    while (svcount--) {
        pv = cbv__sv_to_null_padded_str(*src++, sizeof(buf), buf);
        *b_major++ = pv[0] >> major_rightshift;
        *b_minor++ = (pv[0] << 24) + (pv[1] << 16) + (pv[2] << 8) + pv[3];
    }
}

/*
=item cbv__8to15(B<svcount>, B<src>, B<b_major>, B<b_minor>, B<major_bits>)

An implementation of calculate_bucket_values() for B<major_bits> in the range
8 to 15.

The most significant B<major_bits> bits of bytes 0,1 are taken as the
major bucket, and bytes 1,2,3,4 are packed into the minor bucket value.

=cut
*/

static void
cbv__8to15(int svcount, SV** src,
                               U32* b_major, U32* b_minor, int major_bits)
{
    unsigned char *pv, buf[4+1];
    int major_rightshift = 32 - major_bits;
    U32 bucket;

    while (svcount--) {
        pv = cbv__sv_to_null_padded_str(*src++, sizeof(buf), buf);
        bucket = (pv[0] << 24) + (pv[1] << 16) + (pv[2] << 8) + pv[3];
        *b_major++ = bucket >> major_rightshift;
        *b_minor++ = (bucket << 8) + pv[4];
    }
}

/*
=item cbv__16to23(B<svcount>, B<src>, B<b_major>, B<b_minor>, B<major_bits>)

An implementation of calculate_bucket_values() for B<major_bits> in the range
16 to 23.

The most significant B<major_bits> bits of bytes 0,1,2 are
taken as the major bucket, and bytes 2,3,4,5 are packed into the minor
bucket value.

=cut
*/

static void
cbv__16to23(int svcount, SV** src,
                               U32* b_major, U32* b_minor, int major_bits)
{
    unsigned char *pv, buf[4+2];
    int major_rightshift = 32 - major_bits;
    U32 bucket;

    while (svcount--) {
        pv = cbv__sv_to_null_padded_str(*src++, sizeof(buf), buf);
        bucket = (pv[0] << 24) + (pv[1] << 16) + (pv[2] << 8) + pv[3];
        *b_major++ = bucket >> major_rightshift;
        *b_minor++ = (bucket << 16) + (pv[4] << 8) + pv[5];
    }
}

/*
=item cbv__24to31(B<svcount>, B<src>, B<b_major>, B<b_minor>, B<major_bits>)

An implementation of calculate_bucket_values() for B<major_bits> in the range
24 to 31.

The most significant B<major_bits> bits of bytes 0,1,2,3 are
taken as the major bucket, and bytes 3,4,5,6 are packed into the minor
bucket value.

=cut
*/

static void
cbv__24to31(int svcount, SV** src,
                               U32* b_major, U32* b_minor, int major_bits)
{
    unsigned char *pv, buf[4+3];
    int major_rightshift = 32 - major_bits;
    U32 bucket;

    while (svcount--) {
        pv = cbv__sv_to_null_padded_str(*src++, sizeof(buf), buf);
        bucket = (pv[0] << 24) + (pv[1] << 16) + (pv[2] << 8) + pv[3];
        *b_major++ = bucket >> major_rightshift;
        *b_minor++ = (bucket << 24) + (pv[4] << 16) + (pv[5] << 8) + pv[6];
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
