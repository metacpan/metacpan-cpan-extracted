#!perl -w

use strict;
use Test::More tests => 6;

use_ok("Net::Gnip::Publisher");


my $publisher;
my $name = "myname";
ok($publisher = Net::Gnip::Publisher->new($name), "Created publisher");
is($publisher->name, $name,                       "Got the same name back");

my $xml;
ok($xml = $publisher->as_xml,                      "Generated xml");
ok($publisher = Net::Gnip::Publisher->parse($xml), "Parsed XML again");
is($publisher->name, $name,                        "Got the same name back again");
