use strict;
use warnings;

package Monitor::MetricsAPI::Metric::Timestamp;
$Monitor::MetricsAPI::Metric::Timestamp::VERSION = '0.900';
use namespace::autoclean;
use Moose;
use DateTime;

extends 'Monitor::MetricsAPI::Metric';

=head1 NAME

Monitor::MetricsAPI::Metric::Timestamp - Timestamp metric class for Monitor::MetricsAPI

=head1 SYNOPSIS

    use Monitor::MetricsAPI;

    my $collector = Monitor::MetricsAPI->new(
        metrics => { auditing => { admin => { last_lockout => 'timestamp' } } }
    );

    # Later on, when a client is locked out of your admin functions because
    # of repeated authentication failures:
    $collector->metric('auditing/admin/last_lockout')->now;

=head1 DESCRIPTION

Timestamp metrics allow you to record the time at which an event most recently
occurred. The base set() method is disabled (a warning will be emitted if you
call it, and no other action will be taken). All timestamp metrics initialize
to an empty value, and are always displayed in reporting output as UTC in the
ISO-8601 format.

=cut

=head1 METHODS

The following methods are specific to timestamp metrics. L<Monitor::MetricsAPI::Metric>
defines methods which are common to all metric types.

=head2 now

Sets the value of the timestamp metric to the current time.

=cut

sub now {
    my ($self) = @_;

    $self->_set_dt(DateTime->now( time_zone => 'UTC' ));
    return $self->_set_value($self->dt->iso8601 . 'Z');
}

=head2 dt

Returns a DateTime object, suitable for use in date calculations.

=cut

has 'dt' => (
    is     => 'ro',
    isa    => 'DateTime',
    writer => '_set_dt',
);

=head2 set

Overrides the set() method provided by the base Metric class. Emits a warning
whenever called, and performs no other actions.

=cut

sub set {
    my ($self) = @_;

    warn "set method incorrectly called on timestamp metric " . $self->name;
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
