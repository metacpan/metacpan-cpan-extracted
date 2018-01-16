package Net::ACME2::Challenge::dns_01;

use strict;
use warnings;

use parent qw( Net::ACME2::Challenge );

use constant TXT_PREFIX => '_acme-challenge';

=encoding utf-8

=head1 NAME

Net::ACME2::Challenge::dns_01

=head1 SYNOPSIS

    my $name = $challenge->record_name();

=head1 DESCRIPTION

This module is instantiated by L<Net::ACME2::Authorization> and is a
subclass of L<Net::ACME2::Challenge>.

=head1 METHODS

=head2 I<OBJ>->record_name()

Returns the record name for the TXT record that you must create.

Example:

    _acme-challenge.example.com

=cut

sub record_name {
    my ($self) = @_;

    my $token = $self->token();

    return $self->PATH_DIRECTORY() . "/$token";
}

1;
