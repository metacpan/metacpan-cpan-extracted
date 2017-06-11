package Net::Async::Slack::Event::SubteamSelfRemoved;

use strict;
use warnings;

our $VERSION = '0.001'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::SubteamSelfRemoved - You have been removed from a User Group

=head1 DESCRIPTION

Example input data:

    usergroups:read

=cut

sub type { 'subteam_self_removed' }

1;

