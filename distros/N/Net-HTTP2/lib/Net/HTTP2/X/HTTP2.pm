package Net::HTTP2::X::HTTP2;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Net::HTTP2::X::HTTP2 - Protocol-level errors for L<Net::HTTP2>

=head1 DESCRIPTION

This class extends L<Net::HTTP2::X::Base> and represents protocol-level
errors from HTTP itself.

=head1 PROPERTIES

(See L<X::Tiny::Base> for how to access these.)

=over

=item * C<error_number>

=item * C<error_name>

=back

=cut

#----------------------------------------------------------------------

use parent 'Net::HTTP2::X::Base';

use Protocol::HTTP2::Constants ();

sub _new {
    my ($class, $errnum) = @_;

    my $errname = Protocol::HTTP2::Constants::const_name( errors => $errnum );

    return $class->SUPER::_new(
        "HTTP/2 error: $errname",
        error_number => $errnum,
        error_name => $errname,
    );
}

1;
