package SBOM::CycloneDX::ExternalReference;

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

has url => (is => 'rw', isa => Str, required => 1);

has comment => (is => 'rw', isa => Str);

has type => (is => 'rw', isa => Enum [SBOM::CycloneDX::Enum->values('EXTERNAL_REFERENCE_TYPE')], required => 1);

has hashes => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::Hash']],
    default => sub { SBOM::CycloneDX::List->new }
);

has properties => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::Property']],
    default => sub { SBOM::CycloneDX::List->new }
);

sub TO_JSON {

    my $self = shift;

    my $json = {url => $self->url, type => $self->type};

    $json->{comment}    = $self->comment    if $self->comment;
    $json->{hashes}     = $self->hashes     if @{$self->hashes};
    $json->{properties} = $self->properties if @{$self->properties};

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::ExternalReference - External Reference

=head1 SYNOPSIS

    SBOM::CycloneDX::ExternalReference->new();


=head1 DESCRIPTION

L<SBOM::CycloneDX::ExternalReference> provide a way to
document systems, sites, and information that may be relevant but are not
included with the BOM. They may also establish specific relationships
within or external to the BOM.

=head2 METHODS

L<SBOM::CycloneDX::ExternalReference> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::ExternalReference->new( %PARAMS )

Properties:

=over

=item * C<comment>, A comment describing the external reference

=item * C<hashes>, The hashes of the external reference (if applicable).

=item * C<properties>, Provides the ability to document properties in a name-value
store. This provides flexibility to include data not officially supported in the
standard without having to use additional namespaces or create extensions.
Unlike key-value stores, properties support duplicate names, each potentially
having different values. Property names of interest to the general public are
encouraged to be registered in the CycloneDX Property Taxonomy. Formal
registration is optional. See L<SBOM::CycloneDX::Property>

=item * C<type>, Specifies the type of external reference.

=item * C<url>, The URI (URL or URN) to the external reference. External
references are URIs and therefore can accept any URL scheme including https
(RFC-7230 - L<https://www.ietf.org/rfc/rfc7230.txt>), mailto
(RFC-2368 - L<https://www.ietf.org/rfc/rfc2368.txt>), tel
(RFC-3966 - L<https://www.ietf.org/rfc/rfc3966.txt>), and dns
(RFC-4501 - L<https://www.ietf.org/rfc/rfc4501.txt>). External references may
also include formally registered URNs such as CycloneDX
BOM-Link (L<https://cyclonedx.org/capabilities/bomlink/>) to reference
CycloneDX BOMs or any object within a BOM. BOM-Link transforms applicable
external references into relationships that can be expressed in a BOM or
across BOMs.

=back

=item $external_reference->comment

=item $external_reference->hashes

=item $external_reference->properties

=item $external_reference->type

=item $external_reference->url

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
