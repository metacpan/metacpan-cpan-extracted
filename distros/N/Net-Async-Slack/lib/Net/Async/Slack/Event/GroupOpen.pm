package Net::Async::Slack::Event::GroupOpen;

use strict;
use warnings;

our $VERSION = '0.002'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::GroupOpen - You opened a private channel

=head1 DESCRIPTION

Example input data:

    groups:read

=cut

sub type { 'group_open' }

1;

