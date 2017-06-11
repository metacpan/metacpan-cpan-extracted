package Net::Async::Slack::Event::ReconnectURL;

use strict;
use warnings;

our $VERSION = '0.001'; # VERSION

use Net::Async::Slack::EventType;

=head1 DESCRIPTION

{
"type":"reconnect_url",
"url":"wss://mpmulti-9w2u.slack-msgs.com/websocket/Sjb...zNIE="
}

=cut

use URI;

sub url { shift->{url} }

sub uri { $_[0]->{uri} //= URI->new($_[0]->url) }

sub type { 'reconnect_url' }

1;

