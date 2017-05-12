package Reaction::Meta::InterfaceModel::Action::Class;

use Reaction::Class;
use aliased 'Reaction::Meta::InterfaceModel::Action::ParameterAttribute';

use namespace::clean -except => [ qw(meta) ];
extends 'Reaction::Meta::Class';

around initialize => sub {
  my $super = shift;
  my $class = shift;
  my $pkg   = shift;
  $super->($class, $pkg, attribute_metaclass => ParameterAttribute, @_);
};
sub parameter_attributes {
  my $self = shift;
  return grep { $_->isa(ParameterAttribute) } 
    $self->get_all_attributes;
};

__PACKAGE__->meta->make_immutable(inline_constructor => 0);

  
1;

=head1 NAME

Reaction::Meta::InterfaceModel::Action::Class

=head1 DESCRIPTION

=head2 parameter_attributes

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
