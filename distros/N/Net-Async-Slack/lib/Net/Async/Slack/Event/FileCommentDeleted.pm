package Net::Async::Slack::Event::FileCommentDeleted;

use strict;
use warnings;

our $VERSION = '0.001'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::FileCommentDeleted - A file comment was deleted

=head1 DESCRIPTION

Example input data:

    files:read

=cut

sub type { 'file_comment_deleted' }

1;

