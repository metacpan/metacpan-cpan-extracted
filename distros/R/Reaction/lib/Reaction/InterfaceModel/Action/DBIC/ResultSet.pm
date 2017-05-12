package Reaction::InterfaceModel::Action::DBIC::ResultSet;

use Reaction::InterfaceModel::Action;
use Reaction::Types::DBIC ();
use Reaction::Class;

use namespace::clean -except => [ qw(meta) ];
extends 'Reaction::InterfaceModel::Action';

has '+target_model' => (isa => Reaction::Types::DBIC::ResultSet);

__PACKAGE__->meta->make_immutable;

1;

__END__;


=head1 NAME

Reaction::InterfaceModel::Action::DBIC::ResultSet

=head1 DESCRIPTION

Base class for actions that apply to DBIC resultset objects. Extends
L<InterfaceModel::Action|Reaction::InterfaceModel::Action>

=head1 ATTRIBUTES

=head2 target_model

Extends C<target_model> by assigning it a type constraint of
L<ResultSet|Reaction::Types::DBIC>.

=head1 SEE ALSO

L<Action::DBIC::Result|Reaction::InterfaceModel::Action::DBIC::Result>,

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut

