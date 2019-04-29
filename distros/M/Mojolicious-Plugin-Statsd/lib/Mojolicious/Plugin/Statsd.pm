package Mojolicious::Plugin::Statsd;
$Mojolicious::Plugin::Statsd::VERSION = '0.03';
use Mojo::Base 'Mojolicious::Plugin';

use Mojo::Loader;
use Time::HiRes qw(gettimeofday tv_interval);

has adapter => undef;
has prefix  => '';

sub register {
  my ($self, $app, $conf) = @_;

  $self->_load_adapter(($conf->{adapter} // 'Statsd'), $conf);

  $self->{prefix} = $conf->{prefix} // $app->moniker . q[.];

  $app->helper(($conf->{helper} // 'stats') => sub {$self});
}

sub _load_adapter {
  my ($self, $adapter, $conf) = @_;

  return $self->adapter($adapter) if ref $adapter;

  my $class = sprintf('%s::Adapter::%s', ref $self, $adapter);
  my $err   = Mojo::Loader::load_class $class;

  if (ref $err) {
    die "Loading adapter $class failed: $err";
  }

  $self->adapter($class->new(%$conf));
}

sub with_prefix {
  my ($self, $add_prefix) = @_;

  (ref $self)->new(%$self, prefix => $self->prefix . $add_prefix);
}

sub counter {
  my ($self, $name, @args) = @_;

  $self->adapter->counter($self->_prepare_names($name), @args);
}

sub increment {
  (shift)->counter(shift, 1, shift);
}

sub decrement {
  (shift)->counter(shift, -1, shift);
}

sub timing {
  my ($self, $name, @args) = @_;

  my ($time, $sample_rate) = ref $args[1] ? reverse(@args) : @args;

  if (ref $time eq 'CODE') {
    my @start = gettimeofday();
    $time->();
    $time = int(tv_interval(\@start) * 1000);
  }

  $self->adapter->timing($self->_prepare_names($name), $time, $sample_rate);
}

sub gauge {
  my ($self, $name, $value) = @_;

  $self->adapter->gauge($self->_prepare_names($name), $value);
}

sub set_add {
  my ($self, $name, @values) = @_;

  $self->adapter->set_add($self->_prepare_names($name), @values);
}

sub _prepare_names {
  my ($self, $names) = @_;

  return [map { $self->prefix . $_ } ref($names) ? @$names : $names];
}

1;
__END__

=head1 NAME

Mojolicious::Plugin::Statsd - Emit to Statsd, easy!

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('Statsd');

  # Mojolicious::Lite
  plugin 'Statsd';

  # Anywhere you have Mojo helpers available
  $app->stats->increment('frobs.adjusted');

  # It's safe to pass around if need be
  my $stats = $app->stats;

  # Only sample half of the time
  $stats->increment('frobs.discarded', 0.5);

  # Time a code section
  $stats->timing('frobnicate' => sub {
    # section to be timed
  });

  # Or do it yourself
  $stats->timing('frobnicate', $milliseconds);

  # Save repetition
  my $jobstats = $app->stats->with_prefix('my-special-process.');

  # This becomes myapp.my-special-process.foo
  $jobstats->increment('foo');


=head1 DESCRIPTION

Mojolicious::Plugin::Statsd is a L<Mojolicious> plugin which adds a helper for
throwing your metrics at statsd.

=head1 INHERITANCE

Mojolicious::Plugin::Statsd
  is a L<Mojolicious::Plugin>

=head1 OPTIONS

Mojolicious::Plugin::Statsd supports the following options.

=head2 adapter

  # Mojolicious::Lite
  plugin Statsd => {adapter => 'Memory'};

The tail-end of a classname in the C<Mojolicious::Plugin::Statsd::Adapter::>
namespace, or an object instance to be used as the adapter.

Defaults to C<Statsd>, which itself defaults to emit to UDP C<localhost:8125>.

Bundled adapters are listed in L</SEE ALSO>.  Adapters MUST implement
C<counter> and C<timing>.

=head2 prefix

  # Mojolicious::Lite
  plugin Statsd => {prefix => 'whatever.'};

A prefix applied to all recorded metrics. This a simple string concatenation,
so if you want to namespace, add the trailing . character yourself.  It
defaults to your C<< $app->moniker >>, followed by C<.>.

=head2 helper

  # Mojolicious::Lite
  plugin Statsd => {helper => 'statistics'};

The helper name to be installed. Defaults to 'stats'

=head1 ADDITIONAL OPTIONS

Any further options are passed to the L</adapter> during construction, unless
you've passed an object already.  Refer to the adapter documentation for
supported options.

=head1 ATTRIBUTES

L<Mojolicious::Plugin::Statsd> has the following attributes, which are best
configured through the plugin options above.

=head1 adapter

The statsd adapter in use.

=head1 prefix

The current prefix to apply to metric names.

=head1 METHODS

=head2 register

  $plugin->register(Mojolicious->new);
  $plugin->register(Mojolicious->new, {prefix => 'foo'});

Register plugin in L<Mojolicious> application. The optional second argument is
a hashref of L</OPTIONS>.

=head2 with_prefix

  my $new = $stats->with_prefix('baz.');

Returns a new instance with the given prefix appended to our own prefix, for
scoped recording.

=head2 counter

  $stats->counter('foo', 1);
  $stats->counter('bar', 1, 0.5);

Record a change to a counter.

=head2 increment

  $stats->increment($name, $sample_rate);

Shortcut for L</counter>.

=head2 decrement

  $stats->decrement($name, $sample_rate);

Shortcut for L</counter>.

=head2 timing

  $stats->timing('foo', 2500, 0.5);
  $stats->timing(foo => 0.5, sub { });
  $stats->timing(foo => sub { });

Record timing.

=head2 gauge

  $stats->gauge(xyzzy => 76);
  $stats->gauge(xyzzy => '+25');
  $stats->gauge(xyzzy => -25);

Send a gauge update.  Some receiving servers accept sending a signed value
rather than an absolute value, and this is supported.  Note that on those
servers, in order to reach a negative value, you must update to 0 first.

=head2 set_add

  $stats->set_add(things => 42);
  $stats->set_add(primes => 1, 3, 5, 7);

Add one or more values to a set.

=head1 NAMES

In any place a metric name is specified, it can be substituted with an arrayref
in order to update several metrics in a single packet, provided your server
supports it.

=head1 EXAMPLE

  use Mojolicious::Lite;
  plugin 'Statsd';

  hook after_dispatch => sub {
    my ($c) = @_;
    $c->stats->increment('path.' . $c->req->url->path);
  };

  #...

  app->start;

=head1 SEE ALSO

L<Mojolicious::Plugin::Statsd::Adapter::Statsd>, L<Mojolicious::Plugin::Statsd::Adapter::Memory>.

L<Mojolicious>, L<Mojolicious::Guides>

=head1 LICENSE

This software is licensed under the same terms as Perl itself.

=cut
