package Net::Async::Slack::Event::Bot;

use strict;
use warnings;

our $VERSION = '0.007'; # VERSION

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

sub icons { shift->{bot}{icons} }

1;


