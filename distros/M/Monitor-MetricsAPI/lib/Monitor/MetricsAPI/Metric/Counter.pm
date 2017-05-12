use strict;
use warnings;

package Monitor::MetricsAPI::Metric::Counter;
$Monitor::MetricsAPI::Metric::Counter::VERSION = '0.900';
use namespace::autoclean;
use Moose;

extends 'Monitor::MetricsAPI::Metric';

=head1 NAME

Monitor::MetricsAPI::Metric::Counter - Counter metric class for Monitor::MetricsAPI

=head1 SYNOPSIS

    use Monitor::MetricsAPI;

    my $collector = Monitor::MetricsAPI->new(
        metrics => { messages => { incoming => 'counter' } }
    );

    # Later on, when a new message is received by your app:
    $collector->metric('messages/incoming')->increment;

=head1 DESCRIPTION

Counter metrics are numeric values which initialize at zero and only increase
over the lifetime of the monitored process. Counter metrics are appropriate
when you simply want to know how many times I<X> occurred.

=cut

sub BUILD {
    my ($self) = @_;

    $self->_set_value(0);
}

=head1 METHODS

The following methods are specific to counter metrics. L<Monitor::MetricsAPI::Metric>
defines methods which are common to all metric types.

=head2 add ($amount)

Adds $amount to the current value of the metric.

=cut

sub add {
    my ($self, $amount) = @_;

    return $self->_set_value(($self->_has_value ? $self->value : 0) + $amount);
}

=head2 increment

Increases the value of the metric by 1 each time it is called. Produces the
same effect as calling $metric->add(1), which is unsurprising since that is exactly
what this method does.

=cut

sub increment {
    my ($self) = @_;

    return $self->add(1);
}

=head2 incr

Alias for increment()

=cut

sub incr {
    my ($self) = @_;

    return $self->add(1);
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
