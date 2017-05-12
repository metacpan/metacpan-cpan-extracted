package Reflexive::ZmqSocket::ZmqMultiPartMessage;
{
  $Reflexive::ZmqSocket::ZmqMultiPartMessage::VERSION = '1.130710';
}

#ABSTRACT: The event emitted when a multipart message is received

use Moose;
extends 'Reflex::Event';


has message => (
    is       => 'ro',
    isa      => 'ArrayRef[ZeroMQ::Message]',
    traits   => ['Array'],
    required => 1,
    handles  => {
        pop_part => 'pop',
        unshift_part => 'unshift',
        push_part => 'push',
        shift_part => 'shift',
        count_parts => 'count',
        all_parts => 'elements',
    },
);

__PACKAGE__->meta->make_immutable();

1;


=pod

=head1 NAME

Reflexive::ZmqSocket::ZmqMultiPartMessage - The event emitted when a multipart message is received

=head1 VERSION

version 1.130710

=head1 DESCRIPTION

Reflexive::ZmqSocket::ZmqMultiPartMessage is the event that contains all of the
messages received from the socket that were sent using SNDMORE.

A common idiom for gathering all of the data together is:

    my @data = map { $_->data } $msg->all_parts();

=head1 PUBLIC_ATTRIBUTES

=head2 message

    is: ro, isa: ArrayRef[ZeroMQ::Message], traits: Array

message is the attribute that holds the array reference of all of the message
parts received from the socket.

The following methods are delgated to this attribute:

    pop_part
    unshift_part
    push_part
    shift_part
    count_parts
    all_parts

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


__END__
