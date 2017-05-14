package Myco::Util::DateTime;

###############################################################################
# $Id: DateTime.pm,v 1.4 2006/02/27 22:55:55 sommerb Exp $
#
# See license and copyright near the end of this file.
###############################################################################

=head1 NAME

Myco::Util::DateTime - a Myco utility class

=head1 SYNOPSIS

  use Myco::Util::DateTime;

  # No constructor is offered here - just use the class methods offered,
  # but if this helps you...

  my $datetime = 'Myco::Util::DateTime';

  print "April Fools!" if $datetime->date('YYYY-MM-DD') eq '2006-04-01';

  # Lot's of other neat methods - see below.


=head1 DESCRIPTION

A simple shell to store oft-used Date-munging routines.

=cut

##############################################################################
# Dependencies
##############################################################################
# Module Dependencies and Compiler Pragma
use warnings;
use strict;
use Myco::Exceptions;

##############################################################################
# Programatic Dependencies
use Date::Calc qw( Today Now Delta_Days Add_Delta_Days Add_Delta_Days
                   Date_to_Text Month_to_Text English_Ordinal );
##############################################################################
# Constants
##############################################################################


##############################################################################
# Inheritance & Introspection
##############################################################################
# None

##############################################################################
# Function and Closure Prototypes
##############################################################################


##############################################################################
# Methods
##############################################################################

=head1 CLASS METHODS

=head2 date

  $datetime->date('YYYY-MM-DD');

Get the current date, in several formats: YYYY-MM-DD, YY-MM-DD, MM-DD-YYYY,
MM-DD-YY.

=cut

sub date {
    my $self = shift;
    my $format = shift;

    my ($y, $mo, $d) = scalar @_ == 3 ? @_ : Today();
    my ($h, $mi, $s) = Now;
    for ($mo, $d, $h, $mi, $s) {
        $_ = "0$_" if length $_ == 1;
    }

    my $valid_formats = { 'YYYY-MM-DD' => "$y-$mo-$d",
			  'YYYY-MM-DDThh:mm:ss' => "$y-$mo-$d"."T".
			                           "$h:$mi:$s",
			  'YYYY-MM-DDhh:mm:ss' => "$y-$mo-$d".
			                          "$h:$mo:$s",
                          'YY-MM-DD' => substr($y, 2, 2)."-$mo-$d",
                          'MM-DD-YYYY' => "$mo-$d-$y",
                          'MM-DD-YY' => "$mo-$d-".substr($y, 2, 2), };


    return $valid_formats->{$format}|| Myco::Exception::DataProcessing->throw
      (error =>  "$format is not a valid date format");
}


=head2 year

  my $year = $datetime->year;

Get the current year.

=cut

sub year {
    my ($y, $m, $d) = scalar @_ == 3 ? @_ : Today();
    return $y;
}


=head2 month

  my $month = $datetime->month;

Get the current Month.

=cut

sub month {
    my ($y, $m, $d) = scalar @_ == 3 ? @_ : Today();
    return $y;
}



=head2 day

  my $day = $datetime->day;

Get the current day of the month.

=cut

sub day {
    my ($y, $m, $d) = scalar @_ == 3 ? @_ : Today();
    return $y;
}


=head2 date_add

  $datetime->date_add($offset, $date1);

Adds an integer (positive or negative) offset to a given date. If no date is
given, then the current date is used.

=cut

sub date_add {
    my $self = shift;
    my $offset = shift;
    my $today = shift;
    my @today = $today ? split(/-/, $today) : Today();

    return __PACKAGE__->date('YYYY-MM-DD', Add_Delta_Days( @today, $offset) );
}


=head2 date_range

  my @range = $datetime->date_range('2002-06-01', '2003-06-01');
    or
  my @range = $datetime->date_range(-365, '2003-06-01');
    or
  my @range = $datetime->date_range(-365);

Returns the range of dates between two given dates (including both).
Alternatively, adds an integer (positive or negative) offset to a given date
and returns an array of dates for each intervening day. Starts with the most
recent, and descends or ascends from there. If no date is given, the current
date is used.

=cut

sub date_range {
    my ($self, $offset, $from) = @_;
    my (@start, @stop);
    if ($offset < 0) {
        @stop = $from ? split(/-/, $from) : Today();
        @start = split /-/, $self->date_add($offset);
    } else {
        @start = $from ? split(/-/, $from) : Today();
        @stop = split /-/, $self->date_add($offset);
    }

    my $j = Delta_Days(@start, @stop);
    my @dates;
    for ( my $i = 0; $i <= $j; $i++ ) {
        my ($y, $m, $d) = Add_Delta_Days(@start, $i);
        # make sure month and day are zero-filled
        $_ = length $_ == 1 ? "0$_" : $_ for $m, $d;
        push @dates, "$y-$m-$d";
    }
    return $offset < 0 ? reverse @dates : @dates;
}

=head2 american

  my @american_dates = $datetime->american( @dates );
  my $isa_american_date = $american_dates[0] eq 'June 16th, 2003';

Translates ISO-format dates into an American-style dates.

=cut

sub american {
    shift;
    map { sprintf( "%s %s, %d",
                   Month_to_Text( $_->[1] ),
                   English_Ordinal( $_->[2] ),
                   $_->[0] ) } map { [split '-', $_] } @_;
}

1;
__END__
