#!/usr/bin/perl

package RT::Extension::2ndQuadrantSupport::ShiftPlanning::Onnow;

use strict;
use warnings;
use 5.10.1;

use base 'RT::Record';

=head1 NAME

  RT::Extension::2ndQuadrantSupport::ShiftPlanning::Onnow  - a shift / clock entry from shiftplanning

=head1 DESCRIPTION

An RT record for a ShiftPlanning 'dashboard.onnow' result. We poll
shiftplanning to get the shift status periodically and use that when we're
making alerting decisions and record them in the DB.

These records are really a derived result from underlying data in
shiftplanning, they're an extract of data from shiftplanning.

=head1 Methods

=cut

sub Table { 'ShiftPlanningOnnow'; }

# DBIx::SearchBuilder schema generation is a bit under-documented. If you're
# wondering what's going on, read the DBIx::SearchBuilder::SchemaGenerator sources,
# and t/11schema_records.t in the searchbuilder sources.
sub Schema {
    return {
        UserId => { TYPE => 'integer' },
        ClockinTime => { TYPE => 'timestamp' },
        EmployeeId => { TYPE => 'integer', NULL => 'NOT NULL' },
        EmployeeName => { TYPE => 'text', NULL => 'NOT NULL' },
        IsOnBreak => { TYPE => 'boolean' },
        ScheduleId => { TYPE => 'integer' },
        ScheduleName => { TYPE => 'text' },
        ShiftId => { TYPE => 'integer' },
        ShiftEnd => { TYPE => 'timestamp' },
        ShiftStart => { TYPE => 'timestamp' },
        TimeclockId => { TYPE => 'integer' },
        RefreshedTime => { TYPE => 'timestamp' },
    };
}

sub _CoreAccessible {
    # Models result from dashboard.onnow query in shiftplanning
    return {
        UserId => { read => 1, auto => 1 },
        ClockinTime => { read => 1, write => 1, auto => 1, type => 'datetime', sql_type => 11, is_numeric => 0 },
        EmployeeId => { read => 1, auto => 1 },
        EmployeeName => { read => 1, auto => 1 },
        IsOnBreak => { read => 1, auto => 1, write => 1 },
        ScheduleId => { read => 1, auto => 1 },
        ScheduleName => { read => 1, auto => 1 },
        ShiftId => { read => 1, auto => 1 },
        ShiftEnd => { read => 1, auto => 1, type => 'datetime', sql_type => 11, is_numeric => 0 },
        ShiftStart => { read => 1, auto => 1, type => 'datetime', sql_type => 11, is_numeric => 0 },
        TimeclockId => { read => 1, auto => 1 },
        RefreshedTime => { read => 1, auto => 1, type => 'datetime', sql_type => 11, is_numeric => 0 },
    };
}

1;
