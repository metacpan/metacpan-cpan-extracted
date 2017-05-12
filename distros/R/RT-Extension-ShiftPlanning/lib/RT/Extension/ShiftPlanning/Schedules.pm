#!/usr/bin/perl

use strict;
use warnings;
use 5.10.1;

package RT::Extension::2ndQuadrantSupport::ShiftPlanning::Schedules;

use base 'RT::SearchBuilder';

use RT::Extension::2ndQuadrantSupport::ShiftPlanning::Schedule;

=head1 NAME

  RT::Extension::2ndQuadrantSupport::ShiftPlanning::Schedules - Search class for ::Schedule

See perldoc DBIx::SearchBuilder

=cut

sub _Init {
    my $self = shift;
    $self->Table( RT::Extension::2ndQuadrantSupport::ShiftPlanning::Schedule->Table() );
    return $self->SUPER::_Init(@_);
}

sub NewItem {
    my $self = shift;
    return(RT::Extension::2ndQuadrantSupport::ShiftPlanning::Schedule->new($self->CurrentUser));
}

1;
