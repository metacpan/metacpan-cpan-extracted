package Net::Async::Slack::Event::ReconnectUrl;

use strict;
use warnings;

our $VERSION = '0.002'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::ReconnectUrl - Experimental

=head1 DESCRIPTION

Example input data:

    {
        "type": "reconnect_url"
    }


=cut

sub type { 'reconnect_url' }

1;

