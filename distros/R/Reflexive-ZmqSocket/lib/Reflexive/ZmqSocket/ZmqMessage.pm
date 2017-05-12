package Reflexive::ZmqSocket::ZmqMessage;
{
  $Reflexive::ZmqSocket::ZmqMessage::VERSION = '1.130710';
}

#ABSTRACT: The event emitted when a single message is received

use Moose;
extends 'Reflex::Event';


has message => (
    is       => 'ro',
    isa      => 'ZeroMQ::Message',
    required => 1,
    handles => [qw/data/],
);

__PACKAGE__->meta->make_immutable();

1;

__END__
=pod

=head1 NAME

Reflexive::ZmqSocket::ZmqMessage - The event emitted when a single message is received

=head1 VERSION

version 1.130710

=head1 PUBLIC_ATTRIBUTES

=head2 message

    is: ro, isa: ZeroMQ::Message

This attribute holds the actual message received from the socket. The following
methods are delegated to this attribute:

    data

=head1 AUTHORS

=over 4

=item *

Nicholas R. Perez <nperez@cpan.org>

=item *

Steffen Mueller <smueller@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Nicholas R. Perez <nperez@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

