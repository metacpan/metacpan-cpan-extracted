package Net::mbedTLS::X::mbedTLS;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Net::mbedTLS::X::mbedTLS

=head1 DESCRIPTION

This class represents fatal errors from mbedTLS.

It subclasses L<Net::mbedTLS::X::Base> and exposes two C<get()>table
attributes:

=over

=item * C<number> - mbedTLS’s error number

=item * C<string> - string from mbedTLS that describes the error

=back

=cut

#----------------------------------------------------------------------

use parent qw( Net::mbedTLS::X::Base );

sub _new {
    my ($class, $action, $num, $str, @others) = @_;

    my ($phrase, @other_args) = $class->_mbedtls_new($action, $num, $str, @others);

    return $class->SUPER::_new($phrase,
        number => $num, string => $str,
        @other_args,
    );
}

sub _mbedtls_new {
    my ($class, $action, $num, $str) = @_;

    return "mbedTLS failure ($action) $num: $str";
}

1;
