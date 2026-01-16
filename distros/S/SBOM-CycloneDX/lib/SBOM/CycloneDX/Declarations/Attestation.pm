package SBOM::CycloneDX::Declarations::Attestation;

use 5.010001;
use strict;
use warnings;
use utf8;

use Types::Standard qw(Str InstanceOf HashRef);
use Types::TypeTiny qw(ArrayLike);

use Moo;
use namespace::autoclean;

extends 'SBOM::CycloneDX::Base';

has summary   => (is => 'rw', isa => Str);
has assessor  => (is => 'rw', isa => Str);                                                             # Like bom-ref
has map       => (is => 'rw', isa => ArrayLike [InstanceOf ['SBOM::CycloneDX::Declarations::Map']]);
has signature => (is => 'rw', isa => HashRef);

sub TO_JSON {

    my $self = shift;

    my $json = {};

    $json->{summary}   = $self->summary   if $self->summary;
    $json->{assessor}  = $self->assessor  if $self->assessor;
    $json->{map}       = $self->map       if @{$self->map};
    $json->{signature} = $self->signature if $self->signature;

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::Declarations::Attestation - Attestation

=head1 SYNOPSIS

    SBOM::CycloneDX::Declarations::Attestation->new();


=head1 DESCRIPTION

L<SBOM::CycloneDX::Declarations::Attestation> provides the attestation asserted
by an assessor that maps requirements to claims.

=head2 METHODS

L<SBOM::CycloneDX::Declarations::Attestation> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::Declarations::Attestation->new( %PARAMS )

Properties:

=over

=item C<assessor>, The `bom-ref` to the assessor asserting the attestation.

=item C<map>, The grouping of requirements to claims and the attestors
declared conformance and confidence thereof.

=item C<signature>, Enveloped signature in JSON Signature Format (JSF)
(L<https://cyberphone.github.io/doc/security/jsf.html>).

=item C<summary>, The short description explaining the main points of the
attestation.

=back

=item $attestation->assessor

=item $attestation->map

=item $attestation->signature

=item $attestation->summary

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
