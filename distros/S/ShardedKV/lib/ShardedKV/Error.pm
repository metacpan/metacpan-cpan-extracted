package ShardedKV::Error;
$ShardedKV::Error::VERSION = '0.20';
use Moose;
extends 'Throwable::Error';

#ABSTRACT: Provides an error class for managing exceptions


has storage_type => (
  is => 'ro',
  isa => Moose::Util::TypeConstraints::enum([qw/redis mysql/]),
  required => 1,
);


has endpoint => (
  is => 'ro',
  isa => 'Str',
  required => 1,
);

1;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

=pod

=head1 NAME

ShardedKV::Error - Provides an error class for managing exceptions

=head1 VERSION

version 0.20

=head1 DESCRIPTION

ShardedKV::Error provides a base error class for exceptions that occur in storage backends. Since ShardedKV abstracts away which storage backend is in use, this class provides a couple of attributes that help identify problem endpoints and storage types. There are three subclasses that also identify what sort of operation failed: L<ShardedKV::Error::ConnectFail>, L<ShardedKV::Error::ReadFail>, L<ShardedKV::Error::WriteFail>. 

=head1 PUBLIC ATTRIBUTES

=head2 storage_type

  (is: ro, isa: enum(redis, mysql), required)

storage_type allows for consumers of ShardedKV to know what threw the exception
without knowing which storage backend was in use. Since we only support two
types, it is sufficient to simply have an enum for those two types.

=head2 endpoint

  (is: ro, isa: Str, required)

endpoint allows for consumers of ShardedKV to know to which component the storage backend was communicating. endpoint maybe whatever identifier the storage backend requires. So please consider this a free-form string and check the documentation for the given storage backend module for what endpoint means.

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
