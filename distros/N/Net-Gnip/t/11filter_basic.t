#!perl -wT

use strict;
use lib qw(t/lib);
use GnipTest;
use Net::Gnip;
use Net::Gnip::Filter;
use DateTime;
use Test::More;

GnipTest::plan_tests(24);

my $gnip;
ok($gnip = Net::Gnip->new($ENV{GNIP_TEST_USERNAME}, $ENV{GNIP_TEST_PASSWORD}), "Created publisher");

is(scalar($gnip->filters($ENV{GNIP_TEST_PUBLISHER})), 0, "Got 0 filters");


# Create a filter and
my @rules  = ( { type => 'actor', value => 'joe' } );
my $name   = 'myfilter';
my $filter = Net::Gnip::Filter->new($name, 'true', [@rules]);
ok($gnip->create_filter($ENV{GNIP_TEST_PUBLISHER}, $filter), "Created publisher");

my @filters;
ok(@filters = $gnip->filters($ENV{GNIP_TEST_PUBLISHER}), "Got filters");
is(scalar(@filters), 1, "Got 1 filter");
is($filters[0]->name, "$name", "Got the same name");
is_deeply([$filters[0]->rules], [@rules], "Got the same rules");

push @rules, { type => 'actor', value => 'me' };
$filter->rules(@rules);
ok($gnip->update_filter($ENV{GNIP_TEST_PUBLISHER}, $filter), "Updated publisher");
ok(@filters = $gnip->filters($ENV{GNIP_TEST_PUBLISHER}), "Got filters again");
is(scalar(@filters), 1, "Got 1 filter again");
is($filters[0]->name, "$name", "Got the same name");
is(scalar($filters[0]->rules), scalar(@rules), "Got the same rules again");

ok($gnip->add_filter_rule($ENV{GNIP_TEST_PUBLISHER}, $filter, 'actor', 'godot'), "Added a filter rule");
ok(@filters = $gnip->filters($ENV{GNIP_TEST_PUBLISHER}), "Got filters once more");
is(scalar(@filters), 1, "Got 1 filter again");
is($filters[0]->name, "$name", "Got the same name");
is(scalar($filters[0]->rules), scalar(@rules)+1, "Got the same rules again");

ok($gnip->delete_filter_rule($ENV{GNIP_TEST_PUBLISHER}, $filter, 'actor', 'godot'), "Deleted a filter rule");
ok(@filters = $gnip->filters($ENV{GNIP_TEST_PUBLISHER}), "Got filters once more");
is(scalar(@filters), 1, "Got 1 filter again");
is($filters[0]->name, "$name", "Got the same old name");
is(scalar($filters[0]->rules), scalar @rules, "Got the same old rules again");





ok($gnip->delete_filter($ENV{GNIP_TEST_PUBLISHER}, $filter), "Deleted filter");

is(scalar($gnip->filters($ENV{GNIP_TEST_PUBLISHER})), 0, "Got 0 filters again");
