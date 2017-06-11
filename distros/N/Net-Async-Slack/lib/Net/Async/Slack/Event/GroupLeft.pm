package Net::Async::Slack::Event::GroupLeft;

use strict;
use warnings;

our $VERSION = '0.001'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::GroupLeft - You left a private channel

=head1 DESCRIPTION

Example input data:

    {
        "type": "group_left",
        "channel": "G02ELGNBH"
    }


=cut

sub type { 'group_left' }

1;

