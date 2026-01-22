package SBOM::CycloneDX::PostalAddress;

use 5.010001;
use strict;
use warnings;
use utf8;

use SBOM::CycloneDX::BomRef;

use Types::Standard qw(Str InstanceOf);

use Moo;
use namespace::autoclean;

extends 'SBOM::CycloneDX::Base';

has bom_ref => (
    is     => 'rw',
    isa    => InstanceOf ['SBOM::CycloneDX::BomRef'],
    coerce => sub { ref($_[0]) ? $_[0] : SBOM::CycloneDX::BomRef->new($_[0]) }
);

has country                => (is => 'rw', isa => Str);
has region                 => (is => 'rw', isa => Str);
has locality               => (is => 'rw', isa => Str);
has post_office_box_number => (is => 'rw', isa => Str);
has postal_code            => (is => 'rw', isa => Str);
has street_address         => (is => 'rw', isa => Str);

sub TO_JSON {

    my $self = shift;

    my $json = {};

    $json->{'bom-ref'}           = $self->bom_ref                if $self->bom_ref;
    $json->{country}             = $self->country                if $self->country;
    $json->{region}              = $self->region                 if $self->region;
    $json->{locality}            = $self->locality               if $self->locality;
    $json->{postOfficeBoxNumber} = $self->post_office_box_number if $self->post_office_box_number;
    $json->{postalCode}          = $self->postal_code            if $self->postal_code;
    $json->{streetAddress}       = $self->street_address         if $self->street_address;

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::PostalAddress - Postal address

=head1 SYNOPSIS

    SBOM::CycloneDX::PostalAddress->new();


=head1 DESCRIPTION

L<SBOM::CycloneDX::PostalAddress> provide an address used to identify a contactable
location.

=head2 METHODS

L<SBOM::CycloneDX::PostalAddress> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::PostalAddress->new( %PARAMS )

Properties:

=over

=item * C<bom_ref>, An identifier which can be used to reference the
address elsewhere in the BOM. Every bom-ref must be unique within the BOM.
Value SHOULD not start with the BOM-Link intro 'urn:cdx:' to avoid
conflicts with BOM-Links.

=item * C<country>, The country name or the two-letter ISO 3166-1 country
code.

=item * C<locality>, The locality or city within the country.

=item * C<post_office_box_number>, The post office box number.

=item * C<postal_code>, The postal code.

=item * C<region>, The region or state in the country.

=item * C<street_address>, The street address.

=back

=item $postal_address->bom_ref

=item $postal_address->country

=item $postal_address->locality

=item $postal_address->post_office_box_number

=item $postal_address->postal_code

=item $postal_address->region

=item $postal_address->street_address

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
