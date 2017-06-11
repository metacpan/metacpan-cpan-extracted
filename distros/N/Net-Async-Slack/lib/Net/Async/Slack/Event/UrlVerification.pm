package Net::Async::Slack::Event::UrlVerification;

use strict;
use warnings;

our $VERSION = '0.001'; # VERSION

use Net::Async::Slack::EventType;

=head1 NAME

Net::Async::Slack::Event::UrlVerification - Verifies ownership of an Events API Request URL

=head1 DESCRIPTION

Example input data:

    {
        "token": "Jhj5dZrVaK7ZwHHjRyZWjbDl",
        "challenge": "3eZbrw1aBm2rZgRNFdxV2595E9CY3gmdALWMmHkvFXO7tYXAYM8P",
        "type": "url_verification"
    }


=cut

sub type { 'url_verification' }

1;

