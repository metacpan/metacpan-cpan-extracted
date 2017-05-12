#!/usr/bin/perl

use strict;
use warnings;
use 5.10.1;

package RT::Extension::ShiftPlanning;

use WebService::ShiftPlanning;
use RT::Extension::ShiftPlanning::Onnow;
use RT::Extension::ShiftPlanning::Location;
use RT::Extension::ShiftPlanning::Schedule;
use RT::Extension::ShiftPlanning::Onnows;

use DateTime;

=head1 NAME

RT::Extension::ShiftPlanning - Filter a user list to find those who are on shift

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Given a list of RT::User, return those who're on shift:

  ClockedInOrScheduled(LocationIdByName('Level1'), @list_of_RT_users);

Given an RT::Group:

  ClockedInOrScheduled($ShiftID, @{$theGroup->UserMembersObj->ItemsArrayRef});

To return pager phone numbers only for those users on shift who have pager
phone numbers set:

  map { $_->PagerPhone }
  ClockedInOrScheduled $ShiftId
  grep { $_->PagerPhone } 
  @{$theGroup->UserMembersObj->ItemsArrayRef};

=head1 DESCRIPTION

Filters a user list using shiftplanning data and polls shiftplanning
to get updated shift data.

=head1 Pages

  /NoAuth/ShiftPlanning/refresh_schedules.html - invokes RT::Extension::ShiftPlanning::RefreshScheduleData

  /NoAuth/ShiftPlanning/refresh_onnow.html - invokes RT::Extension::ShiftPlanning::RefreshOnNow

  /ShiftPlanning/create_schema.html - generate initial shiftplanning support schema.



=head1 Functions

=cut

=head2 ClockedInOrScheduled

  ClockedInOrScheduled($ShiftId, @RTUserObjects)

Takes a list of RT users and filters it to return only those who are on shift
according to a cached copy of the ShiftPlanning.com shift state, returning the
filtered list.

The logic we want for selecting who to notify is as follows:

- Return true if the user is clocked in to one of the specified shifts
- Return true if the user is clocked in and not on any particular shift
  (i.e. remember to clock out, people!)
- Otherwise return false

We map RT users to ShiftPlanning.com users using the ShiftplanningEmployeeId
custom field in the RT::User.

It's entirely possible for an empty array to be returned if none of the users
passed are on shift. Callers should have a fallback plan to ignore shifts
and alert everyone.

You might want to use this as part of a template that decides who gets notified,
like we do with Pushover:

  use RT::Extension::ShiftPlanning;
  my @recips;
  push(@recips, @{$Ticket->AdminCc->UserMembersObj->ItemsArrayRef});
  push(@recips, @{$Ticket->QueueObj->AdminCc->UserMembersObj->ItemsArrayRef});
  my @recip_api_keys = 
    map { $_->FirstCustomFieldValue('PushoverUserKey') }
    RT::Extension::ShiftPlanning::ClockedInOrScheduled(
     '24x7 L1', @recips
    );
  # Return comma separated list of unique API keys
  join ',', keys %{{ map { $_ => 1 } @recip_api_keys }};

(Yes, this should be neatly grouped up somewhere else).

=cut 

sub ClockedInOrScheduled {
    my ($location, @users) = (@_);
    die("Must specify location ID or name") unless defined($location);
    # For efficiency we should be doing a single search against an IN list.
    # LocationId may be undef, in which case anyone who is clocked in or scheduled
    # for any shift is notified.
    my $sb = RT::Extension::ShiftPlanning::Onnows->new( $RT::SystemUser );
    my $join_to_sched_alias = $sb->Join(
        TYPE   => 'left',
        TABLE1 => 'main',
        FIELD1 => 'ScheduleId',
        TABLE2 => RT::Extension::ShiftPlanning::Schedule->Table(),
        FIELD2 => 'ScheduleId',
    );
    my $join_to_location_alias = $sb->Join(
        TYPE   => 'left',
        ALIAS1 => $join_to_sched_alias,
        FIELD1 => 'LocationId',
        TABLE2 => RT::Extension::ShiftPlanning::Location->Table(),
        FIELD2 => 'LocationId',
    );
    $sb->Limit(
        ALIAS => $join_to_location_alias,
        FIELD => 'name',
        OPERATOR => 'IS',
        VALUE => 'NULL',
        QUOTEVALUE => 0,
        ENTRYAGGREGATOR => 'OR',
        SUBCLAUSE => 'filter',
    );
    if ($location =~ /^\d+$/) {
        $sb->Limit(
            ALIAS => $join_to_location_alias,
            FIELD => 'LocationId',
            VALUE => int($location),
            QUOTEVALUE => 0,
            ENTRYAGGREGATOR => 'OR',
            SUBCLAUSE => 'filter',
        );
    } else {
        $sb->Limit(
            ALIAS => $join_to_location_alias,
            FIELD => 'name',
            VALUE => $location,
            QUOTEVALUE => 1,
            ENTRYAGGREGATOR => 'OR',
            SUBCLAUSE => 'filter',
        );
    }
    # Result gives us a bunch of OnNow records. They are not very useful by themselves. We need to collect their
    # IDs and use them to filter a list of users by the ShiftPlanningUserId custom field. This could be integrated
    # into the above query and probably should be, but RT custom fields are painful to work with so we'll just use
    # a loop and deal with the icky repeated SQL.
    #
    my %sp_id_to_rt_user = ();
    for my $user (@users) {
        my $spid = $user->FirstCustomFieldValue('ShiftPlanningEmployeeId');
        if (defined($spid)) {
            $sp_id_to_rt_user{$spid} = $user;
        }
    }
    my @users_on_now = ();
    while (my $sp_onnow = $sb->Next) {
        my $rtuser = $sp_id_to_rt_user{$sp_onnow->EmployeeId};
        if (defined($rtuser)) {
            push(@users_on_now, $sp_id_to_rt_user{$sp_onnow->EmployeeId})
        }
    }
    return @users_on_now;
}

=head2 RefreshScheduleData

Fetch mostly-static shift data from shiftplanning.com - the mapping
of "Location" (which we use to aggregate shifts of the same type) to
"Positions", which are shifts.

Hits the shiftplanning api calls location.locations and schedule.schedules .

We look up who is on shift by location and the dashboard.onnow function
returns only positions, so we need this data to determine which positions
correspond to the "location" (shift) of interest.

It's also used for LocationIdByName .

=cut 

sub RefreshScheduleData {
    # We need to fetch the fresh data from shiftplanning and stash it in RAM,
    # begin a transaction, truncate the tables, and repopulate them then
    # commit.
    my $agent = _getAgent();
    my $locations = $agent->doCall('GET', 'location.locations');
    my $shifts = $agent->doCall('GET', 'schedule.schedules');
    $RT::Handle->BeginTransaction;
    $RT::Handle->SimpleQuery("DELETE FROM " . RT::Extension::ShiftPlanning::Schedule->Table());
    $RT::Handle->SimpleQuery("DELETE FROM " . RT::Extension::ShiftPlanning::Location->Table());
    for my $location (@{$locations}) {
        my $l = RT::Extension::ShiftPlanning::Location->new( $RT::Handle );
        $l->Create(
            LocationId => $location->{id},
            Name => $location->{name},
        );
    }
    for my $shift (@{$shifts}) {
        my $s = RT::Extension::ShiftPlanning::Schedule->new( $RT::Handle );
        $s->Create(
            ScheduleId => $shift->{id},
            Name => $shift->{name},
            StartTime => $shift->{start_time}->{id},
            EndTime => $shift->{end_time}->{id},
            LocationId => $shift->{location}->{id},
        );
    }
    $RT::Handle->Commit;
}

=head2 RefreshOnnowData

Fetch the rapidly changing dashboard.onnow data from shiftplanning, getting the
latest info on who is clocked in or should be clocked in.

=cut 

sub RefreshOnnowData {
    # Fetch the fresh data from shiftplanning then truncate and repopulate the
    # table within a transaction.
    my $agent = _getAgent();
    my $result = $agent->doCall('GET', 'dashboard.onnow');
    $RT::Handle->BeginTransaction;
    $RT::Handle->SimpleQuery("DELETE FROM " . RT::Extension::ShiftPlanning::Onnow->Table());
    for my $entry (@{$result}) {
        my $onnow = RT::Extension::ShiftPlanning::Onnow->new( $RT::Handle );
        $onnow->Create (
            UserId => undef,
            ClockinTime => _ShiftPlanningTimeToSQLDate($entry->{clockin_time}),
            EmployeeId => $entry->{employee_id},
            EmployeeName => $entry->{employee_name},
            IsOnBreak => 0,
            ScheduleId => $entry->{schedule_id},
            ScheduleName => $entry->{schedule_name},
            ShiftId => $entry->{shift_id},
            ShiftEnd => _ShiftPlanningTimeToSQLDate($entry->{shift_end}),
            ShiftStart => _ShiftPlanningTimeToSQLDate($entry->{shift_start}),
            TimeclockId => $entry->{timeclock_id},
            RefreshedTime => DateTime->now->iso8601,
        );
    }
    $RT::Handle->Commit;
}

sub _ShiftPlanningTimeToSQLDate {
    my $sptime = shift;
    if (defined($sptime)) {
        my($rtdate) = RT::Date->new(RT->SystemUser);
        $rtdate->Set( Format => 'unix', Value => $sptime->{'timestamp'} );
        return $rtdate->ISO;
    } else {
        return undef;
    }

}

# Helper to wrap ShiftPlanning setup
sub _getAgent {
    my $key = RT->Config->Get('ShiftPlanningAPIKey');
    my $username = RT->Config->Get('ShiftPlanningUsername');
    my $password = RT->Config->Get('ShiftPlanningPassword');
    if (!defined($key)) {
        die('ShiftPlanning support not configured; missing $ShiftPlanningAPIKey in RT_SiteConfig.pm');
    }
    if (!defined($username)) {
        die('ShiftPlanning support not configured; missing $ShiftPlanningUsername in RT_SiteConfig.pm');
    }
    if (!defined($password)) {
        die('ShiftPlanning support not configured; missing $ShiftPlanningUsername in RT_SiteConfig.pm');
    }

    my $agent = WebService::ShiftPlanning->new(
        key => $key
    );
    $agent->doLogin( $username, $password );
    return $agent;
}


=head1 AUTHOR

Craig Ringer, C<< <ringerc at cpan.org> >>

=head1 BUGS

You may report any bugs to C<bug-rt-extension-shiftplanning at rt.cpan.org>, or
through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=RT-Extension-ShiftPlanning>.
However, this module is offered as-is without any support by its author or by
ShiftPlanning.com (who did not have anything to do with this module). You might
also have some luck on the ShiftPlanning.com forums.

=head1 LICENSE

The same license as Perl its self

=cut

1;
