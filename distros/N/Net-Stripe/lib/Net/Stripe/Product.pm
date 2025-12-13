package Net::Stripe::Product;
$Net::Stripe::Product::VERSION = '0.43';
use Moose;
use Kavorka;
extends 'Net::Stripe::Resource';

# ABSTRACT: represent a Product object from Stripe

# Object creation
has 'active'                => (is => 'ro', isa => 'Maybe[Bool]');
has 'attributes'            => (is => 'ro', isa => 'Maybe[ArrayRef[Str]]');
has 'caption'               => (is => 'ro', isa => 'Maybe[Str]');
has 'deactivate_on'         => (is => 'ro', isa => 'Maybe[ArrayRef[Str]]');
has 'description'           => (is => 'ro', isa => 'Maybe[Str]');
has 'id'                    => (is => 'ro', isa => 'Maybe[StripeProductId|Str]');
has 'images'                => (is => 'ro', isa => 'Maybe[ArrayRef[Str]]');
has 'metadata'              => (is => 'ro', isa => 'Maybe[HashRef[Str]|EmptyStr]');
has 'name'                  => (is => 'ro', isa => 'Maybe[Str]');
has 'package_dimensions'    => (is => 'ro', isa => 'Maybe[HashRef[Num]]');
has 'shippable'             => (is => 'ro', isa => 'Maybe[Bool]');
has 'statement_descriptor'  => (is => 'ro', isa => 'Maybe[Str]');
has 'type'                  => (is => 'ro', isa => 'Maybe[StripeProductType]');
has 'unit_label'            => (is => 'ro', isa => 'Maybe[Str]');
has 'url'                   => (is => 'ro', isa => 'Maybe[Str]');

# API response
has 'created'   => (is => 'ro', isa => 'Maybe[Int]');
has 'livemode'  => (is => 'ro', isa => 'Maybe[Bool]');
has 'updated'   => (is => 'ro', isa => 'Maybe[Int]');

method form_fields {
    return $self->form_fields_for(
        qw/ active attributes caption deactivate_on description id images
            metadata name package_dimensions shippable statement_descriptor
            type unit_label url /
    );
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Net::Stripe::Product - represent a Product object from Stripe

=head1 VERSION

version 0.43

=head1 ATTRIBUTES

=head2 active

Reader: active

Type: Maybe[Bool]

=head2 attributes

Reader: attributes

Type: Maybe[ArrayRef[Str]]

=head2 boolean_attributes

Reader: boolean_attributes

Type: ArrayRef[Str]

=head2 caption

Reader: caption

Type: Maybe[Str]

=head2 created

Reader: created

Type: Maybe[Int]

=head2 deactivate_on

Reader: deactivate_on

Type: Maybe[ArrayRef[Str]]

=head2 description

Reader: description

Type: Maybe[Str]

=head2 id

Reader: id

Type: Maybe[Str|StripeProductId]

=head2 images

Reader: images

Type: Maybe[ArrayRef[Str]]

=head2 livemode

Reader: livemode

Type: Maybe[Bool]

=head2 metadata

Reader: metadata

Type: Maybe[EmptyStr|HashRef[Str]]

=head2 name

Reader: name

Type: Maybe[Str]

=head2 package_dimensions

Reader: package_dimensions

Type: Maybe[HashRef[Num]]

=head2 shippable

Reader: shippable

Type: Maybe[Bool]

=head2 statement_descriptor

Reader: statement_descriptor

Type: Maybe[Str]

=head2 type

Reader: type

Type: Maybe[StripeProductType]

=head2 unit_label

Reader: unit_label

Type: Maybe[Str]

=head2 updated

Reader: updated

Type: Maybe[Int]

=head2 url

Reader: url

Type: Maybe[Str]

=head1 AUTHORS

=over 4

=item *

Luke Closs

=item *

Rusty Conover

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Prime Radiant, Inc., (c) copyright 2014 Lucky Dinosaur LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
