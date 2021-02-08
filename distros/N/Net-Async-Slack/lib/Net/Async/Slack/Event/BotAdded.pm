package Net::Async::Slack::Event::BotAdded;

use strict;
use warnings;

our $VERSION = '0.007'; # VERSION

use parent qw(Net::Async::Slack::Event::Bot);

use Net::Async::Slack::EventType;

=head1 DESCRIPTION

    {
     "type": "bot_added",
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

sub type { 'bot_added' }

1;

