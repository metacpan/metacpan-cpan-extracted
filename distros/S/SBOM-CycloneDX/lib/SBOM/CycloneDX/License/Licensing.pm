package SBOM::CycloneDX::License::Licensing;

use 5.010001;
use strict;
use warnings;
use utf8;

use SBOM::CycloneDX::List;
use SBOM::CycloneDX::Enum;

use SBOM::CycloneDX::License::Licensee;
use SBOM::CycloneDX::License::Licensor;
use SBOM::CycloneDX::License::Purchaser;

use Types::Standard qw(Str Enum InstanceOf);
use Types::TypeTiny qw(ArrayLike);

use Moo;
use namespace::autoclean;

extends 'SBOM::CycloneDX::Base';

has alt_ids => (is => 'rw', isa => ArrayLike [Str], default => sub { SBOM::CycloneDX::List->new });

has licensor => (
    is      => 'rw',
    isa     => InstanceOf ['SBOM::CycloneDX::License::Licensor'],
    default => sub { SBOM::CycloneDX::License::Licensor->new }
);

has licensee => (
    is      => 'rw',
    isa     => InstanceOf ['SBOM::CycloneDX::License::Licensee'],
    default => sub { SBOM::CycloneDX::License::Licensee->new }
);

has purchaser => (
    is      => 'rw',
    isa     => InstanceOf ['SBOM::CycloneDX::License::Purchaser'],
    default => sub { SBOM::CycloneDX::License::Purchaser->new }
);

has purchase_order => (is => 'rw', isa => Str);

has license_types => (
    is      => 'rw',
    isa     => ArrayLike [Enum [SBOM::CycloneDX::Enum->LICENSE_TYPES()]],
    default => sub { SBOM::CycloneDX::List->new }
);

has last_renewal => (
    is     => 'rw',
    isa    => InstanceOf ['SBOM::CycloneDX::Timestamp'],
    coerce => sub { ref($_[0]) ? $_[0] : SBOM::CycloneDX::Timestamp->new($_[0]) }
);

has expiration => (
    is     => 'rw',
    isa    => InstanceOf ['SBOM::CycloneDX::Timestamp'],
    coerce => sub { ref($_[0]) ? $_[0] : SBOM::CycloneDX::Timestamp->new($_[0]) }
);

sub TO_JSON {

    my $self = shift;

    my $json = {};

    $json->{altIds}        = $self->alt_ids        if @{$self->alt_ids};
    $json->{licensor}      = $self->licensor       if %{$self->licensor->TO_JSON};
    $json->{licensee}      = $self->licensee       if %{$self->licensee->TO_JSON};
    $json->{purchaser}     = $self->purchaser      if %{$self->purchaser->TO_JSON};
    $json->{purchaseOrder} = $self->purchase_order if $self->purchase_order;
    $json->{licenseTypes}  = $self->license_types  if @{$self->license_types};
    $json->{lastRenewal}   = $self->last_renewal   if $self->last_renewal;
    $json->{expiration}    = $self->expiration     if $self->expiration;

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::License::Licensing - Licensing information

=head1 SYNOPSIS

    SBOM::CycloneDX::License::Licensing->new();


=head1 DESCRIPTION

L<SBOM::CycloneDX::License::Licensing> provides the licensing details describing the
licensor/licensee, license type, renewal and expiration dates, and other
important metadata

=head2 METHODS

L<SBOM::CycloneDX::License::Licensing> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::License::Licensing->new( %PARAMS )

Properties:

=over

=item C<alt_ids>, License identifiers that may be used to manage licenses
and their lifecycle

=item C<expiration>, The timestamp indicating when the current license
expires (if applicable).

=item C<last_renewal>, The timestamp indicating when the license was last
renewed. For new purchases, this is often the purchase or acquisition date.
For non-perpetual licenses or subscriptions, this is the timestamp of when
the license was last renewed.

=item C<license_types>, The type of license(s) that was granted to the
licensee.

=item C<licensee>, The individual or organization for which a license was
granted to

=item C<licensor>, The individual or organization that grants a license to
another individual or organization

=item C<purchase_order>, The purchase order identifier the purchaser sent
to a supplier or vendor to authorize a purchase

=item C<purchaser>, The individual or organization that purchased the
license

=back

=item $licensing->alt_ids

=item $licensing->expiration

=item $licensing->last_renewal

=item $licensing->license_types

=item $licensing->licensee

=item $licensing->licensor

=item $licensing->purchase_order

=item $licensing->purchaser

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
