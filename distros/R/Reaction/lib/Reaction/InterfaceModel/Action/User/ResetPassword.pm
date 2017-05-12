package Reaction::InterfaceModel::Action::User::ResetPassword;

use Reaction::Class;
use aliased 'Reaction::InterfaceModel::Action::User::SetPassword';
use Reaction::Types::Core qw(NonEmptySimpleStr);
use namespace::clean -except => [ qw(meta) ];

extends SetPassword;

has confirmation_code =>
    (isa => NonEmptySimpleStr, is => 'rw', lazy_fail => 1);

has 'user' => (
    is => 'rw', metaclass => 'Reaction::Meta::Attribute',
    predicate => 'has_user',
);

# verification needs to be done here, since there are cases where
# can_apply doesn't run, such as fields being left blank, invalid, etc.
around sync_all => sub {
  my $super = shift;
  my ($self) = @_;
  $self->verify_confirmation_code;
  $self->$super(@_);
};

around can_apply => sub {
    my $super = shift;
    my ($self) = @_;
    return 0 unless $self->has_user;
    return $super->(@_);
};

sub verify_confirmation_code {
  my $self = shift;
  return unless $self->has_confirmation_code;
  my $model = $self->target_model;
  my $supplied_code = $self->confirmation_code;
  if (defined(my $user = $model->find_by_confirmation_code($supplied_code))) {
    $self->user($user);
  }
}

around error_for_attribute => sub {
  my $super = shift;
  my ($self, $attr) = @_;
  if ($attr->name eq 'confirmation_code') {
    return 'Confirmation code incorrect' unless $self->has_user;
  }
  return $super->(@_);
};

sub do_apply {
  my $self = shift;
  return $self->user->reset_password($self->new_password);
}

__PACKAGE__->meta->make_immutable;


1;

=head1 NAME

Reaction::InterfaceModel::Action::User::ResetPassword

=head1 DESCRIPTION

=head2 error_for_attribute

=head2 confirmation_code

=head2 verify_confirmation_code

=head1 SEE ALSO

L<Reaction::InterfaceModel::Action::DBIC::User::ResetPassword>

L<Reaction::InterfaceModel::Action::User::Role::ConfirmationCodeSupport>

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
