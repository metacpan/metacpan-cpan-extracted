package Net::Async::Slack::Event::ReconnectURL;

use strict;
use warnings;

our $VERSION = '0.006'; # VERSION

=head1 NAME

Net::Async::Slack::Event::ReconnectURL - Experimental

=head1 DESCRIPTION

Example input data:

    {
        "type": "reconnect_url"
    }


=cut

use URI;

use Net::Async::Slack::EventType;

sub url { shift->{url} }

sub uri { $_[0]->{uri} //= URI->new($_[0]->url) }

sub type { 'reconnect_url' }

1;

