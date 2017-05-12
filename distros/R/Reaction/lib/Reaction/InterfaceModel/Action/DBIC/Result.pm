package Reaction::InterfaceModel::Action::DBIC::Result;

use Reaction::InterfaceModel::Action;
use Reaction::Types::DBIC 'Row';
use Reaction::Class;

use namespace::clean -except => [ qw(meta) ];
extends 'Reaction::InterfaceModel::Action';

has '+target_model' => (isa => Row);

__PACKAGE__->meta->make_immutable;

1;

__END__;

=head1 NAME

Reaction::InterfaceModel::Action::DBIC::Result

=head1 DESCRIPTION

Base class for actions that apply to DBIC row objects. Extends
L<InterfaceModel::Action|Reaction::InterfaceModel::Action>

=head1 ATTRIBUTES

=head2 target_model

Extends C<target_model> by assigning it a type constraint of
L<Row|Reaction::Types::DBIC>.

=head1 SEE ALSO

L<Action::DBIC::ResultSet|Reaction::InterfaceModel::Action::DBIC::ResultSet>,

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
