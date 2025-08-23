package Minion::Util;
use Mojo::Base -strict;

use Exporter qw(import);
our @EXPORT_OK = qw(desired_tasks);

sub desired_tasks {
  my ($limits, $available_tasks, $active_tasks) = @_;

  my %count;
  $count{$_}++ for @$active_tasks;

  my @desired;
  for my $task (@$available_tasks) {
    my $count = $count{$task} // 0;
    my $limit = $limits->{$task};
    push @desired, $task if !defined($limit) || $count < $limit;
  }

  return \@desired;
}

1;

=encoding utf8

=head1 NAME

Minion::Util - Minion utility functions

=head1 SYNOPSIS

  use Minion::Util qw(desired_tasks);

=head1 DESCRIPTION

L<Minion::Util> provides utility functions for L<Minion>.

=head1 FUNCTIONS

L<Minion::Util> implements the following functions, which can be imported individually.

=head2 desired_tasks

  my $desired_tasks = desired_trasks $limits, $available_tasks, $active_tasks;

Enforce limits and generate list of currently desired tasks.

  # ['bar']
  desired_trasks {foo => 2}, ['foo', 'bar'], ['foo', 'foo'];

=head1 SEE ALSO

L<Minion>, L<Minion::Guide>, L<https://minion.pm>, L<Mojolicious::Guides>, L<https://mojolicious.org>.

=cut
