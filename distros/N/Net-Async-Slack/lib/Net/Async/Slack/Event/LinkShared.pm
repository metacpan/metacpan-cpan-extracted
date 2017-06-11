package Net::Async::Slack::Event::LinkShared;

use strict;
use warnings;

our $VERSION = '0.001'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::LinkShared - A message was posted containing one or more links relevant to your application

=head1 DESCRIPTION

Example input data:

    links:read

=cut

sub type { 'link_shared' }

1;

