package OpenSSL::Versions;

use 5.006;
use strict;
use warnings;
use Carp;
use Exporter qw( import );

our $VERSION = '0.002';
$VERSION = eval $VERSION;

our @EXPORT = ();
our @EXPORT_OK = qw( parse_openssl_version_number );

sub parse_openssl_version_number {
    my ($vstr) = @_;

    $vstr =~ s/^0x//; # remove hex prefix

    # 0.9.6 or later : MNNFFPPS : major, minor, fix, patch, status (0-f)
    # 0.9.5a to before 0.9.6 : high bit of PP is set in MNNFFPPS
    # 0.9.3-dev to before 0.9.5a : MNNFFRBB : major, minor, fix, status (0-1), beta
    # prior to 0.9.3-dev, MNFP

    my @ret;

    if ( $vstr =~ /^(?:[1-9]|0090[6-9])/ ) {
        @ret = ( OpenSSL => _parse_openssl_v096_or_later( $vstr ) );
    }
    elsif ( $vstr =~ /^00905[8-9]/ ) {
        @ret = ( OpenSSL => _parse_openssl_v095a_096( $vstr ) );
    }
    elsif ( $vstr =~ /^0090[3-5][01]/ ) {
       @ret = ( OpenSSL => _parse_openssl_v093dev_095a( $vstr ) );
    }
    else {
        @ret = ( SSLeay => _parse_openssl_pre_v093dev( $vstr ) );
    }

    return wantarray ? reverse @ret : $ret[1];
}

sub _parse_openssl_v096_or_later {
    my ($vstr) = @_;

    # 0.9.6 or later : MNNFFPPS : major, minor, fix, patch, status (0-f)
    my $pat = join '', map "([[:xdigit:]]{$_})", (1, 2, 2, 2, 1);
    
    my @v = $vstr =~ /^$pat\z/;
    
    unless (@v == 5) {
        _croak_invalid_vstr($vstr);
    }

    # The value of OPENSSL_VERSION_NUMBER for in crypto/opensslv.h in the
    # OpenSSL 0.9.8f distribution is inconsistent with the description. We have
    # #define OPENSSL_VERSION_NUMBER	0x00908070L in the header file.
    # However, the comment above the definition states: "The status nibble has
    # one of the values 0 for development, 1 to e for betas 1 to 14, and f for
    # release." According to that description, the version string for that
    # number should be 0.9.8f-dev. This number is special cased below due to
    # that discrepancy.

    if ($vstr eq '00908070') {
        return '0.9.8f';
    }

    my ($major, $minor, $fix, $patch, $status) = map hex, @v;

    $patch = $patch ? chr( ord('a') + $patch - 1 ) : '';

    if    ( $status ==  0 ) { $status = '-dev' }
    elsif ( $status == 15 ) { $status = '' }
    else                    { $status = "-beta$status" }
    return sprintf( '%u.%u.%u%s%s', $major, $minor, $fix, $patch, $status);
}

sub _parse_openssl_v095a_096 {
    my ($vstr) = @_;

    # 0.9.5a to before 0.9.6 :
    # high bit of PP is set in MNNFFPPS

    return _parse_openssl_v096_or_later(
        sprintf '%08x', hex($vstr) & 0xfffff7ff
    );
}

sub _parse_openssl_v093dev_095a {
    my ($vstr) = @_;

    # Prior to 0.9.5a beta1, a different scheme was used: 
    # MMNNFFRBB for major minor fix final patch/beta)

    my @v = $vstr =~ /^(0)(09)(0[3-5])([0-1])(..)\z/;

    unless (@v == 5) {
        _croak_invalid_vstr($vstr);
    }

    my ($major, $minor, $fix, $status, $patch) = map hex, @v;

    $patch = $patch ? chr( ord('a') + $patch - 1 ) : '';
    $status = $status ? '' : '-dev';
    return sprintf( '%u.%u.%u%s%s', $major, $minor, $fix, $patch, $status );
}

sub _parse_openssl_pre_v093dev {
    my ($vstr) = @_;

    # prior to 0.9.3-dev,
    # MNFP : major, minor, fix, patch

    my @v = $vstr =~ /^(0)(9)([12])([0-9])$/;

    unless (@v == 4) {
        croak "'$vstr' does not look like a valid value for OPENSSL_VERSION_NUMBER";
    }

    my ($major, $minor, $fix, $patch) = map hex, @v;

    $patch = $patch ? chr( ord('a') + $patch - 1 ) : '';
    return sprintf( '%u.%u.%u%s', $major, $minor, $fix, $patch );
}

sub _croak_invalid_vstr {
    my ($vstr) = @_;
    
    croak "'$vstr' does not look like a valid value for OPENSSL_VERSION_NUMBER";
}

1;

__END__

=head1 NAME

OpenSSL::Versions - Parse OpenSSL version number

=head1 VERSION

Version 0.001

=head1 SYNOPSIS

Parse OpenSSL version number from source code.

    use OpenSSL::Versions qw( parse_openssl_version_number );
    my $v = parse_openssl_version_number('0x0913');
    print "$v\n";

Outputs:

    0.9.1c


=head1 MOTIVATION

OpenSSL source code uses a hexadecimal number which encodes various bits of
information. The meaning of various parts have changed over the history of the
library. For example, you have

    #define OPENSSL_VERSION_NUMBER	0x0913	/* Version 0.9.1c is 0913 */

versus

    #define OPENSSL_VERSION_NUMBER	0x1000007fL /* OpenSSL 1.0.0g */

The evolution of the version number scheme is explained in the
C<crypto/opensslv.h> file in the distribution. If you have already built
OpenSSL, you can determine its version by invoking the command line utility:

    $ openssl version
    OpenSSL 1.0.0g 18 Jan 2012

However, if all you have is the source code, and you want to determine exact
version information on the basis of the string representation of the
OPENSSL_VERSION_NUMBER macro, you have to use pattern matching and deal with a
bunch of corner cases. 

The C<Makefile.PL> for L<Crypt::SSLeay> contained a simplistic approach to
parsing the value of OPENSSL_VERSION_NUMBER which people had tweaked over time
to deal with changes. I added functions to deal with specific ranges of version
numbers. But, I did not think those functions belonged in a C<Makefile.PL>.

So, I put them in their own module. To test the routines, I downloaded all
available versions of OpenSSL from http://www.openssl.org/source/ (excluding
archives with 'fips' and 'engine' in their names, and built a mapping between
the value of OPENSSL_VERSION_NUMBER in each archive and the corresponding human
friendly version string in the name of the archive.

=head1 EXPORT

=over 4

=item C<parse_openssl_version_number>

By default, this module does not export anything. However, you can ask for
C<parse_openssl_version_number> to be exported.

=back

=head1 SUBROUTINES

=head2 parse_openssl_version_number

Takes a hexadecimal string corresponding to the value
of the macro C<OPENSSL_VERSION_NUMBER> macro in either C<crypto.h> or
C<openssl/opensslv.h> file in an OpenSSL distribution.

In scalar context returns a human friendly version string such as '0.9.8q'. In
list context, it returns a pair of values the first of which is the human
friendly version string and the second is either 'OpenSSL' or 'SSLeay'.

=head1 AUTHOR

A. Sinan Unur, C<< <nanis at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-openssl-versions at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=OpenSSL-Versions>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc OpenSSL::Versions


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=OpenSSL-Versions>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/OpenSSL-Versions>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/OpenSSL-Versions>

=item * Search CPAN

L<http://search.cpan.org/dist/OpenSSL-Versions/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012 A. Sinan Unur.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
