package  Solstice::DateTime::Range;

# $Id: Range.pm 3364 2006-05-05 07:18:21Z mcrawfor $

=head1 NAME

Solstice::DateTime::Range - Represents a range in time.

=head1 SYNOPSIS

  use Solstice::DateTime::Range;

  # initialize:
  
  my $range = new Solstice::DateTime::Range( $start_datetime, $end_datetime );

  my $range = new Solstice::DateTime::Range();
  $range->setStartDateTime( $start_datetime );
  $range->setEndDateTime( $end_datetime );


  # query!

  $range->isValidRange();

  $range->isDateTimeBeforeRange( $other_datetime );
  $range->isDateTimeAfterRange( $other_datetime );
  $range->isDateTimeInRange( $other_datetime );
  $range->isNowInRange();

  $range->getIntervalString();
  $range->toString($format);

=head1 DESCRIPTION

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice::Model);

use Date::Calc qw(:all);
use Date::Format;
use Solstice::DateTime;

use constant TRUE     => 1;
use constant FALSE     => 0;
use constant SUCCESS => 1;
use constant FAIL    => 0;

our ($VERSION) = ('$Revision: 3364 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut

=item new( [ $start, $end ] )

Constructor.  Returns a Solstice::DateTime::Range object.

=cut

sub new {
    my $obj = shift;
    my ($start, $end) = @_;
    
    my $self = $obj->SUPER::new();
    
    if (defined $start and defined $end) {
        $self->setStartDateTime($start);
        $self->setEndDateTime($end);
    } elsif (!defined $start and !defined $end) {
        #it's empty
    } else {
        warn "Improper arguments to Solstice::DateTime::Range, returning an uninitialized range.";
    }

    return $self;
}

=item isValidRange()

Returns true if the start and end times are valid and 
the start time precedes the end

=cut

sub isValidRange {
    my $self = shift;
    
    my $start_date = $self->getStartDateTime();
    my $end_date = $self->getEndDateTime();
    
    return (defined $start_date and defined $end_date and
            $start_date->isValid() and $end_date->isValid() and
            !$end_date->isBefore($start_date)) ? TRUE : FALSE;
}

=item isDateTimeInRange($date)

Returns true if the passed DateTime is within the range

=cut

sub isDateTimeInRange {
    my $self = shift;
    my $date = shift;

    unless (defined $date and $self->isValidDateTime($date)) {
        warn "isDateTimeInRange(): Passed date is invalid";
        return;
    }

    unless ($self->isValidRange()) {
        warn "isDateTimeInRange(): Range is invalid. Called from:" .join(' ', caller);
        return;
    }

    return (!$date->isBefore($self->getStartDateTime()) and
            ($date->isBefore($self->getEndDateTime()) or
            $date->isEqualTo($self->getEndDateTime()))) ? TRUE : FALSE;
}

=item isDateTimeBeforeRange($date)

Returns true if the passed date is before the range

=cut

sub isDateTimeBeforeRange {
    my $self = shift;
    my $date = shift;

    unless (defined $date and $self->isValidDateTime($date)) {
        warn "isDateTimeBeforeRange(): Passed date is invalid";
        return;
    }

    unless ($self->isValidRange()) {
        warn "isDateTimeBeforeRange(): Range is invalid";
        return;
    }

    return $date->isBefore($self->getStartDateTime());
}

=item isDateTimeAfterRange($date)

Returns true if the passed date is after the range

=cut

sub isDateTimeAfterRange {
    my $self = shift;
    my $date = shift;

    unless (defined $date and $self->isValidDateTime($date)) {
        warn "isDateTimeAfterRange(): Passed date is invalid";
        return;
    }

    unless ($self->isValidRange()) {
        warn "isDateTimeAfterRange(): Range is invalid";
        return;
    }

    return (!$date->isBefore($self->getEndDateTime()) and
            !$date->isEqualTo($self->getEndDateTime())) ? TRUE : FALSE;
}

=item isNowInRange()

Returns true if the range encompasses now.

=cut

sub isNowInRange {
    my $self = shift;
    return $self->isDateTimeInRange(Solstice::DateTime->new('now'));
}

=item toString($format)

Returns a formated string of the interval.  The format should be strftime compatible.

=cut

sub toString {
    my $self = shift;
    my $format = shift;

    my ($years, $months, $days, $hours, $min, $sec) = $self->_getDeltaYMDHMS();
    my @date = ($sec, $min, $hours, $days, $months, $years);
    return strftime($format, @date);
}

=item getIntervalString([$display_years])

Returns a formatted string that represents the interval. If passed
$display_years, the returned $str will be formatted as YMDHMS,
otherwise DHMS.

=cut

sub getIntervalString {
    my $self = shift;
    my $display_years = shift || 0;
    
    my ($years, $months, $days, $hours, $min, $sec);
    if ($display_years) {
        ($years, $months, $days, $hours, $min, $sec) = $self->_getDeltaYMDHMS();
    } else {
        ($days, $hours, $min, $sec) = $self->_getDeltaDHMS();
    }
        
    my $str = '';
    if ($years) {
        $str .= $years.' year'.(abs($years) > 1 ? 's' : '').', ';
    }
    if ($months) {
        $str .= $months.' month'.(abs($months) > 1 ? 's' : '').', ';
    }
    if ($days) {
        $str .= $days.' day'.(abs($days) > 1 ? 's' : '').', ';
    }
    if ($hours) {
        $str .= $hours.' hour'.(abs($hours) > 1 ? 's' : '').', ';
    }
    if ($min) {
        $str .= $min.' minute'.(abs($min) > 1 ? 's' : '').', ';
    }
    if ($sec) {
        $str .= $sec.' second'.(abs($sec) > 1 ? 's' : '').', ';
    }
    $str =~ s/, $//;
    
    return $str;
}

=back

=head2 Private Methods

=over 4

=cut 

sub _getDeltaDHMS {
    my $self = shift;

    return () unless $self->isValidRange();

    my $start_date = $self->getStartDateTime();
    my $end_date = $self->getEndDateTime();
        
    return Delta_DHMS(
        $start_date->getYear(),
        $start_date->getMonth(),
        $start_date->getDay(),
        $start_date->getHour(),
        $start_date->getMin(),
        $start_date->getSec(),
        $end_date->getYear(),
        $end_date->getMonth(),
        $end_date->getDay(),
        $end_date->getHour(),
        $end_date->getMin(),
        $end_date->getSec(),
    );
}

sub _getDeltaYMDHMS {
    my $self = shift;

    return () unless $self->isValidRange();

    my $start_date = $self->getStartDateTime();
    my $end_date = $self->getEndDateTime();

    return Delta_YMDHMS(
        $start_date->getYear(),
        $start_date->getMonth(),
        $start_date->getDay(),
        $start_date->getHour(),
        $start_date->getMin(),
        $start_date->getSec(),
        $end_date->getYear(),
        $end_date->getMonth(),
        $end_date->getDay(),
        $end_date->getHour(),
        $end_date->getMin(),
        $end_date->getSec(),
    );
}

=item _getAccessorDefinition()

=cut

sub _getAccessorDefinition {
    return [
        {
            name => 'StartDateTime',
            key  => '_start_date',
            type => 'DateTime',
        },
        {
            name => 'EndDateTime',
            key  => '_end_date',
            type => 'DateTime',
        },
    ];
}
             
1;

__END__

=back

=head2 Modules Used

L<Solstice::DateTime|Solstice::DateTime>,
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
