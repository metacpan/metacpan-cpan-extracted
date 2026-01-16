package SBOM::CycloneDX::Citation;

use 5.010001;
use strict;
use warnings;
use utf8;

use SBOM::CycloneDX::BomRef;
use SBOM::CycloneDX::List;

use Moo;
use namespace::autoclean;

use Types::Standard qw(Str InstanceOf HashRef);
use Types::TypeTiny qw(ArrayLike);

extends 'SBOM::CycloneDX::Base';

has bom_ref => (
    is     => 'rw',
    isa    => InstanceOf ['SBOM::CycloneDX::BomRef'],
    coerce => sub { ref($_[0]) ? $_[0] : SBOM::CycloneDX::BomRef->new($_[0]) }
);

has pointers => (is => 'rw', isa => ArrayLike [Str], default => sub { SBOM::CycloneDX::List->new });

has expressions => (is => 'rw', isa => ArrayLike [Str], default => sub { SBOM::CycloneDX::List->new });

has timestamp => (
    is       => 'rw',
    isa      => InstanceOf ['SBOM::CycloneDX::Timestamp'],
    required => 1,
    coerce   => sub { ref($_[0]) ? $_[0] : SBOM::CycloneDX::Timestamp->new($_[0]) }
);

has attributed_to => (is => 'rw', isa => Str);

has process => (is => 'rw', isa => Str);

has note => (is => 'rw', isa => Str);

has signature => (is => 'rw', isa => HashRef);


sub TO_JSON {

    my $self = shift;

    my $json = {timestamp => $self->timestamp};

    $json->{'bom-ref'}    = $self->bom_ref       if $self->bom_ref;
    $json->{pointers}     = $self->pointers      if @{$self->pointers};
    $json->{expressions}  = $self->expressions   if @{$self->expressions};
    $json->{timestamp}    = $self->timestamp     if $self->timestamp;
    $json->{attributedTo} = $self->attributed_to if $self->attributed_to;
    $json->{process}      = $self->process       if $self->process;
    $json->{note}         = $self->note          if $self->note;
    $json->{signature}    = $self->signature     if $self->signature;

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::Citation - Citation

=head1 SYNOPSIS

    SBOM::CycloneDX::Citation->new();


=head1 DESCRIPTION

L<SBOM::CycloneDX::Citation> Details a specific attribution of data within
the BOM to a contributing entity or process.

=head2 METHODS

=over

=item SBOM::CycloneDX::Citation->new( %PARAMS )

Properties:

=over

=item C<attributed_to>, The C<bom-ref> of an object, such as a component,
service, tool, organisational entity, or person that supplied the cited
information.
At least one of the "attributed_to" or "process" elements must be present.

=item C<bom_ref>, BOM Reference

=item C<expressions>, One or more path expressions used to locate values
within a BOM.
Exactly one of the "pointers" or "expressions" elements must be present.

=item C<note>, A description or comment about the context or quality of the
data attribution.

=item C<pointers>, One or more "JSON
Pointers" (L<https://datatracker.ietf.org/doc/html/rfc6901)> identifying the
BOM fields to which the attribution applies.
Exactly one of the "pointers" or "expressions" elements must be present.

=item C<process>, The C<bom-ref> to a process (such as a formula, workflow,
task, or step) defined in the C<formulation> section that executed or
generated the attributed data.
At least one of the "attributed_to" or "process" elements must be present.

=item C<signature>, A digital signature verifying the authenticity or
integrity of the attribution.

=item C<timestamp>, The date and time when the attribution was made or the
information was supplied.

=back

=item $citation->attributed_to

=item $citation->bom_ref

=item $citation->expressions

=item $citation->note

=item $citation->pointers

=item $citation->process

=item $citation->signature

=item $citation->timestamp

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
