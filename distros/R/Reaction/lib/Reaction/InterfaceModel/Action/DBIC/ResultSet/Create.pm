package Reaction::InterfaceModel::Action::DBIC::ResultSet::Create;

use Reaction::Types::DBIC 'ResultSet';
use Reaction::Class;
use Reaction::InterfaceModel::Action;
use Reaction::InterfaceModel::Action::DBIC::Role::CheckUniques;

use namespace::clean -except => [ qw(meta) ];
extends 'Reaction::InterfaceModel::Action::DBIC::ResultSet';

with 'Reaction::InterfaceModel::Action::DBIC::Role::CheckUniques';

sub do_apply {
  my $self = shift;
  my $args = $self->parameter_hashref;
  my $new = $self->target_model->new({});
  my @delay;
  foreach my $name (keys %$args) {
    my $tm_attr = $new->meta->find_attribute_by_name($name) or next;
    my $tm_writer = $tm_attr->get_write_method;
    unless ($tm_writer) {
      warn "Unable to find writer for ${name}";
      next;
    }
    if ($tm_attr->type_constraint->name eq 'ArrayRef'
        || $tm_attr->type_constraint->is_subtype_of('ArrayRef')) {
      push(@delay, [ $tm_writer, $args->{$name} ]);
    } else {
      $new->$tm_writer($args->{$name});
    }
  }
  $new->insert;
  foreach my $d (@delay) {
    my ($meth, $val) = @$d;
    $new->$meth($val);
  }
  return $new;
};

__PACKAGE__->meta->make_immutable;

1;

__END__;

=head1 NAME

Reaction::InterfaceModel::Action::DBIC::ResultSet::Create

=head1 DESCRIPTION

Create a new object.

C<Update> is a subclass of
L<Action::DBIC::ResultSet|Reaction::InterfaceModel::Action::DBIC::ResultSet> 
that cponsumes L<Role::CheckUniques|'Reaction::InterfaceModel::Action::DBIC::Role::CheckUniques>

=head2 do_apply

Create a C<new_result> for the C<target_model>, sync it to the action's
C<parameter_attributes> and C<insert> it into the database. Returns the newly
inserted object

=head1 SEE ALSO

L<DeleteAll|Reaction::InterfaceModel::Action::DBIC::ResultSet::DeleteAll>,
L<Update|Reaction::InterfaceModel::Action::DBIC::Result::Update>,
L<Delete|Reaction::InterfaceModel::Action::DBIC::Result::Delete>,

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
