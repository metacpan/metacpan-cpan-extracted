use strict;
use warnings;

$ENV{CATALYST_DEBUG}=0;
$ENV{CATALYST_CONFIG}='t/var/osgood_server.yml';

# use Catalyst::Test 'Osgood::Server';
use HTTP::Headers;
use HTTP::Request;
use HTTP::Request::Common;
use Test::More;
use lib 't/lib';

use OsgoodTest;
use Osgood::Client;
use Osgood::Event;
use Osgood::EventList;

BEGIN {
    eval "use DBD::SQLite";
    plan $@ ? (skip_all => 'Needs DBD::SQLite for testing') : ( tests => 4);
}

use_ok 'Catalyst::Test', 'Osgood::Server';

my $schema = OsgoodTest->init_schema();
ok($schema, 'Got a schema');

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

my $req2 = HTTP::Request->new('POST', '/event');
my $content2 = $list->freeze;

$req2->content_type('application/json');
$req2->content_length(do { use bytes; length($content2) });
$req2->content($content2);
my $response2 = request($req2);
cmp_ok($response2->code, '==', 200, 'got 200');

my $events = $schema->resultset('Event')->search;
cmp_ok($events->count, '==', 3, '3 events');