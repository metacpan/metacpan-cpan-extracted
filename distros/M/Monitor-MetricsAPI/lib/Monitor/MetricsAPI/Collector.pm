use strict;
use warnings;

package Monitor::MetricsAPI::Collector;
$Monitor::MetricsAPI::Collector::VERSION = '0.900';
use namespace::autoclean;
use Moose;
use Socket qw(:addrinfo SOCK_RAW);

use Monitor::MetricsAPI::MetricFactory;
use Monitor::MetricsAPI::Server;

=head1 NAME

Monitor::MetricsAPI::Collector - Metrics collection object

=head1 SYNOPSIS

You should not create your own objects from this module directly. All Collector
objects should be instantiated through the L<Monitor::MetricsAPI> module's
create() method. Please refer to that module's documentation for information on
setting up your application's usage of this library.

=cut

=head1 DESCRIPTION

=cut

has 'servers' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
);

has 'metrics' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
);

sub BUILDARGS {
    my $class = shift;
    my %args;

    if (@_ == 1 && ref($_[0]) eq 'HASH') {
        %args = %{$_[0]};
    } elsif (@_ % 2 == 0) {
        %args = @_;
    }

    if (exists $args{'metrics'}) {
        if (ref($args{'metrics'}) eq 'HASH') {
            my %m;
            foreach my $metric (_parse_metrics_hash($args{'metrics'})) {
                if (ref($metric->[1]) eq 'CODE') {
                    $m{$metric->[0]} = Monitor::MetricsAPI::MetricFactory->create(
                        name => $metric->[0],
                        type => 'callback',
                        cb   => $metric->[1],
                    );
                } else {
                    $m{$metric->[0]} = Monitor::MetricsAPI::MetricFactory->create(
                        name => $metric->[0],
                        type => $metric->[1],
                    );
                }
            }
            $args{'metrics'} = \%m;
        } else {
            warn "metrics option must be provided as a hashref";
        }
    }

    if (exists $args{'listen'}) {
        my ($hosts, $port) = _split_host_and_port($args{'listen'});

        $args{'servers'} = {};

        foreach my $host_ip (@{$hosts}) {
            my $listen = "$host_ip:$port";
            next if exists $args{'servers'}{$listen};

            $args{'servers'}{$listen} = Monitor::MetricsAPI::Server->new(
                $host_ip, $port
            );
        }
    }

    return \%args;
}

sub _parse_metrics_hash {
    my ($metrics, @groups) = @_;

    my @m;

    foreach my $k (keys %{$metrics}) {
        if (ref($metrics->{$k}) eq 'HASH') {
            push(@m, _parse_metrics_hash($metrics->{$k}, @groups, $k));
        } else {
            push(@m, [_make_metric_name(@groups, $k), $metrics->{$k}]);
        }
    }

    return @m;
}

sub _make_metric_name {
    my (@groups, $metric) = @_;

    return join('/', grep { defined $_ && $_ =~ m{\w+} } (@groups, $metric));
}

sub _split_host_and_port {
    my ($listen) = @_;

    my ($addr, $port) = split(':', $listen);

    die "address may not be omitted and must be a hostname, an IP, or an asterisk"
        unless defined $addr && $addr =~ m{\S+};
    die "port must be a number (or omitted entirely to use default)"
        if defined $port && $port ne '' && $port !~ m{^\d+$};

    $port = 8200 unless defined $port && $port ne '';

    my $hosts = [];

    if ($addr eq '*') {
        $hosts = ['0.0.0.0'];
    } else {
        my ($err, @res) = getaddrinfo($addr, "", {socktype => SOCK_RAW});
        die "could not resolve $addr: $err" if $err;
        foreach (@res) {
            my $ipaddr;
            ($err, $ipaddr) = getnameinfo($_->{'addr'}, NI_NUMERICHOST, NIx_NOSERV);
            die "could not lookup $_->{'addr'}: $err" if $err;
            push(@{$hosts}, $ipaddr);
        }
    }

    return ($hosts, $port);
}

=head1 METHODS

=head2 metric ($name)

Returns the L<Monitor::MetricsAPI::Metric> object for the given name. Metric
names are collapsed to a slash-delimited string, which mirrors the path used
by the reporting HTTP server to display individual metrics. Thus, this:

    Monitor::MetricsAPI->new(
        metrics => {
            server => {
                version => {
                    major => 'string',
                    minor => 'string',
                }
            }
        }
    );

Creates two metrics:

=over

=item 1. server/version/major

=item 2. server/version/minor

=back

The metric object returned by this method may then be modified, according to
its own methods documented in L<Monitor::MetricsAPI::Metric> and the
type-specific documentation, or its value may be accessed via the standard
value() metric method.

Updating a metric:

    $collector->metric('users/total')->set($user_count);

Retrieving the current value of a metric:

    $collector->metric('users/total')->value;

=cut

sub metric {
    my ($self, $name) = @_;

    unless (defined $name) {
        warn "cannot retrieve metric value without a name";
        return;
    }

    unless (exists $self->metrics->{$name}) {
        warn "the metric $name does not exist";
        return;
    }

    return $self->metrics->{$name};
}

=head2 add_metrics (\%metrics)

Accepts a hashref of hierarchical metric definitions (please see documentation
in L<Monitor::MetricsAPI::Tutorial> for a more complete description). Used to
bulk-add metrics to a collector.

=cut

sub add_metrics {
    my ($self, $metrics) = @_;

    return unless defined $metrics && ref($metrics) eq 'HASH';

    foreach my $metric (_parse_metrics_hash($metrics)) {
        if (ref($metric->[1]) eq 'CODE') {
            $self->metrics->{$metric->[0]} = Monitor::MetricsAPI::MetricFactory->create(
                name => $metric->[0],
                type => 'callback',
                cb   => $metric->[1],
            );
        } else {
            $self->metrics->{$metric->[0]} = Monitor::MetricsAPI::MetricFactory->create(
                name => $metric->[0],
                type => $metric->[1],
            );
        }
    }

    return 1;
}

=head2 add_metric ($name, $type, $callback)

Allows for adding a new metric to the collector as your application is running,
instead of having to define everything at startup.

If the metric already exists, this method will be a noop as long as all of the
metric options match (i.e. the existing metric is of the same type as what you
specified in add_metric()). If the metric already exists and you have specified
options which do not match the existing ones, a warning will be emitted and no
other actions will be taken.

Both $name and $type are required. If $type is 'callback' then a subroutine
reference must be passed in for $callback. Refer to the documentation in
L<Monitor::MetricsAPI::Metric> for details on individual metric types.

=cut

sub add_metric {
    my ($self, $name, $type, $callback) = @_;

    unless (defined $name && defined $type) {
        warn "metric creation requires a name and type";
        return;
    }

    if ($type eq 'callback' && (!defined $callback || ref($callback) ne 'CODE')) {
        warn "callback metrics must also provide a subroutine";
        return;
    }

    if (exists $self->metrics->{$name}) {
        return if $self->metrics->{$name}->type eq $type;
        warn "metric $name already exists, but is not of type $type";
        return;
    }

    my $metric = Monitor::MetricsAPI::MetricFactory->create(
        type => $type,
        name => $name,
        ( $type eq 'callback' ? ( cb => $callback ) : ())
    );

    unless (defined $metric) {
        warn "could not create the metric $name";
        return;
    }

    $self->metrics->{$metric->name} = $metric;
    return $metric;
}

=head2 add_server ($listen)

Adds a new HTTP server listener to the collector. The $listen argument must be
a string in the form of "<address>:<port>" where address may be an asterisk to
indicate all interfaces should be listened on, and where port (as well as the
leading colon) may be omitted if you wish to use the default port of 8200.

Examples:

    $collector->add_server('*:8201');
    $collector->add_server('127.0.0.1:8202');
    $collector->add_server('192.168.1.1');

You may add as many servers as you like. If you attempt to bind to the same
address and port combination more than once, a warning will be emitted and no
action will be taken.

=cut

sub add_server {
    my ($self, $listen) = @_;

    return unless defined $listen;

    my ($hosts, $port) = _split_host_and_port($listen);

    foreach my $host_ip (@{$hosts}) {
        my $listen = "$host_ip:$port";
        if (exists $self->servers->{$listen}) {
            warn "already listening on $listen";
            next;
        }

        $self->servers->{$listen} = Monitor::MetricsAPI::Server->new(
            $host_ip, $port
        );
    }
}

=head1 AUTHORS

Jon Sime <jonsime@gmail.com>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2015 by OmniTI Computer Consulting, Inc.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

__PACKAGE__->meta->make_immutable;
1;
