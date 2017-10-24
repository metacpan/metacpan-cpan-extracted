package Net::Async::Slack::Event::GroupUnarchive;

use strict;
use warnings;

our $VERSION = '0.002'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::GroupUnarchive - A private channel was unarchived

=head1 DESCRIPTION

Example input data:

    groups:read

=cut

sub type { 'group_unarchive' }

1;

