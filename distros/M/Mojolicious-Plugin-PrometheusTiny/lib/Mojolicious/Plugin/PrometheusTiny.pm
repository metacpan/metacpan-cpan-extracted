package Mojolicious::Plugin::PrometheusTiny;
use Mojo::Base 'Mojolicious::Plugin', -signatures;
use Time::HiRes qw/gettimeofday tv_interval/;
use Prometheus::Tiny::Shared;

our $VERSION = '0.02';

has prometheus => sub {Prometheus::Tiny::Shared->new()};
has route => undef;
has setup_metrics => undef;
has update_metrics => undef;

sub register($self, $app, $config = {}) {
    if (my $update = $config->{update}) {
        $self->update_metrics($update);
    }
    $config->{worker_label} //= 1;
    $config->{method_label} //= 1;
    $app->helper(prometheus => sub {$self->prometheus});
    $self->_setup($config);
    if (my $setup = $config->{setup}) {
        $self->setup_metrics($setup);
        $app->$setup($self->prometheus);
    }
    my $prefix = $config->{route} // $app->routes->under('/');
    $self->route($prefix->get($config->{path} // '/metrics'));
    our $endpoint = $self->route->to_string; # Use direct string comparison instead of $route->match
    $self->route->to(
        cb => sub($c) {
            if (my $update = $self->update_metrics) {
                $c->$update($self->prometheus);
            }
            $c->render(
                text   => $c->prometheus->format,
                format => 'txt',
            );
        });
    $app->hook(
        before_dispatch => sub($c, @args) {
            return if $c->req->url->path eq $endpoint;
            $c->stash('prometheus.start_time' => [ gettimeofday ]);
            $self->prometheus->histogram_observe(
                http_request_size_bytes => $c->req->content->body_size => {
                    $config->{worker_label} ? (worker => $$) : (),
                    $config->{method_label} ? (method => $c->req->method) : (),
                },
            );
        }
    );
    $app->hook(
        after_render => sub($c, @args) {
            return if $c->req->url->path eq $endpoint;
            $self->prometheus->histogram_observe(
                http_request_duration_seconds => tv_interval($c->stash('prometheus.start_time')) => {
                    $config->{worker_label} ? (worker => $$) : (),
                    $config->{method_label} ? (method => $c->req->method) : (),
                },
            );

        }
    );
    $app->hook(
        after_dispatch => sub($c, @args) {
            return if $c->req->url->path eq $endpoint;
            $self->prometheus->inc(http_requests_total => {
                $config->{worker_label} ? (worker => $$) : (),
                method => $c->req->method,
                code   => $c->res->code,
            });
            $self->prometheus->histogram_observe(
                http_response_size_bytes => $c->res->body_size => {
                    $config->{worker_label} ? (worker => $$) : (),
                    $config->{method_label} ? (method => $c->req->method) : (),
                    code => $c->res->code,
                },
            );
        }
    );

}

sub _setup($self, $config) {
    my $p = $self->prometheus();
    $p->declare('perl_info', type => 'gauge');
    $p->set(perl_info => 1, { version => $^V });
    $p->declare('http_request_duration_seconds',
        help    => 'Histogram with request processing time',
        type    => 'histogram',
        buckets => $config->{duration_buckets}
            // [ 1 .. 10, 20, 30, 60, 120, 300, 600, 1_200, 3_600, 6_000, 12_000 ],
    );
    $p->declare('http_requests_total',
        help => 'How many HTTP requests processed, partitioned by status code and HTTP method',
        type => 'counter',
    );
    $p->declare('http_request_size_bytes',
        help    => 'Histogram containing request sizes',
        type    => 'histogram',
        buckets => $config->{request_buckets}
            // [ 1, 10, 100, 1_000, 10_000, 50_000, 100_000, 500_000, 1_000_000 ],
    );
    $p->declare('http_response_size_bytes',
        help    => 'Histogram containing response sizes',
        type    => 'histogram',
        buckets => $config->{response_buckets}
            // [ 1, 10, 100, 1_000, 10_000, 50_000, 100_000, 500_000, 1_000_000 ],
    );
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::PrometheusTiny - Export metrics using Prometheus::Tiny::Shared

=head1 SYNOPSIS

    # Mojolicious
    $self->plugin('PrometheusTiny');

    # Mojolicious::Lite
    plugin 'PrometheusTiny';

    # Mojolicious::Lite, with custom response buckets (seconds)
    plugin 'PrometheusTiny' => { response_buckets => [qw/4 5 6/] };

    # You can add your own route to do access control
    my $under = app->routes->under('/secret' =>sub {
      my $c = shift;
      return 1 if $c->req->url->to_abs->userinfo eq 'Bender:rocks';
      $c->res->headers->www_authenticate('Basic');
      $c->render(text => 'Authentication required!', status => 401);
      return undef;
    });
    plugin PrometheusTiny => {
        route  => $under,
        # You may declare additional metrics with their own TYPE and HELP...
        setup  => sub($app, $p) {
            $p->declare('mojo_random',
                type => 'gauge',
                help => "Custom prometheus gauge"
            );
        },
        # ...and set up a callback to update them right before exporting them
        update => sub($c, $p) {
            $p->set(mojo_random => rand(100));
        },
    };

=head1 DESCRIPTION

L<Mojolicious::Plugin::PrometheusTiny> is a L<Mojolicious> plugin that exports Prometheus metrics from Mojolicious.
It's based on L<Mojolicious::Plugin::Prometheus> but uses L<Prometheus::Tiny::Shared> instead of L<Net::Prometheus>.

Default hooks are installed to measure requests response time and count requests by HTTP return code,
with optional labeling of worker PID and HTTP method.
It is easy to add custom metrics and update them right before the metrics are exported.

There is no support for namespaces, subsystems or any other fancy Net::Prometheus features.

=head1 CODE QUALITY NOTICE

This is BETA code =head1 HELPERS

=head2 prometheus

Create further instrumentation into your application by using this helper which gives access to the
 L<Prometheus::Tiny::Shared> object.
See L<Prometheus::Tiny> for usage.

=head1 METHODS

L<Mojolicious::Plugin::PrometheusTiny> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register($app, \%config);

Register plugin in L<Mojolicious> application.

C<%config> can have:

=over 2

=item * route

L<Mojolicious::Routes::Route> object to attach the metrics to, defaults to generating a new one for '/'.

Default: /

=item * path

The path to mount the exporter.

Default: /metrics

=item * prometheus

Override the L<Prometheus::Tiny::Shared> object.
 The default is a new singleton instance of L<Prometheus::Tiny::Shared>.

=item * request_buckets

Override buckets for request sizes histogram.

Default: C<[ 1, 10, 100, 1_000, 10_000, 50_000, 100_000, 500_000, 1_000_000 ]>

=item * response_buckets

Override buckets for response sizes histogram.

Default: C<[ 1, 10, 100, 1_000, 10_000, 50_000, 100_000, 500_000, 1_000_000 ]>

=item * duration_buckets

Override buckets for request duration         setup  => sub($app, $p) {
            $p->declare('mojo_random',
                type => 'gauge',
                help => "Custom prometheus gauge"
            );
        }histogram.

Default: C<[1..10, 20, 30, 60, 120, 300, 600, 1_200, 3_600, 6_000, 12_000]>

=item * worker_label

Label metrics by worker PID, which might increase significantly the number of Prometheus time series.

Default: true

=item * method_label

Label metrics by HTTP method, which might increase significantly the number of Prometheus time series.

Default: true

=item * setup

Coderef to be executed during setup. Receives as arguments Application and Prometheus instances.
 Can be used to declare and/or initialize new metrics. Though it is trivial to use $app->prometheus
 to declare metrics after plugin setup, code is more readable and easier to maintain
 when actions are listed in their natural order.

=item * update

Coderef to be executed right before invoking exporter action configured in C<path>.
 Receives as arguments Controller and Prometheus instances.

=back

=head1 METRICS

This plugin exposes

=over 2

=item * C<http_requests_total>, request counter partitioned over HTTP method and HTTP response code

=item * C<http_request_duration_seconds>, request duration histogram partitioned over HTTP method

=item * C<http_request_size_bytes>, request size histogram partitioned over HTTP method

=item * C<http_response_size_bytes>, response size histogram partitioned over HTTP method

=back

=head1 TO DO

=over 2

=item * Add optional L<Net::Prometheus::ProcessCollector>-like process metrics.

=back

=head1 AUTHOR

Javier Arturo Rodriguez

A significant part of this code has been ripped off L<Mojolicious::Plugin::Prometheus> written by Vidar Tyldum

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2023 by Javier Arturo Rodriguez.

This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<https://mojolicious.org>,
 L<Mojolicious::Plugin::Prometheus>,  L<Prometheus::Tiny>, L<Prometheus::Tiny::Shared>.

=cut
