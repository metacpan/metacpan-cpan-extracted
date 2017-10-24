package Net::Async::Slack::Event::ImCreated;

use strict;
use warnings;

our $VERSION = '0.002'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::ImCreated - A DM was created

=head1 DESCRIPTION

Example input data:

    im:read

=cut

sub type { 'im_created' }

1;

