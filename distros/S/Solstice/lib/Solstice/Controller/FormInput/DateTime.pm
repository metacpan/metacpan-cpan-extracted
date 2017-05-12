package Solstice::Controller::FormInput::DateTime;

# $Id: DateTime.pm 3155 2006-02-21 20:08:18Z mcrawfor $

=head1 NAME

Solstice::Controller::FormInput::DateTime - Allows the manipulation of a Solstice::DateTime model

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use strict;
use warnings;
use 5.006_000;

use base qw(Solstice::Controller::FormInput);

use Solstice::View::FormInput::DateTime;

use Solstice::CGI;
use Solstice::DateTime;
use Solstice::StringLibrary qw(trimstr);

use constant TRUE  => 1;
use constant FALSE => 0;

use constant PARAM => 'datetime_editor';

our ($VERSION) = ('$Revision: 3155 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Superclass

L<Solstice::Controller::FormInput|Solstice::Controller::FormInput>

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut

=item new($datetime)

Constructor.

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
   
    unless (defined $self->getModel()) {
        # Create a datetime obj
        $self->setModel(Solstice::DateTime->new());
    }
    
    return $self;
}

=item getView()

=cut

sub getView {
    my $self = shift;

    my $view = Solstice::View::FormInput::DateTime->new($self->getModel());
    $view->setName($self->getName() || PARAM);
    #if nothing set, always show validation errors
    $view->setShowErrors(defined $self->getShowErrors() ? $self->getShowErrors() : TRUE);
    $view->setError($self->getError());
    
    return $view;
}

=item update()

=cut

sub update {
    my $self = shift;

    my $datetime = $self->getModel();

    $datetime->clearPersistenceValues();   
    
    my $name = $self->getName() || PARAM;

    my $date_str = trimstr(param($name."_date")) || '';

    my ($mon, $day, $year);
    if ($date_str =~ /^(\d{1,2})\D(\d{1,2})\D(\d\d\d\d)$/) {
        ($mon, $day, $year) = ($1, $2, $3);
    } elsif ($date_str =~ /^(\d{1,2})\D(\d{1,2})\D(\d\d)$/) {
        ($mon, $day, $year) = ($1, $2, $self->_getFullYear($3));
    }
    
    my $hour = param($name.'_hour');
    my $min  = param($name.'_minute');
    my $sec  = 0;

    $datetime->setPersistenceMonth($mon);
    $datetime->setPersistenceDay($day);
    $datetime->setPersistenceYear($year);
    $datetime->setPersistenceHour($hour) if defined $hour;
    $datetime->setPersistenceMin($min) if defined $min;
    $datetime->setPersistenceSec($sec);
    
    # Set the literal input str into persistence
    $datetime->setPersistenceDateStr($date_str);
    $datetime->setPersistenceTimeStr(($datetime->getPersistenceHour() || '00').':'.($datetime->getPersistenceMin() || '00'));
    
    return TRUE;
}

=item validate()

IDEA: add a way to set a callback function into this controller for validation.
That would allow validation to be sensitive to the form context.

=cut

sub validate {
    my $self = shift;

    my $name = $self->getName() || PARAM;
    
    my $param = $self->getIsRequired() 
        ? $self->createRequiredParam($name. "_date")
        : $self->createOptionalParam($name. "_date");
    
    $param->addConstraint('invalid_date', $self->constrainValidDateTime());

    if ($self->getRequireFuture()) {
        $param->addConstraint('passed_date', $self->constrainFutureDateTime());
    }
    return $self->processConstraints();
}

=item constrainValidDateTime()

=cut

sub constrainValidDateTime {
    my $self = shift;

    my $datetime = $self->getModel();

    my $test = Solstice::DateTime->new($datetime->getPersistenceDateStr().' '.$datetime->getPersistenceTimeStr());

    return sub {
        return $test->isValid();
    };
}

=item constrainFutureDateTime()

=cut

sub constrainFutureDateTime {
    my $self = shift;

    my $datetime = $self->getModel();
    
    my $test = Solstice::DateTime->new($datetime->getPersistenceDateStr().' '.$datetime->getPersistenceTimeStr());
    
    return sub {
        return !$test->isBeforeNow();
    };
}

=item constrainMinimumDateTime($minimum_date)

=cut

sub constrainMinimumDateTime {
    my $self = shift;
    my $minimum_date = shift;

    my $limit;
    if (defined $minimum_date) {
        if (defined $minimum_date->getPersistenceDateStr() && $minimum_date->getPersistenceTimeStr()) {
            # The mimimum date is also in persistence
            $limit = Solstice::DateTime->new($minimum_date->getPersistenceDateStr().' '.$minimum_date->getPersistenceTimeStr());
        } else {
            # It's just a datetime obj to test against
            $limit = $minimum_date;
        }
    } else {
        # Not defined - this becomes just a 'future' test
        $limit = Solstice::DateTime->new(time);
    }
    $limit->setSec(10);

    my $datetime = $self->getModel();

    my $test = Solstice::DateTime->new($datetime->getPersistenceDateStr().' '.$datetime->getPersistenceTimeStr());

    return sub {
        return $limit->isBefore($test);
    };
}

=item constrainMaximumDateTime($maximum_date)

=cut

sub constrainMaximumDateTime {
    my $self = shift;
    my $maximum_date = shift;

    my $limit;
    if (defined $maximum_date) {
        if (defined $maximum_date->getPersistenceDateStr() && $maximum_date->getPersistenceTimeStr()) {
            # The maximum date is also in persistence
            $limit = Solstice::DateTime->new($maximum_date->getPersistenceDateStr().' '.$maximum_date->getPersistenceTimeStr());
        } else {
            # It's just a datetime obj to test against
            $limit = $maximum_date;
        }
    } else {
        # Not defined - this becomes just a 'future' test
        $limit = Solstice::DateTime->new(time);
    }

    my $datetime = $self->getModel();

    my $test = Solstice::DateTime->new($datetime->getPersistenceDateStr().' '.$datetime->getPersistenceTimeStr());

    return sub {
        return !$limit->isBefore($test);
    };
}

=item commit()

=cut

sub commit {
    my $self = shift;

    my $datetime = $self->getModel();

    return $datetime->processPersistenceValues();
}

=item revert()

=cut

sub revert {
    my $self = shift;

    my $datetime = $self->getModel();

    return $datetime->clearPersistenceValues();
}

=item hasDateChanged()

Returns TRUE if date persistence data differs from stored data.

=cut

sub hasDateChanged {
    my $self = shift;
    
    my $datetime = $self->getModel();
    my $test = Solstice::DateTime->new($datetime->getPersistenceDateStr().' '.$datetime->getPersistenceTimeStr());

    return $test->isEqualTo($datetime) ? FALSE : TRUE;
}

=item setRequireFuture(bool)

=cut

sub setRequireFuture {
    my $self = shift;
    $self->{'_require_future'} = shift;
}

=item getRequireFuture()

=cut

sub getRequireFuture {
    my $self = shift;
    return $self->{'_require_future'};
}

sub getShowErrors {
    my $self = shift;
    return $self->{'_show_calendar_errors'};
}

sub setShowErrors {
    my $self = shift;
    $self->{'_show_calendar_errors'} = shift;
}

=item _getFullYear($str)

Convert a two-digit year string into a four-digit year string

=cut

sub _getFullYear {
    my $self = shift;
    my $str  = shift;

    return ((localtime)[5] + 1900) unless defined $str;
        
    my $year = substr((localtime)[5] + 1900, 0, 2);
    $year -= 1 if $str > 50;
    return ($year . $str);
}

1;
__END__

=back

=head2 Modules Used

L<Solstice::Controller|Solstice::Controller>.

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
