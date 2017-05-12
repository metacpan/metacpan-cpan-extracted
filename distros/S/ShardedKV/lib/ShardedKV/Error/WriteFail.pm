package ShardedKV::Error::WriteFail;
$ShardedKV::Error::WriteFail::VERSION = '0.20';
use Moose;
extends 'ShardedKV::Error';

#ABSTRACT: Thrown when set() fails on a storage backend



has key => (
  is => 'ro',
  isa => 'Str',
  required => 1,
);



has operation => (
  is => 'ro',
  isa => Moose::Util::TypeConstraints::enum([qw/set expire/]),
  predicate => 'has_operation'
);

1;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

=pod

=head1 NAME

ShardedKV::Error::WriteFail - Thrown when set() fails on a storage backend

=head1 VERSION

version 0.20

=head1 DESCRIPTION

ShardedKV::Error::WriteFail is an exception thrown when there is a problem
writing to the particular storage backend. The exception will contain which key
failed, and potentially which operation during the set() failed.

=head1 PUBLIC ATTRIBUTES

=head2 key

  (is: ro, isa: Str, required)

key holds what particular key was used for the set() call.

=head2 operation

  (is: ro, isa: enum(set, expire))

operation may contain what operation the set was doing when the failure
occurred. In the case of the Redis storage backend, the expiration operation is
separate from the actual set operation. In those two cases, this attribute will
be set with the appropriate operation. Other backends may or may not supply
this value.

=head1 PUBLIC METHODS

=head2 has_operation

has_operation() is the predicate check for the L</operation> attribute. It
checks if operation is defined (ie. the backend set a value).

=head1 AUTHORS

=over 4

=item *

Steffen Mueller <smueller@cpan.org>

=item *

Nick Perez <nperez@cpan.org>

=item *

Damian Gryski <dgryski@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Steffen Mueller.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__


# vim: ts=2 sw=2 et
