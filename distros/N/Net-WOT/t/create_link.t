#!perl

use strict;
use warnings;

use Test::More tests => 1;

use Net::WOT;

my $wot  = Net::WOT->new;
my $link = $wot->_create_link('hello');
my $api  = $wot->api_base_url;
my $path = $wot->api_path;
my $ver  = $wot->version;

is(
    $link,
    "http://$api/$ver/$path?target=hello",
    'correct path created with target attr',
);

