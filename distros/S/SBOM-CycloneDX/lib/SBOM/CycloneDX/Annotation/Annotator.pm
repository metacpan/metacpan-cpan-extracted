package SBOM::CycloneDX::Annotation::Annotator;

use 5.010001;
use strict;
use warnings;
use utf8;

use Carp;
use Types::Standard qw(InstanceOf);

use Moo;
use namespace::autoclean;

extends 'SBOM::CycloneDX::Base';

has organization => (is => 'rw', isa => InstanceOf ['SBOM::CycloneDX::OrganizationalEntity']);
has individual   => (is => 'rw', isa => InstanceOf ['SBOM::CycloneDX::OrganizationalContact']);
has component    => (is => 'rw', isa => InstanceOf ['SBOM::CycloneDX::Component']);
has service      => (is => 'rw', isa => InstanceOf ['SBOM::CycloneDX::Service']);

sub TO_JSON {

    my $self = shift;

    my $json = {};

    $json->{organization} = $self->organization if $self->organization;
    $json->{individual}   = $self->individual   if $self->individual;
    $json->{component}    = $self->component    if $self->component;
    $json->{service}      = $self->service      if $self->service;

    my @check = keys %{$json};

    if (scalar @check != 1) {
        Carp::croak '"organization", "individual", "component" and "service" cannot be used at the same time';
    }

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::Annotation::Annotator - Annotator

=head1 SYNOPSIS

    SBOM::CycloneDX::Annotation::Annotator->new();


=head1 DESCRIPTION

L<SBOM::CycloneDX::Annotation::Annotator> provides the organization, person,
component, or service which created the textual content of the annotation.

=head2 METHODS

L<SBOM::CycloneDX::Annotation::Annotator> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::Annotation::Annotator->new( %PARAMS )

Properties:

=over

=item * C<component>, The tool or component that created the annotation

=item * C<individual>, The person that created the annotation

=item * C<organization>, The organization that created the annotation

=item * C<service>, The service that created the annotation

=back

=item $annotator->component

=item $annotator->individual

=item $annotator->organization

=item $annotator->service

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
