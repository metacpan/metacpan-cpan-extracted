package Solstice::View::FormInput::DateTime;

# $Id: DateTime.pm 3155 2006-02-21 20:08:18Z mcrawfor $

=head1 NAME

Solstice::View::FormInput::DateTime - A view of a Solstice DateTime obj, showing a selection widget.

=head1 SYNOPSIS

  use Solstice::View::FormInput::DateTime;

=head1 DESCRIPTION

This is a view of Solstice::DateTime.

=cut

use strict;
use warnings;
use 5.006_000;

use base qw(Solstice::View::FormInput);

use Solstice::StringLibrary qw(unrender);

use constant TRUE  => 1;
use constant FALSE => 0;

use constant HOURS => (qw|0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23|);
use constant MINUTES => (qw|00 15 30 45|);

our $template = 'form_input/datetime.html';

our ($VERSION) = ('$Revision: 3155 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Superclass

L<Solstice::View::FormInput|Solstice::View::FormInput>

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->_setTemplatePath('templates');

    return $self;
}

=item setFormat($format)

Sets a strftime-style formatting string.

=cut

sub setFormat {
    my $self = shift;
    $self->{'_format'} = shift;
}

=item getFormat()

=cut

sub getFormat {
    my $self = shift;
    return $self->{'_format'};
}

=item setDisplayTime($bool)

=cut

sub setDisplayTime {
    my $self = shift;
    $self->{'_display_time'} = shift;
}

=item getDisplayTime()

=cut

sub getDisplayTime {
    my $self = shift;
    return $self->{'_display_time'};
}

=item setReadOnlyTime($bool)

=cut

sub setReadOnlyTime {
    my $self = shift;
    $self->{'_readonly_time'} = shift;
}

=item getReadOnlyTime()

=cut

sub getReadOnlyTime {
    my $self = shift;
    return $self->{'_readonly_time'};
}

=item setStartYear($int)

Set the beginning year for the editor, in the form YYYY.

=cut

sub setStartYear {
    my $self = shift;
    $self->{'_start_year'} = shift;
}

=item getStartYear()

=cut

sub getStartYear {
    my $self = shift;
    return $self->{'_start_year'};
}

=item setStartDate(DateTime)

Set the beginning date for the editor, in the form of a solstice::datetime object.

=cut

sub setStartDate {      
    my $self = shift;
    $self->{'_start_date'} = shift;
}   

=item getStartDate()

=cut
    
sub getStartDate {
    my $self = shift;
    return $self->{'_start_date'};
}


=item setYearCount($int)

Set the year count for the editor. This is
an integer that will be added to the start year

=cut

sub setYearCount {
    my $self = shift;
    $self->{'_year_count'} = shift;
}

=item getYearCount()

=cut

sub getYearCount {
    my $self = shift;
    return $self->{'_year_count'};
}

=item setHours(\@array)

=cut

sub setHours {
    my $self = shift;
    $self->{'_hours'} = shift;
}

=item getHours()

=cut

sub getHours {
    my $self = shift;
    return $self->{'_hours'} || HOURS;
}

=item setMinutes(\@array)

=cut

sub setMinutes {
    my $self = shift;
    $self->{'_minutes'} = shift;
}

=item getMinutes()

=cut

sub getMinutes {
    my $self = shift;
    return $self->{'_minutes'} || MINUTES;
}

=item addClientAction($str)

=cut

sub addClientAction {
    my $self = shift;
    my $str = shift;
    return unless defined $str;

    # strip off trailing semicolons on incoming events
    $str =~ s/;+$//g;

    my $client_actions = $self->{'_client_actions'} || [];
    push @$client_actions, $str;
    $self->{'_client_actions'} = $client_actions;
}

*setClientAction = *addClientAction;

=item getClientActions()

=cut

sub getClientActions {
    my $self = shift;
    return $self->{'_client_actions'} || [];
}

=item generateParams()

=cut
             
sub generateParams {
    my $self = shift;

    my $datetime = $self->getModel();
    my $name     = $self->getName();    
    my $format   = $self->getFormat() || "%m/%d/%Y";
    
    if (my $error = $self->getError()) {
        if($self->getShowErrors()){
            $self->setParam('err_date_name', $error->getFormMessages()->{'err_'.$name.'_date'});
        }
    }

    if ($self->getDisplayTime()) {
        $self->setParam('display_time', TRUE);
        $self->setParam('readonly_time', $self->getReadOnlyTime());
        $self->_addHoursParams(defined ($datetime->getPersistenceHour()) ? $datetime->getPersistenceHour() : 17);
        $self->_addMinutesParams($datetime->getPersistenceMin() || 0);   
    } else {
        #$self->setParam('hour_value', $datetime->getPersistenceHour() || 0);
        #$self->setParam('minute_value', $datetime->getPersistenceMin() || 0);
    }

    $self->setParam('date_value', (defined $datetime->getPersistenceDateStr() || $datetime->isEmpty())
        ? unrender($datetime->getPersistenceDateStr()) : $datetime->toString($format));
    
    # Dynamic form input names
    $self->setParam('date_name', $name ."_date");
    $self->setParam('hour_name', $name . '_hour');
    $self->setParam('minute_name', $name . '_minute');
  
    for my $action (@{$self->getClientActions()}) {
        $self->addParam('client_actions', {action => $action});
    } 

    return TRUE;
}

sub getShowErrors {
    my $self = shift;
    return $self->{'_show_calendar_errors'};
}

sub setShowErrors {
    my $self = shift;
    $self->{'_show_calendar_errors'} = shift;
}

sub _addHoursParams {
    my $self = shift;
    my $hour = shift;
    $hour = 0 unless $hour =~ /^\d+$/;

    for my $h ($self->getHours()) {
        $self->addParam('hour_select', {
            value    => $h,
            selected => ($hour == $h),
            label    => (!$h)      ? '12 midnight' :
                        ($h < 12)  ? $h.' am'      :
                        ($h == 12) ? '12 noon'     : ($h - 12).' pm',
        });
    }
    return TRUE;
}

sub _addMinutesParams {
    my $self = shift;
    my $minute = shift;
    $minute = 0 unless $minute =~ /^\d+$/;

    for my $m ($self->getMinutes()) {
        $self->addParam('minute_select', {
            value    => $m,
            selected => ($minute == $m),
            label    => $m,
        });
    }
    return TRUE;
}

1;

__END__

=back

=head2 Modules Used

L<JSCalendar::View::DateTime|JSCalendar::View::DateTime>

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 3155 $

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
