use strict;

use Test::More;

my $osurl = $ENV{'OSGOOD_SERVER_URL'};

plan skip_all => 'Set $ENV{OSGOOD_SERVER_URL} to run this test.' unless $osurl;

plan tests => 12;

use DateTime;
use Osgood::Client;
use Osgood::Event;
use Osgood::EventList;
use URI;

my $uri = URI->new($ENV{'OSGOOD_SERVER_URL'});
my $client = Osgood::Client->new({ url => $uri });

my $event1 = Osgood::Event->new(
	object => 'Person',
	action => 'sneezed',
	date_occurred => DateTime->now
);
my $event2 = Osgood::Event->new(
	object => 'Person',
	action => 'sneezed',
	date_occurred => DateTime->now
);
my $event3 = Osgood::Event->new(
	object => 'Person',
	action => 'sneezed',
	date_occurred => DateTime->now
);
my $list = Osgood::EventList->new(events => [ $event1, $event2, $event3 ]);

$client->list($list);
my $retval = $client->send;
cmp_ok($list->size, 'eq', $retval, 'add correct number');

$retval = $client->query({
     object => 'Person',
     action => 'sneezed',
});

ok($retval, 'query succeeded');
isa_ok($client->list, 'Osgood::EventList');
ok($client->list->size, 'got events');
my $iterator = $client->list->iterator;
my $nevent = $iterator->next;
isa_ok($nevent, 'Osgood::Event');
cmp_ok($nevent->object, 'eq', 'Person', 'Event object');
cmp_ok($nevent->action, 'eq', 'sneezed', 'Event action');

# Since we inserted 3 events, we are guaranteed to have at least one event
# between these two.
my $lowid = $nevent->id;
my $highid = $client->list->get_highest_id;

# Test id_greater
$retval = $client->query({
     object => 'Person',
     action => 'sneezed',
     id_greater => $lowid
});
ok($retval, 'query succeeded');
$iterator = $client->list->iterator;
$nevent = $iterator->next;
cmp_ok($nevent->id, '>', $lowid, 'id_greater');

# Test id_less
$retval = $client->query({
     object => 'Person',
     action => 'sneezed',
     id_less => $lowid
});
ok($retval, 'query succeeded');

# Test id_less
$retval = $client->query({
     object => 'Person',
     action => 'sneezed',
});
ok($retval, 'query succeeded');
ok($client->list->size, 'people sneezed');
