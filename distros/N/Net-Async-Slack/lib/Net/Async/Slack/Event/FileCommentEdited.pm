package Net::Async::Slack::Event::FileCommentEdited;

use strict;
use warnings;

our $VERSION = '0.001'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::FileCommentEdited - A file comment was edited

=head1 DESCRIPTION

Example input data:

    files:read

=cut

sub type { 'file_comment_edited' }

1;

