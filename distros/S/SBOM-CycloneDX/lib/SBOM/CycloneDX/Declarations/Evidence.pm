package SBOM::CycloneDX::Declarations::Evidence;

use 5.010001;
use strict;
use warnings;
use utf8;

use SBOM::CycloneDX::BomRef;
use SBOM::CycloneDX::Timestamp;
use SBOM::CycloneDX::Declarations::Data;

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

has property_name => (is => 'rw', isa => Str);
has description   => (is => 'rw', isa => Str);

has data => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::Declarations::Data']],
    default => sub { SBOM::CycloneDX::Declarations::Data->new }
);

has created => (
    is     => 'rw',
    isa    => InstanceOf ['SBOM::CycloneDX::Timestamp'],
    coerce => sub { ref($_[0]) ? $_[0] : SBOM::CycloneDX::Timestamp->new($_[0]) }
);

has expires => (
    is     => 'rw',
    isa    => InstanceOf ['SBOM::CycloneDX::Timestamp'],
    coerce => sub { ref($_[0]) ? $_[0] : SBOM::CycloneDX::Timestamp->new($_[0]) }
);

has author    => (is => 'rw', isa => InstanceOf ['SBOM::CycloneDX::OrganizationalContact']);
has reviewer  => (is => 'rw', isa => InstanceOf ['SBOM::CycloneDX::OrganizationalContact']);
has signature => (is => 'rw', isa => HashRef);

sub TO_JSON {

    my $self = shift;

    my $json = {};

    $json->{'bom-ref'}    = $self->bom_ref       if $self->bom_ref;
    $json->{propertyName} = $self->property_name if $self->property_name;
    $json->{description}  = $self->description   if $self->description;
    $json->{data}         = $self->data          if @{$self->data};
    $json->{created}      = $self->created       if $self->created;
    $json->{expires}      = $self->expires       if $self->expires;
    $json->{author}       = $self->author        if $self->author;
    $json->{reviewer}     = $self->reviewer      if $self->reviewer;
    $json->{signature}    = $self->signature     if $self->signature;

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::Declarations::Evidence - Evidence

=head1 SYNOPSIS

    SBOM::CycloneDX::Declarations::Evidence->new();


=head1 DESCRIPTION

L<SBOM::CycloneDX::Declarations::Evidence> provides the evidence object.

=head2 METHODS

L<SBOM::CycloneDX::Declarations::Evidence> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::Declarations::Evidence->new( %PARAMS )

Properties:

=over

=item * C<author>, The author of the evidence.

=item * C<bom_ref>, An identifier which can be used to reference the object
elsewhere in the BOM. Every C<bom_ref> must be unique within the BOM.

=item * C<created>, The date and time (timestamp) when the evidence was
created.

=item * C<data>, The output or analysis that supports claims.

=item * C<description>, The written description of what this evidence is and
how it was created.

=item * C<expires>, The date and time (timestamp) when the evidence is no
longer valid.

=item * C<property_name>, The reference to the property name as defined in
the CycloneDX Property Taxonomy (L<https://github.com/CycloneDX/cyclonedx-property-taxonomy/>).

=item * C<reviewer>, The reviewer of the evidence.

=item * C<signature>, Enveloped signature in JSON Signature Format (JSF)
(L<https://cyberphone.github.io/doc/security/jsf.html>).

=back

=item $evidence->author

=item $evidence->bom_ref

=item $evidence->created

=item $evidence->data

=item $evidence->description

=item $evidence->expires

=item $evidence->property_name

=item $evidence->reviewer

=item $evidence->signature

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
