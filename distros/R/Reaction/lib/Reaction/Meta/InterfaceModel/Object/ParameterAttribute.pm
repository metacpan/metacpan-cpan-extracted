package Reaction::Meta::InterfaceModel::Object::ParameterAttribute;

use Reaction::Class;

use namespace::clean -except => [ qw(meta) ];
extends 'Reaction::Meta::Attribute';


has domain_model => (
  isa => 'Str',
  is => 'ro',
  predicate => 'has_domain_model'
);

has orig_attr_name => (
  isa => 'Str',
  is => 'ro',
  predicate => 'has_orig_attr_name'
);

__PACKAGE__->meta->make_immutable(inline_constructor => 0);

1;

=head1 NAME

Reaction::Meta::InterfaceModel::Object::ParameterAttribute

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head2 domain_model

=head2 orig_attr_name

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
