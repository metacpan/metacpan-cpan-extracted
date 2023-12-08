package TAP::Formatter::GitHubActions::ErrorAggregate;

use strict;
use warnings;
use v5.16;
use base 'TAP::Object';
use TAP::Formatter::GitHubActions::ErrorGroup;

my @ATTR;

BEGIN {
  @ATTR = qw(groups);
  __PACKAGE__->mk_methods(@ATTR);
}

sub _initialize {
  my ($self) = @_;
  $self->{groups} = {};
  return $self;
}

sub _ensure_group_in_line {
  my ($self, $line) = @_;
  return $self->groups->{$line} //= (
    TAP::Formatter::GitHubActions::ErrorGroup->new(line => $line)
  );
}

sub add {
  my ($self, @errors) = @_;
  $self->group($_->line)->add($_) for @errors;
  return $self;
}

sub group {
  my ($self, $key) = @_;
  return $self->_ensure_group_in_line($key);
}

sub as_sorted_array {
  my ($self) = @_;

  return map { $self->groups->{$_} } sort _by_lexical_sortable_numbers keys %{$self->groups};
}

sub _by_lexical_sortable_numbers {
  sprintf("%04d", $a) <=> sprintf("%04d", $b);
}

1;
=head1 NAME

TAP::Formatter::GitHubActions::ErrorAggregate - An aggregate of errrors.

It groups C<TAP::Formatter::GitHubActions::ErrorGroup> and makes it easier to
access groups and loop all of them in oder.

=head1 METHODS

=head2 add(@errors)

Saves C<@errors> into a respective C<TAP::Formatter::GitHubActions::ErrorGroup>.

=head2 group($line)

Get's C<TAP::Formatter::GitHubActions::ErrorGroup> for a given C<$line>.

=head2 as_sorted_array()

Returns an array of C<TAP::Formatter::GitHubActions::ErrorGroup> sorted by line.

=cut
