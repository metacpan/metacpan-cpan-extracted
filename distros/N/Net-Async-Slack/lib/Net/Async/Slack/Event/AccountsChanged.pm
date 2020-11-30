package Net::Async::Slack::Event::AccountsChanged;

use strict;
use warnings;

our $VERSION = '0.005'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::AccountsChanged - The list of accounts a user is signed into has changed

=head1 DESCRIPTION

Example input data:

    {
        "type": "accounts_changed"
    }


=cut

sub type { 'accounts_changed' }

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2016-2020. Licensed under the same terms as Perl itself.
