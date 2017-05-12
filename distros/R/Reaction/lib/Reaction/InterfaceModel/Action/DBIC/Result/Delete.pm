package Reaction::InterfaceModel::Action::DBIC::Result::Delete;

use Reaction::Class;
use namespace::clean -except => [ qw(meta) ];

extends 'Reaction::InterfaceModel::Action::DBIC::Result';
with 'Reaction::InterfaceModel::Action::Role::SimpleMethodCall';

sub _target_model_method { 'delete' }

__PACKAGE__->meta->make_immutable;

1;

__END__;

=head1 NAME

Reaction::InterfaceModel::Action::DBIC::Result::Delete

=head1 DESCRIPTION

C<Delete> is a subclass of
L<Action::DBIC::Result|Reaction::InterfaceModel::Action::DBIC::Result> that consumes
L<Role::SimpleMethodCall|'Reaction::InterfaceModel::Action::Role::SimpleMethodCall>
to call the C<target_model>'s C<delete> method

=head1 METHODS

=head2 _target_model_method

Returns 'delete'

=head1 SEE ALSO

L<Create|Reaction::InterfaceModel::Action::DBIC::ResultSet::Create>,
L<DeleteAll|Reaction::InterfaceModel::Action::DBIC::ResultSet::DeleteAll>,
L<Update|Reaction::InterfaceModel::Action::DBIC::Result::Update>,

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
