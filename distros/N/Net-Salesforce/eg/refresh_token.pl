#!/usr/bin/env perl
#
# refresh_token example
#
# ./eg/refresh_token.pl

use FindBin;
BEGIN { unshift @INC, "$FindBin::Bin/../lib" }

use Mojolicious::Lite;
use Net::Salesforce;
use DDP;

my $refresh_token = $ENV{"SFREFRESH_TOKEN"};

my $sf = Net::Salesforce->new(
    'key'           => $ENV{SFKEY},
    'secret'        => $ENV{SFSECRET},
    'redirect_uri'  => 'https://localhost:8081/callback'
);

my $payload = $sf->refresh($ENV{SFREFRESH_TOKEN});

p $payload;
