package Reaction::InterfaceModel::Action::DBIC::User::Role::SetPassword;

use Reaction::Role;

use namespace::clean -except => [ qw(meta) ];


#requires qw/target_model/;
sub do_apply {
  my $self = shift;
  my $user = $self->target_model;
  $user->password($self->new_password);
  $user->update;
  return $user;
};



1;

=head1 NAME

Reaction::InterfaceModel::Action::DBIC::User::Role::SetPassword

=head1 DESCRIPTION

=head2 meta

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
