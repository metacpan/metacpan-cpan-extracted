use strict;
use warnings;

package Monitor::MetricsAPI::Metric::List;
$Monitor::MetricsAPI::Metric::List::VERSION = '0.900';
use namespace::autoclean;
use Moose;

extends 'Monitor::MetricsAPI::Metric';

=head1 NAME

Monitor::MetricsAPI::Metric::List - List metric class for Monitor::MetricsAPI

=head1 SYNOPSIS

    use Monitor::MetricsAPI;

    my $collector = Monitor::MetricsAPI->new(
        metrics => { messages => { processing_times => 'list' } }
    );

    $collector->metric('messages/processing_times')->limit(1_000);

    # Later on while processing an incoming message...
    use Time::HiRes qw( gettimeofday, tv_interval );

    my $t_start = [gettimeofday];
    # ... do a bunch of work ...
    my $t_end = [gettimeofday];

    $collector->metric('messages/processing_times')->push(
        tv_interval($t_start, $t_end)
    );

=head1 DESCRIPTION

List metrics allow you to track multiple related values inside of a single
metric, and to set limits on the number of values which will be stored at any
given time. As more values are added, the oldest ones are evacuated to keep the
list contents (and conequently, memory usage) fixed.

It may not be terribly useful to have your monitoring system looking at list
metrics directly, but they provide a very useful base for constructing derived
metrics by defining companion callback metrics that perform a computation on
the list metric's values.

For instance, in the example above we track the most recent 1,000 response
times for messages our application processes. A companion callback metric might
be defined to compute the average of those values, thus giving us a single
metric that can be retrieved easily showing a rolling average of our
application's performance on a particular task.

    use List::Util qw( sum0 );

    $collector->add_metric('messages/processing_times_average', 'callback',
        sub {
            sum0(@{$collector->metric('messages/processing_times')->value})
            /
            scalar(@{$collector->metric('messages/processing_times')->value})
        }
    );

=head1 METHODS

String metrics do not provide any additional methods beyond the base methods
offered by L<Monitor::MetricsAPI::Metric>.

=cut

has '+_value' => (
    isa     => 'ArrayRef',
    default => sub { [] },
);

=head2 limit

Sets or returns the current limit on the number of items in the list metric. A
negative or undefined value indicates that there is no limit to the number of
elements. This is generally inadvisable due to memory consumption.

When a limit is set, items at the tail of the list will be dropped to make room
for new entries as necessary.

=cut

has 'limit' => (
    is        => 'rw',
    isa       => 'Int',
    predicate => 'has_limit',
    clearer   => 'clear_limit',
    trigger   => \&_limit_change,
);

=head2 has_limit

Returns a true value if the metric has a limit set, otherwise false.

=head2 clear_limit

Removes list element limit from the metric if one has been set.

=cut

sub _limit_change {
    my ($self, $limit, $old_limit) = @_;

    if (defined $limit && $limit < 0) {
        return $self->clear_limit;
    }

    if (defined $limit && $limit < $self->size) {
        my $drop = $self->size - $limit;
        $self->_set_value([@{$self->_value}[$drop..($self->size -1)]]);
    }
}

=head2 push ( @values )

Adds a new entry to the list metric. If a limit is set on the metric, this
method will have the side effect of dropping the oldest entry, or entries if
you push multiple values, to make room for the new ones.

    $collector->metric('messages/processing_times')->push($duration);

=cut

sub push {
    my ($self, @values) = @_;

    return unless @values;

    if ($self->has_limit && $self->size + scalar(@values) > $self->limit) {
        my $drop = ($self->size + scalar(@values)) - $self->limit;

        $self->_set_value([@{$self->_value}[$drop..($self->size -1)], @values]);
    } else {
        push(@{$self->_value}, @values);
    }
}

=head2 size

Returns the number of elements currently stored in the list metric.

=cut

sub size {
    my ($self) = @_;

    return scalar @{$self->_value};
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
