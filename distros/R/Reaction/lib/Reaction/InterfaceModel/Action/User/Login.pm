package Reaction::InterfaceModel::Action::User::Login;

use Reaction::Class;
use aliased 'Reaction::InterfaceModel::Action';
use Reaction::Types::Core qw(SimpleStr Password);

use namespace::clean -except => [ qw(meta) ];
extends Action;

# Avoid circular ref with target_model for Auth controller login actions.
sub BUILD { Scalar::Util::weaken($_[0]->{target_model}) }

has 'username' => (isa => SimpleStr, is => 'rw', lazy_fail => 1);
has 'password' => (isa => Password,  is => 'rw', lazy_fail => 1);

around error_for_attribute => sub {
  my $super = shift;
  my ($self, $attr) = @_;
  my $result = $super->(@_);
  my $predicate = $attr->get_predicate_method;
  if (defined $result && $self->$predicate) {
    return 'Invalid username or password';
  }
  return;
};
sub do_apply {
  my $self = shift;
  my $target = $self->target_model;
  return $target->login($self->username, $self->password);
};
__PACKAGE__->meta->make_immutable;


1;

=head1 NAME

Reaction::InterfaceModel::Action::User::Login

=head1 DESCRIPTION

=head2 username

=head2 password

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
