use strict;
use warnings;

package Monitor::MetricsAPI;
# ABSTRACT: Metrics collection and reporting for Perl applications.
$Monitor::MetricsAPI::VERSION = '0.900';
use namespace::autoclean;
use Moose;
use MooseX::ClassAttribute;

use Monitor::MetricsAPI::Collector;

=head1 NAME

Monitor::MetricsAPI - Metrics collection and reporting for Perl applications.

=head1 SYNOPSIS

    use Monitor::MetricsAPI;

    my $collector = Monitor::MetricsAPI->create(
        listen => '*:8000',
        metrics => {
            messages => {
                incoming => 'counter',
                outgoing => 'counter',
            },
            networks => {
                configured => 'gauge',
                connected  => 'gauge',
            },
            users => {
                total => sub { $myapp->total_user_count() },
            }
        }
    );

    # Using the collector object methods:
    $collector->metric('messages/incoming')->add(1);
    $collector->metric('networks/connected')->set(3);

    # Using a global collector via class methods:
    Monitor::MetricsAPI->metric('messages/incoming')->increment;

=head1 DESCRIPTION

Monitor::MetricsAPI provides functionality for the collection of arbitrary
application metrics within any event-driven Perl application, as well as the
reporting of those statistics via a JSON-over-HTTP API for consumption by
external systems monitoring tools.

Using Monitor::MetricsAPI first requires that you create the metrics collector
(and accompanying reporting server), by calling create() and providing it with
an address and port to which it should listen. Additionally, any metrics you
wish the collector to track should be defined.

The example above has created a new collector which will listen to all network
interfaces on port 8000. It has also defined two metrics of type 'counter' and
one metric which will invoke the provided subroutine every time the reporting
server displays the value. Refer to L<Monitor::MetricsAPI::Metric> for more
details on support metric types and their usage.

As your app runs, it can manipulate metrics by calling various methods via the
collector object:

For applications where passing around the collector object to all of your
functions and libraries is not possible, you may also allow Monitor::MetricsAPI
to maintain the collector as a global for you. This is done automatically for
the first collector object you create (and very few applications will want to
use more than one collector anyway).

Instead of invoking metric methods on a collector object, invoke them as class
methods:

=cut

class_has 'collector' => (
    is        => 'ro',
    isa       => 'Monitor::MetricsAPI::Collector',
    predicate => '_has_global',
    writer    => '_set_global',
);

=head1 METHODS

=head2 create ( listen => '...', metrics => { ... } )

Creates a new collector, which in turn initializes the defined metrics and
binds to the provided network interfaces and ports. If there is already a
global collector, then any metric definitions passed into this class method
will be added to the existing collector before it is returned.

=cut

sub create {
    my ($class, @args) = @_;

    if ($class->_has_global) {
        if (@args && @args % 2 == 0) {
            my %args = @args;

            if (exists $args{'metrics'}) {
                $class->collector->add_metrics($args{'metrics'});
            }

            if (exists $args{'listen'}) {
                $class->collector->add_server($args{'listen'});
            }
        }
    } else {
        $class->_set_global(
            Monitor::MetricsAPI::Collector->new(
                @args
            )
        );
    }

    return $class->collector;
}

=head2 metric ($name)

Returns the L<Monitor::MetricsAPI::Metric> object for the given name. Metric
names are collapsed to a slash-delimited string, which mirrors the path used
by the reporting HTTP server to display individual metrics. Thus, this:

    Monitor::MetricsAPI->create(
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
    my $class = shift;

    die "no collector has been created yet" unless $class->_has_global;
    return $class->collector->metric(@_);
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
    my $class = shift;

    die "no collector has been created yet" unless $class->_has_global;
    return $class->collector->add_metric(@_);
}

=head1 DEPENDENCIES

Monitor::MetricsAPI primarily makes use of the CPAN distributions listed below,
though others may also be required for building, testing, and/or operation. For
the complete list of dependencies, please refer to the distribution metadata.

=over

=item * L<AnyEvent>

=item * L<Twiggy>

=item * L<Dancer2>

=item * L<Moose>

=back

=head1 BUGS

There are no known bugs at the time of this release.

Please report any bugs or problems to the module's Github Issues page:

L<https://github.com/jsime/monitor-metricsapi/issues>

Pull requests are welcome.

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
