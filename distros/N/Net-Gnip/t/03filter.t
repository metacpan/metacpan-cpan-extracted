#!perl -w

use strict;
use Test::More tests => 13;

use_ok("Net::Gnip::Filter");

my $filter;
my $name   = 'test';
my $full   = 'true';
my $jid    = 'testid';
my $rules  = [ { type => 'actor', value => 'joe' }];
ok($filter = Net::Gnip::Filter->new($name, $full, $rules, jid => $jid), "Created filter");
is($filter->name,      $name,                              "Got correct name");
is($filter->full_data, $full,                              "Got correct full data");
is({$filter->what}->{jid}, $jid,                           "Got correct jid");
is_deeply([$filter->rules], $rules,                        "Got correct rules");


my $xml    = "<filter name='$name' fullData='$full'>\n<jid>$jid</jid>\n<rule type='actor' value='joe' /></filter>";
ok($filter = $filter->parse($xml),                         "Parsed xml");
ok($xml    = $filter->as_xml,                              "Generated xml");
ok($filter = Net::Gnip::Filter->parse($xml),               "Parsed xml again");
is($filter->name,      $name,                              "Got correct name");
is($filter->full_data, $full,                              "Got correct full data");
is({$filter->what}->{jid}, $jid,                           "Got correct jid");
is_deeply([$filter->rules], $rules,                        "Got correct rules");

