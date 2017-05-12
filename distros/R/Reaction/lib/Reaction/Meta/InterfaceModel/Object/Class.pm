package Reaction::Meta::InterfaceModel::Object::Class;

use aliased 'Reaction::Meta::InterfaceModel::Object::ParameterAttribute';
use aliased 'Reaction::Meta::InterfaceModel::Object::DomainModelAttribute';

use Reaction::Class;

use namespace::clean -except => [ qw(meta) ];
extends 'Reaction::Meta::Class';

around initialize => sub {
  my $super = shift;
  my $class = shift;
  my $pkg   = shift;
  $super->($class, $pkg, attribute_metaclass => ParameterAttribute, @_);
};
sub add_domain_model {
  my $self = shift;
  my $name = shift;
  $self->add_attribute($name, metaclass => DomainModelAttribute, @_);
};
sub parameter_attributes {
  my $self = shift;
  return grep { $_->isa(ParameterAttribute) } 
    $self->get_all_attributes;
};
sub domain_models {
  my $self = shift;
  return grep { $_->isa(DomainModelAttribute) } 
    $self->get_all_attributes;
};

__PACKAGE__->meta->make_immutable(inline_constructor => 0);

  
1;

=head1 NAME

Reaction::Meta::InterfaceModel::Object::Class

=head1 DESCRIPTION

=head1 METHODS

=head2 add_domain_model

=head2 domain_models

=head2 parameter_attributes

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
