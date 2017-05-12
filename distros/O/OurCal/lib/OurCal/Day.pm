package OurCal::Day;

use strict;
use OurCal::Event;
use Lingua::EN::Numbers::Ordinate;
use base qw(OurCal::Span);


=head1 NAME

OurCal::Day - a representation of a day in OurCal


=head1 SYNOPSIS

    my $day = OurCal::Day->new( date => "2007-11-12");

=cut

=head1 METHODS

=cut

=head2 day_of_week

What day of the week it is (Monday is 1, Sunday is 7)

=cut

sub day_of_week {
    my $self = shift;
    return $self->{_dt}->strftime("%u");
}

=head2 day_of_month

What day of the month it is

=cut

sub day_of_month {
    my $self = shift;
    return $self->{_dt}->strftime("%d");
}

=head2 is_first_day_of_month

IS this the first day of the month

=cut

sub is_first_day_of_month {
    my $self = shift;
    # TODO did I do this for a clever reason or can I not just check 
    # that day_of_month == 1
    return $self->{_dt}->month != 
           $self->{_dt}->clone->subtract( days => 1)->month;
}

=head2 is_last_day_of_month

Is this the last day of the month.

=cut

sub is_last_day_of_month {
    my $self = shift;
    return $self->{_dt}->month != 
           $self->{_dt}->clone->add( days => 1)->month;
}

=head2 is_this_span

Calls C<is_today>

=cut

sub is_this_span {
    my $self = shift;
    return $self->is_today;
}

=head2 is_today

Returns whether or not this is today in the real world.

=cut

sub is_today {
    my $self = shift;
    my $now  = DateTime->now->truncate( to => 'day' );
    return $now == $self->{_dt};
}

=head2 month

Returns the month object this belongs to.

=cut

sub month {
    my $self = shift;
    my $date = $self->{_dt}->clone->truncate( to => 'month')->strftime("%Y-%m");
    return $self->_span("OurCal::Month", $date);
}

=head2 has_events

Returns whether this day has events.

=cut

sub has_events {
    my $self = shift;
    my $cal  = $self->calendar;
    return $cal->has_events( date => $self->date );
}

=head2 events

Returns the events for this day.

=cut

sub events {
    my $self = shift;
    my $cal  = $self->calendar;
    return $cal->events( date => $self->date );
}
   

=head2 as_string

Returns this day as a string

=cut

sub as_string {
    my $self = shift;
    my $day = ordinate($self->{_dt}->day());
    return $self->{_dt}->strftime("%d/%m");
}


=head2 as_long_string

Returns the day as a long, wordy, almost, dare I say it, verbose string.

=cut

sub as_long_string {
    my $self = shift;
    my $day = ordinate($self->{_dt}->day());
    return $self->{_dt}->strftime("%A the $day of %B, %Y");
}

=head2 prev

Returns the previous day.

=cut

sub prev {
    my $self = shift;
    return $self->_shift($self->{_dt}->clone->subtract( days => 1 )->strftime("%Y-%m-%d"));
}

=head2 next

Returns the next day

=cut

sub next {
    my $self = shift;
    return $self->_shift($self->{_dt}->clone->add( days => 1 )->strftime("%Y-%m-%d"));
}

1;
