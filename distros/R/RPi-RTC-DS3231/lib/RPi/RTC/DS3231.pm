package RPi::RTC::DS3231;

use strict;
use warnings;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('RPi::RTC::DS3231', $VERSION);

use Carp qw(croak);

use constant DS3231_ADDR => 0x68;

sub new {
    my ($class, $rtc_addr) = @_;

    $rtc_addr = DS3231_ADDR if ! defined $rtc_addr;

    my $self = bless {}, $class;
    $self->_fd($rtc_addr);
    return $self;
}

# misc methods

sub temp {
    my ($self, $output) = @_;
    my $celcius =  getTemp($self->_fd);
    return defined $output && $output eq 'f' ? $celcius * 9/5 + 32 : $celcius;
}

# time/date methods

sub year {
    my ($self, $year) = @_;
    if (defined $year){
        setYear($self->_fd, $year);
    }
    return getYear($self->_fd);
}
sub month {
    my ($self, $month) = @_;
    if (defined $month){
        setMonth($self->_fd, $month);
    }
    return getMonth($self->_fd);
}
sub mday {
    my ($self, $mday) = @_;
    if (defined $mday){
        setDayOfMonth($self->_fd, $mday);
    }
    return getDayOfMonth($self->_fd);
}
sub day {
    my ($self, $wday) = @_;
    if (defined $wday){
        setDayOfWeek($self->_fd, $wday);
    }
    return getDayOfWeek($self->_fd);
}
sub hour {
    my ($self, $hour) = @_;
    if (defined $hour){
        setHour($self->_fd, $hour);
    }

    return getHour($self->_fd);
}
sub min {
    my ($self, $min) = @_;
    if (defined $min){
        setMinutes($self->_fd, $min);
    }
    return getMinutes($self->_fd);
}
sub sec {
    my ($self, $sec) = @_;
    if (defined $sec){
        setSeconds($self->_fd, $sec);
    }
    return getSeconds($self->_fd);
}

# auxillary time/date methods

sub am_pm {
    my ($self, $meridien) = @_;

    if (defined $meridien) {
        if ($meridien ne 'AM' && $meridien ne 'PM'){
            croak("am_pm() requires either 'AM' or 'PM' as a param\n");
        }
        if ($meridien eq 'AM') {
            $meridien = 0;
        }
        else {
            $meridien = 1;
        }
        setMeridien($self->_fd, $meridien);
    }
    return getMeridien($self->_fd) ? 'PM' : 'AM';
}
sub clock_hours {
    my ($self, $value) = @_;
    if (defined $value){
        if ($value !~ /\d+/ || ($value != 12 && $value != 24)){
            croak "clock_hours() requires either 12 or 24 as a parameter\n";
        }
        $value = $value == 12 ? 1 : 0;
        setMilitary($self->_fd, $value);
    }
    return getMilitary($self->_fd) ? 12 : 24;
}
sub hms {
    my ($self) = @_;

    my $h = _stringify(getHour($self->_fd));
    my $m = _stringify(getMinutes($self->_fd));
    my $s = _stringify(getSeconds($self->_fd));

    my $hms = "$h:$m:$s";

    $hms = "$hms " . $self->am_pm if $self->clock_hours == 12;

    return $hms;
}
sub date_time {
    my ($self, $datetime) = @_;

    if (defined $datetime){
        my @dt;

        if (@dt =
            $datetime =~ /(\d{4})-(\d{2})-(\d{2})\s+(\d{2}):(\d{2}):(\d{2})/)
        {
            my $ch = $self->clock_hours;

            $self->clock_hours(24) if $ch == 12;

            $self->year($dt[0]);
            $self->month($dt[1]);
            $self->mday($dt[2]);

            $self->hour($dt[3]);
            $self->min($dt[4]);
            $self->sec($dt[5]);

            $self->clock_hours(12) if $ch == 12;
        }
        else {
            croak(
                "datetime parameter must be in the format " .
                "'yyyy-mm-dd hh:mm:ss'. You supplied '$datetime'\n"
            );
        }
    }
    my $y = getYear($self->_fd);
    my $mon = _stringify(getMonth($self->_fd));
    my $day = _stringify(getDayOfMonth($self->_fd));

    my $h;

    if ($self->clock_hours == 12){
        $self->clock_hours(24);
        $h = _stringify(getHour($self->_fd));
        $self->clock_hours(12);
    }
    else {
        $h = _stringify(getHour($self->_fd));
    }

    my $m = _stringify(getMinutes($self->_fd));
    my $s = _stringify(getSeconds($self->_fd));

    return "$y-$mon-$day $h:$m:$s";
}
sub dt_hash {
    my ($self) = @_;

    my %dt;

    $dt{year} = getYear($self->_fd);
    $dt{month} = _stringify(getMonth($self->_fd));
    $dt{day} = _stringify(getDayOfMonth($self->_fd));

    if ($self->clock_hours == 12){
        $self->clock_hours(24);
        $dt{hour} = _stringify(getHour($self->_fd));
        $self->clock_hours(12);
    }
    else {
        $dt{hour} = _stringify(getHour($self->_fd));
    }

    $dt{minute} = _stringify(getMinutes($self->_fd));
    $dt{second} = _stringify(getSeconds($self->_fd));

    return %dt;
}

# operation methods

sub close {
    my ($self) = @_;
    _close($self->_fd);
}

# internal methods

sub _get_register {
    # retrieve the contents of an entire 8-bit register
    my ($self, $reg) = @_;
    return getRegister($self->_fd, $reg);
}
sub _fd {
    # initializes the I2C communications
    my ($self, $rtc_addr) = @_;

    if (! exists $self->{fd}){
        $self->{fd} = getFh($rtc_addr);
    }
    return $self->{fd};
}
sub _stringify {
    # left-pads with a zero any integer with only a single digit
    my ($int) = @_;

    if (! defined $int || $int !~ /\d+/){
        croak "as_string() requires an integer to check/convert to str\n";
    }

    return length($int) < 2 ? "0$int" : $int;
}

sub __vim {};

1;
__END__

=head1 NAME

RPi::RTC::DS3231 - Interface to the DS3231 Real-Time Clock IC over I2C

=head1 SYNOPSIS

    use RPi::RTC::DS3231;

    my $rtc = RPi::RTC::DS3231->new;

    # set individual

    $rtc->month(12);
    $rtc->hour(3);
    $rt->sec(33);
    # ...etc

    # set date/time in one swoop

    $rtc->date_time('2018-05-28 23:15:17');

    # get individual

    my $h = $rtc->hour;
    my $d = $rtc->mday;
    # ...etc

    # get date/time as a string in one swoop

    my $datetime = $rtc->date_time; # "yyyy-mm-dd hh:mm:ss"

    # get/set 24 or 12 hour clock

    my $ch = $rtc->clock_hours;
    $rtc->clock_hours(24); # or 12

    # get/set AM/PM

    my $meridien = $rtc->am_pm;

    $rtc->am_pm('AM'); # or 'PM' # only available in 24 hr clock mode

    # get temperature

    my $c = $rtc->temp;
    my $f = $rtc->temp('f');

    # get a hash ready for use in DateTime->new()
    # must have DateTime installed!

    my $dt = DateTime->new($rtc->dt_hash);

=head1 DESCRIPTION

XS-based interface to the DS3231 Real-Time Clock Integrated Circuit over I2C.
Although packaged under the C<RPi::> umbrella, the distribution will work on
any Linux system with I2C installed and operable.

This distribution *should* work with the DS1307 modules as well, but I do not
have one to test with.

=head1 METHODS

=head1 Operational Methods

=head2 new([$i2c_addr])

Instantiates and returns a new L<RPi::RTC::DS3231> object.

Parameters:

    $i2c_addr

Optional, Integer: The I2C address of the RTC module. Defaults to C<0x68> for
a DS3231 RTC unit.

Return: An L<RPi::RTC::DS3231> object.

=head2 close

Closes the active I2C (C<ioctl>) file descriptor. Should be called at the end
of your script.

Takes no parameters, has no return.

=head1 Individual time/date methods

=head2 year([$year])

Sets/gets the RTC year.

Parameters:

    $year

Optional, Integer: A year between C<2000> and C<2099>. If set, we'll update the
RTC.

Return: Integer, the year currently stored in the RTC.

=head2 month([$month])

Sets/gets the RTC month.

Parameters:

    $month

Optional, Integer: A month between C<1> and C<12>. If set, we'll update the RTC.

Return: String/Integer, the month currently stored in the RTC, between C<1> and
C<12>. Single digits will be left-padded with a zero within a string.

=head2 mday([$mday])

Sets/gets the RTC day of the month.

Parameters:

    $mday

Optional, Integer: A day between C<1> and C<31>. If set, we'll update the RTC.

Return: String/Integer, the day currently stored in the RTC, between C<1> and
C<31>. Single digits will be left-padded with a zero within a string.

=head2 day([$day])

Sets/gets the RTC weekday.

Parameters:

    $day

Optional, Integer: A weekday between C<1> and C<7> (correlates to C<Monday> to
C<Sunday> respectively). If set, we'll update the RTC.

Return: String, the weekday currently stored in the RTC, as C<Monday> to
C<Sunday>.

=head2 hour([$hour])

Sets/gets the RTC hour.

Parameters:

    $hour

Optional, Integer: An hour between C<0> and C<23>. If set, we'll update the RTC.

Return: String/Integer, the hour currently stored in the RTC, between C<0> and
C<23>. Single digits will be left-padded with a zero within a string.

NOTE: If you're in 24-hour clock mode (L</clock_hours>), valid values are C<0>
through C<23>. If in 12-hour clock mode, valid values are C<1> through C<12>.

=head2 min([$min])

Sets/gets the RTC minute.

Parameters:

    $min

Optional, Integer: A minute between C<0> and C<59>. If set, we'll update the
RTC.

Return: String/Integer, the minute currently stored in the RTC, between C<0> and
C<59>. Single digits will be left-padded with a zero within a string.

=head2 sec([$sec])

Sets/gets the RTC second.

Parameters:

    $sec

Optional, Integer: A second between C<0> and C<59>. If set, we'll update the
RTC.

Return: String/Integer, the second currently stored in the RTC, between C<0> and
C<59>. Single digits will be left-padded with a zero within a string.

=head1 Auxillary date/time methods

=head2 am_pm ([$meridien])

Sets/gets the time meridien (AM/PM) when in 12-hour clock mode. This method will
C<croak()> if called while in 24-hour clock format.

Parameters:

   $meridien

Optional, String: Set by sending in either C<AM> for morning hours, or C<PM> for
latter hours.

Return: String: Returns either C<AM> or C<PM>.

=head2 clock_hours([$format])

Sets/gets the current clock format as either 12-hour or 24-hour format. By
default, the RTC is set to 24-hour clock format.

Parameters:

    $format

Optional, Integer: Send in C<24> for 24-hour (aka. Military) clock format, or
C<12> for 12-hour clock format.

Return: Integer: The current format as either C<24> or C<12>.

=head2 hms

Returns the current hours, minutes and seconds as a string in the following
format:

    'HH:MM:SS'

If in 12-hour clock mode, we will append either C<AM> or C<PM> to the string as
such:

    'HH:MM:SS AM'

=head2 date_time([$datetime])

Sets gets the date/time in one single operation.

Parameters:

    $datetime

Optional, String: The date and time you want to set the RTC to, in the format:

    'YYYY-MM-DD HH:MM:SS'

Note that the hours must reflect 24-hour clock format, so for example, if you
want to set 11 PM, use C<23> for the hours field.

Return: String: The date and time in the format C<YYYY-MM-DD HH:MM:SS>.

=head2 dt_hash

This is a convenience method that returns the date and time in hash format,
ready to be used by L<DateTime>'s C<new()> method.

Return: Hash: The format of the hash is as follows:

      'minute' => 20,
      'hour' => '02',
      'year' => 2000,
      'second' => '07',
      'day' => 18,
      'month' => '05'

Example L<DateTime> usage:

    my $dt = DateTime->new($rtc->dt_hash);

=head1 Miscellaneous methods

=head2 temp([$degrees])

The DS3231 has a built-in thermometer which you can leverage to get the current
temperature. By default, we return the temperature in celcius. Send in C<'f'>
to get the temperature in farenheit instead.

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2018 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>
