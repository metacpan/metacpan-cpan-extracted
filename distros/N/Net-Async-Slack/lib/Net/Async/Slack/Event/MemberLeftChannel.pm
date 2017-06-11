package Net::Async::Slack::Event::MemberLeftChannel;

use strict;
use warnings;

our $VERSION = '0.001'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::MemberLeftChannel - A user left a public or private channel

=head1 DESCRIPTION

Example input data:

    channels:read

=cut

sub type { 'member_left_channel' }

1;

