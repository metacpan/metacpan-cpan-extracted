package Reaction::InterfaceModel::Action::DBIC::ResultSet::DeleteAll;

use Reaction::Types::DBIC 'ResultSet';
use Reaction::Class;
use Reaction::InterfaceModel::Action;

use namespace::clean -except => [ qw(meta) ];
extends 'Reaction::InterfaceModel::Action::DBIC::ResultSet';
with 'Reaction::InterfaceModel::Action::Role::SimpleMethodCall';

sub _target_model_method { 'delete_all' }

__PACKAGE__->meta->make_immutable;

1;

__END__;

=head1 NAME

Reaction::InterfaceModel::Action::DBIC::ResultSet::DeleteAll

=head1 DESCRIPTION

C<DeleteAll> is a subclass of
L<Action::DBIC::ResultSet|Reaction::InterfaceModel::Action::DBIC::ResultSet> using
L<Role::SimpleMethodCall|'Reaction::InterfaceModel::Action::Role::SimpleMethodCall>
to call the C<target_model>'s C<delete_all> method, deleting every item in the
resultset.

=head1 METHODS

=head2 _target_model_method

Returns 'delete_all'

=head1 SEE ALSO

L<Create|Reaction::InterfaceModel::Action::DBIC::ResultSet::Create>,
L<Update|Reaction::InterfaceModel::Action::DBIC::Result::Update>,
L<Delete|Reaction::InterfaceModel::Action::DBIC::Result::Delete>,

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
