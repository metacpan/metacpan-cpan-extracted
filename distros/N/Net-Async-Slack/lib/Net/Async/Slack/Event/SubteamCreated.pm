package Net::Async::Slack::Event::SubteamCreated;

use strict;
use warnings;

our $VERSION = '0.001'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::SubteamCreated - A User Group has been added to the team

=head1 DESCRIPTION

Example input data:

    usergroups:read

=cut

sub type { 'subteam_created' }

1;

