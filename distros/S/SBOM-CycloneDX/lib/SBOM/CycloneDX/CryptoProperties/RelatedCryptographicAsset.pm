package SBOM::CycloneDX::CryptoProperties::RelatedCryptographicAsset;

use 5.010001;
use strict;
use warnings;
use utf8;

use Types::Standard qw(Str InstanceOf);

use Moo;
use namespace::autoclean;

extends 'SBOM::CycloneDX::Base';

has type => (is => 'rw', isa => Str);

has ref => (
    is     => 'rw',
    isa    => InstanceOf ['SBOM::CycloneDX::BomRef'],
    coerce => sub { ref($_[0]) ? $_[0] : SBOM::CycloneDX::BomRef->new($_[0]) }
);

sub TO_JSON {

    my $self = shift;

    my $json = {};

    $json->{type} = $self->type if $self->type;
    $json->{ref}  = $self->ref  if $self->ref;

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::CryptoProperties::RelatedCryptographicAsset - Related Cryptographic Asset

=head1 SYNOPSIS

    SBOM::CycloneDX::CryptoProperties::RelatedCryptographicAsset->new();


=head1 DESCRIPTION

L<SBOM::CycloneDX::CryptoProperties::RelatedCryptographicAsset> A
cryptographic assets related to this component.

=head2 METHODS

=over

=item SBOM::CycloneDX::CryptoProperties::RelatedCryptographicAsset->new( %PARAMS )

Properties:

=over

=item C<ref>, The bom-ref to cryptographic asset.

=item C<type>, Specifies the mechanism by which the cryptographic asset is
secured by.

=back

=item $related_cryptographic_asset->ref

=item $related_cryptographic_asset->type

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

This software is copyright (c) 2025-2026 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
