package Mojolicious::Plugin::Prometheus;
use Mojo::Base 'Mojolicious::Plugin';
use Time::HiRes qw/gettimeofday tv_interval/;
use Net::Prometheus;
use IPC::ShareLite;

our $VERSION = '1.2.1';

has prometheus => sub { Net::Prometheus->new(disable_process_collector => 1) };
has route => sub {undef};
has http_request_duration_seconds => sub {
  undef;
};
has http_request_size_bytes => sub {
  undef;
};
has http_response_size_bytes => sub {
  undef;
};
has http_requests_total => sub {
  undef;
};


sub register {
  my ($self, $app, $config) = @_;

  $self->{key} = $config->{shm_key} || '12345';

  $app->helper(prometheus => sub { $self->prometheus });

  # Only the two built-in servers are supported for now
  $app->hook(before_server_start => sub { $self->_start(@_, $config) });

  $self->http_request_duration_seconds(
    $self->prometheus->new_histogram(
      namespace => $config->{namespace}        // undef,
      subsystem => $config->{subsystem}        // undef,
      name      => "http_request_duration_seconds",
      help      => "Histogram with request processing time",
      labels    => [qw/worker method/],
      buckets   => $config->{duration_buckets} // undef,
    )
  );

  $self->http_request_size_bytes(
    $self->prometheus->new_histogram(
      namespace => $config->{namespace} // undef,
      subsystem => $config->{subsystem} // undef,
      name      => "http_request_size_bytes",
      help      => "Histogram containing request sizes",
      labels    => [qw/worker method/],
      buckets   => $config->{request_buckets}
        // [(1, 50, 100, 1_000, 10_000, 50_000, 100_000, 500_000, 1_000_000)],
    )
  );

  $self->http_response_size_bytes(
    $self->prometheus->new_histogram(
      namespace => $config->{namespace} // undef,
      subsystem => $config->{subsystem} // undef,
      name      => "http_response_size_bytes",
      help      => "Histogram containing response sizes",
      labels    => [qw/worker method code/],
      buckets   => $config->{response_buckets}
        // [(5, 50, 100, 1_000, 10_000, 50_000, 100_000, 500_000, 1_000_000)],
    )
  );

  $self->http_requests_total(
    $self->prometheus->new_counter(
      namespace => $config->{namespace} // undef,
      subsystem => $config->{subsystem} // undef,
      name      => "http_requests_total",
      help =>
        "How many HTTP requests processed, partitioned by status code and HTTP method.",
      labels => [qw/worker method code/]
    )
  );

  # Collect stats
  $app->hook(
    after_render => sub {
      my ($c) = @_;
      $self->_guard->_change(
        sub {
          $_->{$$} = $app->prometheus->render;
        }
      );

      #$self->_guard->_store({$$ => $app->prometheus->render});
    }
  );

  $app->hook(
    before_dispatch => sub {
      my ($c) = @_;
      $c->stash('prometheus.start_time' => [gettimeofday]);
      $self->http_request_size_bytes->observe($$, $c->req->method,
        $c->req->content->body_size);
    }
  );

  $app->hook(
    after_render => sub {
      my ($c) = @_;
      $self->http_request_duration_seconds->observe($$, $c->req->method,
        tv_interval($c->stash('prometheus.start_time')));
    }
  );

  $app->hook(
    after_dispatch => sub {
      my ($c) = @_;
      $self->http_requests_total->inc($$, $c->req->method, $c->res->code);
      $self->http_response_size_bytes->observe($$, $c->req->method,
        $c->res->code, $c->res->content->body_size);
    }
  );


  $self->route($app->routes->get($config->{path} // '/metrics'));
  $self->route->to(
    cb => sub {
      my ($c) = @_;
      $c->render(
        text => join("\n",
          map { ($self->_guard->_fetch->{$_}) }
          sort keys %{$self->_guard->_fetch}),
        format => 'txt'
      );
    }
  );

}

sub _guard {
  my $self = shift;

  my $share = $self->{share}
    ||= IPC::ShareLite->new(-key => $self->{key}, -create => 1, -destroy => 0)
    || die $!;

  return Mojolicious::Plugin::Mojolicious::_Guard->new(share => $share);
}

sub _start {

  #my ($self, $app, $config) = @_;
  my ($self, $server, $app, $config) = @_;
  return unless $server->isa('Mojo::Server::Daemon');

  Mojo::IOLoop->next_tick(
    sub {
      $self->prometheus->register(
        Net::Prometheus::ProcessCollector->new(labels => [worker => $$]));
      $self->_guard->_store({$$ => $self->prometheus->render});
    }
  );

  # Remove stopped workers
  $server->on(
    reap => sub {
      my ($server, $pid) = @_;
      $self->_guard->_change(sub { delete $_->{$pid} });
    }
  ) if $server->isa('Mojo::Server::Prefork');
}


package Mojolicious::Plugin::Mojolicious::_Guard;
use Mojo::Base -base;

use Fcntl ':flock';
use Sereal qw(get_sereal_decoder get_sereal_encoder);

my ($DECODER, $ENCODER) = (get_sereal_decoder, get_sereal_encoder);

sub DESTROY { shift->{share}->unlock }

sub new {
  my $self = shift->SUPER::new(@_);
  $self->{share}->lock(LOCK_EX);
  return $self;
}

sub _change {
  my ($self, $cb) = @_;
  my $stats = $self->_fetch;
  $cb->($_) for $stats;
  $self->_store($stats);
}

sub _fetch {
  return {} unless my $data = shift->{share}->fetch;
  return $DECODER->decode($data);
}

sub _store { shift->{share}->store($ENCODER->encode(shift)) }

1;
__END__

=for stopwords prometheus

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Prometheus - Mojolicious Plugin

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('Prometheus');

  # Mojolicious::Lite
  plugin 'Prometheus';

  # Mojolicious::Lite, with custom response buckets (seconds)
  plugin 'Prometheus' => { response_buckets => [qw/4 5 6/] };

=head1 DESCRIPTION

L<Mojolicious::Plugin::Prometheus> is a L<Mojolicious> plugin that exports Prometheus metrics from Mojolicious.

Hooks are also installed to measure requests response time and count requests based on method and HTTP return code.

=head1 HELPERS

=head2 prometheus

Create further instrumentation into your application by using this helper which gives access to the L<Net::Prometheus> object.
See L<Net::Prometheus> for usage.

=head1 METHODS

L<Mojolicious::Plugin::Prometheus> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register($app, \%config);

Register plugin in L<Mojolicious> application.

C<%config> can have:

=over 2

=item * path

The path to mount the exporter.

Default: /metrics

=item * prometheus

Override the L<Net::Prometheus> object. The default is a new singleton instance of L<Net::Prometheus>.

=item * namespace, subsystem

These will be prefixed to the metrics exported.

=item * request_buckets

Override buckets for request sizes histogram.

Default: C<(1, 50, 100, 1_000, 10_000, 50_000, 100_000, 500_000, 1_000_000)>

=item * response_buckets

Override buckets for response sizes histogram.

Default: C<(5, 50, 100, 1_000, 10_000, 50_000, 100_000, 500_000, 1_000_000)>

=item * duration_buckets

Override buckets for request duration histogram.

Default: C<(0.005, 0.01, 0.025, 0.05, 0.075, 0.1, 0.25, 0.5, 0.75, 1.0, 2.5, 5.0, 7.5, 10)> (actually see L<Net::Prometheus|https://metacpan.org/source/PEVANS/Net-Prometheus-0.05/lib/Net/Prometheus/Histogram.pm#L19>)

=item * shm_key

Key used for shared memory access between workers, see L<$key in IPc::ShareLite|https://metacpan.org/pod/IPC::ShareLite> for details.

=back

=head1 METRICS

In addition to exposing the default process metrics that L<Net::Prometheus> already expose
this plugin will also expose

=over 2

=item * C<http_requests_total>, request counter partitioned over HTTP method and HTTP response code

=item * C<http_request_duration_seconds>, request duration histogram partitioned over HTTP method

=item * C<http_request_size_bytes>, request size histogram partitioned over HTTP method

=item * C<http_response_size_bytes>, response size histogram partitioned over HTTP method

=back

=head1 AUTHOR

Vidar Tyldum

(the IPC::ShareLite parts of this code is shamelessly stolen from L<Mojolicious::Plugin::Status> written by Sebastian Riedel and mangled into something that works for me)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018, Vidar Tyldum

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

=over 2

=item L<Net::Prometheus>

=item L<Mojolicious::Plugin::Status>

=item L<Mojolicious>

=item L<Mojolicious::Guides>

=item L<http://mojolicious.org>

=back

=cut
