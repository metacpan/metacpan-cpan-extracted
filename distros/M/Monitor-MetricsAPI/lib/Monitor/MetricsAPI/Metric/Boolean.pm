use strict;
use warnings;

package Monitor::MetricsAPI::Metric::Boolean;
$Monitor::MetricsAPI::Metric::Boolean::VERSION = '0.900';
use namespace::autoclean;
use Moose;

extends 'Monitor::MetricsAPI::Metric';

=head1 NAME

Monitor::MetricsAPI::Metric::Boolean - Boolean metric class for Monitor::MetricsAPI

=head1 SYNOPSIS

    use Monitor::MetricsAPI;

    my $collector = Monitor::MetricsAPI->new(
        metrics => { protocols => { ssl { enabled => 'boolean' } } }
    );

    # Later on, when your app validates its config and turns on SSL:
    $collector->metric('protocols/ssl/enabled')->true;

=head1 DESCRIPTION

Boolean metrics allow you to track the true/false/unknown state of something
in your application. All boolean metrics are initialized as unknown and must
be explicitly set to either true or false.

=cut

=head1 METHODS

Boolean metrics disable the set() method from L<Monitor::MetricsAPI::Metric>
(a warn() is emitted and no action is taken), and provide only the following
methods for manipulating their values.

=head2 true

Sets the metric to true.

=cut

sub true {
    my ($self) = @_;

    return $self->_set_value(1);
}

=head2 false

Sets the metric to false.

=cut

sub false {
    my ($self) = @_;

    return $self->_set_value(0);
}

=head2 unknown

Sets the metric to unknown (will emit a blank value in reporting output).

=cut

sub unknown {
    my ($self) = @_;

    return $self->_clear_value;
}

=head2 set

Overrides the set() method provided by the base Metric class. Emits a warning
whenever called, and performs no other actions.

=cut

sub set {
    my ($self) = @_;

    warn "set method incorrectly called on boolean metric " . $self->name;
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
