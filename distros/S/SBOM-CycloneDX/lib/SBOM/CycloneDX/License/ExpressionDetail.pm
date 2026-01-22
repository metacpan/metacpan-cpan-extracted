package SBOM::CycloneDX::License::ExpressionDetail;

use 5.010001;
use strict;
use warnings;
use utf8;

use SBOM::CycloneDX::BomRef;

use Moo;
use namespace::autoclean;

use Types::Standard qw(Str Enum InstanceOf);

extends 'SBOM::CycloneDX::Base';

has license_identifier => (is => 'rw', required => 1, isa => Str);

has bom_ref => (
    is     => 'rw',
    isa    => InstanceOf ['SBOM::CycloneDX::BomRef'],
    coerce => sub { ref($_[0]) ? $_[0] : SBOM::CycloneDX::BomRef->new($_[0]) }
);

has text => (is => 'rw', isa => InstanceOf ['SBOM::CycloneDX::Attachment']);

has url => (is => 'rw', isa => Str);

sub TO_JSON {

    my $self = shift;

    my $json = {licenseIdentifier => $self->license_identifier};

    $json->{'bom-ref'} = $self->bom_ref if $self->bom_ref;
    $json->{text}      = $self->text    if $self->text;
    $json->{url}       = $self->url     if $self->url;

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::License::ExpressionDetail - Expression Details

=head1 SYNOPSIS

    SBOM::CycloneDX::License::ExpressionDetail->new();


=head1 DESCRIPTION

L<SBOM::CycloneDX::License::ExpressionDetail> Details for parts of the
`expression`.

=head2 METHODS

L<SBOM::CycloneDX::License::ExpressionDetail> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::License::ExpressionDetail->new( %PARAMS )

Properties:

=over

=item * C<bom_ref>, An identifier which can be used to reference the license
elsewhere in the BOM. Every C<bom-ref> must be unique within the BOM.
Value SHOULD not start with the BOM-Link intro 'urn:cdx:' to avoid
conflicts with BOM-Links.

=item * C<license_identifier>, The valid SPDX license identifier. Refer to
L<https://spdx.org/specifications> for syntax requirements.
This property serves as the primary key, which uniquely identifies each
record.

=item * C<text>, A way to include the textual content of the license.

=item * C<url>, The URL to the license file. If specified, a 'license'
externalReference should also be specified for completeness

=back

=item $expression_detail->bom_ref

=item $expression_detail->license_identifier

=item $expression_detail->text

=item $expression_detail->url

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
