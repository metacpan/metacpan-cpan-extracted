package SBOM::CycloneDX::Composition;

use 5.010001;
use strict;
use warnings;
use utf8;

use SBOM::CycloneDX::BomRef;
use SBOM::CycloneDX::Enum;
use SBOM::CycloneDX::List;

use Types::Standard qw(Str Enum InstanceOf HashRef);
use Types::TypeTiny qw(ArrayLike);

use Moo;
use namespace::autoclean;

extends 'SBOM::CycloneDX::Base';

has bom_ref => (
    is     => 'rw',
    isa    => InstanceOf ['SBOM::CycloneDX::BomRef'],
    coerce => sub { ref($_[0]) ? $_[0] : SBOM::CycloneDX::BomRef->new($_[0]) }
);

has aggregate => (is => 'rw', isa => Enum [SBOM::CycloneDX::Enum->values('AGGREGATE_TYPE')], required => 1);

has assemblies => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::BomRef']],
    default => sub { SBOM::CycloneDX::List->new }
);

has dependencies => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::BomRef']],
    default => sub { SBOM::CycloneDX::List->new }
);

has vulnerabilities => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::BomRef']],
    default => sub { SBOM::CycloneDX::List->new }
);

has signature => (is => 'rw', isa => HashRef);

sub TO_JSON {

    my $self = shift;

    my $json = {aggregate => $self->aggregate};

    $json->{'bom-ref'}       = $self->bom_ref         if $self->bom_ref;
    $json->{assemblies}      = $self->assemblies      if @{$self->assemblies};
    $json->{dependencies}    = $self->dependencies    if @{$self->dependencies};
    $json->{vulnerabilities} = $self->vulnerabilities if @{$self->vulnerabilities};
    $json->{signature}       = $self->signature       if $self->signature;

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::Composition - Composition

=head1 SYNOPSIS

    SBOM::CycloneDX::Composition->new();


=head1 DESCRIPTION

L<SBOM::CycloneDX::Composition> describe constituent parts (including components,
services, and dependency relationships) and their completeness. The completeness
of vulnerabilities expressed in a BOM may also be described.

=head2 METHODS

=over

=item SBOM::CycloneDX::Composition->new( %PARAMS )

Properties:

=over

=item * C<aggregate>, Specifies an aggregate type that describes how complete a
relationship is.

=item * C<assemblies>, The bom-ref identifiers of the components or services being
described. Assemblies refer to nested relationships whereby a constituent part
may include other constituent parts. References do not cascade to child parts.
References are explicit for the specified constituent part only.

=item * C<bom_ref>, An identifier which can be used to reference the composition
elsewhere in the BOM. Every C<bom-ref> must be unique within the BOM.

Value SHOULD not start with the BOM-Link intro 'urn:cdx:' to avoid conflicts with BOM-Links.

=item * C<dependencies>, The bom-ref identifiers of the components or services
being described. Dependencies refer to a relationship whereby an independent
constituent part requires another independent constituent part. References do
not cascade to transitive dependencies. References are explicit for the specified
dependency only.

=item * C<signature>, Enveloped signature in JSON Signature Format
(JSF) (L<https://cyberphone.github.io/doc/security/jsf.html>).

=item * C<vulnerabilities>, The bom-ref identifiers of the vulnerabilities being
described.

=back

=item $composition->aggregate

=item $composition->assemblies

=item $composition->bom_ref

=item $composition->dependencies

=item $composition->signature

=item $composition->vulnerabilities

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
