package Reaction::InterfaceModel::Action::User::SetPassword;

use Reaction::Class;
use Reaction::InterfaceModel::Action;
use Reaction::Types::Core qw(Password);

use namespace::clean -except => [ qw(meta) ];
extends 'Reaction::InterfaceModel::Action';



has new_password => (isa => Password, is => 'rw', lazy_fail => 1);
has confirm_new_password => 
    (isa => Password, is => 'rw', lazy_fail => 1);

around error_for_attribute => sub {
  my $super = shift;
  my ($self, $attr) = @_;
  if ($attr->name eq 'confirm_new_password') {
    return "New password doesn't match"
      unless $self->verify_confirm_new_password;
  }
  return $super->(@_);
};

around can_apply => sub {
  my $super = shift;
  my ($self) = @_;
  return $super->(@_) && $self->verify_confirm_new_password;;
};
sub verify_confirm_new_password {
  my $self = shift;
  return $self->has_new_password && $self->has_confirm_new_password
      && ($self->new_password eq $self->confirm_new_password);
};

__PACKAGE__->meta->make_immutable;


1;

=head1 NAME

Reaction::InterfaceModel::Action::User::SetPassword

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head2 new_password

=head2 confirm_new_password

=head1 METHODS

=head2 verify_confirm_new_password

Tests to make sure that C<new_password> and C<confirm_new_password> match.

=head1 SEE ALSO

L<Reaction::InterfaceModel::Action::DBIC::User::SetPassword>

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
