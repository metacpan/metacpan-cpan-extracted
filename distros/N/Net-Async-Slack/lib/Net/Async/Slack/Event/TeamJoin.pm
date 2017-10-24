package Net::Async::Slack::Event::TeamJoin;

use strict;
use warnings;

our $VERSION = '0.002'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::TeamJoin - A new team member has joined

=head1 DESCRIPTION

Example input data:

    users:read

=cut

sub type { 'team_join' }

1;

