use strict;
use warnings;
package RT::Extension::Announce;

our $VERSION = '1.05';

RT->AddJavaScript('announce.js');
RT->AddStyleSheets('announce.css');

sub GetAnnouncements {
    my $current_user     = shift;
    my $form_tools_group = shift || 'RT Homepage';

    my $AnnounceQueue = RT->Config->Get('RTAnnounceQueue') || 'RTAnnounce';
    my $Queue = RT::Queue->new( RT->SystemUser );
    $Queue->Load($AnnounceQueue);
    unless ( $Queue->Id ) {
        $RT::Logger->error(
'RTAnnounce queue not found for Announce extension. Did you run make initdb?'
        );
        return;
    }

    my @tickets;

    # Get announce tickets.
    my $tickets = RT::Tickets->new( RT->SystemUser );
    $tickets->OrderBy( FIELD => 'LastUpdated', ORDER => 'DESC' );
    my @statuses = $Queue->ActiveStatusArray();
    @statuses = map { s/(['\\])/\\$1/g; "Status = '$_'" } @statuses;
    my $status_query = join( ' OR ', @statuses );
    my $ticket_sql = "Queue = '$AnnounceQueue' AND ( $status_query )";
    if ( RT->Config->Get('ShowAnnouncementsInFormTools') && RT->Config->Get('FormToolsEnableGroups') ) {
        my @form_groups = ( "'CF.{Announcement FormTools Groups}' = '$form_tools_group'" );
        if ( $form_tools_group eq 'RT Homepage' ) {
            push @form_groups, "'CF.{Announcement FormTools Groups}' IS NULL";
        }
        $ticket_sql .= ' AND (  ' . join( ' OR ', @form_groups ) . '  )';
    }
    $tickets->FromSQL($ticket_sql);
    return if $tickets->Count == 0;

    my $who = $current_user->Name;

    # Get groups for each ticket
    while ( my $ticket = $tickets->Next ) {
        my $tid    = $ticket->id;
        my $groups = $ticket->CustomFieldValues('Announcement Groups');

        my @groups;
        while ( my $group = $groups->Next ) {
            push @groups, $group->Content;
        }

        unless (@groups) {

            # No groups defined, everyone sees announcement
            RT->Logger->debug(
                "Showing announcement #$tid to $who: not limited to any groups"
            );
            push @tickets, $ticket;
            next;
        }

        foreach my $group_name (@groups) {
            my $group_obj = RT::Group->new( RT->SystemUser );
            $group_obj->LoadUserDefinedGroup($group_name);

            unless ( $group_obj->Id ) {
                $RT::Logger->error(
"Cannot find group '$group_name' for announcement #$tid (for $who)"
                );
                next;
            }

            if ( $group_obj->HasMemberRecursively( $current_user->PrincipalObj )
              )
            {
                # User can see this announcement.
                RT->Logger->debug(
"Showing announcement #$tid to $who: member of '$group_name'"
                );
                push @tickets, $ticket;
            }
            else {
                $RT::Logger->debug(
                        "Not showing announcement ticket #$tid to user $who "
                      . "because they are not in group $group_name" );
            }
        }
    }
    return @tickets;
}


=head1 NAME

RT-Extension-Announce - Display announcements as a banner on RT pages.

=head1 RT VERSION

Works with RT 4.0, 4.2, 4.4, 5.0.

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt5/etc/RT_SiteConfig.pm>

If you are using RT 4.2 or greater, add this line:

    Plugin('RT::Extension::Announce');

For RT 4.0, add this line:

    Set(@Plugins, qw(RT::Extension::Announce));

or add C<RT::Extension::Announce> to your existing C<@Plugins> line.

And add the following:

    Set(@CustomFieldValuesSources, (qw(RT::CustomFieldValues::AnnounceGroups)));

See L</CONFIGURATION> for more options.

=item C<make initdb>

Only run this the first time you install this module.

If you run this twice, you may end up with duplicate data
in your database.

If you are upgrading this module, check for upgrading instructions
in case changes need to be made to your database.

=item Clear your mason cache

    rm -rf /opt/rt5/var/mason_data/obj

=item Restart your webserver

=back

=head1 DESCRIPTION

The Announce extension gives you an easy way to insert announcements on the RT
homepage so all users can see the message. You may want to display a banner
during maintenance or an unscheduled outage to make sure the people fielding
customer tickets know that something is going on.

=for html <p><img src="https://raw.github.com/bestpractical/rt-extension-announce/master/doc/images/announce-screenshot.png" alt="RT Announcement on Homepage" /></p>

=head1 DETAILS

When you install the extension, a new queue is created called RTAnnounce.
To post an announcement, create a ticket in that queue. The extension displays
on the RT homepage the subject and most recent correspondence on active
tickets in the RTAnnounce queue. As the incident or maintenance progresses,
just reply to the ticket and the announcement will be updated with the latest
information.

When multiple announcements are active, they are ordered by
the last update time with the announcement with the most recent
update coming first.

When the incident is over, resolve the ticket and the announcement will be
removed.

Comments on announce tickets are not shown in the announcement. However,
comments are visible on the ticket for users who have permission to view
the full ticket. If you have multiple announcements, a new comment updates
the last updated time and will move the announcement to the top of the list.

=head1 ANNOUNCEMENT GROUPS

The RTAnnounce queue has a custom field called 'Announcement Groups' which
you can use to manage who will see an announcement. If you set no value, all
users will see the announcement. If you set one or more RT groups, only members
of those groups will see it.

=head1 PERMISSIONS

By default, the announcements are static text. If you give
users the ShowTicket right on the RTAnnounce queue, the announcements
will have links to the source tickets. This will allow users to see the
history of an announcement or see longer messages that might be
truncated on the homepage.

The RTAnnounce queue is a regular queue, so you can control access to creating
announcements the same way you manage permissions on other queues.

In addition to setting permissions, you may not
want to send the typical 'ticket create' email messages, so you could change
or customize the scrips that run or create new templates. If you send
announcement messages to an email list,
you could create a list user in RT and add it as a CC to the announcement
queue. Then messages posted for announcement in RT will also be sent to the
notification list.

=head1 RT-Extension-FormTools

If you would like to show announcements on FormTools form pages look at the
configuration option C<$ShowAnnouncementsInFormTools> in the CONFIGURATION
section below.

=head1 CONFIGURATION

=head2 C<$RTAnnounceQueue>

Use this to change the name of the queue used for announcements. First edit the
RTAnnounce queue in RT and change its name to your new name. Then a line
to your RT_SiteConfig.pm to set that new value:

    Set($RTAnnounceQueue, 'Custom Announce Name');

=head2 C<@AnnounceGroups>

By default, all user defined groups will be listed in "Announcement
Groups". If you have a large number of groups in your RT, this can make for
a long list, so you can customize the group list by setting C<@AnnounceGroups>
in your RT_SiteConfig.pm:

    Set(@AnnounceGroups, 'foo', 'bar', 'baz');

=head2 C<$ShowAnnouncementsInSelfService>

Set this to true to show announcements on the self service page as well as
the regular privileged RT page.

=head2 C<$RTAnnounceAllowHTML>

If set to true, the banner content will be set to 'text/html' and allow HTML rendering.

If the content of the message is large there is an option to wrap the content
in overflow divs. In the source HTML of the message, wrap the bottom part of the message
in the following: C<E<lt>div class="RTAnnounceBannerOverflow"E<gt>E<lt>/divE<gt>>.
The top part of the message will be shown with a scrollbar and the part contained in
the div will be hidden. Users can view the bottom section by scrolling without taking
up too much room at the top of the page.

=head2 C<$ShowAnnouncementsInFormTools>

Set this to true to show announcements on FormTools pages.

You will need to add a custom field to the queue used for announcements.

First update the C<@CustomFieldValuesSources> config setting to the following:

    Set(@CustomFieldValuesSources, (qw(RT::CustomFieldValues::AnnounceGroups RT::CustomFieldValues::FormToolsGroups)));

Then add create a new custom field and apply it to the queue used for
announcements:

    Name:                Announcement FormTools Groups
    Type:                Select multiple values
    Field values source: RT user defined FormTools groups for the RT Announce plugin
    Applies to:          Tickets

When creating a new announcement ticket select values in the new custom field to
control where the announcement will be displayed.

If the custom field is left empty the announcement will only display on the
homepage. If one or more values are selected the announcement will only display
for the values selected.

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head1 BUGS

All bugs should be reported via email to

    L<bug-RT-Extension-Announce@rt.cpan.org|mailto:bug-RT-Extension-Announce@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-Announce>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2012-2024 by Best Practical Solutions, LLC

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
