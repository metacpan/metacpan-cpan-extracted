package Net::Async::Slack::Event::MessageMpim;

use strict;
use warnings;

our $VERSION = '0.005'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::MessageMpim - A message was posted in a multiparty direct message channel

=head1 DESCRIPTION

Example input data:

    mpim:history

=cut

sub type { 'message.mpim' }

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2016-2020. Licensed under the same terms as Perl itself.
