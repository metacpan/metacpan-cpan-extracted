
#!perl -w

use strict;
use Test::More tests => 14;
use Net::Gnip::Filter;
use_ok('Net::Gnip::FilterStream');

my $stream;
ok($stream = Net::Gnip::FilterStream->new, "Created filter stream");
is(scalar($stream->filters), 0, "Got 0 filters");

my $name   = "name";
my $full   = "true";
my $rules  = [ { type => 'actor', value => 'joe' } ]; 
my $filter = Net::Gnip::Filter->new($name, $full, $rules);
ok($stream->filters($filter), "Added a filter");
is(scalar($stream->filters), 1, "Got 1 filter");
my ($tmp) = $stream->filters;
is($tmp->name,      $name, "Got the same name back");
is($tmp->full_data, $full, "Got the same full data back");
is_deeply([$tmp->rules], $rules, "Got the same rules");

my $xml;
ok($xml = $stream->as_xml, "Got xml");
ok($stream = $stream->parse($xml), "Parsed xml");
is(scalar($stream->filters), 1, "Got 1 filter still");
($tmp) = $stream->filters;
is($tmp->name,      $name, "Got the same name back");
is($tmp->full_data, $full, "Got the same full data back");
is_deeply([$tmp->rules], $rules, "Got the same rules");
