package Net::Async::Slack::Event::GroupArchive;

use strict;
use warnings;

our $VERSION = '0.002'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::GroupArchive - A private channel was archived

=head1 DESCRIPTION

Example input data:

    groups:read

=cut

sub type { 'group_archive' }

1;

