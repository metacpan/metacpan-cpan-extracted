package RTx::Calendar;

use strict;
use DateTime;
use DateTime::Set;

our $VERSION = "1.09";

RT->AddStyleSheets('calendar.css');
RT->AddJavaScript('calendar.js');

sub FirstDay {
    my ( $year, $month, $matchday ) = @_;
    my $set
        = DateTime::Set->from_recurrence(
        next => sub { $_[0]->truncate( to => 'day' )->subtract( days => 1 ) }
        );

    my $day = DateTime->new( year => $year, month => $month );

    $day = $set->next($day) while $day->day_of_week != $matchday;
    $day;

}

sub LastDay {
    my ( $year, $month, $matchday ) = @_;
    my $set = DateTime::Set->from_recurrence(
        next => sub { $_[0]->truncate( to => 'day' )->add( days => 1 ) } );

    my $day = DateTime->last_day_of_month( year => $year, month => $month );

    $day = $set->next($day) while $day->day_of_week != $matchday;
    $day;
}

sub DatesClauses {
    my ( $Dates, $begin, $end ) = @_;

    my $clauses = "";

    my @DateClauses = map {
        "($_ >= '" . $begin . " 00:00:00' AND $_ <= '" . $end . " 23:59:59')"
    } @$Dates;

    # All multiple days events are already covered on the query above
    # The following code works for covering events that start before and ends
    # after the selected period.
    # Start and end fields of the multiple days must also be present on the
    # format.
    my $multiple_days_events = RT->Config->Get('CalendarMultipleDaysEvents');
    for my $event ( keys %$multiple_days_events ) {
        next unless
            grep { $_ eq $multiple_days_events->{$event}{'Starts'} } @$Dates;
        next unless
            grep { $_ eq $multiple_days_events->{$event}{'Ends'} } @$Dates;
        push @DateClauses,
            "("
            . $multiple_days_events->{$event}{Starts}
            . " <= '"
            . $end
            . " 00:00:00' AND "
            . $multiple_days_events->{$event}{Ends}
            . " >= '"
            . $begin
            . " 23:59:59')";
    }

    $clauses .= " AND " . " ( " . join( " OR ", @DateClauses ) . " ) "
        if @DateClauses;

    return $clauses;
}

sub FindTickets {
    my ( $CurrentUser, $Query, $Dates, $begin, $end ) = @_;

    my $multiple_days_events = RT->Config->Get('CalendarMultipleDaysEvents');
    my @multiple_days_fields;
    for my $event ( keys %$multiple_days_events ) {
        next unless
            grep { $_ eq $multiple_days_events->{$event}{'Starts'} } @$Dates;
        next unless
            grep { $_ eq $multiple_days_events->{$event}{'Ends'} } @$Dates;
        for my $type ( keys %{ $multiple_days_events->{$event} } ) {
            push @multiple_days_fields,
                $multiple_days_events->{$event}{$type};
        }
    }

    $Query .= DatesClauses( $Dates, $begin, $end )
        if $begin and $end;

    my $Tickets = RT::Tickets->new($CurrentUser);
    $Tickets->FromSQL($Query);
    $Tickets->OrderBy( FIELD => 'id', ORDER => 'ASC' );
    my %Tickets;
    my %AlreadySeen;
    my %TicketsSpanningDays;
    my %TicketsSpanningDaysAlreadySeen;

    while ( my $Ticket = $Tickets->Next() ) {
        # How to find the LastContacted date ?
        # Find single day events fields
        for my $Date (@$Dates) {
            # $dateindex is the date to use as key in the Tickets Hash
            # in the YYYY-MM-DD format
            # Tickets are then groupd by date in the %Tickets hash
            my $dateindex_obj = GetDate( $Date, $Ticket, $CurrentUser );
            next unless $dateindex_obj;
            my $dateindex = $dateindex_obj->ISO( Time => 0, Timezone => 'user' );
            push @{ $Tickets{$dateindex } },
                $Ticket

                # if reminder, check it's refering to a ticket
                unless ( $Ticket->Type eq 'reminder'
                and not $Ticket->RefersTo->First )
                or $AlreadySeen{ $dateindex }
                {$Ticket}++;
        }

        # Find spanning days of multiple days events
        for my $event (sort keys %$multiple_days_events) {
            next unless
                grep { $_ eq $multiple_days_events->{$event}{'Starts'} } @$Dates;
            next unless
                grep { $_ eq $multiple_days_events->{$event}{'Ends'} } @$Dates;
            my $starts_field = $multiple_days_events->{$event}{'Starts'};
            my $ends_field   = $multiple_days_events->{$event}{'Ends'};
            my $starts_date  = GetDate( $starts_field, $Ticket, $CurrentUser );
            my $ends_date    = GetDate( $ends_field,   $Ticket, $CurrentUser );
            next unless $starts_date and $ends_date;
            # Loop through all days between start and end and add the ticket
            # to it
            my $current_date = RT::Date->new($CurrentUser);
            $current_date->Set(
                Format => 'unix',
                Value => $starts_date->Unix,
            );

            my $end_date = $ends_date->ISO( Time => 0, Timezone => 'user' );
            my $first_day = 1;
            # We want to prevent infinite loops if user for some reason
            # set a future date for year 3000 or something like that
            my $prevent_infinite_loop = 0;
            while ( ( $current_date->ISO( Time => 0, Timezone => 'user' ) le $end_date )
                && ( $prevent_infinite_loop++ < 10000 ) )
            {
                my $dateindex = $current_date->ISO( Time => 0, Timezone => 'user' );

                push @{ $TicketsSpanningDays{$dateindex} }, $Ticket->id
                    unless $first_day
                    || $TicketsSpanningDaysAlreadySeen{$dateindex}
                    {$Ticket}++;
                push @{ $Tickets{$dateindex } },
                    $Ticket
                    # if reminder, check it's refering to a ticket
                    unless ( $Ticket->Type eq 'reminder'
                    and not $Ticket->RefersTo->First )
                    or $AlreadySeen{ $dateindex }
                    {$Ticket}++;

                $current_date->AddDay();
                $first_day = 0;
            }
        }
    }
    if ( wantarray ) {
        return ( \%Tickets, \%TicketsSpanningDays );
    } else {
        return \%Tickets;
    }
}

sub GetDate {
    my $date_field = shift;
    my $Ticket = shift;
    my $CurrentUser = shift;

    unless ($date_field) {
        $RT::Logger->debug("No date field provided. Using created date.");
        $date_field = 'Created';
    }

    if ($date_field =~ /^CF\./){
        my $cf = $date_field;
        $cf =~ s/^CF\.\{(.*)\}/$1/;
        my $CustomFieldObj = $Ticket->LoadCustomFieldByIdentifier($cf);
        unless ($CustomFieldObj->id) {
            RT->Logger->debug("$cf Custom Field is not available for this object.");
            return;
        }
        my $CFDateValue = $Ticket->FirstCustomFieldValue($cf);
        return unless $CFDateValue;
        my $CustomFieldObjType = $CustomFieldObj->Type;
        my $DateObj            = RT::Date->new($CurrentUser);
        if ( $CustomFieldObjType eq 'Date' ) {
            $DateObj->Set(
                Format   => 'unknown',
                Value    => $CFDateValue,
            );
        } else {
            $DateObj->Set( Format => 'ISO', Value => $CFDateValue );
        }
        return $DateObj;
    } else {
        my $DateObj = $date_field . "Obj";
        return $Ticket->$DateObj;
    }
}

#
# Take a user object and return the search with Description "calendar" if it exists
#
sub SearchDefaultCalendar {
    my $CurrentUser = shift;
    my $Description = "calendar";

    my $UserObj  = $CurrentUser->UserObj;
    my @searches = $UserObj->Attributes->Named('SavedSearch');
    for my $search (@searches) {
        next
            if ( $search->SubValue('SearchType')
            && $search->SubValue('SearchType') ne 'Ticket' );

        return $search
            if "calendar" eq $search->Description;
    }

    # search through user's groups as well
    my $Groups = RT::Groups->new($CurrentUser);
    $Groups->LimitToUserDefinedGroups;
    $Groups->WithCurrentUser;
    while ( my $group = $Groups->Next ) {
        @searches = $group->Attributes->Named('SavedSearch');
        for my $search (@searches) {
            next
                if ( $search->SubValue('SearchType')
                && $search->SubValue('SearchType') ne 'Ticket' );

            return $search
                if "calendar" eq $search->Description;
        }
    }

    # search thru system saved searches
    @searches = $RT::System->Attributes->Named('SavedSearch');
    for my $search (@searches) {
        next
            if ( $search->SubValue('SearchType')
            && $search->SubValue('SearchType') ne 'Ticket' );

        return $search
            if "calendar" eq $search->Description;
    }
}

sub GetEventImg {
    my $Object      = shift;
    my $CurrentDate = shift;
    my $DateTypes   = shift;
    my $IsReminder  = shift;
    my $CurrentUser = shift;
    my $EventIcon;
    my %CalendarIcons = RT->Config->Get('CalendarIcons');

CALENDAR_ICON:
    for my $legend ( sort { (split /\s*,\s*/, $b) <=> (split /\s*,\s*/, $a) or ($a cmp $b) } keys %CalendarIcons ) {
        if (   $legend eq 'Reminder'
            && $IsReminder
            && $Object->DueObj->ISO( Time => 0, Timezone => 'user' ) eq $CurrentDate )
        {
            $EventIcon = 'reminder.png';
            last;
        }

        for my $DateField ( split /\s*,\s*/, $legend ) {
            next CALENDAR_ICON unless $DateTypes->{$DateField};

            if ( $DateField =~ /^CF\./ ) {
                my $cf = $DateField;
                $cf =~ s/^CF\.\{(.*)\}/$1/;
                my $CustomFieldObj = $Object->LoadCustomFieldByIdentifier($cf);
                next CALENDAR_ICON unless $CustomFieldObj->id;
                my $DateValue = $Object->FirstCustomFieldValue($cf);
                next CALENDAR_ICON unless $DateValue;
                unless ( $CustomFieldObj->Type eq 'Date' ) {
                    my $DateObj = RT::Date->new( $CurrentUser );
                    $DateObj->Set( Format => 'ISO', Value => $DateValue );
                    $DateValue = $DateObj->ISO( Time => 0, Timezone => 'user' );
                }
                next CALENDAR_ICON unless $DateValue eq $CurrentDate;
            } else {
                my $DateObj = $DateField . "Obj";
                my $DateValue
                    = $Object->$DateObj->ISO( Time => 0, Timezone => 'user' );
                next CALENDAR_ICON unless $DateValue eq $CurrentDate;
            }
        }

        # If we are here, it means that all comparissons are true
        $EventIcon = $CalendarIcons{$legend};
        last;
    }

    if ($EventIcon) {
        return '<img src="' . $RT::WebImagesURL . '/' . $EventIcon . '" />';
    } else {
        return '';
    }
}


1;

__END__

=head1 NAME

RTx::Calendar - Calendar view for RT ticket dates and custom fields

=head1 DESCRIPTION

C<RTx::Calendar> provides a calendar view to display tickets and
reminders based on selected dates. Once the extension is installed,
if you perform a ticket search using the Query Builder, you will see
a new Calendar entry in the page menu. You can click that menu to see
the calendar view of your search. A portlet is also available to add
to any dashboard, including on the RT home page.

=begin HTML

<p><img width="600" src="https://static.bestpractical.com/images/calendar/calendar.png" alt="Calendar Overview" /></p>

=end HTML

=head1 RT VERSION

Works with RT 5.

For older versions of RT, see the CHANGES file for compatible earlier versions.

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt5/etc/RT_SiteConfig.pm>

Add this line:

    Plugin('RTx::Calendar');

=item Clear your mason cache

    rm -rf /opt/rt5/var/mason_data/obj

=item Restart your webserver

=back

=head1 USAGE

To view a Calendar, first perform a ticket search in the ticket Query
Builder and load the search results. Then click the Calendar item in the
page menu to see the calendar view based on the results from that search.

By default, RTx::Calendar will display the Starts and Due date fields of
each ticket from your search results as events on the Calendar.

Other date fields added to the Format of a ticket search are displayed on the
Calendar as events. You can also display events based on Date or DateTime
custom fields by adding them to the Format of a ticket search as well.

Hover over events in the calendar to see additional details for that event.
You can click on entries to go to the ticket.

=head2 Displaying Other Date Fields

You can show other date fields as events on the Calendar by adding them
to the Format section at the Advanced tab of your query. You can add and
remove dates from search results using the Display Columns section at
the bottom of the Query Builder.

Changes made using the Display Columns settings automatically update the
search Format. You can also edit the Format directly on the Advanced page.

=head2 Calendar Portlet Saved Searches

As described above, you can see a calendar for any ticket search using
the calendar link in the search results.

You can also create a saved search for the calendar to be used in calendar
portlets on dashboards. See L</"CONFIGURATION"> for details on adding the
calendar portlets.

By default, the calendar looks for a saved search with the name "calendar"
and will use that search for calendar portlets. Saved searches can be
saved with different privacy settings, so your system can have multiple
saved "calendar" searches. For a given user, the calendar first checks
for a user-level saved search (personal to that user), then for a group-level
saved search for groups the user is in, and finally, for a system-level saved
search.

=head2 Displaying Reminders

Reminders are displayed on the Calendar only if you explicitly add the
following clause to your query:

    AND ( Type = 'ticket' OR Type = 'reminder' )

=head1 CONFIGURATION

=head2 Use the Calendar on Dashboard

The Calendar comes with 3 different portlets that can be added to your
RT dashboards:

=over

=item C<MyCalendar>

A summary of the events for the current week.

=item C<Calendar>

A full-month view of the Calendar.

=item C<CalendarWithSidebar>

A full-month view of the Calendar, with a sidebar that includes an extra
status filter and legends of the Calendar events.

=back

To make these portlets available in RT, add them to the
C<$HomepageComponents> configuration in your F<etc/RT_SiteConfig.pm>:

    Set($HomepageComponents, [qw(QuickCreate Quicksearch
        MyAdminQueues MySupportQueues MyReminders RefreshHomepage
        MyCalendar Calendar CalendarWithSidebar)]);

Users can then select them when building dashboards.

=head2 Display Configuration

=head3 Display Owner

You can show the owner of the ticket in each event box by adding this line
to your F<etc/RT_SiteConfig.pm>:

    Set($CalendarDisplayOwner, 1);

=head3 Choosing the fields to be displayed in the popup

When you mouse over events on the calendar, a popup window shows additional
details from the ticket associated with that event. You can configure which
fields are displayed with C<@CalendarPopupFields>. This is the default
configuration:

    Set(@CalendarPopupFields, (
        "OwnerObj->Name",
        "CreatedObj->ISO",
        "StartsObj->ISO",
        "StartedObj->ISO",
        "LastUpdatedObj->ISO",
        "DueObj->ISO",
        "ResolvedObj->ISO",
        "Status",
        "Priority",
        "Requestors->MemberEmailAddressesAsString",
    ));

To show custom field values, add them using the custom field name in
this format: C<"CustomField.{Maintenance Start}">.

Valid values are all fields on an RT ticket. See the RT documentation for
C<RT::Ticket> for a list.

As shown above, for ticket fields that can have multiple output formats,
like dates and users, you can also use the C<Obj> associated with the field
to call a specific method to display the format you want. The ticket dates
shown above will display dates in C<ISO> format. The documentation for C<RT::Date>
has other format options. User fields, like Owner, can use the methods shown
in the C<RT::User> documentation to show values like EmailAddress or
RealName, for example.

=head3 Event Colors

The Calendar shows events in different colors based on the ticket status.
Use C<$CalendarStatusColorMap> to set alternate colors or add custom statuses.
The following is the default configuration:

    Set(%CalendarStatusColorMap, (
        '_default_'                             => '#5555f8',
        'new'                                   => '#87873c',
        'open'                                  => '#5555f8',
        'rejected'                              => '#FF0000',
        'resolved'                              => '#72b872',
        'stalled'                               => '#FF0000',
    ));

You can use any color declaration that CSS supports, including hex codes,
color names, and RGB values.

The C<_default_> key is used for events that don't have a status
in the C<$CalendarStatusColorMap> hash. The default color is a dark tone of
blue.

=head3 Filter on Status

The Calendar has a Filter on Status section that allows you to filter
events by status without having to change the original query.
The C<@CalendarFilterStatuses> setting controls which statuses are available
for filtering. The following is the default:

    Set(@CalendarFilterStatuses, qw(new open stalled rejected resolved));

You can change the default selected statuses of the Filter On Status section
by defining C<@CalendarFilterDefaultStatuses>. The following is the default:

    Set(@CalendarFilterDefaultStatuses, qw(new open));

=head3 Custom Icons

The calendar shows different icons for events based on the date fields
used to display the event on that day. The C<%CalendarIcons> setting
controls which icons are used for each date field. The following is the
default using provided icons:

    Set(%CalendarIcons, (
        'Reminder'     => 'reminder.png',
        'Resolved'     => 'resolved.png',
        'Starts, Due'  => 'starts_due.png',
        'Created, Due' => 'created_due.png',
        'Created'      => 'created.png',
        'Due'          => 'due.png',
        'Starts'       => 'starts.png',
        'Started'      => 'started.png',
        'LastUpdated'  => 'updated.png',
    ));

You can also define icons for custom fields by using the following format:

        'CF.{Maintenance Start}' => 'maintstart.png',
        'CF.{Maintenance Stop}'  => 'maintstop.png',

To add custom images, create a directory F<local/static/images> in your installed
RT directory (usually F</opt/rt5>) and copy images files there.

You can use any image format that your browser supports, but PNGs and GIFs
with transparent backgrounds are recommended because they will display better
to the background color of the events. The recommended size is 10 pixels wide
and 7 pixels in high.

=head3 Multiple Days Events

By default, calendars display individual events on each day based on
the dates in the query.

=begin HTML

<p><img src="https://static.bestpractical.com/images/calendar/calendar-disconnected-events.png" alt="Calendar Disconnected Events" /></p>

=end HTML

To display events that span multiple days, such as the full expected
duration of a change blackout period, define the fields using the
C<%CalendarMultipleDaysEvents> configuration. This option accepts
named keys that each define the field to reference for the start (Starts)
and end (Ends) of multi-day events. For example:

    Set( %CalendarMultipleDaysEvents, (
        'Project Task' => {
            'Starts' => 'Starts',
            'Ends'   => 'Due',
        },
    ));

=begin HTML

<p><img src="https://static.bestpractical.com/images/calendar/calendar-multiple-days-events.png" alt="Calendar Multi-days Events" /></p>

=end HTML

The keys, like C<Project Task>, are arbitrary labels to group each
set, so you can use a name that helps you identify the entry.

You can also define multiple day events for custom fields by using the
following format:

    Set( %CalendarMultipleDaysEvents, (
        'Maintenance' => {
            "Starts" => "CF.{Maintenance Start}",
            "Ends"   => "CF.{Maintenance Stop}",
        },
        'Project Task' => {
            'Starts' => 'Starts',
            'Ends'   => 'Due',
        },
    ));

As with all calendar entries, the date fields referenced in the
configuration must be included in the search result Format to
display the event on the Calendar.

=head1 AUTHOR

Best Practical Solutions, LLC

Originally written by Nicolas Chuche E<lt>nchuche@barna.beE<gt>

=head1 BUGS

All bugs should be reported via email to

    L<bug-RTx-Calendar@rt.cpan.org|mailto:bug-RTx-Calendar@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RTx-Calendar>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2010-2023 by Best Practical Solutions

Copyright 2007-2009 by Nicolas Chuche

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
