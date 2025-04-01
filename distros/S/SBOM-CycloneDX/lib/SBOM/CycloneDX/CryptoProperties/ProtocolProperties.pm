package SBOM::CycloneDX::CryptoProperties::ProtocolProperties;

use 5.010001;
use strict;
use warnings;
use utf8;

use SBOM::CycloneDX::Enum;
use SBOM::CycloneDX::List;

use Types::Standard qw(Str Enum InstanceOf);
use Types::TypeTiny qw(ArrayLike);

use Moo;
use namespace::autoclean;

extends 'SBOM::CycloneDX::Base';

has type    => (is => 'rw', isa => Enum [SBOM::CycloneDX::Enum->PROTOCOL_PROPERTIES_TYPES()]);
has version => (is => 'rw', isa => Str);

has cipher_suites => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::CryptoProperties::CipherSuite']],
    default => sub { SBOM::CycloneDX::List->new }
);

has ikev2_transform_types => (is => 'rw', isa => InstanceOf ['SBOM::CycloneDX::CryptoProperties::Ikev2TransformType']);

# Bom-ref like
has crypto_ref_array => (is => 'rw', isa => ArrayLike [Str], default => sub { SBOM::CycloneDX::List->new });

sub TO_JSON {

    my $self = shift;

    my $json = {};

    $json->{type}                = $self->type                  if $self->type;
    $json->{version}             = $self->version               if $self->version;
    $json->{cipherSuites}        = $self->cipher_suites         if @{$self->cipher_suites};
    $json->{ikev2TransformTypes} = $self->ikev2_transform_types if $self->ikev2_transform_types;
    $json->{cryptoRefArray}      = $self->crypto_ref_array      if @{$self->crypto_ref_array};

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::CryptoProperties::ProtocolProperties - Protocol Properties

=head1 SYNOPSIS

    SBOM::CycloneDX::CryptoProperties::ProtocolProperties->new();


=head1 DESCRIPTION

L<SBOM::CycloneDX::CryptoProperties::ProtocolProperties> specifies properties specific
to cryptographic assets of type: "protocol".

=head2 METHODS

L<SBOM::CycloneDX::CryptoProperties::ProtocolProperties> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::CryptoProperties::ProtocolProperties->new( %PARAMS )

Properties:

=over

=item C<cipher_suites>, A list of cipher suites related to the protocol.

=item C<crypto_ref_array>, A list of protocol-related cryptographic assets

=item C<ikev2_transform_types>, The IKEv2 transform types supported (types
1-4), defined in RFC 7296 section 3.3.2 (L<https://www.ietf.org/rfc/rfc7296.html#section-3.3.2>),
and additional properties.

=item C<type>, The concrete protocol type.

=item C<version>, The version of the protocol.

=back

=item $protocol_properties->cipher_suites

=item $protocol_properties->crypto_ref_array

=item $protocol_properties->ikev2_transform_types

=item $protocol_properties->type

=item $protocol_properties->version

=back



=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-SBOM-CycloneDX/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-SBOM-CycloneDX>

    git clone https://github.com/giterlizzi/perl-SBOM-CycloneDX.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2025 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
