package SBOM::CycloneDX::Declarations::Assessor;

use 5.010001;
use strict;
use warnings;
use utf8;

use SBOM::CycloneDX::BomRef;

use Types::Standard qw(Str Bool InstanceOf);

use Moo;
use namespace::autoclean;

extends 'SBOM::CycloneDX::Base';

has bom_ref => (
    is     => 'rw',
    isa    => InstanceOf ['SBOM::CycloneDX::BomRef'],
    coerce => sub { ref($_[0]) ? $_[0] : SBOM::CycloneDX::BomRef->new($_[0]) }
);

has third_party  => (is => 'rw', isa => Bool);
has organization => (is => 'rw', isa => InstanceOf ['SBOM::CycloneDX::OrganizationalEntity']);

sub TO_JSON {

    my $self = shift;

    my $json = {};

    $json->{'bom-ref'}    = $self->bom_ref      if $self->bom_ref;
    $json->{thirdParty}   = $self->third_party  if $self->third_party;
    $json->{organization} = $self->organization if $self->organization;

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::Declarations::Assessor - Assessor

=head1 SYNOPSIS

    SBOM::CycloneDX::Declarations::Assessor->new();


=head1 DESCRIPTION

L<SBOM::CycloneDX::Declarations::Assessor> provides the assessor who evaluates
claims and determines conformance to requirements and confidence in that
assessment.

=head2 METHODS

L<SBOM::CycloneDX::Declarations::Assessor> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::Declarations::Assessor->new( %PARAMS )

Properties:

=over

=item C<bom_ref>, An identifier which can be used to reference the object
elsewhere in the BOM. Every C<bom_ref> must be unique within the BOM.

=item C<organization>, The entity issuing the assessment.

=item C<third_party>, The boolean indicating if the assessor is outside the
organization generating claims. A value of false indicates a self assessor.

=back

=item $assessor->bom_ref

=item $assessor->organization

=item $assessor->third_party

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
