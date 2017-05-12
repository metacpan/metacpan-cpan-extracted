use strict;
use warnings;

package Monitor::MetricsAPI::Metric::Callback;
$Monitor::MetricsAPI::Metric::Callback::VERSION = '0.900';
use namespace::autoclean;
use Moose;
use Try::Tiny;

extends 'Monitor::MetricsAPI::Metric';

=head1 NAME

Monitor::MetricsAPI::Metric::Callback - Callback metric class for Monitor::MetricsAPI

=head1 SYNOPSIS

    use Monitor::MetricsAPI;
    use DateTime;

    # Put into scope first so we can capture it as part of the callback sub.
    my $collector;
    $collector = Monitor::MetricsAPI->new(
        metrics => {
            process  => {
                started => 'timestamp'
            },
            messages => {
                incoming => {
                    total   => 'counter',
                    per_min => sub {
                        $collector->metric('messages/incoming/total')->value
                        /
                        DateTime->now()->delta_ms(
                            $collector->metric('process/started')->dt
                        )->in_units('minutes')
                    },
                }
            }
        }
    );

    $collector->metric('process/started')->now;

=head1 DESCRIPTION

Boolean metrics allow you to track the true/false/unknown state of something
in your application. All boolean metrics are initialized as unknown and must
be explicitly set to either true or false.

=cut

has 'cb' => (
    is        => 'ro',
    isa       => 'CodeRef',
    predicate => '_has_cb',
    writer    => '_set_cb',
);

=head1 METHODS

Callback metrics do not provide any additional methods not already offered by
L<Monitor::MetricsAPI::Metric>. You may call the set() method at any time to
updated the callback function that will be used when the metric is displayed.

=cut

=head2 callback (sub { ... })

Allows you to provide a new subroutine to be invoked for the callback metric.

=cut

sub callback {
    my ($self, $sub) = @_;

    unless (defined $sub && ref($sub) eq 'CODE') {
        warn "must provide subroutine for callback";
        return;
    }

    return $self->_set_cb($sub);
}

=head2 value

Overrides the value() method provided by the base Metric class. Invoking this
method will run the callback subroutine. For expensive callbacks, you are very
strongly advised to consider incorporating some reasonable caching mechanism
so that unnecessary computations can be avoided during metrics reporting.

=cut

sub value {
    my ($self) = @_;

    my $v;

    try {
        $v = &{$self->cb};
    } catch {
        warn "could not invoke callback metric's subroutine";
    };

    return $v;
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
