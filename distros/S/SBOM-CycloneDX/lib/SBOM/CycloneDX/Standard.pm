package SBOM::CycloneDX::Standard;

use 5.010001;
use strict;
use warnings;
use utf8;

use SBOM::CycloneDX::BomRef;
use SBOM::CycloneDX::List;

use Types::Standard qw(Str InstanceOf HashRef);
use Types::TypeTiny qw(ArrayLike);

use Moo;
use namespace::autoclean;

extends 'SBOM::CycloneDX::Base';

has bom_ref => (
    is     => 'rw',
    isa    => InstanceOf ['SBOM::CycloneDX::BomRef'],
    coerce => sub { ref($_[0]) ? $_[0] : SBOM::CycloneDX::BomRef->new($_[0]) }
);

has name        => (is => 'rw', isa => Str);
has version     => (is => 'rw', isa => Str);
has description => (is => 'rw', isa => Str);
has owner       => (is => 'rw', isa => Str);

has requirements => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::Standard::Requirement']],
    default => sub { SBOM::CycloneDX::List->new }
);

has levels => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::Standard::Level']],
    default => sub { SBOM::CycloneDX::List->new }
);

has external_references => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::ExternalReference']],
    default => sub { SBOM::CycloneDX::List->new }
);

has signature => (is => 'rw', isa => HashRef);

sub TO_JSON {

    my $self = shift;

    my $json = {};

    $json->{'bom-ref'}          = $self->bom                 if $self->bom_ref;
    $json->{name}               = $self->name                if $self->name;
    $json->{version}            = $self->version             if $self->version;
    $json->{description}        = $self->description         if $self->description;
    $json->{owner}              = $self->owner               if $self->owner;
    $json->{requirements}       = $self->requirements        if @{$self->requirements};
    $json->{levels}             = $self->levels              if @{$self->levels};
    $json->{externalReferences} = $self->external_references if @{$self->external_references};
    $json->{signature}          = $self->signature           if $self->signature;

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::Standard - Standard

=head1 SYNOPSIS

    SBOM::CycloneDX::Standard->new();


=head1 DESCRIPTION

A standard may consist of regulations, industry or organizational-specific
standards, maturity models, best practices, or any other requirements which can
be evaluated against or attested to.

=head2 METHODS

L<SBOM::CycloneDX::Standard> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::Standard->new( %PARAMS )

Properties:

=over

=item C<bom_ref>, An optional identifier which can be used to reference the
object elsewhere in the BOM. Every bom-ref must be unique within the BOM.

=item C<description>, The description of the standard.

=item C<external_references>, External references provide a way to document
systems, sites, and information that may be relevant but are not included
with the BOM. They may also establish specific relationships within or
external to the BOM.

=item C<levels>, The list of levels associated with the standard. Some
standards have different levels of compliance.

=item C<name>, The name of the standard. This will often be a shortened,
single name of the standard.

=item C<owner>, The owner of the standard, often the entity responsible for
its release.

=item C<requirements>, The list of requirements comprising the standard.

=item C<signature>, Enveloped signature in [JSON Signature Format
(JSF)](https://cyberphone.github.io/doc/security/jsf.html).

=item C<version>, The version of the standard.

=back

=item $standard->bom_ref

=item $standard->description

=item $standard->external_references

=item $standard->levels

=item $standard->name

=item $standard->owner

=item $standard->requirements

=item $standard->signature

=item $standard->version

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
