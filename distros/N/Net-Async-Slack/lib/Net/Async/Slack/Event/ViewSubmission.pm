package Net::Async::Slack::Event::ViewSubmission;

use strict;
use warnings;

our $VERSION = '0.013'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::ViewSubmission - View submitted

=head1 DESCRIPTION

Example input data:

    {
    ...
    }


=cut

sub type { 'view_submission' }
sub view { shift->{view} }
sub callback_id { shift->{callback_id} }
sub trigger_id { shift->{trigger_id} }
sub action_ts { shift->{action_ts} }
sub token { shift->{token} }

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2016-2023. Licensed under the same terms as Perl itself.
