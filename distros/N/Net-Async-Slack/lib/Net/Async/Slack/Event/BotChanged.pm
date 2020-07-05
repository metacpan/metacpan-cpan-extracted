package Net::Async::Slack::Event::BotChanged;

use strict;
use warnings;

our $VERSION = '0.004'; # VERSION

use parent qw(Net::Async::Slack::Event::Bot);

use Net::Async::Slack::EventType;

=head1 DESCRIPTION

    {
     "type": "bot_changed",
     "bot": {
      "id": "B024BE7LH",
      "app_id": "A4H1JB4AZ",
      "name": "hugbot",
      "icons": {
       "image_48": "url here"
      }
     }
    }

=cut


sub id { shift->{bot}{id} }

sub app_id { shift->{bot}{app_id} }

sub name { shift->{bot}{name} }

sub type { 'bot_changed' }

1;

