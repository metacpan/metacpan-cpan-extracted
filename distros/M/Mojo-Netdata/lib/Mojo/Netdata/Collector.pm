package Mojo::Netdata::Collector;
use Mojo::Base 'Mojo::EventEmitter', -signatures;

use Carp qw(croak);
use Mojo::Netdata::Chart;
use Mojo::Netdata::Util qw(logf safe_id);
use Mojo::Promise;
use Time::HiRes qw(time);

has charts       => sub ($self) { +{} };
has module       => sub ($self) { lc(ref $self) =~ s!\W+!_!gr };
has type         => sub ($self) { croak '"type" cannot be built' };
has update_every => 1;

sub chart ($self, $id) {
  my $key = safe_id $id;
  return $self->charts->{$key} //= Mojo::Netdata::Chart->new(
    module       => $self->module,
    id           => $id,
    type         => $self->type,
    update_every => $self->update_every,
  );
}

sub recurring_update_p ($self) {
  my $next_time = time + $self->update_every;

  return $self->{recurring_update_p} //= $self->update_p->then(sub {
    $self->emit_data;
    logf(debug => 'Will update in %0.3fs...', $next_time - time);
    return Mojo::Promise->timer($next_time - time);
  })->then(sub {
    delete $self->{recurring_update_p};
    return $self->recurring_update_p;
  });
}

sub register ($self, $config, $netdata) { }
sub update_p ($self)                    { Mojo::Promise->resolve }

sub emit_data ($self) {
  my @stdout = map { $self->charts->{$_}->data_to_string } sort keys %{$self->charts};
  return $self->emit(stdout => join '', @stdout);
}

sub emit_charts ($self) {
  my @stdout = map { $self->charts->{$_}->to_string } sort keys %{$self->charts};
  return $self->emit(stdout => join '', @stdout);
}

1;

=encoding utf8

=head1 NAME

Mojo::Netdata::Collector - Base class for Mojo::Netdata collectors

=head1 SYNOPSIS

  package Mojo::Netdata::Collector::CoolBeans;
  use Mojo::Base 'Mojo::Netdata::Collector', -signatures;

  has type    => 'ice_cool';

  sub register ($self, $config, $netdata) { ... }
  sub update_p ($self) { ... }

  1;

=head1 DESCRIPTION

L<Mojo::Netdata::Collector> has basic functionality which should be inherited
by L<Mojo::Netdata> collectors. See L<Mojo::Netdata::Collector::HTTP> for an
(example) implementation.

=head1 ATTRIBUTES

=head2 charts

  $hash_ref = $collector->charts;

=head2 module

  $str = $collector->module;

Defaults to a decamelized version of L<$collector>. This is used as default
value for L<Mojo::Netdata::Chart/module>.

=head2 type

  $str = $collector->type;

This value must be set. This is used as default value for
L<Mojo::Netdata::Chart/type>.

=head2 update_every

  $num = $chart->update_every;

Used by L</recurring_update_p> to figure out how often to update Netdata.

=head1 METHODS

=head2 chart

  $chart = $collector->chart($id);

Returns a L<Mojo::Netdata::Chart> object identified by L</id>.

=head2 emit_charts

  $collector = $collector->emit_charts;

Emits all the L</charts> specifications as an "stdout" event.

=head2 emit_data

  $collector = $collector->emit_data;

Emits all the L</charts> data as an "stdout" event.

=head2 recurring_update_p

  $p = $collector->recurring_update_p;

Calls L</update_p> on L</update_every> interval, until the process is killed.

=head2 register

  $collector = $collector->register(\%config, $netdata);

Called by L<Mojo::Netdata> when initialized, and should return C<$collector> on
success or C<undef> if the collector should I<not> be registered.

=head2 update_p

  $p = $collector->update_p;

Must be defined in the sub class. This method should update
L<Mojo::Netdata::Chart/dimensions>.

=head1 SEE ALSO

L<Mojo::Netdata>.

=cut
