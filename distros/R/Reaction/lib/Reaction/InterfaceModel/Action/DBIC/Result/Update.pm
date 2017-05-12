package Reaction::InterfaceModel::Action::DBIC::Result::Update;

use Reaction::Class;
use namespace::clean -except => [ qw(meta) ];

extends 'Reaction::InterfaceModel::Action::DBIC::Result';
with 'Reaction::InterfaceModel::Action::DBIC::Role::CheckUniques';

sub BUILD {
  my ($self) = @_;
  my $tm = $self->target_model;
  foreach my $attr ($self->parameter_attributes) {
    my $writer = $attr->get_write_method;
    my $name = $attr->name;
    my $tm_attr = $tm->meta->find_attribute_by_name($name);
    next unless ref $tm_attr;
    my $tm_reader = $tm_attr->get_read_method;
    $self->$writer($tm->$tm_reader) if defined($tm->$tm_reader);
  }
}

sub do_apply {
  my $self = shift;
  my $args = $self->parameter_hashref;
  my $model = $self->target_model;
  foreach my $name (keys %$args) {
    my $tm_attr = $model->meta->find_attribute_by_name($name);
    next unless ref $tm_attr;
    my $tm_writer = $tm_attr->get_write_method;
    $model->$tm_writer($args->{$name});
  }
  $model->update;
  return $model;
}

__PACKAGE__->meta->make_immutable;

1;

__END__;

=head1 NAME

Reaction::InterfaceModel::Action::DBIC::Result::Update

=head1 DESCRIPTION

Update the target model and sync the Action's parameter attributes to
the target model.

C<Update> is a subclass of
L<Action::DBIC::Result|Reaction::InterfaceModel::Action::DBIC::Result> that cponsumes
L<Role::CheckUniques|'Reaction::InterfaceModel::Action::DBIC::Role::CheckUniques>

=head2 BUILD

Sync the values from the target model's parameter attributes to the action's
parameter attributes

=head2 do_apply

Sync the target model's parameter attributes to the values returned by
C<parameter_hashref>, call C<update> and return the C<target_model>.

=head1 SEE ALSO

L<Create|Reaction::InterfaceModel::Action::DBIC::ResultSet::Create>,
L<DeleteAll|Reaction::InterfaceModel::Action::DBIC::ResultSet::DeleteAll>,
L<Delete|Reaction::InterfaceModel::Action::DBIC::Result::Delete>,

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
