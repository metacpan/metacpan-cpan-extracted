package Reaction::UI::ViewPort::Collection::Grid;

use Reaction::Class;

use aliased 'Reaction::InterfaceModel::Collection' => 'IM_Collection';
use aliased 'Reaction::UI::ViewPort::Collection::Grid::Member';

use namespace::clean -except => [ qw(meta) ];
use MooseX::Types::Moose qw/ArrayRef HashRef Int/;
extends 'Reaction::UI::ViewPort::Collection';

with 'Reaction::UI::ViewPort::Role::FieldArgs';

has member_action_count => (
  is => 'rw',
  isa => Int,
  required => 1,
  lazy => 1,
  default => sub {
    my $self = shift;
    for (@{ $self->members }) {
      my $protos = $_->action_prototypes;
      return scalar(keys(%$protos));
    }
    return 1;
  },
);

sub _build_member_class { Member };

__PACKAGE__->meta->make_immutable;


1;

__END__;

=head1 NAME

Reaction::UI::ViewPort::Collection

=head1 DESCRIPTION

This subclass of L<Reaction::UI::ViewPort::Collection> allows you to display a
homogenous collection of Reaction::InterfaceModel::Objects as a grid.

=head1 ATTRIBUTES

=head2 field_order

=head2 excluded_fields

List of field names to exclude.

=head2 included_fields

List of field names to include. If both C<included_fields> and
C<excluded_fields> are specified the result is those fields which
are in C<included_fields> and not in C<excluded_fields>.

=head2 included_fields

List of field names to include. If both C<included_fields> and
C<excluded_fields> are specified the result is those fields which
are in C<included_fields> and not in C<excluded_fields>.


=head2 field_labels

=head2 _raw_field_labels

=head2 computed_field_order

=head2 member_action_count

=head1 INTERNAL METHODS

These methods, although stable, are subject to change without notice. These are meant
to be used only by developers. End users should refrain from using these methods to
avoid potential breakages.

=head1 SEE ALSO

L<Reaction::UI::ViewPort::Collection>

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
