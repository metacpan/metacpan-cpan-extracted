
package OpusVL::Preferences::Schema;

=head1 SYNOPSIS

This is the DBIx::Class schema for the Preferences module.

=head1 ATTRIBUTES

=head2 encryption_key

An Encryption key to use for symmetric cryptography of selected fields.

This will be used in the L<OpusVL::SimpleCrypto> module, see that for
how to generate keys.

=head2 encryption_salt

A salt to use for symmetric cryptography of selected fields.

This will be used in the L<OpusVL::SimpleCrypto> module, see that for
how to generate keys and salt.

=head2 encryption_client

The client to perform encryption.  If the key or salt are not provided
this will return undef.

=cut

use Moose;
use namespace::autoclean;
use OpusVL::SimpleCrypto;

extends 'DBIx::Class::Schema';

has encryption_key => (is => 'rw', isa => 'Str');
has encryption_salt => (is => 'rw', isa => 'Str');
has encryption_client => (is => 'ro', lazy => 1, builder => '_build_encryption_client');

sub _build_encryption_client
{
    my $self = shift;
    return undef unless $self->encryption_salt && $self->encryption_key;
    my $crypto = OpusVL::SimpleCrypto->new({
        key_string => $self->encryption_key,
        deterministic_salt_string => $self->encryption_salt,
    });
    return $crypto;
}

sub schema_version { 1 }

__PACKAGE__->load_namespaces;

__PACKAGE__->meta->make_immutable(inline_constructor => 0);

1;

