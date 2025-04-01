package SBOM::CycloneDX::Declarations::Signatory;

use 5.010001;
use strict;
use warnings;
use utf8;

use SBOM::CycloneDX::List;

use Types::Standard qw(InstanceOf HashRef Str);

use Moo;
use namespace::autoclean;

extends 'SBOM::CycloneDX::Base';

sub BUILD {
    my ($self, $args) = @_;

    if (exists $args->{signature} and exists $args->{organization} and exists $args->{external_reference}) {
        Carp::croak('"signature", "organization" and "external_reference" cannot be used at the same time');
    }

    if (!exists $args->{signature} and (not exists $args->{organization} or not exists $args->{external_reference})) {
        Carp::croak('"organization" and "external_reference" are required');
    }

}

has name               => (is => 'rw', isa => Str);
has role               => (is => 'rw', isa => Str);
has signature          => (is => 'rw', isa => HashRef);
has organization       => (is => 'rw', isa => InstanceOf ['SBOM::CycloneDX::OrganizationalEntity']);
has external_reference => (is => 'rw', isa => InstanceOf ['SBOM::CycloneDX::ExternalReference']);


sub TO_JSON {

    my $self = shift;

    my $json = {};

    $json->{name}              = $self->name               if $self->name;
    $json->{role}              = $self->role               if $self->role;
    $json->{signature}         = $self->signature          if $self->signature;
    $json->{organization}      = $self->organization       if $self->organization;
    $json->{externalReference} = $self->external_reference if $self->external_reference;

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::Declarations::Signatory - Signatory

=head1 SYNOPSIS

    SBOM::CycloneDX::Declarations::Signatory->new();


=head1 DESCRIPTION

L<SBOM::CycloneDX::Declarations::Signatory> provide the signatory authorized on
behalf of an organization to assert validity of this document.

=head2 METHODS

L<SBOM::CycloneDX::Declarations::Signatory> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::Declarations::Signatory->new( %PARAMS )

Properties:

=over

=item C<external_reference>, External references provide a way to document
systems, sites, and information that may be relevant but are not included
with the BOM. They may also establish specific relationships within or
external to the BOM.

=item C<name>, The signatory's name.

=item C<organization>, The signatory's organization.

=item C<role>, The signatory's role within an organization.

=item C<signature>, Enveloped signature in JSON Signature Format (JSF)
(L<https://cyberphone.github.io/doc/security/jsf.html>).

=back

=item $signatory->external_reference

=item $signatory->name

=item $signatory->organization

=item $signatory->role

=item $signatory->signature

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

This software is copyright (c) 2025 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
