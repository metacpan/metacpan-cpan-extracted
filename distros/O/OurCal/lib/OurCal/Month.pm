package OurCal::Month;

use strict;
use Carp qw(confess);
use base qw(OurCal::Span);
use OurCal::Day;
use OurCal::Month;

=head1 NAME

OurCal::Month - a representation of an OurCal::Month

=head1 SYNOPSIS

    my $month = OurCal::Month->new( date => '2007-11');
    

=head1 METHODS

=cut

=head2 prev

Returns the previous month as an object

=cut

sub prev {
    my $self = shift;
    return $self->_shift($self->{_dt}->clone->subtract( months => 1 )->strftime("%Y-%m"));
}


=head2 next

Returns the next month as an object.

=cut

sub next {
    my $self = shift;
    return $self->_shift($self->{_dt}->clone->add( months => 1 )->strftime("%Y-%m"));
}

=head2 as_string

Returns this month as a string

=cut

sub as_string {
    my $self = shift;
    return $self->{_dt}->strftime("%b, %Y");
}


=head2 is_this_span 

Calls C<is_this_month>

=cut

sub is_this_span {
    my $self = shift;
    return $self->is_this_month;
}

=head2 is_this_month

Returns whether this month object is also the current month in the real 
world

=cut

sub is_this_month {
    my $self = shift;
    my $now  = DateTime->now->truncate( to => 'month' );
    return $now == $self->{_dt};
}

=head2 days

Returns an array of all the days in this month as objects.

=cut

sub days {
    my $self = shift;
    my $dt   = $self->{_dt}->clone;

    my @days;
    my $month = $dt->month;
    while ($dt->month == $month) {
        push @days, $self->_span("OurCal::Day", $dt->strftime("%Y-%m-%d")); 
        $dt->add( days => 1);
    }
    return @days;
}

=head2 number_of_weeks

Returns the number of weeks in this month.

=cut

sub number_of_weeks {
    my $self = shift;
    
    # get the last day of the month
    my $dt   = $self->{_dt}->clone;
    my $last = DateTime->last_day_of_month( year => $dt->year, month => $dt->month );

      my $start_of_week = shift || 1;

      # Work out what day the first of the month falls on
      my $first = $dt->clone();
      $first->set(day => 1);
      my $wday  = $first->day_of_week();

      # And adjust the day to the start of the week
      $wday = ($wday - $start_of_week + 7) % 7;

      # Then do the calculation to work out the week
      my $mday  = $last->day_of_month_0();

      return int ( ($mday + $wday) / 7 ) + 1;
}

1;
