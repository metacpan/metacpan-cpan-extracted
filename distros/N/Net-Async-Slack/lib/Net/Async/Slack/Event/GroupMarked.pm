package Net::Async::Slack::Event::GroupMarked;

use strict;
use warnings;

our $VERSION = '0.002'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::GroupMarked - A private channel read marker was updated

=head1 DESCRIPTION

Example input data:

    {
        "type": "group_marked",
        "channel": "G024BE91L",
        "ts": "1401383885.000061"
    }


=cut

sub type { 'group_marked' }

1;

