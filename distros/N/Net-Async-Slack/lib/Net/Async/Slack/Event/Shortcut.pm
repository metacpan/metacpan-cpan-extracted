package Net::Async::Slack::Event::Shortcut;

use strict;
use warnings;

our $VERSION = '0.013'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::Shortcut - User selected a shortcut

=head1 DESCRIPTION

Example input data:

    {
        "action_ts": "1678943959.921154",
        "callback_id": "some_request",
        "enterprise": null,
        "is_enterprise_install": false,
        "team": {
            "domain": "example",
            "id => "T02038412",
        },
        "token": "I...",
        "trigger_id" => "2048348233713.13045238123.402bb8adc722834fe8a8a8ed7a82d1ac",
        "type": "shortcut",
        "user": {
            "id": "U1WC7C9E0",
            "team_id": "T0D277EE5",
            "username": "tom"
        }
    }


=cut

sub type { 'shortcut' }
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
