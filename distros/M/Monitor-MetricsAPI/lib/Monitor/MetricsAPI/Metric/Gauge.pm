use strict;
use warnings;

package Monitor::MetricsAPI::Metric::Gauge;
$Monitor::MetricsAPI::Metric::Gauge::VERSION = '0.900';
use namespace::autoclean;
use Moose;

extends 'Monitor::MetricsAPI::Metric';

=head1 NAME

Monitor::MetricsAPI::Metric::Gauge - Gauge metric class for Monitor::MetricsAPI

=head1 SYNOPSIS

    use Monitor::MetricsAPI;

    my $collector = Monitor::MetricsAPI->new(
        metrics => { process => { threads => 'gauge' } }
    );

    # Later on, when your application modifies its worker thread pool:
    $collector->metric('process/threads')->set(4);

=head1 DESCRIPTION

Gauge counters are numeric metrics providing an arbitrary point-in-time value.
Gauges may increase and decrease, and may do either by varying amounts each
time. They are useful for tracking things like current memory usage, number of
child threads or processes, temperature of a sensor, and any other arbitrary
values of interest.

All gauges are initialized at zero, but may be set to any numeric value even
negative values.

=cut

sub BUILD {
    my ($self) = @_;

    $self->_set_value(0);
}

=head1 METHODS

Gauge metrics do not provide any additional methods beyond the base methods
offered by L<Monitor::MetricsAPI::Metric>.

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
