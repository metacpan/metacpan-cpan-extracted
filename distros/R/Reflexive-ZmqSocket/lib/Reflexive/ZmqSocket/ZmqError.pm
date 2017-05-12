package Reflexive::ZmqSocket::ZmqError;
{
  $Reflexive::ZmqSocket::ZmqError::VERSION = '1.130710';
}

#ABSTRACT: The event emitted when errors occur

use Moose;

extends 'Reflex::Event';


has errnum => (
    is => 'ro',
    isa => 'Int',
    required => 1,
);


has errstr => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);


has errfun => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

__PACKAGE__->meta->make_immutable();

1;


=pod

=head1 NAME

Reflexive::ZmqSocket::ZmqError - The event emitted when errors occur

=head1 VERSION

version 1.130710

=head1 DESCRIPTION

Reflexive::ZmqSocket::ZmqError is an event emitted when bad things happen to sockets.

=head1 PUBLIC_ATTRIBUTES

=head2 errnum

    is: ro, isa: Int

This is the number version of the error ($!+0)

=head2 errstr

    is: ro, isa: Str

This is the string version of the error ("$!")

=head2 errfun

    is: ro, isa: Str

This is the function that is the source of the error

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

