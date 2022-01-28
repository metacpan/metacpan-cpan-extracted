package Mojo::Netdata::Chart;
use Mojo::Base -base, -signatures;

use Carp qw(croak);
use Mojo::Netdata::Util qw(safe_id);

has chart_type   => 'line';
has context      => 'default';
has dimensions   => sub ($self) { +{} };
has family       => sub ($self) { $self->id };
has id           => sub ($self) { croak '"id" cannot be built' };
has module       => '';
has name         => '';
has options      => '';                                               # "detail hidden obsolete"
has plugin       => 'mojo';
has priority     => 10000;
has title        => sub ($self) { $self->name || $self->id };
has type         => sub ($self) { croak '"type" cannot be built' };
has units        => '#';
has update_every => 1;

sub data_to_string ($self, $microseconds = undef) {
  my $dimensions = $self->dimensions;
  my $set        = join "\n",
    map { sprintf "SET %s = %s", $_, $dimensions->{$_}{value} // '' } sort keys %$dimensions;

  return !$set ? '' : sprintf "BEGIN %s.%s%s\n%s\nEND\n", safe_id($self->type), safe_id($self->id),
    ($microseconds ? " $microseconds" : ""), $set;
}

sub dimension ($self, $name, $attrs = undef) {
  my $id = safe_id $name;
  return $self->dimensions->{$id} unless $attrs;
  my $dimension = $self->dimensions->{$id} //= {name => $name};
  @$dimension{keys(%$attrs)} = values %$attrs;
  return $self;
}

sub to_string ($self) {
  my $dimensions = $self->dimensions;
  return '' unless %$dimensions;

  my $str = sprintf "CHART %s.%s %s\n", safe_id($self->type), safe_id($self->id),
    q('name' 'title' 'units' 'family' context chart_type priority update_every 'options' 'plugin' 'module')
    =~ s!([a-z_]+)!{$self->$1}!ger;

  for my $id (sort keys %$dimensions) {
    my $dimension = $dimensions->{$id};
    $dimension->{algorithm}  ||= 'absolute';
    $dimension->{divisor}    ||= 1;
    $dimension->{multiplier} ||= 1;
    $dimension->{name}       ||= $id;
    $dimension->{options}    ||= '';
    $str .= sprintf "DIMENSION %s %s\n", $id,
      q('name' algorithm multiplier divisor 'options') =~ s!([a-z_]+)!{$dimension->{$1}}!ger;
  }

  return $str;
}

1;

=encoding utf8

=head1 NAME

Mojo::Netdata::Chart - Represents a Netdata chart and dimensions

=head1 SYNOPSIS

  my $chart = Mojo::Netdata::Chart->new;
  $chart->data_to_string;
  $chart->to_string;

=head1 DESCRIPTION

L<Mojo::Netdata::Chart> is a class that represents a Netdata chart and
dimensions. See L<https://learn.netdata.cloud/docs/agent/collectors/plugins.d#chart>
for more details.

=head1 ATTRIBUTES

=head2 chart_type

  $str = $chart->chart_type;

Either "area", "line" or "stacked". Defaults to "line".

=head2 context

  $str = $chart->context;

Defaults to "default".

=head2 dimensions

  $hash_ref = $chart->dimensions;

See L</dimension>.

=head2 family

  $str = $chart->family;

Defaults to L</id>.

=head2 id

  $str = $chart->id;

Required to be set.

=head2 module

  $str = $chart->module;

Defaults to empty string.

=head2 name

  $str = $chart->name;

Defaults to empty string.

=head2 options

  $str = $chart->options;

Defaults to empty string.

=head2 plugin

  $str = $chart->options;

Defaults to "mojo". The default is subject to change!

=head2 priority

  $int = $chart->priority;

Defaults to 10000.

=head2 title

  $str = $chart->title;

Defaults to L</name> or L</id>.

=head2 type

  $str = $chart->type;

Required to be set.

=head2 units

  $str = $chart->units;

Defaults to "#".

=head2 update_every

  $num = $chart->update_every;

How often to update Netdata.

=head1 METHODS

=head2 data_to_string

  $str = $chart->data_to_string;

Takes the values in L</dimensions> and creates a string with SET, suitable to
be sent to Netdata.

=head2 dimension

  $dimension = $chart->dimension($id);
  $chart = $chart->dimension($id => {name => 'cool'});
  $chart = $chart->dimension($id => {value => 42});

Used to get or set an item in L</dimensions>. Possible keys are "algorithm",
"divisor", "multiplier", "name" and "options".

See L<https://learn.netdata.cloud/docs/agent/collectors/plugins.d#dimension>
for more details.

=head2 to_string

  $str = $chart->to_string;

Creates a string with CHART and DIMENSION, suitable to be sent to Netdata.

=head1 SEE ALSO

L<Mojo::Netdata>.

=cut
