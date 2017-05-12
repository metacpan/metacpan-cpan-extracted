#!/usr/bin/perl

package RT::Extension::2ndQuadrantSupport::ShiftPlanning::Schedule;

use strict;
use warnings;
use 5.10.1;

use base 'RT::Record';

=head1 NAME

  RT::Extension::2ndQuadrantSupport::ShiftPlanning::Schedule - Schedule of shifts for a given "location" in shiftplanning

=head1 DESCRIPTION

An RT record for the shift schedule for a particular shiftplanning "position". Schedules are assigned
to people for shifts. Each schedule has a position that's part of a location.

=cut

sub Table { 'ShiftPlanningSchedules' };

sub Schema { 
    return {
        ScheduleId => { TYPE => 'integer', NULL => 'NOT NULL' },
        Name => { TYPE => 'varchar', NULL => 'NOT NULL' },
        StartTime => { TYPE => 'integer', NULL => 'NOT NULL' },
        EndTime => { TYPE => 'integer', NULL => 'NOT NULL' },
        LocationId => { TYPE => 'integer', NULL => 'NOT NULL' },
    };
}

sub _CoreAccessible {
    {
        ScheduleId => { read => 1, auto => 1 },
        Name => { read => 1, auto => 1 },
        # StartTime and EndTime are shiftplanning.com TimeIDs
        # They can be looked up with other API calls.
        StartTime => { read => 1, auto => 1 },
        EndTime => { read => 1, auto => 1 },
        # FK to Location
        LocationId => { read => 1, auto => 1 },
    };
}

1;
