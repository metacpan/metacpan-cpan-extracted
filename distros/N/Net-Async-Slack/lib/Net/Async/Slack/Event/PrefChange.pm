package Net::Async::Slack::Event::PrefChange;

use strict;
use warnings;

our $VERSION = '0.001'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::PrefChange - You have updated your preferences

=head1 DESCRIPTION

Example input data:

    {
        "type": "pref_change",
        "name": "messages_theme",
        "value": "dense"
    }


=cut

sub type { 'pref_change' }

1;

