package Net::Async::Slack::Event::FilePublic;

use strict;
use warnings;

our $VERSION = '0.002'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::FilePublic - A file was made public

=head1 DESCRIPTION

Example input data:

    files:read

=cut

sub type { 'file_public' }

1;

