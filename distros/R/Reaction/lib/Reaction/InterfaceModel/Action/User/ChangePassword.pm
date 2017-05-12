package Reaction::InterfaceModel::Action::User::ChangePassword;

use Reaction::Class;

use Reaction::Types::Core qw(Password);

use namespace::clean -except => [ qw(meta) ];
extends 'Reaction::InterfaceModel::Action::User::SetPassword';


has old_password => (isa => Password, is => 'rw', lazy_fail => 1);

around error_for_attribute => sub {
  my $super = shift;
  my ($self, $attr) = @_;
  if ($attr->name eq 'old_password') {
    return "Old password incorrect"
      unless $self->verify_old_password;
  }
  #return $super->(@_); #commented out because the original didn't super()
};

around can_apply => sub {
  my $super = shift;
  my ($self) = @_;
  return 0 unless $self->verify_old_password;
  return $super->(@_);
};
sub verify_old_password {
  my $self = shift;
  return unless $self->has_old_password;
  
  my $user = $self->target_model;
  return $user->can("check_password") ?
	$user->check_password($self->old_password) :
	    $self->old_password eq $user->password;
};

__PACKAGE__->meta->make_immutable;


1;

=head1 NAME

Reaction::InterfaceModel::Action::User::ChangePassword

=head1 DESCRIPTION

=head1 METHODS

=head2 old_password

=head2 verify_old_password

=head1 SEE ALSO

L<Reaction::InterfaceModel::Action::DBIC::User::ChangePassword>

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
