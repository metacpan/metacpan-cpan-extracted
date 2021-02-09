package Sentry::SourceFileRegistry::ContextLine;
use Mojo::Base -base, -signatures;

use List::Util qw(min max uniq);
use Mojo::Util 'dumper';

has content    => undef;
has line_count => 5;
has _lines     => sub ($self) { [split(/\n/, $self->content)] };

sub _get_lower_bound ($self, $line) {
  return [] if $line < 0;
  my $lower_bound = max(0, $line - $self->line_count);
  my $from        = $lower_bound - 1;
  my $to          = $line - 2;

  return [] if $to < 0;

  my @line_range = uniq(map { $_ >= 0 ? $_ : 0 } ($from .. $to));
  return [grep {defined} @{ $self->_lines }[@line_range]];
}

sub _get_upper_bound ($self, $line) {
  return [] if $line < 0;
  my $upper_bound = min($line + $self->line_count, scalar $self->_lines->@*);
  return [@{ $self->_lines }[$line .. $upper_bound - 1]];
}

sub get ($self, $line) {
  my $line_count = $self->line_count;
  return {
    pre_context  => $self->_get_lower_bound($line),
    context_line => $self->_lines->[$line - 1],
    post_context => $self->_get_upper_bound($line),
  };
}

1;
