package Net::mbedTLS::X::mbedTLS::x509VerificationFailed;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Net::mbedTLS::X::mbedTLS::x509VerificationFailed

=head1 DESCRIPTION

This class represents X.509 certificate verification failures
from mbedTLS.

It subclasses L<Net::mbedTLS::X::mbedTLS> and, in addition to
the attributes that that class exposes, also exposes:

=over

=item * C<verification_flags> - A bit field that describes the
verification failure.

=item * C<verification_string> - A string that represents
C<verification_flags>.

=back

=cut

#----------------------------------------------------------------------

use parent qw( Net::mbedTLS::X::mbedTLS );

sub _mbedtls_new {
    my ($class, $action, $num, $str, $vflags, $vstr) = @_;

    chomp $vstr;

    return (
        "mbedTLS X.509 verification failure ($action): $vstr",
        verification_flags => $vflags,
        verification_string => $vstr,
    );
}

1;
