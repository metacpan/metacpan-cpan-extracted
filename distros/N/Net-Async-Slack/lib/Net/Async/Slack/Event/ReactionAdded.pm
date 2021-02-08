package Net::Async::Slack::Event::ReactionAdded;

use strict;
use warnings;

our $VERSION = '0.007'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::ReactionAdded - A member has added an emoji reaction to an item

=head1 DESCRIPTION

Example input data:

    reactions:read

=cut

sub type { 'reaction_added' }

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2016-2021. Licensed under the same terms as Perl itself.
