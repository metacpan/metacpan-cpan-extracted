#!/usr/bin/env perl

use strict;
use warnings;

use LWP::UserAgent;
use JSON;
use Scalar::Dynamizer qw(dynamize);

# API URL for random cat facts
my $api_url = 'https://catfact.ninja/fact';

# Configure the HTTP client
my $ua = LWP::UserAgent->new( agent => 'Mozilla/5.0' );

# Dynamized scalar to fetch a new random cat fact on each access
my $fact = dynamize {
    my $response = $ua->get($api_url);

    unless ( $response->is_success ) {
        return "Failed to fetch a cat fact: " . $response->status_line;
    }

    return decode_json( $response->decoded_content )->{'fact'};
};

while (1) {
    print "$fact\n\n";
    sleep(2);
}
