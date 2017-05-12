
#!perl -w

use strict;
use Test::More tests => 10;
use Net::Gnip::Publisher;
use_ok('Net::Gnip::PublisherStream');

my $stream;
ok($stream = Net::Gnip::PublisherStream->new, "Created filter stream");
is(scalar($stream->publishers), 0,  "Got 0 publishers");

my $name = "myname";
my $publisher = Net::Gnip::Publisher->new($name);

ok($stream->publishers($publisher), "Added a publisher");
is(scalar($stream->publishers), 1,  "Got 1 filter");
my ($tmp) = $stream->publishers;
is($tmp->name,      $name,          "Got the same name back");

my $xml;
ok($xml = $stream->as_xml,          "Got xml");
ok($stream = $stream->parse($xml),  "Parsed xml");
is(scalar($stream->publishers), 1,  "Got 1 filter still");
($tmp) = $stream->publishers;
is($tmp->name,      $name,          "Got the same name back");
