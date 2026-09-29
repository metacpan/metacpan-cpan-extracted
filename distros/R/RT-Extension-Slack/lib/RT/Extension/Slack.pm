use strict;
use warnings;
package RT::Extension::Slack;

our $VERSION = '1.1';

=head1 NAME

RT-Extension-Slack - Send and sync RT ticket notifications to Slack

=head1 RT VERSION

Works with RT 6.

=head1 DESCRIPTION

This RT extension allows for creating Slack messages linked to RT tickets.
    -Custom formatting based on status
    -Provides Take/Steal links
    -Slack messages are updated when Status, Owner, or Subject are modified.


=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item C<make initdb>

Only run this the first time you install this module.

If you run this twice, you may end up with duplicate data in your
database.

=item Edit your F</opt/rt6/etc/RT_SiteConfig.pm>

        Add this line:

            Plugin('RT::Extension::Slack');

        See below for additional configuration details.

=item Clear your mason cache

    rm -rf /opt/rt6/var/mason_data/obj

=item Restart your webserver

=back

=head1 CONFIGURATION

=over

=item Create a Slack App

Create a new Slack App from a manifest 
(see /opt/rt6/local/plugins/RT-Extension-Slack/etc/Slack_Manifest.json)
Install it to your workspace and copy the Bot User OAuth Token (starts with xoxb-).

Invite the app to every Slack channel you intend to map below.
Posts to a channel the bot hasn't joined will fail silently.

=item Set your Bearer Token

Copy:
        F</opt/rt6/local/plugins/RT-Extension-Slack/etc/Slack_Token.pm.example>
    to:
        F</opt/rt6/etc/RT_SiteConfig.d/Slack_Token.pm>
    and set your token:
        Set($SlackToken, 'xoxb-your-real-token');

=item Configure URLs and Queue-to-Channel Mapping

    Copy:
        F</opt/rt6/local/plugins/RT-Extension-Slack/etc/Slack_Config.pm.example>
    to:
        F</opt/rt6/etc/RT_SiteConfig.d/Slack_Config.pm>

    Edit $slackURL and $rtURL.
    Edit %SlackQueueConfig to map RT Queue Names (case-sensitive) to 
    Slack Channel IDs. Get a channel ID by right-clicking the channel 
    in Slack > Channel details > View channel details > and it will be at the bottom.

=item Restart your webserver and clear your mason cache


=item Create the Scrip & Apply to Queues

    Create a new Scrip
        Applies to: Tickets
        Condition: SlackCondition
        Action: Slack
        Template: Blank

    The condition, action, and a slack_timestamp customfield were created
    via initialdata when you ran:
        make initdb
    during installation. Only queues with both the Scrip applied AND an 
    entry in %SlackQueueConfig will post to Slack.

=back

=head1 AUTHOR

    Josh Tackitt <tackittj@reed.edu>

=head1 LICENSE AND COPYRIGHT

This extension is Copyright (C) 2026 Reed College.

This is free software, licensed under:
  The GNU General Public License, Version 2, June 1991


=cut

1;
