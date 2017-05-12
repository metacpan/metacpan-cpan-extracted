#!perl
use strict;
use warnings;
use lib 'lib';
use Term::Prompt;
use Net::Google::DataAPI::Auth::OAuth2;
use Net::Google::Spreadsheets;

my $oauth2 = Net::Google::DataAPI::Auth::OAuth2->new(
    client_id => $ENV{CLIENT_ID},
    client_secret => $ENV{CLIENT_SECRET},
    scope => ['http://spreadsheets.google.com/feeds/'],
);
my $url = $oauth2->authorize_url();
system("open '$url'");
my $code = prompt('x', 'paste code: ', '', '');
my $token = $oauth2->get_access_token($code);
# my $refresh_token = $token->refresh_token;
my $service = Net::Google::Spreadsheets->new(auth => $oauth2);
my @items = $service->spreadsheets;
binmode(STDOUT, ':utf8');
print $_->title . "\n" for @items;
