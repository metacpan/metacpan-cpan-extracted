#!/usr/bin/perl

package RT::Extension::2ndQuadrantSupport::ShiftPlanning::Location;

use strict;
use warnings;
use 5.10.1;

use base 'RT::Record';

=head1 NAME

  RT::Extension::2ndQuadrantSupport::ShiftPlanning::Location  - "location" in shiftplanning

=head1 DESCRIPTION

An RT record for a ShiftPlanning "location". We use these to identify roles
for shifts - imagine them like a seat labeled "Level 1 support".

=cut

sub Table { 'ShiftPlanningLocations' }

sub Schema {
    return {
        LocationId => { TYPE => 'integer', NULL => 'NOT NULL' },
        Name => { TYPE => 'varchar', NULL => 'NOT NULL' }
    };
}

sub _CoreAccessible {
    # Models result from location.locations query in shiftplanning
    {
        LocationId => { read => 1, auto => 1},
        Name => { read => 1, auto => 1},
    };
}

1;
