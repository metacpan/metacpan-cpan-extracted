use strict;
use warnings;

package Monitor::MetricsAPI::MetricFactory;
$Monitor::MetricsAPI::MetricFactory::VERSION = '0.900';
use Module::Loaded;

use Monitor::MetricsAPI::Metric;

use Monitor::MetricsAPI::Metric::Boolean;
use Monitor::MetricsAPI::Metric::Callback;
use Monitor::MetricsAPI::Metric::Counter;
use Monitor::MetricsAPI::Metric::Gauge;
use Monitor::MetricsAPI::Metric::List;
use Monitor::MetricsAPI::Metric::String;
use Monitor::MetricsAPI::Metric::Timestamp;

=head1 NAME

Monitor::MetricsAPI::MetricFactory - Factory for creating Metric::* objects.

=head1 SYNOPSIS

You should not interact with this module directly in your code. Please refer to
L<Monitor::MetricsAPI> for how to integrate this service with your application.

=head1 DESCRIPTION

This module provides a factory pattern for creating individual metric objects.
The intent is for L<Monitor::MetricsAPI::Collector> to use this when building
the collector, as well as any time new metrics are added to an existing
collector.

=head1 METHODS

=head2 create (%options)

Accepts a hash of options describing a metric, and returns the appropriate type
of metric object. Valid entries in the options hash are:

=over

=item * name

A string containing the full name (including all parent groups) for the metric.
As detailed in L<Monitor::MetricsAPI::Tutorial>, full metric names are
slash-delimited strings of the form "<group>/<subgroup>/<metric>" and there may
be as many or as few subgroups as you choose.

Example:

    process/workers/current_threads

=item * type

A string naming the type of metric to be created. This will match the last
component of the metric class's name, in lowercase. Thus, a metric of the class
L<Monitor::MetricsAPI::Metric::Boolean> would have a type of "boolean".

=item * callback

A subroutine to be invoked every time the metric is included in API output, or
when the metric's value() method is called. Relevant only for metrics of type
'callback'.

=back

=cut

sub create {
    my ($class, %options) = @_;

    die "must pass metric options as a hash" unless %options;
    die "must indicate the type of metric to create" unless exists $options{'type'};

    my $type = ucfirst($options{'type'});
    my $pkg = "Monitor::MetricsAPI::Metric::$type";

    die $options{'type'} . " is not a valid metric type" unless is_loaded($pkg);

    return $pkg->new(%options);
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

1;
