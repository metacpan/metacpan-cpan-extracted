package Mojolicious::Plugin::Statsd::Adapter::Memory;

use Mojo::Base -base;

our $VERSION = '0.06';

# scalar values: counter
# hashref values: timings (keys: samples[] avg min max)
has stats => sub {
  {}
};

sub timing {
  my ($self, $names, $time, $sample_rate) = @_;

  if (($sample_rate // 1) != 1) {
    return unless rand() <= $sample_rate;
  }

  my $stats = $self->stats;
  for my $key (@$names) {
    my $timing = $stats->{$key} //= {};

    ($timing->{samples} //= 0) += 1;

    $timing->{avg} =
      (($timing->{avg} // 0) + $time) / $timing->{samples};

    if (!exists $timing->{min} or $timing->{min} > $time) {
      $timing->{min} = $time;
    }

    if (!exists $timing->{max} or $timing->{max} < $time) {
      $timing->{max} = $time;
    }
  }
  return 1;
}

sub counter {
  my ($self, $counters, $delta, $sample_rate) = @_;

  if (($sample_rate // 1) != 1) {
    return unless rand() <= $sample_rate;
  }

  my $stats = $self->stats;

  for my $name (@$counters) {
    ($stats->{$name} //= 0) += $delta;
  }
  return 1;
}

1;

# ABSTRACT In-Memory stat recording

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Statsd::Adapter::Memory

=head1 VERSION

version 0.06

=head1 DESCRIPTION

This adapter for L<Mojolicious::Plugin::Statsd> keeps all recorded stats in its
L</stats> attribute and does nothing else.  It's useful for testing.

=head1 OPTIONS

=head2 stats

A hashref with a key per stat name recorded.  Currently, counters are scalar
values and timings are hashrefs with 'samples', 'avg, 'min', 'max' keys.  This
isn't meant to keep reliable metrics right now.

=head1 METHODS

=head2 timing

See L<Mojolicious::Plugin::Statsd/timing>.

=head2 counter

See L<Mojolicious::Plugin::Statsd/counter>.

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/perl-Mojolicious-Plugin-Statsd>
and may be cloned from L<https://github.com/robrwo/perl-Mojolicious-Plugin-Statsd.git>

=head1 SUPPORT

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/perl-Mojolicious-Plugin-Statsd/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Meredith Howard  <mhoward@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2026 by Meredith Howard  <mhoward@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
