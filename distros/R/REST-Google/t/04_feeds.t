#
# $Id$

use strict;

use Test::More tests => 5;

use REST::Google::Feeds;

REST::Google::Feeds->http_referer('http://www.cpan.org');

use Data::Dumper;

# The official google blog
my $res = REST::Google::Feeds->new('http://feedproxy.google.com/blogspot/MKuf');

is($res->responseStatus, 200, "response ok");

my $feed = $res->responseData->feed;
isa_ok($feed, "REST::Google::Feeds::Feed", "feed object");

my $entries = $feed->entries;
is(ref $entries, "ARRAY", "entries are arrayref");
ok(@$entries, "entries are not empty");

my $entry = $entries->[0];

isa_ok($entry, "REST::Google::Feeds::Entry", "entry object");


