package Mojolicious::Plugin::Statsd::Adapter::Memory;
$Mojolicious::Plugin::Statsd::Adapter::Memory::VERSION = '0.04';
use Mojo::Base -base;

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
__END__

=head1 NAME

Mojolicious::Plugin::Statsd::Adapter::Memory - In-Memory stat recording

=head1 DESCRIPTION

This adapter for L<Mojolicious::Plugin::Statsd> keeps all recorded stats in its
L</stats> attribute and does nothing else.  It's useful for testing.

=head1 INHERITANCE

Mojolicious::Plugin::Statsd::Adapter::Memory
  is a L<Mojo::Base>

=head1 ATTRIBUTES

=head2 stats

A hashref with a key per stat name recorded.  Currently, counters are scalar
values and timings are hashrefs with 'samples', 'avg, 'min', 'max' keys.  This
isn't meant to keep reliable metrics right now.

=head1 METHODS

=head2 timing

See L<Mojolicious::Plugin::Statsd/timing>.

=head2 counter

See L<Mojolicious::Plugin::Statsd/counter>.

=cut
