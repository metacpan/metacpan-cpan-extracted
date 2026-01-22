package SBOM::CycloneDX::Annotation;

use 5.010001;
use strict;
use warnings;
use utf8;

use SBOM::CycloneDX::BomRef;
use SBOM::CycloneDX::List;
use SBOM::CycloneDX::Timestamp;

use Types::Standard qw(Str HashRef InstanceOf);
use Types::TypeTiny qw(ArrayLike);

use Moo;
use namespace::autoclean;

extends 'SBOM::CycloneDX::Base';

has bom_ref => (
    is     => 'rw',
    isa    => InstanceOf ['SBOM::CycloneDX::BomRef'],
    coerce => sub { ref($_[0]) ? $_[0] : SBOM::CycloneDX::BomRef->new($_[0]) }
);

has subjects => (is => 'rw', isa => ArrayLike [Str], required => 1, default => sub { SBOM::CycloneDX::List->new });

has annotator => (
    is       => 'rw',
    isa      => ArrayLike [InstanceOf ['SBOM::CycloneDX::Annotation::Annotator']],
    required => 1,
    default  => sub { SBOM::CycloneDX::List->new }
);

has timestamp => (
    is       => 'rw',
    isa      => InstanceOf ['SBOM::CycloneDX::Timestamp'],
    required => 1,
    coerce   => sub { ref($_[0]) ? $_[0] : SBOM::CycloneDX::Timestamp->new($_[0]) }
);

has text => (is => 'rw', isa => Str, required => 1);
has signature => (is => 'rw', isa => ArrayLike [HashRef], default => sub { SBOM::CycloneDX::List->new });

sub TO_JSON {

    my $self = shift;

    my $json = {
        subjects  => $self->subjects,
        annotator => $self->annotator,
        timestamp => $self->timestamp,
        text      => $self->text
    };

    $json->{'bom-ref'} = $self->bom_ref   if $self->bom_ref;
    $json->{signature} = $self->signature if $self->signature;


    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::Annotation - Annotations

=head1 SYNOPSIS

    SBOM::CycloneDX::Annotation->new();


=head1 DESCRIPTION

A comment, note, explanation, or similar textual content which provides
additional context to the object(s) being annotated.

=head2 METHODS

L<SBOM::CycloneDX::Annotation> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::Annotation->new( %PARAMS )

Properties:

=over

=item * C<annotator>, The organization, person, component, or service which
created the textual content of the annotation.

=item * C<bom_ref>, An identifier which can be used to reference the
annotation elsewhere in the BOM. Every bom-ref must be unique within the
BOM.
Value SHOULD not start with the BOM-Link intro 'urn:cdx:' to avoid
conflicts with BOM-Links.

=item * C<signature>, Enveloped signature in JSON Signature Format (JSF)
(L<https://cyberphone.github.io/doc/security/jsf.html>).

=item * C<subjects>, The object in the BOM identified by its bom-ref. This is
often a component or service, but may be any object type supporting
bom-refs.

=item * C<text>, The textual content of the annotation.

=item * C<timestamp>, The date and time (timestamp) when the annotation was
created.

=back

=item $annotation->annotator

=item $annotation->bom_ref

=item $annotation->signature

=item $annotation->subjects

=item $annotation->text

=item $annotation->timestamp

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
