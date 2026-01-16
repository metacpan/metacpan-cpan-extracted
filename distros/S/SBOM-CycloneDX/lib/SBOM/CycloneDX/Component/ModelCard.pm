package SBOM::CycloneDX::Component::ModelCard;

use 5.010001;
use strict;
use warnings;
use utf8;

use SBOM::CycloneDX::BomRef;
use SBOM::CycloneDX::List;

use Types::Standard qw(Str InstanceOf);
use Types::TypeTiny qw(ArrayLike);

use Moo;
use namespace::autoclean;

extends 'SBOM::CycloneDX::Base';

has bom_ref => (
    is     => 'rw',
    isa    => InstanceOf ['SBOM::CycloneDX::BomRef'],
    coerce => sub { ref($_[0]) ? $_[0] : SBOM::CycloneDX::BomRef->new($_[0]) }
);

has model_parameters => (is => 'rw', isa => InstanceOf ['SBOM::CycloneDX::Component::ModelParameters']);

has quantitative_analysis => (is => 'rw', isa => InstanceOf ['SBOM::CycloneDX::Component::QuantitativeAnalysis']);

has considerations => (is => 'rw', isa => InstanceOf ['SBOM::CycloneDX::Component::Considerations']);

has properties => (is => 'rw', isa => ArrayLike [InstanceOf ['SBOM::CycloneDX::Property']]);

sub TO_JSON {

    my $self = shift;

    my $json = {};

    $json->{bom}                  = $self->bom                  if $self->bom;
    $json->{modelParameters}      = $self->model_parameters     if $self->model_parameters;
    $json->{quantitativeAnalysis} = $self->quantitativeAnalysis if $self->quantitative_analysis;
    $json->{considerations}       = $self->considerations       if $self->considerations;
    $json->{properties}           = $self->properties           if @{$self->properties};

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::Component::ModelCard - Model Card

=head1 SYNOPSIS

    SBOM::CycloneDX::Component::ModelCard->new();


=head1 DESCRIPTION

L<SBOM::CycloneDX::Component::ModelCard> provides a model card describes the
intended uses of a machine learning model and potential limitations,
including biases and ethical considerations. Model cards typically contain
the training parameters, which datasets were used to train the model,
performance metrics, and other relevant data useful for ML transparency.
This object SHOULD be specified for any component of type
`machine-learning-model` and must not be specified for other component
types.

=head2 METHODS

L<SBOM::CycloneDX::Component::ModelCard> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::Component::ModelCard->new( %PARAMS )

Properties:

=over

=item C<bom_ref>, An identifier which can be used to reference the
model card elsewhere in the BOM. Every bom-ref must be unique within the
BOM.
Value SHOULD not start with the BOM-Link intro 'urn:cdx:' to avoid
conflicts with BOM-Links.

=item C<considerations>, What considerations should be taken into account
regarding the model's construction, training, and application?

=item C<model_parameters>, Hyper-parameters for construction of the model.

=item C<properties>, Provides the ability to document properties in a
name-value store. This provides flexibility to include data not officially
supported in the standard without having to use additional namespaces or
create extensions. Unlike key-value stores, properties support duplicate
names, each potentially having different values. Property names of interest
to the general public are encouraged to be registered in the CycloneDX
Property Taxonomy (L<https://github.com/CycloneDX/cyclonedx-property-taxonomy>).
Formal registration is optional.

=item C<quantitative_analysis>, A quantitative analysis of the model

=back

=item $model_card->bom_ref

=item $model_card->considerations

=item $model_card->model_parameters

=item $model_card->properties

=item $model_card->quantitative_analysis

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
