package Mojo::UserAgent::Role::Cache;
use Mojo::Base -role;

use Mojo::UserAgent::Role::Cache::Driver::File;
use Mojo::Util 'term_escape';

use constant DEBUG => $ENV{MOJO_CLIENT_DEBUG} || $ENV{MOJO_UA_CACHE_DEBUG} || 0;
use constant TRACE => $ENV{MOJO_CLIENT_DEBUG} || 0;

our $VERSION = '0.03';

my $DEFAULT_STRATEGY = 'playback_or_record';

has cache_driver => sub { shift->cache_driver_singleton };

has cache_key => sub {
  return sub {
    my $req = shift->req;
    my $url = $req->url;
    my @key = (lc $req->method, $url->host || 'local', map { _escape($_) } @{$url->path});

    # The question marks is a hack to make sure the path parts will
    # never be in conflict with the query and body.
    push @key, '?q=' . $url->query->to_string;
    push @key, '?b=' . Mojo::Util::md5_sum($req->body) if length $req->body // '';

    return \@key;
  };
};

has cache_strategy => sub {
  my $strategy   = $ENV{MOJO_USERAGENT_CACHE_STRATEGY} || $DEFAULT_STRATEGY;
  my @strategies = map { split /=/, $_, 2 } split '&', $strategy;
  my %strategies = @strategies == 1 ? () : @strategies;

  return !%strategies ? sub {$strategy} : sub {
    my $method = uc shift->req->method;
    return $strategies{$method} || $strategies{DEFAULT} || $DEFAULT_STRATEGY;
  };
};

sub cache_driver_singleton {
  my $class = shift;
  state $driver = Mojo::UserAgent::Role::Cache::Driver::File->new;
  return $driver unless @_;
  $driver = shift;
  return $class;
}

around start => sub {
  my ($orig, $self, $tx) = (shift, shift, shift);

  my $strategy = $self->cache_strategy->($tx);
  warn qq(-- Cache strategy is "$strategy" (@{[_url($tx)]})\n) if DEBUG and !$self->{cache_passthrough};
  return $self->$orig($tx, @_) if $strategy eq 'passthrough' or delete $self->{cache_passthrough};

  my $method = $self->can("_cache_start_$strategy");
  Carp::confess(qq([Mojo::UserAgent::Role::Cache] Invalid strategy "$strategy".)) unless $method;
  return $self->$method($tx, @_);
};

sub _escape {
  local $_ = Mojo::Util::url_escape($_[0]);
  s!_!%5F!g;
  s!%!_!g;
  $_;
}

sub _url { shift->req->url->to_abs }

sub _cache_get_tx {
  my ($self, $tx_input) = @_;
  my $key = $self->cache_key->($tx_input);

  my $buffer = $self->cache_driver->get($key);
  return undef unless defined $buffer;

  $tx_input->res->parse($buffer);
  return $tx_input;
}

sub _cache_set_tx {
  my ($self, $tx_input, $tx_output) = @_;
  $self->cache_driver->set($self->cache_key->($tx_input), $tx_output->res->to_string);
  return $self;
}

sub _cache_start_playback {
  my ($self, $tx_input, $cb) = @_;
  my $tx_output = $self->_cache_get_tx($tx_input);
  my $status    = $tx_output ? '<<<' : '!!!';

  # Not in cache
  unless ($tx_output) {
    $tx_output = $tx_input;
    $tx_output->res->error({message => 'Not in cache.'});
  }

  warn term_escape "-- Client >>> Cache (@{[_url($tx_input)]})\n@{[$tx_input->req->to_string]}\n"      if TRACE;
  warn term_escape "-- Client $status Cache (@{[_url($tx_input)]})\n@{[$tx_output->res->to_string]}\n" if TRACE;

  # Blocking
  return $tx_output unless $cb;

  # Non-blocking
  Mojo::IOLoop->next_tick(sub { $self->$cb($tx_input) });
  return $self;
}

sub _cache_start_playback_or_record {
  my ($self, $tx_input, $cb) = @_;
  my $tx_output = $self->_cache_get_tx($tx_input);

  # Not cached
  unless ($tx_output) {
    warn term_escape "-- Client !!! Cache (@{[_url($tx_input)]}) - Start recording...\n" if DEBUG;
    return $self->_cache_start_record($tx_input, $cb ? ($cb) : ());
  }

  warn term_escape "-- Client >>> Cache (@{[_url($tx_input)]})\n@{[$tx_input->req->to_string]}\n"  if TRACE;
  warn term_escape "-- Client <<< Cache (@{[_url($tx_input)]})\n@{[$tx_output->res->to_string]}\n" if TRACE;

  # Blocking
  return $tx_output unless $cb;

  # Non-blocking
  Mojo::IOLoop->next_tick(sub { $self->$cb($tx_output) });
  return $self;
}

sub _cache_start_record {
  my ($self, $tx_input, $cb) = @_;

  # Make sure we perform the actual request when calling start();
  $self->{cache_passthrough} = 1;

  # Blocking
  unless ($cb) {
    my $tx_output = $self->start($tx_input);
    $self->_cache_set_tx($tx_input, $tx_output);
    return $tx_output;
  }

  # Non-blocking
  $self->start($tx_input, sub { $_[0]->_cache_set_tx($tx_input, $_[1])->$cb($_[1]) });
  return $self;
}

1;

=encoding utf8

=head1 NAME

Mojo::UserAgent::Role::Cache - Role for Mojo::UserAgent that provides caching

=head1 SYNOPSIS

=head2 General

  # Apply the role
  my $ua_class_with_cache = Mojo::UserAgent->with_roles('+Cache');
  my $ua = $ua_class_with_cache->new;

  # Change the global cache driver
  use CHI;
  $ua_class_with_cache->cache_driver_singleton(CHI->new(driver => "Memory", datastore => {}));

  # Or change the driver for the instance
  $ua->cache_driver(CHI->new(driver => "Memory", datastore => {}));

  # The rest is like a normal Mojo::UserAgent
  my $tx = $ua->get($url)->error;

=head2 Module

  package MyCoolModule;
  use Mojo::Base -base;

  has ua => sub {
    return $ENV{MOJO_USERAGENT_CACHE_STRATEGY}
      ? Mojo::UserAgent->with_roles('+Cache') : Mojo::UserAgent->new;
  };

  sub get_mojolicious_org {
    return shift->ua->get("https://mojolicious.org/");
  }

Using the C<MOJO_USERAGENT_CACHE_STRATEGY> inside the module is a very
effective way to either use the global cache set up by a unit test, or run with
the default L<Mojo::UserAgent> without caching.

=head2 Test

  use Mojo::Base -strict;
  use Mojo::UserAgent::Role::Cache;
  use MyCoolModule;
  use Test::More;

  # Set up the environment and change the global cache_driver before running
  # the tests
  $ENV{MOJO_USERAGENT_CACHE_STRATEGY} ||= "playback";
  Mojo::UserAgent::Role::Cache->cache_driver_singleton->root_dir("/some/path");

  # Run the tests
  my $cool = MyCoolModule->new;
  is $cool->get_mojolicious_org->res->code, 200, "mojolicious.org works";

  done_testing;

=head1 DESCRIPTION

L<Mojo::UserAgent::Role::Cache> is a role for the full featured non-blocking
I/O HTTP and WebSocket user agent L<Mojo::UserAgent>, that provides caching.

The L</SYNOPSIS> shows how to use this in with tests, but there's nothing wrong
with using it for other things as well, where you want caching.

By default, this module caches everything without any expiration. This is
because L<Mojo::UserAgent::Role::Cache::Driver::File> is very basic and
actually just meant for unit testing. If you want something more complex, you
can use L<CHI> or another L</cache_driver> that implements the logic you want.

One exotic hack that is possible, is to make L</cache_key> return the whole
L<$tx> object and then implement a wrapper around L<CHI> that will investigate
the transaction and see if it wants to cache the request at all.

=head1 WARNING

=head2 Experimenntal

L<Mojo::UserAgent::Role::Cache> is still under development, so there will be
changes and there is probably bugs that needs fixing. Please report in if you
find a bug or find this role interesting.

L<https://github.com/jhthorsen/mojo-useragent-role-cache/issues>

=head2 Upgrading from 0.02 to 0.03

Upgrading from version 0.02 to 0.03 will cause all your cached files to be
invalid, since the L</cache_key> is changed. If you are using
L<Mojo::UserAgent::Role::Cache::Driver::File>, you can set the environment
variable C<MOJO_UA_CACHE_RENAME=1> to on-the-fly rename the old files to the
new format.

=head1 ATTRIBUTES

=head2 cache_driver

  $obj = $self->cache_driver;
  $self = $self->cache_driver(CHI->new);

Holds an object that will get/set the HTTP messages. Default is
L<Mojo::UserAgent::Role::Cache::Driver::File>, but any backend that supports
C<get()> and C<set()> should do. This means that you can use L<CHI> if you
like.

=head2 cache_key

  $code = $self->cache_key;
  $self = $self->cache_key(sub { my $tx = shift; return $tx->req->url });

Holds a code ref that returns an array-ref of the key parts that is passed on
to C<get()> or C<set()> in the L</cache_driver>.

This works with L<CHI> as well, since CHI will serialize the key if it is a
reference.

The default is EXPERIMENTAL, but returns this value for now:

  [
    $http_method, # get, post, ...
    $host,        # no port
    $path_query,  # /foo?x=42
    md5($body),   # but not for GET
  ]

=head2 cache_strategy

  $code = $self->cache_strategy;
  $self = $self->cache_strategy(sub { my $tx = shift; return "passthrough" });

Used to set up a callback to return a cache strategy. Default value is read
from the C<MOJO_USERAGENT_CACHE_STRATEGY> environment variable or
"playback_or_record".

The return value from the C<$code> can be one of:

=over 2

=item * passthrough

Will disable any caching.

=item * playback

Will never send a request to the remote server, but only look for recorded
messages.

=item * playback_or_record

Will return a recorded message if it exists, or fetch one from the remote
server and store the response.

=item * record

Will always fetch a new response from the remote server and store the response.

=back

=head1 METHODS

=head2 cache_driver_singleton

  $obj = Mojo::UserAgent::Role::Cache->cache_driver_singleton;
  Mojo::UserAgent::Role::Cache->cache_driver_singleton($obj);

Used to retrieve or set the default L</cache_driver>. Useful for setting up
caching globally in unit tests.

=head1 AUTHOR

Jan Henning Thorsen

=head1 COPYRIGHT AND LICENSE

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Mojo::UserAgent>,
L<https://metacpan.org/pod/Mojo::UserAgent::Cached> and
L<https://metacpan.org/pod/Mojo::UserAgent::Mockable>.

=cut
