use strict;
use warnings;
package RT::Extension::TimeTracking;

our $VERSION = '0.20';

RT->AddStyleSheets("time_tracking.css");
RT->AddJavaScript("time_tracking.js");

RT::System->AddRight( Admin => AdminTimesheets  => 'Add time worked for other users' );

# RT::Date does weedkay abbreviations, but not full weekday names.
our @DAYS_OF_WEEK = (
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
);

our %WEEK_INDEX = (
    Sunday    => 0,
    Monday    => 1,
    Tuesday   => 2,
    Wednesday => 3,
    Thursday  => 4,
    Friday    => 5,
    Saturday  => 6,
);

=head1 NAME

RT-Extension-TimeTracking - Time Tracking Extension

=head1 RT VERSION

Works with RT 5.0. Check 0.1* versions if you are using RT 4.

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item C<make initdb>

Only run this the first time you install this module.

If you run this twice, you may end up with duplicate data
in your database.

If you are upgrading this module, check for upgrading instructions
in case changes need to be made to your database.

=item Edit your F</opt/rt5/etc/RT_SiteConfig.pm>

Add this line:

    Plugin('RT::Extension::TimeTracking');

=item Clear your mason cache

    rm -rf /opt/rt5/var/mason_data/obj

=item Restart your webserver

=back

=head2 Configure Custom Fields

This extension installs two transaction custom fields to track time data:
Actor and Worked Date. Since the visibility of these fields is very
specific to your usage, no permissions are set during the install.

You need to give all users tracking time permission to view and
modify these custom fields. You can do this using RT's standard rights
management by navigating to the custom fields: Admin > Custom Fields >
Select, clicking on each one, and editing the Group Rights. You can
then give rights to Everyone, a custom group, or any other variation
that makes sense for your instance.

If permissions are not set correctly on these custom fields, you will
see strange behavior like all time being recorded on the current day
rather than the date you select.

=head1 DESCRIPTION

RT::Extension::TimeTracking adds several features to make it easier to use
RT to track time for you and your team as you work on tasks. These
features include breakdowns of time by user on tickets, tracking time for
specific days, including in the past, and a new page that organizes all of
your time for the past week. You can find details on configuration in the
next section.

=head2 Entering Time

When running this extension, you can still use all of the existing methods
to track time in RT including editing Basics, adding time on a comment or
reply, or even using the new ticket timer introduced in RT 4.4. All of
these will record the time and log it with a transaction at the current
day and time.

The TimeTracking extension adds a new feature to track a "Worked Date"
for cases where you forgot to enter your time for work you did earlier
in the week. For these cases, you'll see a new date field in Basics
where you can select a date and time worked and add it directly to the
ticket. You'll also see Worked Date on replies and comments to track to a
different day from the day you are recording the comment.

=begin HTML

<p><img width="500px" src="http://static.bestpractical.com/images/timetracking/timetracking-basics-shadow.png"
alt="Basics with TimeTracking" /></p>

=end HTML

TimeTracking also installs a new page at Tools > My Week. This shows a summary
of all of your time tracked for the week by day. In addition to showing you
your week, you can track time directly on the page as well for whichever day
you need to. You can add new tickets and time below each day using the ticket
box. The Ticket selection box has autocomplete functionality, so you can just
start typing something from the subject of a ticket to find it. And you can
update tickets already in your list with the boxes in the Update column.

The total hours for the week are displayed at the bottom of the page.

=begin HTML

<p><img src="http://static.bestpractical.com/images/timetracking/timetracking-my-week-shadow.png"
alt="Basics with TimeTracking" /></p>

=end HTML

=head3 Fixing Mistakes

If you accidentally add time for the wrong day or ticket, you can subtract it
by entering a negative value on the ticket for that day.

=head2 Time Summary on Tickets

On individual tickets, in addition to seeing the Add time worked boxes in Basics,
this extension also adds a Worked section with a summary of the total time worked
per user on that ticket.

=head2 Viewing Other Weeks on My Week

You can view other weeks on My Week by selecting any day in the desired week using
the date picker at the top of the page. You can also use the Previous and Next
links to move from week to week.

=head2 Administrative View

TimeTracking adds a right to allow some users to see the My Week page for other
users and enter time for them. The right is in Admin > Global > Group Rights
on the Rights for Administrators tab. It's labelled "Add time worked for other
users" and should be at the top of the tab.

Once you have this right, you'll see an addition selection box at the top
of the My Week page for selecting a user. You can then use the autocomplete
box to find another user and display their timesheet.

This allows managers or similar staff to see timesheets for their team and also
add time if another user is out of the office sick or otherwise can't add time
themselves. All entries made by an admin user on another user's timesheet
are recorded as entered by the admin user using the Actor custom field. This
keeps an audit trail to avoid confusion over who may have added a time entry.

=head1 CONFIGURATION

=head2 C<$TimeTrackingFirstDayOfWeek>

The default week start day in MyWeek page is Monday, you can change it by
setting C<$TimeTrackingFirstDayOfWeek>, e.g.

    Set($TimeTrackingFirstDayOfWeek, 'Wednesday');

=head2 C<$TimeTrackingDisplayCF>

In the ticket listings on the My Week page, there is a room for an additional
field next to Status, Owner, etc. To display a custom field that might be
helpful when filling out your timesheet, you can set $TimeTrackingDisplayCF
to the name of that custom field. In the display, that field name will be
added to the ticket heading between Owner and Time Worked for each
day on My Week. The value will be populated for each ticket.

=head1 METHODS

=head2 WeekStartDate

Accepts an RT::User object, an RT::Date object and a day of the week (Monday,
Tuesday, etc.) and calculates the start date for the week the date object is
in using the passed day as the first day of the week. The default
first day of the week is Monday.

Returns:

($ret, $week_start, $first_day)

where $ret is true on success, false on error, $week_start is an RT::Date
object set to the calculated date, and $first_day is a string of the first
day of the week, either from $TimeTrackingFirstDayOfWeek or the default of
Monday.

=cut

sub WeekStartDate {
    my $user = shift;
    my $date = shift;
    my $first_day = shift;

    $first_day //= 'Monday';
    $first_day = ucfirst lc $first_day;

    unless ( $first_day and exists $WEEK_INDEX{$first_day} ){
        RT->Logger->warning("Invalid TimeTrackingFirstDayOfWeek value: "
             . "$first_day. It should be one of Monday, Tuesday, etc.");
        return (0, "Invalid day of week set for TimeTrackingFirstDayOfWeek");
    }

    my $day = ($date->Localtime('user'))[6];
    my $week_start = RT::Date->new($user);

    if ( $day == $WEEK_INDEX{$first_day} ){
        # Set to same day passed in
        $week_start->Set( Format => 'unix', Value => $date->Unix );
    }
    else{
        # Calculate date of first day of the week
        require Time::ParseDate;
        my $seconds = Time::ParseDate::parsedate("last $first_day",
            NOW => $date->Unix );
        $week_start->Set( Format => 'unix', Value => $seconds );
    }

    return (1, $week_start, $first_day);
}

=head2 SetDateToMidnightForDST

Accepts an RT::Date object expected to be at midnight, but probably is not yet
because of DST, this method adjusts it accordingly. Note that the adjustment
is inplace.

=cut

sub SetDateToMidnightForDST {
    my $self = shift;
    my $date = shift;
    return unless $date && $date->isa( 'RT::Date' );

    my $user_hour = ( $date->Localtime( 'user' ) )[ 2 ];
    if ( $user_hour == 23 ) {
        $date->AddSeconds( 3600 );
    }
    elsif ( $user_hour == 1 ) {
        $date->AddSeconds( -3600 );
    }
}


=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head1 BUGS

All bugs should be reported via email to: L<bug-RT-Extension-TimeTracking@rt.cpan.org|mailto:bug-RT-Extension-TimeTracking@rt.cpan.org>

Or via the web at: L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-TimeTracking>.

=head1 COPYRIGHT

This extension is Copyright (C) 2013-2020 Best Practical Solutions, LLC.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
