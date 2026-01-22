package SBOM::CycloneDX::Metadata::DistributionConstraint;

use 5.010001;
use strict;
use warnings;
use utf8;

use SBOM::CycloneDX::Enum;

use Types::Standard qw(Enum Str);

use Moo;
use namespace::autoclean;

extends 'SBOM::CycloneDX::Base';

has tlp => (is => 'rw', default => 'CLEAR', isa => Enum [SBOM::CycloneDX::Enum->values('TLP_CLASSIFICATION')]);

sub TO_JSON {

    my $self = shift;

    my $json = {};

    $json->{tlp} = $self->tlp if $self->tlp;

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::Metadata::DistributionConstraint - Distribution Constraints

=head1 SYNOPSIS

    SBOM::CycloneDX::Metadata::DistributionConstraint->new();


=head1 DESCRIPTION

L<SBOM::CycloneDX::Metadata::DistributionConstraint> Conditions and
constraints governing the sharing and distribution of the data or
components described by this BOM.

=head2 METHODS

L<SBOM::CycloneDX::Metadata::DistributionConstraint> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::Metadata::DistributionConstraint->new( %PARAMS )

Properties:

=over

=item * C<tlp>, The Traffic Light Protocol (TLP) classification that controls
the sharing and distribution of the data that the BOM describes.

The default classification is C<CLEAR>.

=back

=item $distribution_constraint->tlp

Traffic Light Protocol (TLP) is a classification system for identifying the 
potential risk associated with artefact, including whether it is subject to 
certain types of legal, financial, or technical threats. Refer to 
L<https://www.first.org/tlp/> for further information.

The default classification is C<CLEAR>.

=over

=item * C<CLEAR>, The information is not subject to any restrictions as regards 
the sharing.

=item * C<GREEN>, The information is subject to limited disclosure, and 
recipients can share it within their community but not via publicly accessible 
channels.

=item * C<AMBER>, The information is subject to limited disclosure, and 
recipients can only share it on a need-to-know basis within their organization 
and with clients.

=item * C<AMBER_AND_STRICT>, The information is subject to limited disclosure, 
and recipients can only share it on a need-to-know basis within their 
organization.

=item * C<RED>, The information is subject to restricted distribution to 
individual recipients only and must not be shared.

=back

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
