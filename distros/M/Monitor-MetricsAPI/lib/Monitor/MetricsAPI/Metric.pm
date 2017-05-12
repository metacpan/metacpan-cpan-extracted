use strict;
use warnings;

package Monitor::MetricsAPI::Metric;
$Monitor::MetricsAPI::Metric::VERSION = '0.900';
use namespace::autoclean;
use Moose;

=head1 NAME

Monitor::MetricsAPI::Metric - Base class for Monitor::MetricsAPI metrics.

=head1 SYNOPSIS

You should not interact with this module directly in your code. Please refer to
L<Monitor::MetricsAPI> for how to integrate this service with your application.

=head1 DESCRIPTION

=cut

=head1 METRIC TYPES

Several different types of metrics are offered, to allow for tracking many
unique and varying bits of information in your applications. Each metric type
behaves slightly different, permits its own limited range of values, and
exposes its own set of methods for manipulating the metric value.

It is important that you choose the proper type of metric for whatever it is
you are attempting to track. Using a boolean metric, for instance, to monitor
your memory usage is utter nonsense, as is using a string metric for your API
requests counter.

=over

=item * L<string|Monitor::MetricsAPI::Metric::String>

The simplest of metric types. Any arbitrary string value may be stored in the
metric and it will be echoed back in reporting output. Application names,
version numbers, build numbers, and so on make sense for String metrics.

=item * L<boolean|Monitor::MetricsAPI::Metric::Boolean>

Boolean metrics allow you to monitor the true/false/unknown state of something.

=item * L<counter|Monitor::MetricsAPI::Metric::Counter>

=item * L<gauge|Monitor::MetricsAPI::Metric::Gauge>

=item * L<timestamp|Monitor::MetricsAPI::Metric::Timestamp>

Timestamp metrics allow you to update a timestamp when a particular event
occurs. Useful for ensuring that it hasn't been too long since an expected
event has been triggered.

=item * L<callback|Monitor::MetricsAPI::Metric::Callback>

Callback metrics allow you to supply a subroutine to invoke any time the metric
is included in reporting output. Useful when the metric requires additional
computation (e.g. avg-events-over-time), or the use of an external resource
such as a database (e.g. total registered users).

=back

=cut

has 'name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'type' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has '_value' => (
    is        => 'ro',
    predicate => '_has_value',
    writer    => '_set_value',
    clearer   => '_clear_value',
);

=head1 BASE METHODS

The following methods are provided for all types of metrics. Additional methods
may be provided by individual metric types.

=head2 value

Returns the current value of the metric.

=cut

sub value {
    my ($self) = @_;

    return unless $self->_has_value;
    return $self->_value;
}

=head2 set ($value)

Updates the current value of the metric to $value. Individual metric types may
perform validation on the value.

=cut

sub set {
    my ($self, $value) = @_;

    return $self->_set_value($value);
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
