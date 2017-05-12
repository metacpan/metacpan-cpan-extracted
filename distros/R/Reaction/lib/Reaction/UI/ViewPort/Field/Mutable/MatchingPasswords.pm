package Reaction::UI::ViewPort::Field::Mutable::MatchingPasswords;

use Reaction::Class;
use namespace::clean -except => [ qw(meta) ];
use MooseX::Types::Moose qw/Str/;

extends 'Reaction::UI::ViewPort::Field::Mutable::Password';

has check_value => (is => 'rw', isa => Str, );
has check_label => (is => 'rw', isa => Str, lazy_build => 1);

sub _build_check_label {
  my $orig_label = shift->label;
  return "Confirm ${orig_label}";
}

#maybe both check_value and value_string should have triggers ?
#that way if one even happens before the other it would still work?
around adopt_value_string => sub {
  my $orig = shift;
  my ($self) = @_;
  return $orig->(@_) if $self->check_value eq $self->value_string;
  $self->message("Passwords do not match");
  return;
};

#order is important check_value should happen before value here ...
#i don't like how this works, it's unnecessarily fragile, but how else ?
around accept_events => sub { ('check_value', shift->(@_)) };

around can_sync_to_action => sub {
  my $orig = shift;
  my ($self) = @_;
  return $orig->(@_) if $self->check_value eq $self->value_string;
  $self->message("Passwords do not match");
  return;
};

__PACKAGE__->meta->make_immutable;

1;

__END__;
