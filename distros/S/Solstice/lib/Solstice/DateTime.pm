package Solstice::DateTime;

# $Id: DateTime.pm 3364 2006-05-05 07:18:21Z mcrawfor $

=head1 NAME

Solstice::DateTime - Models a point in time.

=head1 SYNOPSIS

  use Solstice::DateTime;

  my $dt = new Solstice::DateTime(time());
  my $dt = new Solstice::DateTime('2005-03-11 02:34:12');
  my $dt = new Solstice::DateTime('now');

  # These functions return the object
  $date_time->addYears($year_count);
  $date_time->addMonths($month_count);
  $date_time->addDays($day_count);

=head1 DESCRIPTION

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice::Model);

use Date::Calc qw(:all);
use Date::Format;

use constant TRUE    => 1;
use constant FALSE   => 0;
use constant SUCCESS => 1;
use constant FAIL    => 0;

our ($VERSION) = ('$Revision: 3364 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Export 

No symbols exported.

=head2 Methods

=over 4

=cut


=item new([$input])

Constructor.  Returns a DateTime object.

=cut

sub new {
    my $class = shift;
    my $input = shift;
    
    my $self = $class->SUPER::new();

    return $self unless defined $input;

    $self->_init($input);

    return $self;
}

=item setDate($year, $month, $day)

Sets the date

=cut

sub setDate {
    my $self = shift;
    my ($year, $month, $day) = @_;

    $self->_setYear($year);
    $self->_setMonth($month);
    $self->_setDay($day);
    return SUCCESS; 
}    

=item setTime($hour, $min, $sec [, $ampm])

Sets the time

=cut

sub setTime {
    my $self = shift;
    my ($hour, $min, $sec, $ampm) = @_;

    if (defined $ampm and defined $hour and $hour =~ /^\d+$/) {
        $hour += 12 if ($ampm eq 'pm' and $hour > 0 and $hour < 13);
        $hour = 0 if ($ampm eq 'am' and $hour == 12);
    }

    $self->_setHour($hour);
    $self->_setMin($min);
    $self->_setSec($sec);
    return SUCCESS;
}

=item clone()

Returns a duplicate DateTime object.

=cut

sub clone {
    my $self = shift;
    $self->_updateToNow();
    
    my $clone = Solstice::DateTime->new({
        year   => $self->_getYear(),
        month  => $self->_getMonth(),
        day    => $self->_getDay(),
        hour   => $self->_getHour(),
        min    => $self->_getMin(),
        sec    => $self->_getSec(),
        ampm   => 0,
    });
    $clone->setIsNow($self->getIsNow());
    
    return $clone;
}

=item addYears($years)

Add some number of years to the date.

=cut

sub addYears {
    my $self = shift;
    my $years = shift;
    return $self->_addYMD($years, 0, 0);
}

=item addMonths($months)

Add some number of months to the date.

=cut

sub addMonths {
    my $self = shift;
    my $months = shift;
    return $self->_addYMD(0, $months, 0);
}

=item addDays($days)

Add some number of days to the date

=cut

sub addDays {
    my $self = shift;
    my $days = shift;
    return $self->_addYMD(0, 0, $days);
}

=item addHours($hours)

Add some number of hours to the date

=cut

sub addHours {
    my $self = shift;
    my $hours = shift;
    return $self->_addHMS($hours, 0, 0);
}

=item addMinutes($min)

Add some number of min to the date

=cut

sub addMinutes {
    my $self = shift;
    my $min = shift;
    return $self->_addHMS(0, $min, 0);
}

=item addSeconds($sec)

Add some number of seconds to the date

=cut

sub addSeconds {
    my $self = shift;
    my $seconds = shift;
    return $self->_addHMS(0, 0, $seconds);
}

=item getYear()

=cut

sub getYear {
    my $self = shift;
    $self->_updateToNow();
    return $self->_getYear();
}

=item getMonth()
  
=cut 
    
sub getMonth {
    my $self = shift;
    $self->_updateToNow();
    return $self->_getMonth();
}

=item getDay()
       
=cut 
           
sub getDay {
    my $self = shift;
    $self->_updateToNow();
    return $self->_getDay();
}

=item getHour()
     
=cut

sub getHour {
    my $self = shift;
    $self->_updateToNow();
    return $self->_getHour();
}

=item getMin()
      
=cut

sub getMin {
    my $self = shift;
    $self->_updateToNow();
    return $self->_getMin();
}

=item getSec()

=cut

sub getSec {
    my $self = shift;
    $self->_updateToNow();
    return $self->_getSec();
}

=item isValidDate()

Validate the date values as forming a valid date. Date::Calc::check_date
does the heavy work.

=cut

sub isValidDate {
    my $self = shift;
    
    return TRUE if $self->getIsNow();
    
    my $year  = $self->_getYear();
    my $month = $self->_getMonth();
    my $day   = $self->_getDay();

    return FALSE unless (
        defined $year and $year =~ /^\d+$/ and 
        defined $month and $month =~ /^\d+$/ and
        defined $day and $day =~ /^\d+$/
    );
    
    return check_date($year, $month, $day) ? TRUE : FALSE;
}

=item isValidTime()

Validate the time values as forming a valid time. Date::Calc::check_time
does the heavy work.

=cut

sub isValidTime {
    my $self = shift;

    return TRUE if $self->getIsNow();
    
    my $hour = $self->_getHour();
    my $min  = $self->_getMin();
    my $sec  = $self->_getSec();

    return FALSE unless (
        defined $hour and $hour =~ /^\d+$/ and
        defined $min and $min =~ /^\d+$/ and
        defined $sec and $sec =~ /^\d+$/
    );
    
    return check_time($hour, $min, $sec) ? TRUE : FALSE;
}

=item isValid()

Returns a boolean specifying whether the obj datetime is valid 

=cut

sub isValid {
    my $self = shift;
    return ($self->isValidDate() && $self->isValidTime()) ? TRUE : FALSE;
}

=item isEmpty()

Returns a boolean specifying whether the obj contains a datetime

=cut

sub isEmpty {
    my $self = shift;

    return FALSE if $self->getIsNow();
    
    return ($self->_getYear() || $self->_getMonth() || $self->_getDay() || $self->_getHour() || $self->_getMin() || $self->_getSec()) ? FALSE : TRUE;
}

=item isEqualTo($datetime)

Returns a boolean specifying whether the obj datetime is equal to the passed datetime.

=cut

sub isEqualTo {
    my $self = shift;
    my $arg  = shift;

    return FALSE unless $self->isValid();
    return FALSE unless (defined $arg and $arg->isValid());

    $self->_updateToNow();
    $arg->_updateToNow();

    return ($self->getTimeApart($arg)==0) ? TRUE : FALSE;
}

=item isSameDay($datetime)

Returns a boolean specifying whether the obj datetime is the same date to the passed in datetime

=cut

sub isSameDay {
    my $self = shift;
    my $arg = shift;

    return FALSE unless $self->isValid();
    return FALSE unless (defined $arg && $arg->isValid());

    $self->_updateToNow();
    $arg->_updateToNow();

    return ($self->getDaysApart($arg)==0) ? TRUE : FALSE;
}
    
=item isBefore($datetime)

Returns a boolean specifying whether the obj datetime is before the passed datetime.

=cut

sub isBefore {
    my $self = shift;
    my $arg  = shift;

    return undef unless $self->isValid();
    return undef unless (defined $arg and $arg->isValid());

    $self->_updateToNow();
    $arg->_updateToNow();
    my $days1 = Date_to_Days($self->_getYear(), $self->_getMonth(), $self->_getDay());
    my $days2 = Date_to_Days($arg->_getYear(), $arg->_getMonth(), $arg->_getDay());

    return TRUE if ($days1 < $days2);
    return FALSE if ($days1 > $days2);
    return ($self->_getHour() * 3600 + $self->_getMin() * 60 + $self->_getSec()) <
        ($arg->_getHour() * 3600 + $arg->_getMin() * 60 + $arg->_getSec()) ? TRUE : FALSE;
}

=item isBeforeNow()

Returns a boolean specifying whether the obj datetime is before now.

=cut

sub isBeforeNow {
    my $self = shift;
    
    return undef unless $self->isValid();
    return FALSE if $self->getIsNow();

    $self->_updateToNow();
    my ($year, $month, $day, $hour, $min, $sec) = Today_and_Now();

    my $days1 = Date_to_Days($self->_getYear(), $self->_getMonth(), $self->_getDay());
    my $days2 = Date_to_Days($year, $month, $day);

    return TRUE if ($days1 < $days2);
    return FALSE if ($days1 > $days2);
    return ($self->_getHour() * 3600 + $self->_getMin() * 60 + $self->_getSec()) <
        ($hour * 3600 + $min * 60 + $sec) ? TRUE : FALSE;    
}

=item getDaysApart($datetime)

Returns the number of days apart the 2 datetime objects are, as a float.  Returns 0 if either is invalid.

=cut


sub getDaysApart {
    my $self = shift;
    my $date = shift;

    return 0 unless $self->isValidDate();
    return 0 unless $date->isValidDate();

    return Delta_Days($self->getYear(), $self->getMonth(), $self->getDay(), $date->getYear(), $date->getMonth(), $date->getDay());
}

=item getTimeApart($datetime)

Returns the number of seconds apart the 2 datetime objects are.  Returns 0 if either is invalid.

=cut

sub getTimeApart {
    my $self = shift;
    my $date = shift;
    
    return 0 unless $self->isValidDate();
    return 0 unless $date->isValidDate();

    my ($day, $hour, $min, $sec) = 
                    Delta_DHMS($self->getYear(), $self->getMonth(), $self->getDay(),$self->getHour(), $self->getMin(),$self->getSec(), 
                    $date->getYear(), $date->getMonth(), $date->getDay(), $date->getHour(), $date->getMin(), $date->getSec());
    
    return $sec +($min*60)+($hour*3600)+ ($day*24*3600);
}

=item toSQL()
       
Returns an SQL formatted date

=cut

sub toSQL {
    my $self = shift;
    
    return undef unless $self->isValid();

    return $self->toString("%Y-%m-%d %H:%M:%S");
}

=item toISO()
       
Returns an ISO 8601 formatted date

=cut

sub toISO {
    my $self = shift;

    return undef unless $self->isValid();

    return $self->toString("%Y%m%d%H%M%S");
}

=item toCommon()

Returns a human-readable date string

=cut

sub toCommon {
    my $self = shift;

    return undef unless $self->isValid();

    return $self->toString("%L/%d/%Y %l:%M %p");
}

=item toMovingWindow()

Return a formatted string, that displays a moving 3-day window

=cut

sub toMovingWindow {
    my $self = shift;

    return undef unless $self->isValid();

    my $now = time();
    my $day = 60 * 60 * 24;
    my $dateformat = "%L%d%Y";
    my $timeformat = "%l:%M %p";
    
    my $date = $self->toString($dateformat);
    if($self->isBefore(Solstice::DateTime->new($now - $day)) || Solstice::DateTime->new($now + $day)->isBefore($self)){
        return $self->toString("%b %e, %Y %l:%M %p");
    }
    elsif ($date == Solstice::DateTime->new($now)->toString($dateformat)) {
        return $self->toString('Today, '.$timeformat);
    } elsif ($date == Solstice::DateTime->new($now - $day)->toString($dateformat)) {
        return $self->toString('Yesterday, '.$timeformat);
    } elsif ($date == Solstice::DateTime->new($now + $day)->toString($dateformat)) {
        return $self->toString('Tomorrow, '.$timeformat);
    }else {
        return $self->toString("%b %e, %Y %l:%M %p");
    }
}

=item toUnix()
        
Returns a Unix formatted date (epoch seconds)

=cut

sub toUnix {
    my $self = shift;


    # seeing as 3:14:07 a.m. on Jan. 19, 2038 is the limit on 32bit machines for unix timestamps
    # we don't want to be using this method since our model considers dates larger than that valid
    warn "toUnix is deprecated!! DO NOT USE AT ". join(' ', caller());

    return undef unless $self->isValid();

    $self->_updateToNow();
    return Mktime($self->_getYear(), $self->_getMonth(), $self->_getDay(),
        $self->_getHour(), $self->_getMin(), $self->_getSec());
}

=item toString($format)

Returns a formatted datetime string; $format contains a strftime-style
formatting string. Date validity is not implicit. 

=cut

sub toString {
    my $self = shift;
    my $format = shift;
    
    $self->_updateToNow();
    my @date  = ($self->_getSec(), $self->_getMin(), $self->_getHour(),
        $self->_getDay(), ($self->_getMonth() || 1) - 1,
        ($self->_getYear() || 1900) - 1900);
    
    return strftime($format, @date); 
}

=item cmpDate($date)

Takes a date object and compares it to itself.

=cut

sub cmpDate {
    my $self = shift;
    my $date = shift;

    if (!$self->isValidDate()) {
        # I'm invalid, but the other one isn't, it should be ahead of me.
        if ($date->isValidDate()) {
            return 1;
        }
        else {
            # Both are invalid, consider them equivelent.
            return 0;
        }
    }

    # I'm valid, but the other one isn't, i should be ahead of it.
    if (!$date->isValidDate()) {
        return -1;
    }

    my $diff = $self->getTimeApart($date);

    return 0 <=> $diff;
}

# Legacy method
sub isNow {
    my $self = shift;
    return $self->getIsNow();
}

=back

=head2 Private Methods

=over 4

=cut

=item _init($input)

=cut

sub _init {
    my $self = shift;
    my $input = shift;

    my ($year, $month, $day, $hour, $min, $sec, $ampm);

    if ($self->isValidHashRef($input)) {
        # Hashref input
        $year  = $input->{'year'};
        $month = $input->{'month'};
        $day   = $input->{'day'};
        $hour  = $input->{'hour'};
        $min   = $input->{'min'};
        $sec   = $input->{'sec'};
        $ampm  = $input->{'ampm'};
    } elsif ($input =~ /^0000-00-00 00:00:00$/) {
        # MySQL 'zero' date...leave values undef
    } elsif ($input =~ /^(\d\d\d\d)-(\d\d)-(\d\d) (\d\d):(\d\d):(\d\d)$/) {
        # MySQL date...leading zeros are removed
        ($year, $month, $day, $hour, $min, $sec) = ($1, $2+0, $3+0, $4+0, $5+0, $6+0);
    } elsif ($input =~ /^(\d\d\d\d)-(\d\d)-(\d\d)$/) {
        # MySQL date with no time
        ($year, $month, $day, $hour, $min, $sec) = ($1, $2+0, $3+0, 0, 0, 0);
    } elsif ($input =~ /^(\d{1,2})\D(\d{1,2})\D(\d\d\d\d) (\d{1,2}):(\d|[0-5][0-9])([^\d]|$)/){
        # Form input
        ($month, $day, $year, $hour, $min, $sec) = ($1, $2, $3, $4, $5, 0);
    } elsif ($input =~ /^(\d\d\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)$/) {
        # ISO 8601 date
        ($year, $month, $day, $hour, $min, $sec) = ($1, $2, $3, $4, $5, $6);
    }elsif ($input =~ /^\w+\s+(\w+)\s+(\d+)\s+(\d\d):(\d\d):(\d\d)\s*\w*\s+(\d\d\d\d)$/){
        #system date
        ($year, $month, $day, $hour, $min, $sec) = ($6, Decode_Month($1), $2, $3, $4, $5);

    } elsif ($input =~ /^\w+,\s+(\d+)\s+(\w+)\s+(\d{4})\s+(\d\d):(\d\d):(\d\d)\s+\w+$/) {
        ($year, $month, $day, $hour, $min, $sec) = ($3, Decode_Month($2), $1, $4, $5, $6);
    } elsif ($input =~ /^\d+$/) {
        # Unix date
        ($sec, $min, $hour, $day, $month, $year) = localtime($input);
        $year += 1900;
        $month++;
    } elsif ($input eq 'now') {
        # Moving 'now' date
        $self->setIsNow(TRUE);
        return SUCCESS;
    } else {
        return FAIL;
    }
    
    $self->setDate($year, $month, $day);
    $self->setTime($hour, $min, $sec, $ampm);
    $self->setIsNow(FALSE);
    return SUCCESS;
}
    
=item _addYMD($y, $m, $d)

Does the heavy lifting for addDays, addMonths, and addYears.

=cut

sub _addYMD {
    my $self = shift;
    my $y = shift || 0;
    my $m = shift || 0;
    my $d = shift || 0;
    
    return FAIL if $self->isEmpty();

    my ($year, $month, $day) = Add_Delta_YMD($self->_getYear(), $self->_getMonth(), $self->_getDay(), $y, $m, $d);
    
    return $self->setDate($year, $month, $day);
}

sub _addHMS {
    my $self = shift;
    my $h = shift || 0;
    my $m = shift || 0;
    my $s = shift || 0;

    return FAIL if $self->isEmpty();

    my ($year, $month, $day, $hour, $min, $sec) = Add_Delta_DHMS($self->_getYear(), $self->_getMonth(), $self->_getDay(), 
                                            $self->_getHour(), $self->_getMin(), $self->_getSec(),
                                            0,$h,$m,$s);
    return $self->setTime($hour, $min, $sec);
}

=item _updateToNow()

Update the date if the DateTime obj is a 'now' obj

=cut

sub _updateToNow {
    my $self = shift;

    return SUCCESS unless $self->getIsNow();

    my ($sec, $min, $hour, $day, $month, $year) = localtime();

    $self->setDate($year + 1900, $month + 1, $day);
    $self->setTime($hour, $min, $sec);
    
    return SUCCESS;
}

=back

=head2 Private Functions

=over 4

=cut

=item _getAccessorDefinition()

=cut

sub _getAccessorDefinition {
    return [
        {
            name => 'IsNow',
            key  => '_is_now',
            type => 'Boolean',
        },
        {
            name => 'Sec',
            key  => '_sec',
            type => 'Integer',
            private_get => TRUE,
        },
        {
            name => 'Min',
            key  => '_min',
            type => 'Integer',
            private_get => TRUE,
        },
        {
            name => 'Hour',
            key  => '_hour',
            type => 'Integer',
            private_get => TRUE,
        },
        {
            name => 'Day',
            key  => '_day',
            type => 'Integer',
            private_get => TRUE,
        },
        {
            name => 'Month',
            key  => '_month',
            type => 'Integer',
            private_get => TRUE,
        },
        {
            name => 'Year',
            key  => '_year',
            type => 'Integer',
            private_get => TRUE,
        },
    ];
}


1;

__END__

=back

=head2 Modules Used

L<Date::Format|Date::Format>.

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 3364 $



=cut

=head1 COPYRIGHT

Copyright 1998-2007 Office of Learning Technologies, University of Washington

Licensed under the Educational Community License, Version 1.0 (the "License");
you may not use this file except in compliance with the License. You may obtain
a copy of the License at: http://www.opensource.org/licenses/ecl1.php

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied.  See the License for the
specific language governing permissions and limitations under the License.

=cut
